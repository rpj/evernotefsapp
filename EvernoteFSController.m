//
//  EvernoteFSController.m
//  EvernoteFSApp
//
//  Created by Ryan Joseph on 10/1/08.
//  Copyright 2009 Ryan Joseph. All rights reserved.
//

#import "EvernoteFSController.h"
#import "EvernoteFUSE.h"
#import "EvernoteConnection.h"

static NSString* kServiceName				= @"EvernoteFSApp";
static NSString* kUserDefAccountNameKey		= @"me.rpj.EvernoteFSApp.UserDefaults.AccountNameKey";
static NSString* kUserDefUseFullNameKey		= @"me.rpj.EvernoteFSApp.UserDefaults.UseFullNameKey";

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
@implementation EvernoteFSController
///////////////////////////////////////////////////////////////////////////////
- (id) init {
	if ((self = [super init])) {
		_efs = nil;
		_econn = nil;
		
		_changingMountPoint = NO;
	}
	
	return self;
}
///////////////////////////////////////////////////////////////////////////////
- (IBAction) verifyAccount:(id)sender {
	NSString* u = [_username stringValue];
	NSString* p = [_password stringValue];
	
	if (u && p) {
		EvernoteConnection* conn = [[EvernoteConnection alloc] initWithUserName:u andPassword:p];
		
		if ([conn authenticate]) {
			[_econn release];
			_econn = conn;
			
			[[NSUserDefaults standardUserDefaults] setObject:u forKey:kUserDefAccountNameKey];
			
			SecKeychainRef keychain = nil;
			OSStatus retStat;
			
			if (noErr == (retStat = SecKeychainCopyDefault(&keychain)) && keychain) {
				const char* serviceCString = [kServiceName cStringUsingEncoding:NSUTF8StringEncoding];
				const char* accountCString = [u cStringUsingEncoding:NSUTF8StringEncoding];
				const char* passwordCString = [p cStringUsingEncoding:NSUTF8StringEncoding];
				
				retStat = SecKeychainAddGenericPassword(keychain, strlen(serviceCString), serviceCString,
														strlen(accountCString), accountCString, 
														strlen(passwordCString), passwordCString, NULL);
				
				if (noErr != retStat) {
					NSString* err = @"Unknown error.";
					// TODO: (BUG) in the case of this error, we really need to modify the keychain content...
					if (retStat == -25299) err = @"Password already exists.";
					
					[_info setStringValue:[NSString stringWithFormat:@"Error saving to keychain: %@", err]];
				}
				else {
					NSLog(@"Checking keychain and trying to mount...");
					[self checkKeychainAndMount];
				}
				
				[_prefPanel close];
			}
		}
		else {
			[_password setStringValue:@""];
			[_info setStringValue:@"Authentication failed."];
		}
	}
	else {
		[_info setStringValue:@"Missing information."];
	}
}

///////////////////////////////////////////////////////////////////////////////
- (IBAction) fullNameToggle:(id)sender {
	[[NSUserDefaults standardUserDefaults] setBool:([_useFullName state] == NSOnState) forKey:kUserDefUseFullNameKey];
	_changingMountPoint = YES;
	[self mountFuseFS];
}

///////////////////////////////////////////////////////////////////////////////
- (void) mountFuseFS {
	if (_econn) {
		NSString* volName = [NSString stringWithFormat:@"%@'s Evernote", 
							 ([_useFullName state] == NSOnState) ? [_econn name] : [_econn username]];
		[_info setStringValue:[NSString stringWithFormat:@"Account email: %@", [_econn email]]];
		
		if (!_efs) {
			_efs = [[EvernoteFUSE alloc] initWithVolumeName:volName andConnection:_econn];
		}
		else {
			[_efs unmount];
			[_efs setVolumeName:volName];
		}
		
		NSLog(@"Built EvernoteFUSE \"%@\"", volName);
		[_efs mount];
	}
	else {
		NSLog(@"EvernoteConnection not yet setup: cannot mount!");
	}
}

///////////////////////////////////////////////////////////////////////////////
- (void) checkKeychainAndMount {
	NSUserDefaults* udef = [NSUserDefaults standardUserDefaults];
	NSString* accountName = [udef stringForKey:kUserDefAccountNameKey];
	OSStatus retStat = 1;
	
	if (accountName) {
		[_username setStringValue:accountName];
		
		SecKeychainRef keychain = nil;
		const char* accountCString = [accountName cStringUsingEncoding:NSUTF8StringEncoding];
		const char* serviceCString = [kServiceName cStringUsingEncoding:NSUTF8StringEncoding];
		UInt32 passwordLength = 0;
		const char* passwordString = NULL;
		
		if (noErr == (retStat = SecKeychainCopyDefault(&keychain))) {
			retStat = SecKeychainFindGenericPassword(keychain, strlen(serviceCString), serviceCString, 
													 strlen(accountCString), accountCString, 
													 &passwordLength, (void**)&passwordString, NULL);
			
			if (noErr == retStat) {
				[_password setStringValue:[NSString stringWithCString:passwordString length:passwordLength]];
				
				if (!_econn) {
					_econn = [[EvernoteConnection alloc] initWithUserName:[_username stringValue] 
															  andPassword:[_password stringValue]];
				}
				
				if (![_econn authenticate]) {
					[_info setStringValue:@"Authentication failed."];
					[_prefPanel makeKeyAndOrderFront:self];
				}
				else {
					// FOR NOW, when a username/password combination is good, we don't allow a new one
					// to be entered: related to the keychain bug referenced above.
					[_username setEnabled:NO];
					[_password setEnabled:NO];
					[_verifyAccount setEnabled:NO];
					[self mountFuseFS];
				}
			}
			
			SecKeychainItemFreeContent(NULL, passwordString);
		}
	}
	
	if (noErr != retStat) {
		[_info setStringValue:@"Enter Evernote account information:"];
		[_prefPanel makeKeyAndOrderFront:self];
	}	
}

///////////////////////////////////////////////////////////////////////////////
- (void)applicationDidFinishLaunching:(NSNotification *)notification; 
{
	[_useFullName setState:([[NSUserDefaults standardUserDefaults] boolForKey:kUserDefUseFullNameKey])];
	[self checkKeychainAndMount];
}

///////////////////////////////////////////////////////////////////////////////
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
{
	NSApplicationTerminateReply reply = NSTerminateNow;
	
	if (_changingMountPoint) {
		NSLog(@"Told to terminate but we're changing mount point; cancelling.");
		reply = NSTerminateCancel;
		_changingMountPoint = NO;
	}
	else {
		[_efs release];
		[_econn release];
	}
	
	return reply;
}

///////////////////////////////////////////////////////////////////////////////
- (IBAction) quit:(id)sender;
{
	[[NSApplication sharedApplication] terminate:self];
}
@end
