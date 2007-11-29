#include "libffi/include/ffi.h"
#import "piobjc.h"
#import <Foundation/NSInvocation.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSString.h>
#import "PiObjCObject.h"
#import "OC_Array.h"
#import "OC_Mapping.h"
#import "ObjC.h"
/*
 *  util.c: helper functions and objects.
 *
 *
 */

/* this code is from pyobjc-1.4. */
extern void dynamic_class_event_handler(int ev);

extern struct mapping * global_proxy_cache;
 static struct pike_type *a_markers[10], *b_markers[10];
 static struct svalue get_signature_for_func_sval;
 static int got_signature_for_func_func = 0;
 static struct program * nsnil_prog = NULL;

@interface NSObject (PiObjCSupport)
-(struct object*)__piobjc_PikeObject__;
+(struct object*)__piobjc_PikeObject__;
@end /* PiObjCSupport */

@implementation NSObject (PiObjCSupport)

-(struct object*)__piobjc_PikeObject__
{
	struct object *rval;
printf("__piobjc_PikeObject__\n");
	rval = PiObjC_FindPikeProxy(self);

	if (rval == NULL) 
	{
		rval = wrap_real_id(self);
//		add_ref(rval);
	 	PiObjC_RegisterPikeProxy(self, rval);
	}
    //add_ref(rval);
	return rval;
}

+(struct object*)__piobjc_PikeObject__
{
	struct object *rval;
printf("__piobjc_PikeObject__\n");

	//rval = PyObjC_FindPythonProxy(self);
	rval = NULL;
	if (rval == NULL) {
//		rval = (struct object *)PyObjCClass_New(self);
		//PyObjC_RegisterPythonProxy(self, rval);
	}

	return rval;
}

@end /* PiObjCSupport */

@interface NSProxy (PiObjCSupport)
-(struct object*)__piobjc_PikeObject__;
+(struct object*)__piobjc_PikeObject__;
@end /* PiObjCSupport */

@implementation NSProxy (PiObjCSupport)

-(struct object*)__piobjc_PikeObject__
{
	struct object *rval;
printf("NSProxy.__piobjc_PikeObject__\n");
	rval = PiObjC_FindPikeProxy(self);
	if (rval == NULL) {
		printf("wrapping...\n");
		rval = wrap_real_id(self);
printf("wrapped!\n");
	 	PiObjC_RegisterPikeProxy(self, rval);
	}

	return rval;
}

+(struct object*)__piobjc_PikeObject__
{
	struct object *rval;

	//rval = PyObjC_FindPythonProxy(self);
	rval = NULL;
	if (rval == NULL) {
//		rval = (struct object *)PyObjCClass_New(self);
		//PyObjC_RegisterPythonProxy(self, rval);
	}

	return rval;
}

@end /* PiObjCSupport */

@implementation OC_NSAutoreleasePoolCollector
-(void)newAutoreleasePool
{
  release_pool = [[NSAutoreleasePool alloc] init];
}

-(id)init
{
  main_thread = [NSThread currentThread];
  return [super init];
}

-(id)getAutoreleasePool
{
  if([[NSThread currentThread] isEqual: main_thread])
    return nil;
  else
    return release_pool;  
}

-(void)purgeAndNew
{
  [release_pool release];
  [self newAutoreleasePool];
}

-(void)dealloc
{
        release_pool = nil;
        [super dealloc];
}

-(void)targetForBecomingMultiThreaded:(id)sender
{
    [sender self];
}

@end


NSMapTableKeyCallBacks PiObjCUtil_PointerKeyCallBacks = {
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
};

NSMapTableValueCallBacks PiObjCUtil_PointerValueCallBacks = {
	NULL,
	NULL,
	NULL,
};

static void
nsmaptable_objc_retain(NSMapTable *table __attribute__((__unused__)), const void *datum) {
	[(id)datum retain];
}

static void
nsmaptable_objc_release(NSMapTable *table __attribute__((__unused__)), void *datum) {
	[(id)datum release];
}

NSMapTableKeyCallBacks PiObjCUtil_ObjCIdentityKeyCallBacks = {
	NULL,
	NULL,
	&nsmaptable_objc_retain,
	&nsmaptable_objc_release,
	NULL,
	NULL,
};

NSMapTableValueCallBacks PiObjCUtil_ObjCValueCallBacks = {
	&nsmaptable_objc_retain,
	&nsmaptable_objc_release,
	NULL  // generic description
};

struct object * wrap_real_id(id r)
{
  struct program * prog;
  struct objc_dynamic_class * pc; 
  struct pike_string * ps;
  struct object * o;
  id toc;

    ps = make_shared_binary_string(r->isa->name, strlen(r->isa->name));
    prog = pike_create_objc_dynamic_class(ps);
	free_string(ps);

