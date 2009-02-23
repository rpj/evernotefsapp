//
//  EvernoteConnection.m
//  EvernoteFSApp
//
//  Created by Ryan Joseph on 10/2/08.
//  Copyright 2009 Ryan Joseph. All rights reserved.
//

#import "EvernoteConnection.h"

#import "UserStore.h"
#import "NoteStore.h"

#import "TProtocol.h"
#import "TBinaryProtocol.h"
#import "THTTPClient.h"

static NSString* kVersionName	= @"SoulSurfer Productions - EvernoteFSApp";
static NSString* kConsumerKey	= @"soulsurfer-5999";
static NSString* kUserStoreURL	= @"http://lb.evernote.com/edam/user";
static NSString* kNoteStoreURL	= @"http://lb.evernote.com/edam/note";

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
@implementation EvernoteConnection
///////////////////////////////////////////////////////////////////////////////
- (EDAMAccounting*) _getAccounting;
{
	if (_authedUser && !_accounting)
		_accounting = [[_authedUser accounting] retain];
	
	return _accounting;
}

///////////////////////////////////////////////////////////////////////////////
- (id) initWithUserName:(NSString*)username andPassword:(NSString*)password;
{
	if (username && password && (self = [super init])) {
		_username = [username retain];
		_password = [password retain];
		
		_userStoreClient = nil;
		_authedUser = nil;
		_authToken = nil;
		
		_noteStoreClient = nil;
		_accounting = nil;
	}
	
	return self;
}

///////////////////////////////////////////////////////////////////////////////
- (id) init;
{
	// an object init'ed this way will be forever useless. probably don't want to do that, do you...
	return [self initWithUserName:nil andPassword:nil];
}

///////////////////////////////////////////////////////////////////////////////
- (BOOL) authenticate;
{
	BOOL retVal = NO;
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	if (_username && _password) {
		@try {
			id <TTransport> httptrans = [[[THTTPClient alloc] 
										  initWithURL:[NSURL URLWithString:kUserStoreURL]] autorelease];
			TBinaryProtocol* tbproto = [[TBinaryProtocolFactory sharedFactory] newProtocolOnTransport:httptrans];
			_userStoreClient = [[EDAMUserStoreClient alloc] initWithProtocol:tbproto];
			
			if ([_userStoreClient checkVersion:kVersionName 
											  :[EDAMUserStoreConstants EDAM_VERSION_MAJOR] 
											  :[EDAMUserStoreConstants EDAM_VERSION_MINOR]]) {
				EDAMAuthenticationResult* authRes = [_userStoreClient authenticate:_username :_password :kConsumerKey :nil];
				
				if (authRes && [authRes authenticationTokenIsSet] && [authRes userIsSet]) {
					_authedUser = [[authRes user] retain];
					_authToken = [[authRes authenticationToken] retain];
					
					NSURL* shardedURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", kNoteStoreURL, [_authedUser shardId]]];
					httptrans = [[[THTTPClient alloc] initWithURL:shardedURL] autorelease];
					tbproto = [[TBinaryProtocolFactory sharedFactory] newProtocolOnTransport:httptrans];
					
					_noteStoreClient = [[EDAMNoteStoreClient alloc] initWithProtocol:tbproto];					
					retVal = (_noteStoreClient && _userStoreClient && _authToken && _authedUser);
				}
			}
		}
		@catch (NSException* e) {
			NSLog(@"Exception caught: %@", e);
			retVal = NO;
		}
	}
	
	[pool release];
	return retVal;
}

///////////////////////////////////////////////////////////////////////////////
- (NSString*) username;
{
	if (_authedUser && [_authedUser usernameIsSet]) return [_authedUser username];
	else return nil;
}

///////////////////////////////////////////////////////////////////////////////
- (NSString*) name;
{
	if (_authedUser && [_authedUser nameIsSet]) return [_authedUser name];
	else return nil;
}

///////////////////////////////////////////////////////////////////////////////
- (NSString*) email;
{
	if (_authedUser && [_authedUser emailIsSet]) return [_authedUser email];
	else return nil;
}

///////////////////////////////////////////////////////////////////////////////
- (int64_t) accountSize;
{
	if (_noteStoreClient && _authToken) return [_noteStoreClient getAccountSize:_authToken];
	else return (int64_t)-1;
}

///////////////////////////////////////////////////////////////////////////////
- (int64_t) uploadLimit;
{
	if ([self _getAccounting]) return [[self _getAccounting] uploadLimit];
	else return (int64_t)-1;
}

///////////////////////////////////////////////////////////////////////////////
- (void) dealloc;
{
	[_username release];
	[_password release];
	
	[_userStoreClient release];
	[_authedUser release];
	[_authToken release];
	
	[_noteStoreClient release];
	[_accounting release];
	
	[super dealloc];
}
@end
