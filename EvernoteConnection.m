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
				retVal = (authRes && [authRes authenticationTokenIsSet] && [authRes userIsSet] && [[authRes user] usernameIsSet]);
			}
		}
		@catch (NSException * e) {
			NSLog(@"Exception caught: %@", e);
			retVal = NO;
		}
	}
	
	NSLog(@"authenticate returning %d", retVal);
	return retVal;
}

///////////////////////////////////////////////////////////////////////////////
- (void) dealloc {
	[_username release];
	[_password release];
	
	[super dealloc];
}
@end
