//
//  EvernoteFUSE.m
//  EvernoteFS
//
//  Created by Ryan Joseph on 10/1/08.
//  Copyright 2009 Ryan Joseph. All rights reserved.
//

#import "EvernoteFUSE.h"
#import "EvernoteConnection.h"

#import "NoteStore.h"

#import <MacFUSE/GMUserFileSystem.h>

static NSString* kMountPathPrefix			= @"/Volumes";
static NSString* kAppSupportFolder			= @"~/Library/Application Support/EvernoteFS";
static NSString* kEDAMObjectSpecialKey		= @"//me.rpj.EvernoteFSApp.SpecialKey::EDAMObject";

@interface EvernoteFUSE (CacheThread)
- (void) generateCache:(id)arg;
- (void) refreshDiskCache;
@end

@interface EvernoteFUSE (DelegatesAndNotifications)
// notifications
- (void) didMount:(NSNotification*)notify;
- (void) didUnmount:(NSNotification*)notify;
- (void) mountFailed:(NSNotification*)notify;

// delegate methods
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;
- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)path error:(NSError **)error;
@end

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
@implementation ENFUSEConditionLock
///////////////////////////////////////////////////////////////////////////////
- (id) init;
{
	if ((self = [super init])) {
		_lastCondition = kCacheNotReady;
	}
	
	return self;
}

///////////////////////////////////////////////////////////////////////////////
- (BOOL) tryLockWhenConditionGTE:(NSInteger)cond;
{
	BOOL gotLock = NO;
	NSInteger condCount = cond;
	_lastCondition = [self condition];
	
	for(; condCount < kLastCacheLockValue && !gotLock; condCount++) {
		gotLock = [self tryLockWhenCondition:condCount];
	}
	
	return gotLock;
}

///////////////////////////////////////////////////////////////////////////////
- (void) unlockWithLastCondition;
{
	[self unlockWithCondition:_lastCondition];
}
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
		}
		
		// here is where any consumers waiting on the kNotebookCacheReady condition but *not* needing to wait
		// for kNotesCacheReady may have the ability to gain the lock and do some processing...
		
		[_structCacheLock lockWhenCondition:kNotebookCacheReady];
		ntbkEnum = [[_structCache allKeys] objectEnumerator];
		NSString* ntbkName = nil;
		
		@try {
			while ((ntbkName = [ntbkEnum nextObject])) {
				ntbk = (EDAMNotebook*)[_structCache objectForKey:ntbkName];
				//NSLog(@"%@ -> %@\n\n", ntbkName, ntbk);
				NSEnumerator* nEnum = [[_econn notesInNotebook:ntbk] objectEnumerator];
				EDAMNote* note = nil;
				NSMutableDictionary* ntbkDict = [NSMutableDictionary dictionary];
				
				while ((note = [nEnum nextObject])) {
					//NSLog(@"%@ -> %@\n", [note title], note);
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
		}
		
		//NSLog(@"generateCache finished, starting refreshDiskCache on thread %@", [NSThread currentThread]);
		//[self refreshDiskCache];
	}
	
	[pool release];
}

///////////////////////////////////////////////////////////////////////////////
- (void) refreshDiskCache;
{
	[_diskCacheLock lock];
	NSLog(@"[%@ refreshDiskCache] starting", [NSThread currentThread]);
	
	NSFileManager* fmgr = [NSFileManager defaultManager];
	BOOL isDir = NO;
	
	if (_diskCache) [_diskCache release];
	_diskCache = [[NSMutableDictionary alloc] init];
	
	NSString* expAppSup = [kAppSupportFolder stringByExpandingTildeInPath];
	if (![fmgr fileExistsAtPath:expAppSup isDirectory:&isDir] || !isDir) {
		if (!isDir && ![fmgr removeFileAtPath:expAppSup handler:nil]) {
			NSLog(@"%@ exists and isn't a folder, but was unable to remove.", expAppSup);
		}
		
		[fmgr createDirectoryAtPath:expAppSup attributes:nil];
		NSLog(@"Created %@", expAppSup);
	}
	
	NSEnumerator* nbEnum = [[_structCache allValues] objectEnumerator];
	NSDictionary* dict = nil;
	
	while ((dict = [nbEnum nextObject])) {
		NSLog(@"%@", [dict objectForKey:kEDAMObjectSpecialKey]);
	}
	
	NSLog(@"[%@ refreshDiskCache] ending", [NSThread currentThread]);
	[_diskCacheLock unlock];
}
@end

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
@implementation EvernoteFUSE (DelegatesAndNotifications)
///////////////////////////////////////////////////////////////////////////////
- (void) didMount:(NSNotification*)notify;
{
	// selects the newly-mounted FS in the Finder; lifted from Google's sample
	NSString* mountPath = [[notify userInfo] objectForKey:kGMUserFileSystemMountPathKey];
	NSLog(@"Mounted new EvernoteFS at '%@'", mountPath);
	NSAssert1((_mountStatus == kMounting), @"didMount: mount status should be kMounting, but is %d", _mountStatus);
	_mountStatus = kMounted;
}

