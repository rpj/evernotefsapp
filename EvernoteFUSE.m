//
//  EvernoteFUSE.m
//  EvernoteFS
//
//  Created by Ryan Joseph on 10/1/08.
//  Copyright 2009 Ryan Joseph. All rights reserved.
//

#import "EvernoteFUSE.h"

#import <MacFUSE/GMUserFileSystem.h>

static NSString* kMountPathPrefix			= @"/Volumes";
const NSString* kAppSupportFolder			= @"~/Library/Application Support/EvernoteFS";
const NSString* kEDAMObjectSpecialKey		= @"//me.rpj.EvernoteFSApp.SpecialKey::EDAMObject";

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
@implementation EvernoteFUSE (DelegatesAndNotifications)
///////////////////////////////////////////////////////////////////////////////
- (void) didMount:(NSNotification*)notify;
{
	NSLog(@"Mounted new EvernoteFS at '%@'", [[notify userInfo] objectForKey:kGMUserFileSystemMountPathKey]);
	NSAssert1((_mountStatus == kMounting), @"didMount: mount status should be kMounting, but is %d", _mountStatus);
	_mountStatus = kMounted;
}

///////////////////////////////////////////////////////////////////////////////
- (void) didUnmount:(NSNotification*)notify;
{
	// if this is fired by toggling the "full name" checkbox in prefs, no termination will result
	NSLog(@"didUnmount notification");
	[[NSApplication sharedApplication] terminate:self];
	_mountStatus = kNotMounted;
}

///////////////////////////////////////////////////////////////////////////////
- (void) mountFailed:(NSNotification*)notify;
{
	NSLog(@"mountFailed: %@", notify);
	_mountStatus = kNotMounted;
}

///////////////////////////////////////////////////////////////////////////////
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;
{
	NSArray* retArr = nil;
	
	if (_mountStatus == kMounted) {
		NSArray* comps = [path componentsSeparatedByString:@"/"];
		NSString* topLvl = nil;
		NSUInteger count = [comps count];
		
		if (count > 1 && (topLvl = [comps objectAtIndex:1])) {
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
					EDAMNote* nNote = nil;
					
					// level two is the note-folder level
					if (count == 2) {
						while ((note = [structObj objectForKey:(NSString*)[nEnum nextObject]])) {
							if ([note isKindOfClass:[EDAMNote class]]) {
								nNote = (EDAMNote*)note;
								
								[mrArr addObject:[nNote title]];
							}
						}
					}
					else if (count == 3) {	// level three is within a note-folder, hence the note's contents
						nNote = [structObj objectForKey:[comps objectAtIndex:2]];
						
						if (nNote) {
							
							[mrArr addObject:[NSString stringWithFormat:@"%@.html", [nNote title]]];
							
							NSEnumerator* resEnum = [[nNote resources] objectEnumerator];
							EDAMResource* res = nil;
							
							while ((res = [resEnum nextObject])) {
								EDAMResourceAttributes* attrs = [res attributes];
								NSString* name = nil;
								
								if ([attrs fileNameIsSet]) {
									name = [attrs fileName];
								}
								else {
									NSString* mimeExtn = [[[res mime] componentsSeparatedByString:@"/"] objectAtIndex:1];
									name = [NSString stringWithFormat:@"%@.%@", [res guid], mimeExtn];
								}
								
								[mrArr addObject:name];
							}
						}
					}
			
					retArr = (NSArray*)mrArr;
				}
				
				[_structCacheLock unlockWithLastCondition];
			}
		}
	}
	else 
		NSLog(@"contentsOfDirectoryAtPath:%@ -- not yet mounted (%d)", path, _mountStatus);
	
	return retArr;
}

///////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)path error:(NSError **)error;
{	
	if (!_fsAttrDict) {
		_fsAttrDict = [[NSMutableDictionary alloc] init];
		
		if ([_connLock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:30.0]]) {
			int64_t size = [_econn accountSize];
			int64_t lim = [_econn uploadLimit];
			
			if (lim > 0 && size > 0 && lim > size) {
				// this value will necessarily need be adjusted as the sync state changes (if we or
				// other clients add or remove data).
				[_fsAttrDict setObject:[NSNumber numberWithInt:(lim - size)] forKey:@"NSFileSystemFreeSize"];
				[_fsAttrDict setObject:[NSNumber numberWithInt:lim] forKey:@"NSFileSystemSize"];
			}
			else {
				NSLog(@"Bad values for size (%lld) or lim (%lld).", size, lim);
			}
			
			[_connLock unlock];
		}
		else {
			NSLog(@"attributesOfFileSystemForPath couldn't lock _connLock; returning");
			return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"NSFileSystemFreeSize",
					[NSNumber numberWithInt:1], @"NSFileSystemSize", nil];
		}
	}
	
	return (NSDictionary*)_fsAttrDict;
}

