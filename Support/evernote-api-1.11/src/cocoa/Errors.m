/**
 * Autogenerated by Thrift
 *
 * DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
 */

#import <Cocoa/Cocoa.h>

#import "TProtocol.h"
#import "TApplicationException.h"
#import "TProtocolUtil.h"

#import "Errors.h"


@implementation ErrorsConstants
+ (void) initialize {
}
@end

@implementation EDAMUserException
- (id) init
{
  return [super initWithName: @"EDAMUserException" reason: @"unknown" userInfo: nil];
}
- (id) initWithErrorCode: (int) errorCode parameter: (NSString *) parameter
{
  self = [self init];
  __errorCode = errorCode;
  __errorCode_isset = YES;
  __parameter = [parameter retain];
  __parameter_isset = YES;
  return self;
}

- (void) dealloc
{
  [__parameter release];
  [super dealloc];
}

- (int) errorCode {
  return __errorCode;
}

- (void) setErrorCode: (int) errorCode {
  __errorCode = errorCode;
  __errorCode_isset = YES;
}

- (BOOL) errorCodeIsSet {
  return __errorCode_isset;
}

- (void) unsetErrorCode {
  __errorCode_isset = NO;
}

- (NSString *) parameter {
  return [[__parameter retain] autorelease];
}

- (void) setParameter: (NSString *) parameter {
  [parameter retain];
  [__parameter release];
  __parameter = parameter;
  __parameter_isset = YES;
}

- (BOOL) parameterIsSet {
  return __parameter_isset;
}

- (void) unsetParameter {
  [__parameter release];
  __parameter = nil;
  __parameter_isset = NO;
}

- (void) read: (id <TProtocol>) inProtocol
{
  NSString * fieldName;
  int fieldType;
  int fieldID;

  [inProtocol readStructBeginReturningName: NULL];
  while (true)
  {
    [inProtocol readFieldBeginReturningName: &fieldName type: &fieldType fieldID: &fieldID];
    if (fieldType == TType_STOP) { 
      break;
    }
    switch (fieldID)
    {
      case 1:
        if (fieldType == TType_I32) {
          int fieldValue = [inProtocol readI32];
          [self setErrorCode: fieldValue];
        } else { 
          [TProtocolUtil skipType: fieldType onProtocol: inProtocol];
        }
        break;
      case 2:
        if (fieldType == TType_STRING) {
          NSString * fieldValue = [inProtocol readString];
          [self setParameter: fieldValue];
        } else { 
          [TProtocolUtil skipType: fieldType onProtocol: inProtocol];
        }
        break;
      default:
        [TProtocolUtil skipType: fieldType onProtocol: inProtocol];
        break;
    }
    [inProtocol readFieldEnd];
  }
  [inProtocol readStructEnd];
}

- (void) write: (id <TProtocol>) outProtocol {
  [outProtocol writeStructBeginWithName: @"EDAMUserException"];
  if (__errorCode_isset) {
    [outProtocol writeFieldBeginWithName: @"errorCode" type: TType_I32 fieldID: 1];
    [outProtocol writeI32: __errorCode];
    [outProtocol writeFieldEnd];
  }
  if (__parameter_isset) {
    if (__parameter != nil) {
      [outProtocol writeFieldBeginWithName: @"parameter" type: TType_STRING fieldID: 2];
      [outProtocol writeString: __parameter];
      [outProtocol writeFieldEnd];
    }
  }
  [outProtocol writeFieldStop];
  [outProtocol writeStructEnd];
}

- (NSString *) description {
  NSMutableString * ms = [NSMutableString stringWithString: @"EDAMUserException("];
  [ms appendString: @"errorCode:"];
  [ms appendFormat: @"%i", __errorCode];
  [ms appendString: @",parameter:"];
  [ms appendFormat: @"\"%@\"", __parameter];
  [ms appendString: @")"];
  return [ms copy];
}

@end

@implementation EDAMSystemException
- (id) init
{
  return [super initWithName: @"EDAMSystemException" reason: @"unknown" userInfo: nil];
}
- (id) initWithErrorCode: (int) errorCode message: (NSString *) message
{
  self = [self init];
  __errorCode = errorCode;
  __errorCode_isset = YES;
  __message = [message retain];
  __message_isset = YES;
  return self;
}

- (void) dealloc
{
  [__message release];
  [super dealloc];
}

- (int) errorCode {
  return __errorCode;
}

- (void) setErrorCode: (int) errorCode {
  __errorCode = errorCode;
  __errorCode_isset = YES;
}

- (BOOL) errorCodeIsSet {
  return __errorCode_isset;
}

- (void) unsetErrorCode {
  __errorCode_isset = NO;
}

- (NSString *) message {
  return [[__message retain] autorelease];
}

- (void) setMessage: (NSString *) message {
  [message retain];
  [__message release];
  __message = message;
  __message_isset = YES;
}

- (BOOL) messageIsSet {
  return __message_isset;
}

- (void) unsetMessage {
  [__message release];
  __message = nil;
  __message_isset = NO;
}