///////////////////////////////////////////////////////////////////////////////
- (void) didUnmount:(NSNotification*)notify;
{
	NSLog(@"Unmounted by user: terminating.");
	[[NSApplication sharedApplication] terminate:self];
	_mountStatus = kNotMounted;
}

///////////////////////////////////////////////////////////////////////////////
- (void) mountFailed:(NSNotification*)notify;
{
	NSLog(@"mountFailed: %@", notify);
	NSLog(@"-- userInfo: %@", [notify userInfo]);
	_mountStatus = kNotMounted;
}

///////////////////////////////////////////////////////////////////////////////
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;
{
	NSArray* retArr = nil;
	
	if (_mountStatus > kNotMounted) {
		NSArray* comps = [path componentsSeparatedByString:@"/"];
		NSString* topLvl = nil;
		
		if ([comps count] > 1 && (topLvl = [comps objectAtIndex:1])) {
			id structObj = nil;
			
			if ([topLvl isEqualToString:@""] && [_structCacheLock tryLockWhenConditionGTE:kNotebookCacheReady]) {
				retArr = [_structCache allKeys];
				[_structCacheLock unlockWithLastCondition];
			}
			else if ([_structCacheLock tryLockWhenConditionGTE:kNotesCacheReady]) {
				if ((structObj = [_structCache objectForKey:topLvl]) && [structObj isKindOfClass:[NSDictionary class]]) {
					NSMutableArray* mrArr = [NSMutableArray array];
					NSEnumerator* nEnum = [[(NSDictionary*)structObj allKeys] objectEnumerator];
					id note = nil;
					
					while ((note = [structObj objectForKey:(NSString*)[nEnum nextObject]])) {
						if ([note isKindOfClass:[EDAMNote class]])
							[mrArr addObject:[(EDAMNote*)note title]];
					}
					
					retArr = (NSArray*)mrArr;
				}
				
				[_structCacheLock unlockWithLastCondition];
			}
		}
		
		NSLog(@"contentsForPath:%@ returning %@", path, retArr);
	}
	else NSLog(@"contentsOfDirectoryAtPath:%@ -- not yet mounted (%d)", path, _mountStatus);
	
	return retArr;
}

///////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)path error:(NSError **)error;
{
	int64_t size = [_econn accountSize];
	int64_t lim = [_econn uploadLimit];
	
	if (!_fsAttrDict) {
		_fsAttrDict = [[NSMutableDictionary alloc] init];
		
		if (lim > 0 && size > 0 && lim > size) {
			// this value will necessarily need be adjusted as the sync state changes (if we or
			// other clients add or remove data).
			[_fsAttrDict setObject:[NSNumber numberWithInt:(lim - size)] forKey:@"NSFileSystemFreeSize"];
			[_fsAttrDict setObject:[NSNumber numberWithInt:lim] forKey:@"NSFileSystemSize"];
		}
		else {
			NSLog(@"Bad values for size (%lld) or lim (%lld).", size, lim);
		}
	}
	
	return (NSDictionary*)_fsAttrDict;
}

///////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)attributesOfItemAtPath:(NSString *)path
                                userData:(id)userData
                                   error:(NSError **)error;
{
	NSDictionary* retDict = nil;
	NSArray* comps = [path componentsSeparatedByString:@"/"];
	NSString* top = nil;
	int cCount = [comps count];
	
	// default return is a regular file of size 4096 with mode 0444
	retDict = [NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeRegular, NSFileType, 
			   [NSNumber numberWithUnsignedLong:420], NSFilePosixPermissions, 
			   [NSNumber numberWithUnsignedLongLong:4096], NSFileSize, nil];
	
	if (cCount > 1 && (top = [comps objectAtIndex:1])) {
		if ([_structCacheLock tryLockWhenConditionGTE:kNotebookCacheReady]) {
			if (cCount <= 3 && ([top isEqualToString:@""] || [_structCache objectForKey:top])) {
				retDict = [NSDictionary dictionaryWithObjectsAndKeys:
						   NSFileTypeDirectory, NSFileType, 
						   [NSNumber numberWithUnsignedLong:365], NSFilePosixPermissions,
						   [NSNumber numberWithUnsignedLongLong:1024], NSFileSize, nil];
			}
			
			[_structCacheLock unlockWithLastCondition];
		}
	}
	
	return retDict;
}