    if(!prog) return NULL;

    o = low_clone(prog);
    pc = OBJ2_DYNAMIC_OBJECT(o);
    pc->obj = (id)r;
  // we need to  the object, because the dynamic_class object 
  // will free it when the object is destroyed.
  if((id)r->isa != [NSAutoreleasePool class])
  {
    [r retain];
  }
    pc->is_instance = 1;

  return o;
}

void void_dispatch_method(id obj, SEL select, struct objc_method * method, marg_list argumentList)
{
	printf("void_dispatch_method()\n");
  THREADS_ALLOW();
//  printf("void [%s %s]\n", [[obj description] UTF8String], select);
  objc_msgSendv(obj,select,method_getSizeOfArguments(method),argumentList);
  THREADS_DISALLOW();
}

struct svalue * object_dispatch_method(id obj, SEL select, struct objc_method * method, marg_list argumentList)
{
  struct svalue * o;
  id r;
  
  THREADS_ALLOW();
  r = objc_msgSendv(obj,select,method_getSizeOfArguments(method),argumentList);
  THREADS_DISALLOW();
  o = id_to_svalue(r);
  if(!(o && o->u.object))
	o = NULL;
  return o;
}

struct svalue * low_id_to_svalue(id obj, int prefer_native)
{
	struct svalue * sv;
	struct object * o;
//	NSLog([obj description]);
	if(!obj) {/*printf("low_id_to_svalue(): no object to convert!\n");*/ return NULL;}
	
	sv = malloc(sizeof(struct svalue));
	
	// TODO: this method very likely has flaws.
	if(prefer_native)
	{
		if([obj respondsToSelector: SELUID("characterAtIndex:")])
		{
			NSStringEncoding enc;		  
			struct pike_string * str;
			char * u8s;
			
		    enc =  NSUTF8StringEncoding;
		  
	//		printf("got a string to convert.\n");
			u8s = [obj UTF8String];
			str = make_shared_binary_string(u8s, [obj lengthOfBytesUsingEncoding: enc]);
//			free(u8s);
			ref_push_string(str);
			f_utf8_to_string(1);
			
			sv->type = T_STRING;
			sv->subtype = 0;
			sv->u.string = Pike_sp[-1].u.string;
            add_ref(sv->u.string);
			pop_stack();
            return sv;
		}
	}
	
	if([obj respondsToSelector: SELUID("__ObjCgetPikeArray")])
	{
		struct array * a;
		
		a = [obj __ObjCgetPikeArray];
        // add_ref(a);
		sv->type = T_ARRAY;
		sv->subtype = 0;
		sv->u.array = a;
	}

	else if([obj respondsToSelector: SELUID("__ObjCgetPikeMapping")])
	{
		struct mapping * m;
		
		m = [obj __ObjCgetPikeMapping];
        // add_ref(m);
		sv->type = T_MAPPING;
		sv->subtype = 0;
		sv->u.mapping = m;
	}

	else 
	  o = wrap_objc_object(obj);

    if(o)
    {
//	    add_ref(o);
//	printf("o'': %d\n",o->refs);
		sv->type = T_OBJECT;
		sv->subtype = 0;
		sv->u.object = o;
	}
    else
    {
	  sv->type = T_INT;
	  sv->subtype = 1;
	  sv->u.integer = 0;
//	  printf("id_to_svalue(): no object!\n");
    }

    return sv;
}

void * svalue_to_ptr(struct svalue * sval, char * type)
{
	return NULL;
}

struct svalue * id_to_svalue(id obj)
{
	return low_id_to_svalue(obj, 0);
}


id svalue_to_id(struct svalue * sv)
{
  id rv;

// printf("svalue_to_id(): %d\n", sv->type);

	switch(sv->type)
	{
		case T_INT:
		  rv = [NSNumber numberWithLong: sv->u.integer];
	  	  break;
	
		case T_FLOAT:
		  rv = [NSNumber numberWithDouble: sv->u.float_number];
  		  break;
		
		case T_STRING:
			{
			  NSStringEncoding enc;
			  enc =  NSUTF8StringEncoding;
			  push_svalue(sv);
//			  add_ref(sv->u.string);
//			  add_ref(sv->u.string);
			  f_string_to_utf8(1);
			  sv = &Pike_sp[-1];
			  rv = [[NSString alloc] initWithBytes: sv->u.string->str length: sv->u.string->len encoding: enc];
			  [rv autorelease];
			  pop_stack();
			}		
			
			break;

		case T_ARRAY:
			// add_ref(sv->u.array);
			rv = [OC_Array newWithPikeArray: sv->u.array];
			[rv autorelease];
		
			break;
			
		case T_MAPPING:
			//add_ref(sv->u.mapping);
			rv = [OC_Mapping newWithPikeMapping: sv->u.mapping];
			[rv autorelease];
		
			break;
		
		case T_OBJECT:
	    	{
		  		struct object * o;
		  		//add_ref(sv->u.object);
		  		o = sv->u.object;
				rv = id_from_object(o);
			}
			break;
			
		default:
			printf("SV TYPE: %d\n", sv->type);
		  Pike_error("expected object return value.\n");		
	}

//	printf("returning from svalue_to_id()\n");
	return rv;	
}

