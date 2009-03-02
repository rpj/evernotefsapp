//
//  EvernoteFUSE+CacheThread.m
//  EvernoteFSApp
//
//  Created by Ryan Joseph on 3/1/09.
//  Copyright 2009 Ryan Joseph. All rights reserved.
//

#import "EvernoteFUSE.h"

@interface EvernoteFUSE (CacheThread)
- (void) generateCache:(id)arg;
- (void) refreshDiskCache;
@end

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
@implementation EvernoteFUSE (CacheThread)
///////////////////////////////////////////////////////////////////////////////
- (void) generateCache:(id)arg;
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	if (_econn) {
		EDAMNotebook* ntbk = nil;
		NSEnumerator* ntbkEnum = nil;
		
		// this thread modifies the cache, so must hold the lock regardless of condition
		[_structCacheLock lock];
		[_connLock lock];
		
		if (_structCache) {
			[_structCache release];
		}		
		
		@try {
			_structCache = [[NSMutableDictionary alloc] init];
			ntbkEnum = [[_econn listNotebooks] objectEnumerator];
			
			while ((ntbk = [ntbkEnum nextObject])) {
				[_structCache setObject:ntbk forKey:[ntbk name]];
			}
		}
		@catch (NSException* e) {
			NSLog(@"Exception in stage one: %@", e);
		}
		@finally {
			[_structCacheLock unlockWithCondition:kNotebookCacheReady];
			[_connLock unlock];
		}
		
		// here is where any consumers waiting on the kNotebookCacheReady condition but *not* needing to wait
		// for kNotesCacheReady may have the ability to gain the lock and do some processing...
		
		[_structCacheLock lockWhenCondition:kNotebookCacheReady];
		[_connLock lock];
		ntbkEnum = [[_structCache allKeys] objectEnumerator];
		NSString* ntbkName = nil;
		
		@try {
			while ((ntbkName = [ntbkEnum nextObject])) {
				ntbk = (EDAMNotebook*)[_structCache objectForKey:ntbkName];
				NSEnumerator* nEnum = [[_econn notesInNotebook:ntbk] objectEnumerator];
				EDAMNote* note = nil;
				NSMutableDictionary* ntbkDict = [NSMutableDictionary dictionary];
				
				while ((note = [nEnum nextObject])) {
					[ntbkDict setObject:note forKey:[note title]];
				}
				
				[ntbkDict setObject:ntbk forKey:kEDAMObjectSpecialKey];
				[_structCache setObject:ntbkDict forKey:ntbkName];
			}
		}
		@catch (NSException* e) {
			NSLog(@"Exception in stage two: %@", e);
		}
		@finally {
			[_structCacheLock unlockWithCondition:kNotesCacheReady];
			[_connLock unlock];
		}
		
		[self refreshDiskCache];
	}
	
	[pool release];
}

///////////////////////////////////////////////////////////////////////////////
- (BOOL) _checkFolderAndCreateIfNeeded:(NSString*)folder;
{
	NSFileManager* fmgr = [NSFileManager defaultManager];
	BOOL isDir = NO;
	BOOL retVal = YES;
	
	if (![fmgr fileExistsAtPath:folder isDirectory:&isDir] || !isDir) {
		if (!isDir) [fmgr removeFileAtPath:folder handler:nil];
		retVal = [fmgr createDirectoryAtPath:folder attributes:nil];
	}
	
	return retVal;
}