///////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)attributesOfItemAtPath:(NSString *)path
                                userData:(id)userData
                                   error:(NSError **)error;
{
	// thinking we're going to need a seperate attributes cache data structure at some point...
	NSDictionary* retDict = nil;
	NSArray* comps = [path componentsSeparatedByString:@"/"];
	NSString* top = nil;
	int cCount = [comps count];
	
	// default return is a regular file of size 4096 with mode 0444
	retDict = [NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeRegular, NSFileType, 
			   [NSNumber numberWithUnsignedLong:292], NSFilePosixPermissions, 
			   [NSNumber numberWithUnsignedLongLong:4096], NSFileSize, nil];
	
	if (cCount > 1 && (top = [comps objectAtIndex:1])) {
		if ([_structCacheLock tryLockWhenConditionGTE:kNotebookCacheReady]) {
			NSDictionary* dict = nil;
			
			if (cCount < 4 && ([top isEqualToString:@""] || (dict = [_structCache objectForKey:top]))) {
				retDict = [NSDictionary dictionaryWithObjectsAndKeys:
						   NSFileTypeDirectory, NSFileType, 
						   [NSNumber numberWithUnsignedLong:365], NSFilePosixPermissions,
						   [NSNumber numberWithUnsignedLongLong:1024], NSFileSize, nil];
			}
			else if (cCount == 4) {
				EDAMNote* cNote = [[_structCache objectForKey:[comps objectAtIndex:1]] 
								   objectForKey:[comps objectAtIndex:2]];
				NSString* fName = [comps objectAtIndex:3];
				NSArray* fNameArr = [fName componentsSeparatedByString:@"."];
				
				if ([fNameArr count] == 2) {
					NSString* fN = [fNameArr objectAtIndex:0];
					NSString* extn = [fNameArr objectAtIndex:1];
					
					if ([fN isEqualToString:[cNote title]] && [extn isEqualToString:@"html"]) {
						// this is the HTML file we'll generate (later) from the a translation of the ENML markup
					}
					else {
						NSEnumerator* rEnum = [[cNote resources] objectEnumerator];
						EDAMResource* res = nil;
						
						while ((res = [rEnum nextObject])) {
							EDAMResourceAttributes* rAttr = [res attributes];
							EDAMData* rData = [res data];
							NSString* mimeExtn = [[[res mime] componentsSeparatedByString:@"/"] objectAtIndex:1];
							
							if (([rAttr fileNameIsSet] && [[rAttr fileName] isEqualToString:fName]) ||
								([fN isEqualToString:[res guid]] && [extn isEqualToString:mimeExtn])) {
								retDict = [NSDictionary dictionaryWithObjectsAndKeys:
										   [NSNumber numberWithUnsignedInt:[rData size]], NSFileSize,
										   NSFileTypeRegular, NSFileType,
										   [NSNumber numberWithUnsignedLong:292], NSFilePosixPermissions, nil];
							}
						}
					}
				}
			}
			
			[_structCacheLock unlockWithLastCondition];
		}
	}
	
	return retDict;
}

///////////////////////////////////////////////////////////////////////////////
- (NSData *)contentsAtPath:(NSString *)path;
{
	NSData* retData = nil;
	
	if ([_diskCacheLock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:0.25]]) {
		//NSArray* comps = [path componentsSeparatedByString:@"/"];
		//NSLog(@"Disk Cache: %@", _diskCache);
		
		[_diskCacheLock unlock];
	}
	
	return retData;
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
	[_connLock lock];
	[_econn release];
	_econn = [conn retain];
	[_connLock unlock];
	
	[NSThread detachNewThreadSelector:@selector(generateCache:) toTarget:self withObject:nil];
}

///////////////////////////////////////////////////////////////////////////////
- (void) mount;
{
	if (_volName && _econn) {
		NSMutableArray* options = [NSMutableArray array];
		[options addObject:@"daemon_timeout=15"];
		[options addObject:@"fsname=EvernoteFS"];
		//[options addObject:@"kill_on_unmount"];
		[options addObject:@"noappledouble"];
		[options addObject:@"noapplexattr"];
		[options addObject:@"rdonly"];		// FOR NOW...
		[options addObject:@"-s"];			// single-threaded mode... FOR NOW...
		[options addObject:[NSString stringWithFormat:@"volname=%@", _volName]];
		[options addObject:[NSString stringWithFormat:@"volicon=%@",
							[[NSBundle mainBundle] pathForResource:@"ytfs" ofType:@"icns"]]];
		//NSLog(@"mount options: %@\n", options);
		
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
		NSNotificationCenter* dCent = [NSNotificationCenter defaultCenter];
		[dCent addObserver:self selector:@selector(mountFailed:) name:kGMUserFileSystemMountFailed object:nil];
		[dCent addObserver:self selector:@selector(didUnmount:) name:kGMUserFileSystemDidUnmount object:nil];
		[dCent addObserver:self selector:@selector(didMount:) name:kGMUserFileSystemDidMount object:nil];
		
		_fs = [[GMUserFileSystem alloc] initWithDelegate:self isThreadSafe:YES];
		_connLock = [[NSLock alloc] init];
		
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
	if (_mountStatus > kNotMounted) {
		[_fs unmount];
	}
	
	_mountStatus = kNotMounted;
}

///////////////////////////////////////////////////////////////////////////////
- (void) dealloc;
{
	[self unmount];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_fs release];
	[_volName release];
	[_fsAttrDict release];
	
	[_econn release];
	[_connLock release];
	
	[_structCache release];
	[_structCacheLock release];
	
	[_diskCache release];
	[_diskCacheLock release];
	
	[super dealloc];
}
@end