id objcify_pike_object(struct object * o)
{
	Class cls;
	id proxy;
	
	cls = get_objc_proxy_class(o->prog);
	
	proxy = [cls newWithPikeObject: o];
	
	return proxy;
}

Class get_objc_proxy_class(struct program * prog)
{
	struct svalue * c = NULL;
    Class cls;

//    printf("*** get_objc_proxy_class()\n");*/
	ref_push_program(prog);
	c = low_mapping_lookup(global_proxy_cache, Pike_sp-1);	
	pop_stack();

	if(c) 
	{ 
		cls = (Class)(c->u.ptr);
	    free_svalue(c);
		return cls;
	}
	else
	{
		char * name;
		int i;
		name = malloc(sizeof(char) * 15);
		i = (int)random();
		snprintf(name, 14, "PiProxy%05d", i);
		add_piobjcclass(name, prog);
		free(name);
	}

	cls = get_objc_proxy_class(prog);

	return cls;
}

// ok, here's the algorithm we should use for unwrapping
//
// all pike objects that represent an objective c object should have an 
// objective c counterpart stored if they've been through the bridge.
// that means, if we have one in the map, then it's the right one.
// if a pike object doesn't, then it's definitely a pike object that hasn't
// been through the bridge at all, and we should wrap it.
id id_from_object(struct object * o)
{
	id c;
	
	c = PiObjC_FindObjCProxy(o);	
	if(!c)
	{
		c = objcify_pike_object(o);
	}
	
	return c;
}

SEL selector_from_pikename(struct pike_string * name)
{
  SEL select;
  char * selectorName;
  int ind;
    
    // first, we perty up the selector.
    selectorName = malloc(name->len + 1);
    if(selectorName == NULL)
    {
      Pike_error("unable to allocate selector storage.\n");
    }
    strncpy(selectorName, name->str, name->len);

    for(ind = 0; ind < name->len; ind++)
    {
      if(selectorName[ind] == '_')
        selectorName[ind] = ':';
    }  
    selectorName[ind] = '\0';
    select = sel_registerName(selectorName);

  free(selectorName);  

  return select;
}

//! convert a pointer to a pike svalue based on an objective c type encoding.
//! objective c objects will be converted to wrapped objects. for conversion
//! to native pike datatypes such as array and mapping, see low_ptr_to_svalue(). 
struct svalue * ptr_to_svalue(void * ptr, char * type)
{
	return low_ptr_to_svalue(ptr, type, 0);
}

// TODO: implement native conversions
// TODO: implement conversion from non-id datatypes
struct svalue * low_ptr_to_svalue(void * ptr, char * type, int prefer_native)
{
	struct svalue * sv;
	
	sv = malloc(sizeof(struct svalue));
	
	switch(*type)
	{
		case '@':
		{
			struct object * o;
			o = wrap_objc_object((id)ptr);
            if(!o) goto undefined_val;

			sv->type = T_OBJECT;
			sv->subtype = 0;
			sv->u.object = o;
			break;
		}
		default:
			printf("whee! %s\n", type);
	}

	return sv;
	
	undefined_val:
	
		sv->type = T_INT;
		sv->subtype = 1;
		sv->u.integer = 0;
	
	return sv;
	
}

struct object * wrap_objc_object(id r)
{
  struct object * o;

  if(!r || !r->isa) 
  { 
	printf("skipping null object.\n");
    return NULL; 
  }
  
  /* TODO: Do we need to make these methods in PiObjCObject hidden? */
	o = [r __piobjc_PikeObject__];
   add_ref(o);
  return o;
}

struct program * wrap_objc_class(Class r)
{
  struct program * prog;
  struct objc_dynamic_class * pc; 

  if(!r || !r->isa)  { return NULL; }

  push_text(r->name);

  prog = pike_create_objc_dynamic_class(Pike_sp[-1].u.string);
  pop_stack();  
  
  return prog;
}