///////////////////////////////////////////////////////////////////////////////
- (void) _refreshNoteDiskCache:(EDAMNote*)note inNotebook:(NSString*)nbFolder;
{
	NSString* notePath = [NSString stringWithFormat:@"%@/%@", nbFolder, [note guid]];
	
	if ([self _checkFolderAndCreateIfNeeded:notePath]) {
		NSString* verifyPath = [NSString stringWithFormat:@"%@/contentVerify", notePath];
		NSDictionary* verifyDict = nil;
		BOOL needRefresh = YES;
		
		if ((verifyDict = [NSDictionary dictionaryWithContentsOfFile:verifyPath])) {
			needRefresh = !([[note contentHash] isEqualToData:[verifyDict objectForKey:@"contentHash"]] &&
							[(NSNumber*)[verifyDict objectForKey:@"contentLength"] intValue] == [note contentLength] &&
							[(NSNumber*)[verifyDict objectForKey:@"created"] unsignedLongLongValue] == [note created] &&
							[(NSNumber*)[verifyDict objectForKey:@"updated"] unsignedLongLongValue] == [note updated]);
		}
		
		// for the time being, refresh is an all-or-nothing thing...
		if (needRefresh) {
			NSLog(@"Refreshing \"%@\" (%@)", [note title], [note guid]);
			
			NSString* content = nil;
			NSString* contentPath = [NSString stringWithFormat:@"%@/content.xhtml", notePath];
			BOOL writeVerify = YES;
			
			if (![note contentIsSet] || !(content = [note content])) {
				[_connLock lock];
				@try { content = [_econn noteContent:note]; }
				@catch (NSException* e) { NSLog(@"Exception getting note content: %@", e); }
				@finally { [_connLock unlock]; }
			}
			
			[content writeToFile:contentPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
			
			NSEnumerator* resEnum = [[note resources] objectEnumerator];
			EDAMResource* res = nil;
			
			while ((res = [resEnum nextObject])) {
				[_connLock lock];
				NSData* resData = nil;
				
				@try { resData = [_econn resourceContent:res]; }
				@catch (NSException* e) { NSLog(@"Exception getting resource content: %@", e); }
				@finally { [_connLock unlock]; }
				
				if (resData && [resData length]) {
					NSString* path = [NSString stringWithFormat:@"%@/%@", notePath, [res guid]];
					
					if (![resData writeToFile:path atomically:NO]) {
						NSLog(@"Unable to write resource at %@", path);
						writeVerify = NO;
					}
				}
				else {
					NSLog(@"Data for resource %@ is no good.", [res guid]);
					writeVerify = NO;
				}
			}
			
			if (writeVerify) {
				NSDictionary* verifyDict = [NSDictionary dictionaryWithObjectsAndKeys:
											[note contentHash], @"contentHash", 
											[NSNumber numberWithInt:[note contentLength]], @"contentLength",
											[NSNumber numberWithUnsignedLongLong:[note created]], @"created", 
											[NSNumber numberWithUnsignedLongLong:[note updated]], @"updated", nil];
				
				[verifyDict writeToFile:verifyPath atomically:NO];
			}
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
- (void) refreshDiskCache;
{
	[_diskCacheLock lock];
	
	if (_diskCache) [_diskCache release];
	_diskCache = [[NSMutableDictionary alloc] init];
	
	NSString* expAppSup = [kAppSupportFolder stringByExpandingTildeInPath];
	[self _checkFolderAndCreateIfNeeded:expAppSup];
	
	NSEnumerator* nbEnum = [[_structCache allValues] objectEnumerator];
	NSDictionary* dict = nil;
	
	while ((dict = [nbEnum nextObject])) {
		EDAMNotebook* nb = [dict objectForKey:kEDAMObjectSpecialKey];
		
		if (nb && [nb guidIsSet]) {
			NSString* nbFolder = [[NSString stringWithFormat:@"%@/%@", kAppSupportFolder, [nb guid]] stringByExpandingTildeInPath];
			
			if ([self _checkFolderAndCreateIfNeeded:nbFolder]) {
				NSEnumerator* dEnum = [[dict allKeys] objectEnumerator];
				NSString* dKey = nil;
				EDAMNote* note = nil;
				
				while ((dKey = [dEnum nextObject])) {
					if (![dKey isEqualToString:(NSString*)kEDAMObjectSpecialKey] && 
						([(note = [dict objectForKey:dKey]) isKindOfClass:[EDAMNote class]])) {
						[self _refreshNoteDiskCache:note inNotebook:nbFolder];
					}
				}
			}
			else NSLog(@"Error creating '%@'", nbFolder);
		}
	}
	
	[_diskCacheLock unlock];
}
@end
