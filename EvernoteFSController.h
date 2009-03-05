//
//  EvernoteFSController.h
//  EvernoteFSApp
//
//  Created by Ryan Joseph on 10/1/08.
//  Copyright 2009 Ryan Joseph. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EvernoteFUSE, EvernoteConnection;

@interface EvernoteFSController : NSObject {
	EvernoteFUSE* _efs;
	EvernoteConnection* _econn;
	
	// preference panel outlets
	IBOutlet NSPanel* _prefPanel;
	IBOutlet NSTextField* _username;
	IBOutlet NSTextField* _password;
	IBOutlet NSButton* _verifyAccount;
	IBOutlet NSTextField* _info;
	IBOutlet NSButton* _useFullName;
	
	BOOL _changingMountPoint;
}

- (void) mountFuseFS;
- (void) checkKeychainAndMount;

- (IBAction) verifyAccount:(id)sender;
- (IBAction) fullNameToggle:(id)sender;

- (IBAction) quit:(id)sender;
@end
