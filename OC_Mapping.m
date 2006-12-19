#include "piobjc.h"
#import "OC_Mapping.h"

@interface OC_MappingEnumerator  : NSEnumerator
{
	struct object* iterator;
	BOOL valid;
	int next_id;
	int key_id;
	int type;
}
+ newWithWrappedMapping:(OC_Mapping*)value type: (int) t;
- initWithWrappedMapping:(OC_Mapping*)value type: (int) t;
-(void)dealloc;

-(id)nextObject;

@end /* interface OC_MappingEnumerator */

@implementation OC_MappingEnumerator

+ newWithWrappedMapping:(OC_Mapping*)value type: (int) t
{
	return [[[self alloc] initWithWrappedMapping:value type: t] autorelease];
}

- initWithWrappedMapping:(OC_Mapping*)value type: (int) t
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
    add_ref(m);
    pop_stack();

	next_id=find_identifier("next", iterator->prog);

    if(t)
  	  key_id=find_identifier("value", iterator->prog);
    else
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
    printf("[OC_MappingEnumerator nextObject]\n");
    if(!valid)
	{
	  printf("we're at the end of the enumerator.\n");
      return nil;	
	}
	
	add_ref(iterator);
	apply_low(iterator, key_id, 0);
	if(Pike_sp[-1].type == T_INT && Pike_sp[-1].subtype)
	{
		pop_stack();
		return nil;
	}
//printf("got the key id.\n");	
	rv = svalue_to_id(Pike_sp-1);
	pop_stack();
		
    printf("forwarding iterator to next object.\n");
 //   add_ref(iterator);
	apply_low(iterator, next_id, 0);
	
	if(Pike_sp[-1].type != T_INT)
	{
		pop_stack();
		NSException *exception = [NSException exceptionWithName:@"IteratorException"
		                            reason:@"Something went wrong while advancing the iterator."  userInfo:nil];
		@throw exception;		
	}
	else if(Pike_sp[-1].subtype)
	{
		printf("at the end of the iterator.\n");
		valid = NO;
	}	
 //   printf("next value: %d", Pike_sp[-1].u.integer);	
	pop_stack();

//	[rv retain];
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
	
	mapping = value;
	add_ref(mapping);
	
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
  printf("[OC_Mapping count] returns %d\n", r);
  pop_stack();
  return r; 
}

- (NSEnumerator*)keyEnumerator
{
	OC_MappingEnumerator * e;
	printf("[OC_Mapping keyEnumerator]\n");
	e = [OC_MappingEnumerator newWithWrappedMapping: self type: 0];

	return e;
}

- (NSEnumerator*)objectEnumerator
{
	OC_MappingEnumerator * e;
	printf("[OC_Mapping objectEnumerator]\n");
	e = [OC_MappingEnumerator newWithWrappedMapping: self type: 1];

	return e;
}

- (void)setObject:(id)object forKey:(id)key
{
	struct svalue * v;
	struct svalue * k;
	
	printf("[OC_Mapping keyEnumerator]\n");
	k = id_to_svalue(key);
	v = id_to_svalue(object);

//	add_ref(mapping);
	mapping_insert(mapping, k, v);
}

- (void)removeObjectForKey:(id)key
{
	struct svalue * k = id_to_svalue(key);
//	add_ref(mapping);
	map_delete(mapping,k);	
}

- (id)objectForKey:(id)key
{
	struct svalue * v;
	id vid;
	struct svalue * k;
//	printf("[OC_Mapping objectForKey: %s]\n", [[key description] UTF8String]);
	k = low_id_to_svalue(key, 1);

//    add_ref(mapping);
    v = low_mapping_lookup(mapping, k);

    if(!v)
{
	printf("missed the entry.\n");
		return nil;
}		
    vid = svalue_to_id(v);	

	return vid;
}

@end /* implementation OC_Mapping */