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

//    printf("[OC_Array initWithPikeArray:]\n");	
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


-(BOOL)__ObjCisPikeType
{
  return YES;	
}

-(int)__ObjCgetPikeType
{
  return PIKE_T_ARRAY;
}

-(int)count
{
    printf("[OC_Array count]\n");	
	return array->size;
}

- (id)objectAtIndex:(int)idx
{
	printf("[OC_Array objectAtIndex: %d]\n", idx);	
    
	if(idx >= array->size) return nil;
//	printf("[OC_Array objetAtIndex:] converting to id.\n");
	
	id x = svalue_to_id(&(ITEM(array)[idx]));

//	printf("[OC_Array objetAtIndex:] finished converting to id.\n");
    
    return x;
}

-(void)replaceObjectAtIndex:(int)idx withObject:newValue
{
//	printf("[OC_Array replaceObjectAtIndex:]\n");	
    
	array_set_index(array, idx, id_to_svalue(newValue));
}

-(void)getObjects:(id*)buffer inRange:(NSRange)range
{
        unsigned int i;
        
        for (i = 0; i < range.length; i++) {
                buffer[i] = [self objectAtIndex:i+range.location];
        }
}

@end /* implementation OC_Array */