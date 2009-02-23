//
//  EvernoteConnection.h
//  EvernoteFSApp
//
//  Created by Ryan Joseph on 10/2/08.
//  Copyright 2009 Ryan Joseph. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EDAMUserStoreClient, EDAMUser;

@interface EvernoteConnection : NSObject {
	NSString* _username;
	NSString* _password;
	
	EDAMUserStoreClient* _userStoreClient;
	EDAMUser* _authedUser;
}

- (id) initWithUserName:(NSString*)username andPassword:(NSString*)password;
- (BOOL) authenticate;

- (NSString*) username;
@end
