#include "piobjc.h"
#import "OC_Array.h"

@implementation OC_Array
+ newWithPikeArray:(struct array*)value;
{
	OC_Array * rv;
	
	rv = [[OC_Array alloc] initWithPikeArray: value];
	[rv autorelease];
	return rv;
}

- initWithPikeArray:(struct array*)value
{
	self = [super init];
	if(!self) return nil;
	
	array = value;
	
	add_ref(array);
	
	return self;
}

-(void)dealloc
{
	free_array(array);
	[super dealloc];
}

-(struct array*)__ObjCgetPikeArray
{
	return array;
}

-(int)count
{
	return array->size;
}

- (id)objectAtIndex:(int)idx
{
	if(idx >= array->size) return nil;
	
	return svalue_to_id(array->item[idx]);
}

-(void)replaceObjectAtIndex:(int)idx withObject:newValue
{
	array_set_index(array, idx, id_to_svalue(newValue));
}

-(void)getObjects:(id*)buffer inRange:(NSRange)range;
{
	
}

@end /* implementation OC_Array */