int push_objc_types(NSMethodSignature* sig, NSInvocation* invocation)
{
	char * type = NULL;
    void * buf = NULL;
	int arg = 0;
	id cobj = NULL;
	struct svalue * sval = NULL;
	int args_pushed = 0;
 	// args 0 and 1 are the object and the method, respectively.
	for(arg = 2; arg < [sig numberOfArguments];arg++)
    {
	  // now, we push the argth argument onto the stack.
	  type = (char*)[sig getArgumentTypeAtIndex: arg];
      while((*type)&&(*type=='r' || *type =='n' || *type =='N' || *type=='o' || *type=='O' || *type =='V'))
		type++;
  printf("type for arg %d: %s\n", arg, type);

      switch(*type)
      {
	     case 'c':
	       // char
	       buf = (char*)malloc(sizeof(char));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_int((char)(*(char *)buf));
		   args_pushed++;
           free(buf);
	       break;
         case 'C':
	       buf = (unsigned char*)malloc(sizeof(unsigned char));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_int((unsigned char)(*(unsigned char *)buf));
		   args_pushed++;
           free(buf);
	       break;
	     case 'i':
	       // int
	       buf = (int*)malloc(sizeof(int));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_int((int)(*(int *)buf));
		   args_pushed++;
           free(buf);
	       break;
	     case 'I':
	       // int
	       buf = (unsigned int*)malloc(sizeof(unsigned int));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_int((unsigned int)(*(unsigned int *)buf));
		   args_pushed++;
           free(buf);
	       break;
	     case 's':
	       // int
	       buf = (short*)malloc(sizeof(short));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_int((short)(*(short *)buf));
		   args_pushed++;
           free(buf);
	       break;
	     case 'S':
	       // int
	       buf = (unsigned short*)malloc(sizeof(unsigned short));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_int((unsigned short)(*(unsigned short *)buf));
		   args_pushed++;
           free(buf);
	       break;
	     case 'l':
	       // int
	       buf = (long*)malloc(sizeof(long));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_int((long)(*(long *)buf));
		   args_pushed++;
           free(buf);
	       break;	
	     case 'L':
	       // int
	       buf = (unsigned long*)malloc(sizeof(unsigned long));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_int((unsigned long)(*(unsigned long *)buf));
		   args_pushed++;
           free(buf);
	       break;
		     case 'f':
	       // int
	       buf = (float*)malloc(sizeof(float));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_float((float)(*(float *)buf));
		   args_pushed++;
           free(buf);
	       break;
	     case 'd':
	       // int
	       buf = (double*)malloc(sizeof(double));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_float((double)(*(double *)buf));
		   args_pushed++;
           free(buf);
	       break;
	     case 'q':
	       // int
	       buf = (long long*)malloc(sizeof(long long));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_float((long long)(*(long long *)buf));
		   args_pushed++;
           free(buf);
	       break;
	     case 'Q':
	       // int
	       buf = (unsigned long long*)malloc(sizeof(unsigned long long));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_float((unsigned long long)(*(unsigned long long *)buf));
		   args_pushed++;
           free(buf);
	       break;
	     case '*':
	       // int
	       buf = (char*)malloc(sizeof(char *));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_text((char *)buf);
		   args_pushed++;
           free(buf);
	       break;
	     case ':':
	       // int
	       buf = (SEL)malloc(sizeof(SEL));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           push_text((char *)buf);
		   args_pushed++;
           free(buf);
	       break;
	     case '@':
	       // int
	       buf = (id)malloc(sizeof(id));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           cobj = (id)buf;
printf("arg %d: %p\n", arg, cobj->isa);
//NSLog([cobj description]);
           sval = id_to_svalue(cobj);
		        args_pushed++;
            push_svalue(sval);
			free(sval);
          // free(buf);
	       break;
	     case '#':
	       {
	         struct program * pprog;
           buf = (Class)malloc(sizeof(Class));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           pprog = wrap_objc_class((Class)buf);
           if(!pprog){printf("AAAAAH! No program to push.\n");}
    		   args_pushed++;
           push_program(pprog);
           //free(buf);
         }
	       break;
	
         default:
           printf("type: %s\n", type);
           Pike_error("invalid argument type!\n");
           break;
      }

    }
	return args_pushed;
}

int get_argcount_by_selector(SEL aSelector)
{
  char * funname;
  int funlen;
  int ind;
  int argcount = 0;

  funlen = strlen((char *)aSelector);

  for(ind = 0; ind < funlen; ind++)
  {
    if(((char *)aSelector)[ind] == ':')
      argcount++;
  }   
  return argcount;	
}