- (void) read: (id <TProtocol>) inProtocol
{
  NSString * fieldName;
  int fieldType;
  int fieldID;

  [inProtocol readStructBeginReturningName: NULL];
  while (true)
  {
    [inProtocol readFieldBeginReturningName: &fieldName type: &fieldType fieldID: &fieldID];
    if (fieldType == TType_STOP) { 
      break;
    }
    switch (fieldID)
    {
      case 1:
        if (fieldType == TType_I32) {
          int fieldValue = [inProtocol readI32];
          [self setErrorCode: fieldValue];
        } else { 
          [TProtocolUtil skipType: fieldType onProtocol: inProtocol];
        }
        break;
      case 2:
        if (fieldType == TType_STRING) {
          NSString * fieldValue = [inProtocol readString];
          [self setMessage: fieldValue];
        } else { 
          [TProtocolUtil skipType: fieldType onProtocol: inProtocol];
        }
        break;
      default:
        [TProtocolUtil skipType: fieldType onProtocol: inProtocol];
        break;
    }
    [inProtocol readFieldEnd];
  }
  [inProtocol readStructEnd];
}

- (void) write: (id <TProtocol>) outProtocol {
  [outProtocol writeStructBeginWithName: @"EDAMSystemException"];
  if (__errorCode_isset) {
    [outProtocol writeFieldBeginWithName: @"errorCode" type: TType_I32 fieldID: 1];
    [outProtocol writeI32: __errorCode];
    [outProtocol writeFieldEnd];
  }
  if (__message_isset) {
    if (__message != nil) {
      [outProtocol writeFieldBeginWithName: @"message" type: TType_STRING fieldID: 2];
      [outProtocol writeString: __message];
      [outProtocol writeFieldEnd];
    }
  }
  [outProtocol writeFieldStop];
  [outProtocol writeStructEnd];
}

- (NSString *) description {
  NSMutableString * ms = [NSMutableString stringWithString: @"EDAMSystemException("];
  [ms appendString: @"errorCode:"];
  [ms appendFormat: @"%i", __errorCode];
  [ms appendString: @",message:"];
  [ms appendFormat: @"\"%@\"", __message];
  [ms appendString: @")"];
  return [ms copy];
}

@end

@implementation EDAMNotFoundException
- (id) init
{
  return [super initWithName: @"EDAMNotFoundException" reason: @"unknown" userInfo: nil];
}
- (id) initWithIdentifier: (NSString *) identifier key: (NSString *) key
{
  self = [self init];
  __identifier = [identifier retain];
  __identifier_isset = YES;
  __key = [key retain];
  __key_isset = YES;
  return self;
}

- (void) dealloc
{
  [__identifier release];
  [__key release];
  [super dealloc];
}

- (NSString *) identifier {
  return [[__identifier retain] autorelease];
}

- (void) setIdentifier: (NSString *) identifier {
  [identifier retain];
  [__identifier release];
  __identifier = identifier;
  __identifier_isset = YES;
}

- (BOOL) identifierIsSet {
  return __identifier_isset;
}

- (void) unsetIdentifier {
  [__identifier release];
  __identifier = nil;
  __identifier_isset = NO;
}

- (NSString *) key {
  return [[__key retain] autorelease];
}

- (void) setKey: (NSString *) key {
  [key retain];
  [__key release];
  __key = key;
  __key_isset = YES;
}

- (BOOL) keyIsSet {
  return __key_isset;
}

- (void) unsetKey {
  [__key release];
  __key = nil;
  __key_isset = NO;
}

- (void) read: (id <TProtocol>) inProtocol
{
  NSString * fieldName;
  int fieldType;
  int fieldID;

  [inProtocol readStructBeginReturningName: NULL];
  while (true)
  {
    [inProtocol readFieldBeginReturningName: &fieldName type: &fieldType fieldID: &fieldID];
    if (fieldType == TType_STOP) { 
      break;
    }
    switch (fieldID)
    {
      case 1:
        if (fieldType == TType_STRING) {
          NSString * fieldValue = [inProtocol readString];
          [self setIdentifier: fieldValue];
        } else { 
          [TProtocolUtil skipType: fieldType onProtocol: inProtocol];
        }
        break;
      case 2:
        if (fieldType == TType_STRING) {
          NSString * fieldValue = [inProtocol readString];
          [self setKey: fieldValue];
        } else { 
          [TProtocolUtil skipType: fieldType onProtocol: inProtocol];
        }
        break;
      default:
        [TProtocolUtil skipType: fieldType onProtocol: inProtocol];
        break;
    }
    [inProtocol readFieldEnd];
  }
  [inProtocol readStructEnd];
}

- (void) write: (id <TProtocol>) outProtocol {
  [outProtocol writeStructBeginWithName: @"EDAMNotFoundException"];
  if (__identifier_isset) {
    if (__identifier != nil) {
      [outProtocol writeFieldBeginWithName: @"identifier" type: TType_STRING fieldID: 1];
      [outProtocol writeString: __identifier];
      [outProtocol writeFieldEnd];
    }
  }
  if (__key_isset) {
    if (__key != nil) {
      [outProtocol writeFieldBeginWithName: @"key" type: TType_STRING fieldID: 2];
      [outProtocol writeString: __key];
      [outProtocol writeFieldEnd];
    }
  }
  [outProtocol writeFieldStop];
  [outProtocol writeStructEnd];
}

- (NSString *) description {
  NSMutableString * ms = [NSMutableString stringWithString: @"EDAMNotFoundException("];
  [ms appendString: @"identifier:"];
  [ms appendFormat: @"\"%@\"", __identifier];
  [ms appendString: @",key:"];
  [ms appendFormat: @"\"%@\"", __key];
  [ms appendString: @")"];
  return [ms copy];
}

@end

