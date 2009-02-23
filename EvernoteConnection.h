//
//  EvernoteConnection.h
//  EvernoteFSApp
//
//  Created by Ryan Joseph on 10/2/08.
//  Copyright 2009 Ryan Joseph. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EDAMUserStoreClient, EDAMUser, EDAMNoteStoreClient, EDAMAccounting;

@interface EvernoteConnection : NSObject {
	NSString* _username;
	NSString* _password;
	
	EDAMUserStoreClient* _userStoreClient;
	EDAMUser* _authedUser;
	NSString* _authToken;
	
	EDAMNoteStoreClient* _noteStoreClient;
	EDAMAccounting* _accounting;
}

- (id) initWithUserName:(NSString*)username andPassword:(NSString*)password;
- (BOOL) authenticate;

- (NSString*) username;
- (NSString*) name;
- (NSString*) email;

- (int64_t) accountSize;
- (int64_t) uploadLimit;

- (NSArray*) listNotebooks;
@end
