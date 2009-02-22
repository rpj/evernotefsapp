//
//  EvernoteFUSE.h
//  EvernoteFS
//
//  Created by Ryan Joseph on 10/1/08.
//  Copyright 2009 Ryan Joseph. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GMUserFileSystem;

@interface EvernoteFUSE : NSObject {
	GMUserFileSystem*	_fs;
	NSString*			_volName;
}

- (id) initWithVolumeName:(NSString*)volName;

@end
