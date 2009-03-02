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
	return (_authedUser && [_authedUser usernameIsSet]) ? [_authedUser username] : nil;
}

///////////////////////////////////////////////////////////////////////////////
- (NSString*) name;
{
	return (_authedUser && [_authedUser nameIsSet]) ? [_authedUser name] : nil;
}

///////////////////////////////////////////////////////////////////////////////
- (NSString*) email;
{
	return (_authedUser && [_authedUser emailIsSet]) ? [_authedUser email] : nil;
}

///////////////////////////////////////////////////////////////////////////////
- (int64_t) accountSize;
{
	return ((_noteStoreClient && _authToken) ? [_noteStoreClient getAccountSize:_authToken] : (int64_t)-1);
}

///////////////////////////////////////////////////////////////////////////////
- (int64_t) uploadLimit;
{
	return ([self _getAccounting] ? [[self _getAccounting] uploadLimit] : (int64_t)-1);
}

///////////////////////////////////////////////////////////////////////////////
- (NSArray*) listNotebooks;
{
	return ((_noteStoreClient && _authToken) ? [_noteStoreClient listNotebooks:_authToken] : [NSArray array]);
}

///////////////////////////////////////////////////////////////////////////////
- (NSString*) noteContent:(EDAMNote*)note;
{
	return ((_noteStoreClient && _authToken && [note guidIsSet]) ? 
			[_noteStoreClient getNoteContent:_authToken :[note guid]] : nil);
}

///////////////////////////////////////////////////////////////////////////////
- (NSData*) resourceContent:(EDAMResource*)res;
{
	return ((_noteStoreClient && _authToken && [res guidIsSet]) ?
			([res dataIsSet] && [[res data] bodyIsSet] ? 
			 [[res data] body] : [_noteStoreClient getResourceData:_authToken :[res guid]]) : nil);
}

///////////////////////////////////////////////////////////////////////////////
- (NSArray*) notesInNotebook:(EDAMNotebook*)notebook;
{
	NSArray* ret = [NSArray array];
	
	if (_noteStoreClient && _authToken && notebook) {
		@try {
			EDAMNoteFilter* filter = [[[EDAMNoteFilter alloc] init] autorelease];
			[filter setNotebookGuid:[notebook guid]];
			
			EDAMNoteList* nList = [_noteStoreClient findNotes:_authToken :filter :0 :500];
			if (nList) ret = [nList notes];
		}
		@catch (NSException* e) {
			NSLog(@"Exception in notesInNotebook: %@\n\n(notebook %@)\n", e, notebook);
			@throw e;
		}
	}
	
	return ret;
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