void piobjc_set_return_value(id sig, id invocation, struct svalue * svalue)
{
	char * type;
    struct object * o;
    id wrapper;
printf("piobjc_set_return_value()\n");
 	  // now, we push the argth argument onto the stack.
	type = (char *)[sig methodReturnType];
    while((*type)&&(*type=='r' || *type =='n' || *type =='N' || *type=='o' || *type=='O' || *type =='V'))
	  type++;
   printf("return value type is %s -> %d\n", type, svalue->subtype);
//   printf("arg 0 type is %s\n", [sig getArgumentTypeAtIndex: 2]);

    printf("returned value type is %d\n", svalue->type);
    switch(*type)
    {
	  // id
    case 'c':
    case 'i':  // TODO handle bignums
      if(svalue->type == T_INT)
      {
        printf("returning %d\n", svalue->u.integer);
        [invocation setReturnValue: &svalue->u.integer];    
      }
      else
      {
        printf("AAAARG! not an integer returned from function!\n");
      }
      break;
	  case '@':
		{
			id val;
			val = svalue_to_id(svalue);
//printf("id object: %s", [[val description] UTF8String]);
			[invocation setReturnValue: &val];
		}
  	    break;
      case 'v': 
        // void return value!
        break;
      case '#':
      case ':':
      // class
      // selector 
      default:
      printf("ERROR: don't know how to set a return value of encoding %s\n", type);
        break;
 	}
}

char * get_signature_for_func(struct svalue * func, SEL selector)
{
  char * encoding;
  int numargs;
  struct svalue sv;

  printf("|-> get_signature_for_func()\n");

  if(!got_signature_for_func_func)
  {
    push_text( "Public.ObjectiveC.get_signature_for_func"); 
    SAFE_APPLY_MASTER("resolv", 1 );
	if(!(Pike_sp-1))
	{
		Pike_error("aieee!\n");
	}
    assign_svalue_no_free(&get_signature_for_func_sval, Pike_sp-1);
    pop_stack();
    got_signature_for_func_func = 1;
  }
  numargs = get_argcount_by_selector(selector);

  push_svalue(func);
  push_text(selector);
  push_int(numargs);

  apply_svalue(&get_signature_for_func_sval, 3);

  // result is at top of the stack, function is still one down 
  // and we want to pop it. 
//  stack_swap(); 
//  pop_stack();


  if(Pike_sp[-1].type != T_STRING)
  {
    pop_stack();
    return NULL;
  }
  else
  {
    encoding = strdup(Pike_sp[-1].u.string->str);
    pop_stack();
    return encoding;
  }
  return 0;
}


struct svalue * get_func_by_selector(struct object * pobject, SEL aSelector)
{
  char * funname;
  int funlen;
  int ind;
  int argcount;
  struct svalue * sv2;
  int z;

  if(!pobject) return NULL;

  sv2 = malloc(sizeof(struct svalue));

  if(!sv2)
	{
		Pike_error("Unable to allocate memory.\n");
	}
  
  funlen = strlen((char *)aSelector);

  funname = malloc(funlen + 1);

  if(funname == NULL)
  {
    Pike_error("unable to allocate selector storage.\n");
  }
  
  strncpy(funname, (char *)aSelector, funlen);
  
  for(ind = 0; ind < funlen; ind++)
  {
    if(funname[ind] == ':')
      funname[ind] = '_';
      argcount++;
  }   
  funname[ind] = '\0';

  printf("get_func_by_selector: %s ", funname);

  // do we need to do this?
  push_text(funname);
  free(funname);

  object_index_no_free(sv2, pobject, Pike_sp-1);
  pop_stack();

  if(sv2->type == PIKE_T_FUNCTION) // jackpot!
  {
	printf("yes\n");
    if(!sv2->u.efun) { printf("no fun!\n");}
    else
	  return sv2;
//    printf("Pike_sp[-1]: <%p> <%D>\n", Pike_sp[-1], &Pike_sp[-1]);
//    printf("**> fun refs: %d\n\n", Pike_sp[-1].u.efun->refs); 
  }

  printf("no\n");

  free_svalue(sv2);
  free(sv2);
  return NULL;

}

char * make_pike_name_from_selector(SEL s)
{
  char * pikename;
  int len, ind;

  pikename = strdup((char *)s);
  
  if(pikename == NULL)
  {
    Pike_error("unable to allocate pikename storage.\n");
  }

  len = strlen(pikename);
  
  for(ind = 0; ind < len; ind++)
  {
    if(pikename[ind] == ':')
      pikename[ind] = '_';
  }  
  pikename[ind] = '\0';

  return pikename;
}

BOOL isNSNil(struct svalue * sv)
{
	if(sv->type != T_OBJECT) return 0;
	if(!nsnil_prog) 
	{
	  push_text("Public.ObjectiveC.nil");
	  SAFE_APPLY_MASTER("resolv", 1);
	
	  if(Pike_sp[-1].type != T_OBJECT)
      {
		printf("aiee! unable to find the pike nil placeholder!\n");
		pop_stack();
	    return 0;
	  }
	
	  nsnil_prog = Pike_sp[-1].u.object->prog;
      add_ref(nsnil_prog);		
      pop_stack();
	}
	
	if(nsnil_prog && sv->u.object->prog == nsnil_prog) return 1;
	else return 0;
}

