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
@implementation EvernoteFUSE (DelegatesAndNotifications)
///////////////////////////////////////////////////////////////////////////////
- (void) didMount:(NSNotification*)notify;
{
	// selects the newly-mounted FS in the Finder; lifted from Google's sample
	NSString* mountPath = [[notify userInfo] objectForKey:kGMUserFileSystemMountPathKey];
	NSLog(@"Mounted new EvernoteFS at '%@'", mountPath);
}

///////////////////////////////////////////////////////////////////////////////
- (void) didUnmount:(NSNotification*)notify;
{
	NSLog(@"Unmounted by user: terminating.");
	[[NSApplication sharedApplication] terminate:self];
}

///////////////////////////////////////////////////////////////////////////////
- (void) mountFailed:(NSNotification*)notify;
{
	NSLog(@"mountFailed: %@", notify);
	NSLog(@"-- userInfo: %@", [notify userInfo]);
}

///////////////////////////////////////////////////////////////////////////////
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;
{
	NSArray* retArr = [NSArray arrayWithObjects:@"There", @"Is", @"Nothing", @"To", @"See", @"Here", nil];
	NSArray* comps = [path componentsSeparatedByString:@"/"];
	NSString* topLvl = nil;
	
	if ([comps count] > 1 && (topLvl = [comps objectAtIndex:1])) {
		id structObj = nil;
		EDAMNotebook* ntbk = nil;
		NSMutableArray* mrArr = [NSMutableArray array];
		
		if ([topLvl isEqualToString:@""]) {
			NSEnumerator* ntbkEnum = [[_econn listNotebooks] objectEnumerator];
			
			while ((ntbk = [ntbkEnum nextObject])) {
				[mrArr addObject:[ntbk name]];
				[_structCache setObject:ntbk forKey:[ntbk name]];
			}
		}
		else if ((structObj = [_structCache objectForKey:topLvl])) {
			if ([structObj isKindOfClass:[EDAMNotebook class]]) {
				NSEnumerator* nEnum = [[_econn notesInNotebook:(EDAMNotebook*)structObj] objectEnumerator];
				EDAMNote* note = nil;
				
				while ((note = [nEnum nextObject])) {
					[mrArr addObject:[note title]];
				}
			}
		}
		
		retArr = (NSArray*)mrArr;
	}
	
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
			NSLog(@"Account Size: %lld bytes", [_econn accountSize]);
			NSLog(@"Upload Limit: %lld bytes", [_econn uploadLimit]);
			
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
	NSArray* comps = [path componentsSeparatedByString:@"/"];
	NSDictionary* retDict = [NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeRegular, NSFileType, nil];
	NSString* top = nil;
	int cCount = [comps count];
	
	if (cCount > 1 && (top = [comps objectAtIndex:1])) {
		if (cCount <= 2 && ([top isEqualToString:@""] || [_structCache objectForKey:top])) {
			retDict = [NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeDirectory, NSFileType, nil];
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
		
		[_fs mountAtPath:[NSString stringWithFormat:@"%@/%@", kMountPathPrefix, _volName] withOptions:options];
	}
	else {
		NSLog(@"Must call setVolumeName: and setConnection: before mount.");
	}
}

///////////////////////////////////////////////////////////////////////////////
- (void) unmount;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_fs unmount];
}

///////////////////////////////////////////////////////////////////////////////
- (id) initWithVolumeName:(NSString*)volName andConnection:(EvernoteConnection*)conn;
{
	if ((self = [super init])) {
		_fs = [[GMUserFileSystem alloc] initWithDelegate:self isThreadSafe:YES];
		
		if (conn) _econn = [conn retain];		
		if (volName) _volName = [volName retain];
		
		_fsAttrDict = nil;
		_structCache = [[NSMutableDictionary alloc] init];
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
- (void) dealloc;
{
	[self unmount];
	
	[_fs release];
	[_volName release];
	[_econn release];
	[_fsAttrDict release];
	[_structCache release];
	
	[super dealloc];
}
@end
