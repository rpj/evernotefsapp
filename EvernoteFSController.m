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

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
@implementation EvernoteFSController
///////////////////////////////////////////////////////////////////////////////
- (IBAction) verifyAccount:(id)sender {
	NSString* u = [_username stringValue];
	NSString* p = [_password stringValue];
	
	if (u && p) {
		[_spinner startAnimation:self];
		
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
					if (retStat == -25299) err = @"Password already exists.";
					
					[_info setStringValue:[NSString stringWithFormat:@"Error saving to keychain: %@", err]];
				}
				
				[_prefPanel close];
			}
		}
		else {
			[_password setStringValue:@""];
			[_info setStringValue:@"Authentication failed."];
		}
		
		[_spinner stopAnimation:self];
	}
	else {
		[_info setStringValue:@"Missing information."];
	}
}

///////////////////////////////////////////////////////////////////////////////
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	NSUserDefaults* udef = [NSUserDefaults standardUserDefaults];
	NSString* accountName = [udef stringForKey:kUserDefAccountNameKey];
	
	if (accountName) {
		SecKeychainRef keychain = nil;
		OSStatus retStat;
		const char* accountCString = [accountName cStringUsingEncoding:NSUTF8StringEncoding];
		const char* serviceCString = [kServiceName cStringUsingEncoding:NSUTF8StringEncoding];
		UInt32 passwordLength = 0;
		const char* passwordString = NULL;
		
		if (noErr == (retStat = SecKeychainCopyDefault(&keychain))) {
			retStat = SecKeychainFindGenericPassword(keychain, strlen(serviceCString), serviceCString, 
													 strlen(accountCString), accountCString, 
													 &passwordLength, (void**)&passwordString, NULL);
			
			if (noErr == retStat) {
				[_username setStringValue:accountName];
				[_password setStringValue:[NSString stringWithCString:passwordString length:passwordLength]];
			}
		}
	}
	else {
		[_prefPanel makeKeyAndOrderFront:self];
	}
		
	/*
					_efs = [[EvernoteFUSE alloc] initWithVolumeName:
							[NSString stringWithFormat:@"%@'s Evernote", [user username]]];
	 */
}

///////////////////////////////////////////////////////////////////////////////
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	[_efs release];
	
	return NSTerminateNow;
}
@end