struct object * new_method_runner(struct object * obj, SEL selector)
{
  struct program * dclass = NULL;
  struct object * dobject = NULL;
  static ptrdiff_t dclass_storage_offset;
  int siglen;
  char * psig;
  id signature;
  struct objc_dynamic_class * c;

  c = OBJ2_DYNAMIC_OBJECT(obj);

  [c->obj description2];
  signature = [c->obj methodSignatureForSelector: selector];

  if(!signature) 
  {
	printf("no method signature for selector %s\n", (char *)selector);
    return NULL;
  };

  start_new_program();

  add_string_constant("__objc_selector", (char *) selector, ID_PUBLIC);

  dclass_storage_offset = ADD_STORAGE(struct objc_dynamic_class);

  psig = pike_signature_from_nsmethodsignature(signature, &siglen);
  quick_add_function("`()", strlen("`()"), f_objc_dynamic_instance_method, psig,
                     siglen, 0, 
                     OPT_SIDE_EFFECT|OPT_EXTERNAL_DEPEND);


  pike_set_prog_event_callback(dynamic_class_event_handler);
  dclass = end_program();

  dobject = fast_clone_object(dclass);
  
  return dobject;
}

BOOL has_objc_method(id obj, SEL aSelector)
{
	void *iterator = 0;
  struct objc_method_list *methodList;
  int index;
  int x = 0;
  SEL selector;

  if(obj == nil) Pike_error("whoa, horsie! no class for this object!\n");

        while (methodList = class_nextMethodList(obj->isa, &iterator)) {
                for (index = 0; index < methodList->method_count; index++) {
                        if((char *)aSelector == (char *)methodList->method_list[index].method_name) return YES;
                }
        }

  return NO;
}


