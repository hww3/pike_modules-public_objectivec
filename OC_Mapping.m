#include "piobjc.h"
#import "OC_Mapping.h"

@interface OC_MappingEnumerator  : NSEnumerator
{
	struct object* iterator;
	BOOL valid;
	int next_id;
	int key_id;
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
	struct mapping * m;
	
	self = [super init];
	if (!self) return nil;

    m = [value __ObjCgetPikeMapping];

	// do we need to do this?
    ref_push_mapping(m);
    f_get_iterator(1);
    
    if(Pike_sp[-1].type != T_OBJECT)
	{
		NSException *exception = [NSException exceptionWithName:@"IteratorException"
		                            reason:@"Unable to get an iterator for the mapping."  userInfo:nil];
		@throw exception;
	}

	iterator = Pike_sp[-1].u.object;

    add_ref(iterator);
    pop_stack();

	next_id=find_identifier("next", iterator->program);
	key_id=find_identifier("key", iterator->program);

	valid = YES;
	return self;
}

-(void)dealloc
{
	[value release];
	[super dealloc];	
}


// TODO: do we need to do this the other way around? We might be missing the first object.
-(id)nextObject
{
	id rv;
	
    printf("next object\n");
	apply_low(iterator, next_id, 0);
	
	if(Pike_sp[-1].type != T_INT)
	{
		NSException *exception = [NSException exceptionWithName:@"IteratorException"
		                            reason:@"Something went wrong while advancing the iterator."  userInfo:nil];
		@throw exception;		
	}
	
	if(!Pike_sp[-1].u.integer)
	{
		pop_stack();
		return nil;
	}	
	else
	{
		apply_low(iterator, key_id, 0);
		if(Pike_sp[-1].type == T_INT && Pike_sp[-1].subtype)
		{
			pop_n_elems(2);
			return nil;
		}
		
		rv = svalue_to_id(Pike_sp[-1]);
		pop_n_elems(2);
		
		return rv;
	}
}

@end /* implementation OC_MappingEnumerator */

@implementation OC_Mapping

+ newWithPikeMapping:(struct mapping*)value
{
  OC_Mapping * res = [[OC_Mapping alloc] initWithPikeMapping: value];
  [res autorelease];
  return res;
}

- initWithPikeMapping:(struct mapping*)value
{
  	self = [super init];
	if (!self) return nil;
	
	add_ref(value);
	mapping = value;
	
	return self;	
}

- (void)dealloc
{
	sub_ref(mapping);
	[super dealloc];
}

- (struct mapping *)__ObjCgetPikeMapping
{
  return mapping;
}

- (int)count
{ 
  int r;

  ref_push_mapping(mapping);
  f_sizeof(1);

  r = Pike_sp[-1].u.integer; 
  pop_stack();

  return r; 
}

- (NSEnumerator*)keyEnumerator
{
	
}

- (void)setObject:(id)object forKey:(id)key
{
	
}

- (void)removeObjectForKey:(id)key
{
	
}

- (id)objectForKey:(id)key
{
	
}

@end /* implementation OC_Mapping */