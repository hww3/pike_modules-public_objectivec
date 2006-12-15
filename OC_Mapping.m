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
	return [[[self alloc] initWithWrappedMapping:value] autorelease];
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

    pop_stack();

	next_id=find_identifier("next", iterator->prog);
	key_id=find_identifier("index", iterator->prog);

	valid = YES;
	return self;
}

-(void)dealloc
{
	sub_ref(iterator);
	[super dealloc];	
}


// TODO: do we need to do this the other way around? We might be missing the first object.
-(id)nextObject
{
	id rv;

    if(!valid)
      return nil;	
	
	apply_low(iterator, key_id, 0);
	if(Pike_sp[-1].type == T_INT && Pike_sp[-1].subtype)
	{
		pop_n_elems(2);
		return [NSNull null];
	}
		
	rv = svalue_to_id(Pike_sp[-1]);
	pop_n_elems(2);
		
    printf("next object\n");
	apply_low(iterator, next_id, 0);
	
	if(Pike_sp[-1].type != T_INT)
	{
		NSException *exception = [NSException exceptionWithName:@"IteratorException"
		                            reason:@"Something went wrong while advancing the iterator."  userInfo:nil];
		@throw exception;		
	}
	else if(!Pike_sp[-1].u.integer)
	{
		pop_stack();
		valid = NO;
	}	

	return rv;
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
	OC_MappingEnumerator * e;
	
	e = [OC_MappingEnumerator newWithWrappedMapping: self];

	return e;
}

- (void)setObject:(id)object forKey:(id)key
{
	struct svalue * v;
	struct svalue * k;
	
	k = id_to_svalue(key);
	v = id_to_svalue(object);
	
	mapping_insert(mapping, k, v);
}

- (void)removeObjectForKey:(id)key
{
	struct svalue * k = id_to_svalue(key);
	
	map_delete(mapping,k);	
}

- (id)objectForKey:(id)key
{
	struct svalue * v;
	id vid;
	struct svalue * k;
	
	k = id_to_svalue(key);

    v = low_mapping_lookup(mapping, k);

    if(!v)
		return nil;
		
    vid = svalue_to_id(v);	

	return vid;
	
}

@end /* implementation OC_Mapping */