// this is one of two functions that generate pike signatures. the other is pike_signature_from_objc_signature.
char * pike_signature_from_nsmethodsignature(id nssig, int * lenptr)
{
  char * rettype;
  char * argtype;
  char * psig;
  int spsig;
  int argcount;
  int offset;
  char * type;
  int sret;
  int x;
  int i;
  int sargs;
  int cpos;
  int now;
  char * psigo;
  
  argcount = [nssig numberOfArguments];

  // ok, let's do return type first.

//  printf("TYPE: %s\n", nssig->method_types);

  type = [nssig methodReturnType];

  while((*type)&&(*type=='r' || *type =='n' || *type =='N' || *type=='o' || *type=='O' || *type =='V'))
                type++;

    switch(*type)
    {
      case 'c': // char
        rettype = tInt;
        sret = CONSTANT_STRLEN(tInt);
//      printf("c\n");
        break;

      case 'i': // int
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("i\n");
        break;

      case 's': // short
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("s\n");
        break;

      case 'l': // long
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
      //    printf("l\n");
        break;

      case 'q': // long long
        rettype = tInt;
        sret = CONSTANT_STRLEN(tInt);
//        printf("q\n");
        break;

      case 'C': // unsigned char
        rettype = tInt;
        sret = CONSTANT_STRLEN(tInt);
//        printf("I\n");
        break;

      case 'I': // unsigned int
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("I\n");
        break;

      case 'S': // unsigned short
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("S\n");
        break;

      case 'L': // unsigned long
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("L\n");
        break;

      case 'Q': // unsigned long long
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("Q\n");
        break;

      case 'f': // float
        rettype = tFloat;
      sret = CONSTANT_STRLEN(tFloat);
//      printf("f\n");
        break;

      case 'd': // double
        rettype = tFloat;
      sret = CONSTANT_STRLEN(tFloat);
//      printf("d\n");
        break;

      case 'B': // bool
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("B\n");
        break;

      case 'v': // void
        rettype = tVoid;
      sret = CONSTANT_STRLEN(tVoid);
//      printf("v\n");
        break;

      case '*': // char *
        rettype = tStr;
      sret = CONSTANT_STRLEN(tStr);
//      printf("*\n");
        break;

      case '@': // object
        rettype = tObj;
      sret = CONSTANT_STRLEN(tObj);
//      printf("@\n");
        break;

      case '#': // class
        rettype = tPrg(tObj);
      sret = CONSTANT_STRLEN(tPrg(tObj));
//      printf("#\n");
        break;

      case ':': // SEL
        rettype = tString;
      sret = CONSTANT_STRLEN(tString);
//      printf(":\n");
        break;

      case '[': // array
        rettype = tArr(tMix);
      sret = CONSTANT_STRLEN(tArr(tMix));
//      printf("[\n");
        break;

      case '{': // struct
        rettype = tObj;
      sret = CONSTANT_STRLEN(tObj);
//      printf("{\n");
        break;

      case '(': // union
        rettype = tObj;
      sret = CONSTANT_STRLEN(tObj);
//      printf("(\n");
        break;

      case 'b':  // bit field
        rettype = tInt;
      sret = CONSTANT_STRLEN(tObj);
//      printf("b\n");
        break;

      case '^':  // pointer
        rettype = tObj;
      sret = CONSTANT_STRLEN(tObj);
//      printf("^\n");
        break;

      case '?':  // unknown (function ptr)
        rettype = tObj;
      sret = CONSTANT_STRLEN(tObj);
      printf("?\n");
        break;
      default:
        printf("SIGNATURE: %s\n", type);
    }

  for (x = 2; x < argcount; x++)
  {
    type = [nssig getArgumentTypeAtIndex: x];

    while((*type)&&(*type=='r' || *type =='n' || *type =='N' || *type=='o' || *type=='O' || *type =='V'))
                type++;

    switch(*type)
    {
      case 'c': // char
//      printf("c\n");
        break;

      case 'i': // int
//        printf("i\n");
        break;

      case 's': // short
//        printf("s\n");
        break;

      case 'l': // long
//        printf("l\n");
        break;

      case 'q': // long long
//        printf("q\n");
        break;

        case 'C': // unsigned char
//           printf("C\n");
           break;
           
        case 'I': // unsigned int
//         printf("I\n");
         break;

 
       case 'S': // unsigned short
//        printf("S\n");
        break;

      case 'L': // unsigned long
//        printf("L\n");
        break;

      case 'Q': // unsigned long long
//        printf("Q\n");
        break;

      case 'f': // float
//        printf("f\n");
        break;

      case 'd': // double
//        printf("d\n");
        break;

      case 'B': // bool
//        printf("B\n");
        break;

      case 'v': // void
//        printf("v\n");
        break;

      case '*': // char *
//        printf("*\n");
        break;

      case '@': // object
//        printf("@\n");
        break;

      case '#': // class
//        printf("#\n");
        break;

      case ':': // SEL
//        printf(":\n");
        break;

      case '[': // array
//        printf("[\n");
        break;

      case '{': // struct
//        printf("{\n");
        break;

      case '(': // union
//        printf("(\n");
        break;

      case 'b':  // bit field
//        printf("b\n");
        break;

      case '^':  // pointer
//        printf("^\n");
        break;

      case '?':  // unknown (function ptr)
        printf("c?\n");
        break;
    }


  }

  spsig = CONSTANT_STRLEN("\004\021\020") + (CONSTANT_STRLEN(tMix)*(argcount-2)) + sret;
//printf("allocated %d bytes for signature.\n", spsig);
  psig = malloc(spsig);
  psigo = psig;
  now = 0;

  psig[now++] = '\004';

  for(i = 0; i < (argcount-2); i++)
    psig[now++] = '\373';


  psig[now++] = '\021';
  psig[now++] = '\020';
  
  for(cpos = 0; cpos < sret; cpos++)
  {
    psig[now++] = rettype[cpos];
  }

  *lenptr = spsig;
  return psigo;
}


unsigned piobjc_type_size(char** type_encoding)
{
	int result=-1;
	*type_encoding=(char*)NSGetSizeAndAlignment(*type_encoding,(unsigned*)&result,NULL);
	return result;
}

