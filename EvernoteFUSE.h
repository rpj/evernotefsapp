//
//  EvernoteFUSE.h
//  EvernoteFS
//
//  Created by Ryan Joseph on 10/1/08.
//  Copyright 2009 Ryan Joseph. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GMUserFileSystem, EvernoteConnection;

typedef enum {
	kCacheNotReady			= 0,
	kNotebookCacheReady		= 1,
	kNotesCacheReady		= 2,
	kLastCacheLockValue
} EvernoteFUSELockConditions;

@interface ENFUSEConditionLock : NSConditionLock {
	NSInteger _lastCondition;
}

- (BOOL) tryLockWhenConditionGTE:(NSInteger)cond;
- (void) unlockWithLastCondition;
@end

@interface EvernoteFUSE : NSObject {
	GMUserFileSystem*		_fs;
	EvernoteConnection*		_econn;
	
	NSString*				_volName;
	NSMutableDictionary*	_fsAttrDict;
	
	NSMutableDictionary*	_structCache;
	ENFUSEConditionLock*	_structCacheLock;
}

- (id) initWithVolumeName:(NSString*)volName andConnection:(EvernoteConnection*)conn;
- (id) initWithVolumeName:(NSString*)volName;

- (NSString*) volumeName;
- (void) setVolumeName:(NSString*)volName;

- (EvernoteConnection*) connection;
- (void) setConnection:(EvernoteConnection*)conn;

- (void) mount;
- (void) unmount;
@end
