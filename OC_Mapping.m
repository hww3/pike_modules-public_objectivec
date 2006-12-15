#include "piobjc.h"
#import "OC_Mapping.h"

@interface OC_MappingEnumerator  : NSEnumerator
{
	struct mapping* mapping;
	BOOL valid;
	int pos;
}
+ newWithWrappedMapping:(OC_Mapping*)value;
- initWithWrappedMapping:(OC_Mapping*)value;
-(void)dealloc;

-(id)nextObject;

@end /* interface OC_MappingEnumerator */

@implementation OC_MappingEnumerator

+ newWithWrappedMapping:(OC_Mapping*)value
{
	return [[[self alloc] initWithWrappedMapping:v] autorelease];
}

- initWithWrappedMapping:(OC_Mapping*)value
{
	self = [super init];
	if (!self) return nil;

	mapping = [v retain];
	valid = YES;
	pos = 0;
	return self;
	
}

-(void)dealloc
{
	[value release];
	[super dealloc];	
}

-(id)nextObject
{
	
}

@end /* implementation OC_MappingEnumerator */
