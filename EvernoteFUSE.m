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

@interface EvernoteFUSE (DelegatesAndNotifications)
// notifications
- (void) didMount:(NSNotification*)notify;
- (void) didUnmount:(NSNotification*)notify;
- (void) mountFailed:(NSNotification*)notify;

// delegate methods
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;
//- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)path error:(NSError **)error;
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
	NSLog(@"someone unmounted us... trying to terminate lé app...");
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
	return [NSArray arrayWithObjects:@"There", @"Is", @"Nothing", @"To", @"See", @"Here", nil];
}

/*
///////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)path error:(NSError **)error;
{
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:(1024 * 1024 * 1)], @"NSFileSystemSize", nil];
}*/
@end


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
@implementation EvernoteFUSE
///////////////////////////////////////////////////////////////////////////////
- (id) initWithVolumeName:(NSString*)volName;
{
	if ((self = [super init])) {
		NSNotificationCenter* dCent = [NSNotificationCenter defaultCenter];
		[dCent addObserver:self selector:@selector(didMount:) name:kGMUserFileSystemDidMount object:nil];
		[dCent addObserver:self selector:@selector(didUnmount:) name:kGMUserFileSystemDidUnmount object:nil];
		[dCent addObserver:self selector:@selector(mountFailed:) name:kGMUserFileSystemMountFailed object:nil];
		
		_fs = [[GMUserFileSystem alloc] initWithDelegate:self isThreadSafe:YES];
		
		NSMutableArray* options = [NSMutableArray array];
		[options addObject:[NSString stringWithFormat:@"volname=%@", volName]];
		[options addObject:[NSString stringWithFormat:@"volicon=%@",
							[[NSBundle mainBundle] pathForResource:@"ytfs" ofType:@"icns"]]];
		
		[_fs mountAtPath:[NSString stringWithFormat:@"%@/%@", kMountPathPrefix, volName] withOptions:options];
	}
	
	return self;
}

///////////////////////////////////////////////////////////////////////////////
- (id) init;
{
	return [self initWithVolumeName:@"Generic Evernote FS"];
}

///////////////////////////////////////////////////////////////////////////////
- (void) dealloc;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_fs unmount];
	[_fs release];
	
	[super dealloc];
}
@end