// this is one of two functions that generate pike signature strings.
char * pike_signature_from_objc_signature(struct objc_method * nssig, int * lenptr)
{
  char * rettype;
  char * argtype;
  char * psig;
  int spsig;
  int argcount;
  int offset;
  char * type;
  int sret;
  int x;
  int i;
  int sargs;
  int cpos;
  int now;
  char * psigo;
  
  argcount = method_getNumberOfArguments(nssig);

  // ok, let's do return type first.

//  printf("TYPE: %s\n", nssig->method_types);

  type = nssig->method_types;

  while((*type)&&(*type=='r' || *type =='n' || *type =='N' || *type=='o' || *type=='O' || *type =='V'))
                type++;

    switch(*type)
    {
      case 'c': // char
        rettype = tInt;
        sret = CONSTANT_STRLEN(tInt);
//      printf("c\n");
        break;

      case 'i': // int
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("i\n");
        break;

      case 's': // short
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("s\n");
        break;

      case 'l': // long
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
      //    printf("l\n");
        break;

      case 'q': // long long
        rettype = tInt;
        sret = CONSTANT_STRLEN(tInt);
//        printf("q\n");
        break;

      case 'C': // unsigned char
        rettype = tInt;
        sret = CONSTANT_STRLEN(tInt);
//        printf("I\n");
        break;

      case 'I': // unsigned int
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("I\n");
        break;

      case 'S': // unsigned short
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("S\n");
        break;

      case 'L': // unsigned long
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("L\n");
        break;

      case 'Q': // unsigned long long
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("Q\n");
        break;

      case 'f': // float
        rettype = tFloat;
      sret = CONSTANT_STRLEN(tFloat);
//      printf("f\n");
        break;

      case 'd': // double
        rettype = tFloat;
      sret = CONSTANT_STRLEN(tFloat);
//      printf("d\n");
        break;

      case 'B': // bool
        rettype = tInt;
      sret = CONSTANT_STRLEN(tInt);
//      printf("B\n");
        break;

      case 'v': // void
        rettype = tVoid;
      sret = CONSTANT_STRLEN(tVoid);
//      printf("v\n");
        break;

      case '*': // char *
        rettype = tStr;
      sret = CONSTANT_STRLEN(tStr);
//      printf("*\n");
        break;

      case '@': // object
        rettype = tObj;
      sret = CONSTANT_STRLEN(tObj);
//      printf("@\n");
        break;

      case '#': // class
        rettype = tPrg(tObj);
      sret = CONSTANT_STRLEN(tPrg(tObj));
//      printf("#\n");
        break;

      case ':': // SEL
        rettype = tString;
      sret = CONSTANT_STRLEN(tString);
//      printf(":\n");
        break;

      case '[': // array
        rettype = tArr(tMix);
      sret = CONSTANT_STRLEN(tArr(tMix));
//      printf("[\n");
        break;

      case '{': // struct
        rettype = tObj;
      sret = CONSTANT_STRLEN(tObj);
//      printf("{\n");
        break;

      case '(': // union
        rettype = tObj;
      sret = CONSTANT_STRLEN(tObj);
//      printf("(\n");
        break;

      case 'b':  // bit field
        rettype = tInt;
      sret = CONSTANT_STRLEN(tObj);
//      printf("b\n");
        break;

      case '^':  // pointer
        rettype = tObj;
      sret = CONSTANT_STRLEN(tObj);
//      printf("^\n");
        break;

      case '?':  // unknown (function ptr)
        rettype = tObj;
      sret = CONSTANT_STRLEN(tObj);
      printf("?\n");
        break;
      default:
        printf("SIGNATURE: %s\n", type);
    }

  for (x = 2; x < argcount; x++)
  {
    method_getArgumentInfo(nssig, x, (const char **)&type, &offset);

    while((*type)&&(*type=='r' || *type =='n' || *type =='N' || *type=='o' || *type=='O' || *type =='V'))
                type++;

    switch(*type)
    {
      case 'c': // char
//      printf("c\n");
        break;

      case 'i': // int
//        printf("i\n");
        break;

      case 's': // short
//        printf("s\n");
        break;

      case 'l': // long
//        printf("l\n");
        break;

      case 'q': // long long
//        printf("q\n");
        break;

        case 'C': // unsigned char
//           printf("C\n");
           break;
           
        case 'I': // unsigned int
//         printf("I\n");
         break;

 
       case 'S': // unsigned short
//        printf("S\n");
        break;

      case 'L': // unsigned long
//        printf("L\n");
        break;

      case 'Q': // unsigned long long
//        printf("Q\n");
        break;

      case 'f': // float
//        printf("f\n");
        break;

      case 'd': // double
//        printf("d\n");
        break;

      case 'B': // bool
//        printf("B\n");
        break;

      case 'v': // void
//        printf("v\n");
        break;

      case '*': // char *
//        printf("*\n");
        break;

      case '@': // object
//        printf("@\n");
        break;

      case '#': // class
//        printf("#\n");
        break;

      case ':': // SEL
//        printf(":\n");
        break;

      case '[': // array
//        printf("[\n");
        break;

      case '{': // struct
//        printf("{\n");
        break;

      case '(': // union
//        printf("(\n");
        break;

      case 'b':  // bit field
//        printf("b\n");
        break;

      case '^':  // pointer
//        printf("^\n");
        break;

      case '?':  // unknown (function ptr)
        printf("c?\n");
        break;
    }


  }

  spsig = CONSTANT_STRLEN("\004\021\020") + (CONSTANT_STRLEN(tMix)*(argcount-2)) + sret;
//printf("allocated %d bytes for signature.\n", spsig);
  psig = malloc(spsig);
  psigo = psig;
  now = 0;

  psig[now++] = '\004';

  for(i = 0; i < (argcount-2); i++)
    psig[now++] = '\373';


  psig[now++] = '\021';
  psig[now++] = '\020';
  
  for(cpos = 0; cpos < sret; cpos++)
  {
    psig[now++] = rettype[cpos];
  }

  *lenptr = spsig;
  return psigo;
}
