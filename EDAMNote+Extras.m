
#import "NoteStore.h"

@implementation EDAMNote (Extras)
- (id) retain;
{
	NSString* str = [NSString stringWithFormat:@"RETAIN\tEDAMNote\t\t<%@> %x: count is %d", [self title], self, [self retainCount]];
	id ret = [super retain];
	NSLog(@"%@ ... is now %d", str, [self retainCount]);
	return ret;
}

- (void) release;
{
	NSUInteger rc = [self retainCount];
	NSString* str = [NSString stringWithFormat:@"RELEASE\tEDAMNote\t\t<%@> %x: count is %d", [self title], self, [self retainCount]];
	[super release];
	if (rc > 1) NSLog(@"%@ ... is now %d", str, [self retainCount]);
	else NSLog(str);
}
@end


@implementation EDAMNotebook (Extras)
- (id) retain;
{
	NSString* str = [NSString stringWithFormat:@"RETAIN\tEDAMNotebook\t<%@> %x: count is %d", [self name], self, [self retainCount]];
	id ret = [super retain];
	NSLog(@"%@ ... is now %d", str, [self retainCount]);
	return ret;
}

- (void) release;
{
	NSUInteger rc = [self retainCount];
	NSString* str = [NSString stringWithFormat:@"RELEASE\tEDAMNotebook\t<%@> %x: count is %d", [self name], self, [self retainCount]];
	[super release];
	if (rc > 1) NSLog(@"%@ ... is now %d", str, [self retainCount]);
	else NSLog(str);
}
@end