///////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)attributesOfItemAtPath:(NSString *)path 
                                   error:(NSError **)error;
{
	return [self attributesOfItemAtPath:path userData:nil error:error];
}
@end


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
@implementation EvernoteFUSE
///////////////////////////////////////////////////////////////////////////////
- (NSString*) volumeName;
{
	return _volName;
}

///////////////////////////////////////////////////////////////////////////////
- (void) setVolumeName:(NSString*)volName;
{
	[_volName release];
	_volName = [volName retain];
}

///////////////////////////////////////////////////////////////////////////////
- (EvernoteConnection*) connection;
{
	return _econn;
}

///////////////////////////////////////////////////////////////////////////////
- (void) setConnection:(EvernoteConnection*)conn;
{
	[_econn release];
	_econn = [conn retain];
	
	[NSThread detachNewThreadSelector:@selector(generateCache:) toTarget:self withObject:nil];
}

///////////////////////////////////////////////////////////////////////////////
- (void) mount;
{
	if (_volName && _econn) {		
		NSNotificationCenter* dCent = [NSNotificationCenter defaultCenter];
		[dCent addObserver:self selector:@selector(didMount:) name:kGMUserFileSystemDidMount object:nil];
		[dCent addObserver:self selector:@selector(didUnmount:) name:kGMUserFileSystemDidUnmount object:nil];
		[dCent addObserver:self selector:@selector(mountFailed:) name:kGMUserFileSystemMountFailed object:nil];
		
		NSMutableArray* options = [NSMutableArray array];
		[options addObject:[NSString stringWithFormat:@"volname=%@", _volName]];
		[options addObject:[NSString stringWithFormat:@"volicon=%@",
							[[NSBundle mainBundle] pathForResource:@"ytfs" ofType:@"icns"]]];
		//[options addObject:@"debug"];
		
		NSString* mntPath = [NSString stringWithFormat:@"%@/%@", kMountPathPrefix, _volName];
		NSLog(@"Mounting at '%@'", mntPath);
		[_fs mountAtPath:mntPath withOptions:options];
		
		_mountStatus = kMounting;
	}
	else {
		NSLog(@"Must call setVolumeName: and setConnection: before mount.");
	}
}

///////////////////////////////////////////////////////////////////////////////
- (id) initWithVolumeName:(NSString*)volName andConnection:(EvernoteConnection*)conn;
{
	if ((self = [super init])) {
		_fs = [[GMUserFileSystem alloc] initWithDelegate:self isThreadSafe:YES];
		
		if (conn) [self setConnection:conn];		
		if (volName) [self setVolumeName:volName];
		
		_fsAttrDict = nil;
		_structCache = nil;
		_structCacheLock = [[ENFUSEConditionLock alloc] initWithCondition:kCacheNotReady];
		
		_diskCacheLock = nil;
		_diskCacheLock = [[NSLock alloc] init];
		
		_mountStatus = kNotMounted;
	}
	
	return self;
}

///////////////////////////////////////////////////////////////////////////////
- (id) initWithVolumeName:(NSString*)volName;
{
	return [self initWithVolumeName:volName andConnection:nil];
}

///////////////////////////////////////////////////////////////////////////////
- (id) init;
{
	return [self initWithVolumeName:nil andConnection:nil];
}

///////////////////////////////////////////////////////////////////////////////
- (void) unmount;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_fs unmount];
	_mountStatus = kNotMounted;
}

///////////////////////////////////////////////////////////////////////////////
- (void) dealloc;
{
	[self unmount];
	
	[_fs release];
	[_volName release];
	[_econn release];
	[_fsAttrDict release];
	
	[_structCache release];
	[_structCacheLock release];
	
	[_diskCache release];
	[_diskCacheLock release];
	
	[super dealloc];
}
@end
