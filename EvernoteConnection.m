//
//  EvernoteConnection.m
//  EvernoteFSApp
//
//  Created by Ryan Joseph on 10/2/08.
//  Copyright 2009 Ryan Joseph. All rights reserved.
//

#import "EvernoteConnection.h"

#import "UserStore.h"

#import "TProtocol.h"
#import "TBinaryProtocol.h"
#import "THTTPClient.h"

static NSString* kVersionName = @"SoulSurfer Productions - EvernoteFSApp";
static NSString* kConsumerKey = @"soulsurfer-5999";

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
@implementation EvernoteConnection
///////////////////////////////////////////////////////////////////////////////
- (id) initWithUserName:(NSString*)username andPassword:(NSString*)password {
	if (username && password && (self = [super init])) {
		_username = [username retain];
		_password = [password retain];
	}
	
	return self;
}

///////////////////////////////////////////////////////////////////////////////
- (BOOL) authenticate {
	BOOL retVal = NO;
	
	if (_username && _password) {
		@try {
			id <TTransport> httptrans = [[[THTTPClient alloc] 
										  initWithURL:[NSURL URLWithString:@"http://lb.evernote.com/edam/user"]] autorelease];
			TBinaryProtocol* tbproto = [[TBinaryProtocolFactory sharedFactory] newProtocolOnTransport:httptrans];
			_userStoreClient = [[EDAMUserStoreClient alloc] initWithProtocol:tbproto];
			
			if ([_userStoreClient checkVersion:kVersionName 
											  :[EDAMUserStoreConstants EDAM_VERSION_MAJOR] 
											  :[EDAMUserStoreConstants EDAM_VERSION_MINOR]]) {
				EDAMAuthenticationResult* authRes = [_userStoreClient authenticate:_username :_password :kConsumerKey :nil];
				_authedUser = [[authRes user] retain];
				retVal = (authRes && [authRes authenticationTokenIsSet] && [authRes userIsSet] && [_authedUser usernameIsSet]);
			}
		}
		@catch (NSException * e) {
			NSLog(@"Exception caught: %@", e);
			retVal = NO;
		}
	}
	
	return retVal;
}

///////////////////////////////////////////////////////////////////////////////
- (NSString*) username {
	if (_authedUser && [_authedUser usernameIsSet]) return [_authedUser username];
	else return nil;
}

///////////////////////////////////////////////////////////////////////////////
- (NSString*) name {
	if (_authedUser && [_authedUser nameIsSet]) return [_authedUser name];
	else return nil;
}

///////////////////////////////////////////////////////////////////////////////
- (NSString*) email {
	if (_authedUser && [_authedUser emailIsSet]) return [_authedUser email];
	else return nil;
}

///////////////////////////////////////////////////////////////////////////////
- (void) dealloc {
	[_username release];
	[_password release];
	[_userStoreClient release];
	[_authedUser release];
	
	[super dealloc];
}
@end
