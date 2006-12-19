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

 static struct pike_type *a_markers[10], *b_markers[10];
 static struct svalue get_signature_for_func_sval;
 static int got_signature_for_func_func = 0;

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
//printf("hello from another thread.\n");
  
}

@end

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
  
	if(! [(id)r isKindOfClass: [NSAutoreleasePool class]])
    	r = [(id)r retain];

  return o;
}

struct svalue * low_id_to_svalue(id obj, int prefer_native)
{
	struct svalue * sv;
	struct object * o;
	
	sv = malloc(sizeof(struct svalue));
	
	// TODO: this method very likely has flaws.
	if(prefer_native)
	{
		if([obj respondsToSelector: SELUID("characterAtIndex:")])
		{
			NSStringEncoding enc;		  
			struct pike_string * str;
			
		    enc =  NSUTF8StringEncoding;
		  
			printf("got a string to convert.\n");
			str = make_shared_binary_string([obj UTF8String], [obj lengthOfBytesUsingEncoding: enc]);

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
        add_ref(a);
		sv->type = T_ARRAY;
		sv->subtype = 0;
		sv->u.array = a;
	}

	else if([obj respondsToSelector: SELUID("__ObjCgetPikeMapping")])
	{
		struct mapping * m;
		
		m = [obj __ObjCgetPikeMapping];
        add_ref(m);
		sv->type = T_MAPPING;
		sv->subtype = 0;
		sv->u.mapping = m;
	}

	o = wrap_objc_object(obj);

    if(o)
    {
	    add_ref(o);
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
			  add_ref(sv->u.string);
			  add_ref(sv->u.string);
			  f_string_to_utf8(1);
			  sv = &Pike_sp[-1];
			  rv = [[NSString alloc] initWithBytes: sv->u.string->str length: sv->u.string->len encoding: enc];
			  [rv autorelease];
			  pop_stack();
			}		
			
			break;

		case T_ARRAY:
			add_ref(sv->u.array);
			rv = [OC_Array newWithPikeArray: sv->u.array];
			[rv autorelease];
		
			break;
			
		case T_MAPPING:
			add_ref(sv->u.mapping);
			rv = [OC_Mapping newWithPikeMapping: sv->u.mapping];
			[rv autorelease];
		
			break;
		
		case T_OBJECT:
	    	{
		  		struct object * o;
		  		add_ref(sv->u.object);
		  		o = sv->u.object;
		  		rv = unwrap_objc_object(o);
		  		if(!rv)
		  		{
		    		printf("Whee! We're wrappin' an object for a return value!\n");
		    	// if we don't have a wrapped object, we should make a pike object wrapper.
		    		rv = [PiObjCObject newWithPikeObject: o];
		  		}
			}
			break;
			
		default:
			printf("SV TYPE: %d\n", sv->type);
		  Pike_error("expected object return value.\n");		
	}

	printf("returning from svalue_to_id()\n");
	return rv;	
}

// ok, here's the algorithm we should use for unwrapping
//
// if the top level program does not have c methods, we know it's a pike object, and there's nothing to unwrap.
// if the program does have c methods, we check to see if we've added the program as a dynamic class. if so, we can unwrap
// otherwise, we can't unwrap (such as for someone passing an image object).
id unwrap_objc_object(struct object * o)
{
	int is_objcobj = 0;
	if(o->prog->flags & !PROGRAM_HAS_C_METHODS)
	{
		printf("unwrap_objc_object(): can't unwrap a pure pike object.\n");
		return 0;
	}
    else
	{
		is_objcobj = find_dynamic_program_in_cache(o->prog);
		if(is_objcobj)
		{
		  struct objc_dynamic_class * s = (struct objc_dynamic_class *)get_storage(o, o->prog);
		  if(!s) { printf("unwrap_objc_object(): couldn't get storage!\n"); return nil; }
		  else { printf("unwrap_objc_object(): got the id!\n"); return s->obj; }
		}
		else
		{
			printf("unwrap_objc_object(): didn't find an objc class for the object\n");
		}
		return 0;
	}

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
  
  return select;
}

struct svalue * ptr_to_svalue(void * ptr, char * type)
{
	struct svalue * sv;
	
	sv = malloc(sizeof(struct svalue));
	
	switch(*type)
	{
		case '@':
			sv->type = T_OBJECT;
			sv->subtype = 0;
			sv->u.object = wrap_objc_object((id)ptr);
			break;

		default:
			printf("whee! %s\n", type);
	}
	
	return sv;
}

struct object * wrap_objc_object(id r)
{
  struct object * o;
  struct program * prog;
  struct objc_dynamic_class * pc; 
  struct pike_string * ps;
  if(!r) {printf("wrap_objc_object: no object!\n"); return NULL; }
  if(!r->isa) printf("wrap_objc_object: no class!\n");
  
  /* TODO: Do we need to make these methods in PiObjCObject hidden? */
  if([r respondsToSelector: SELUID("__ObjCgetPikeObject")])
  {
	o = [r __ObjCgetPikeObject];
  }
  else 
  {
    ps = make_shared_string(r->isa->name);
    prog = pike_create_objc_dynamic_class(ps);
    if(!prog) return NULL;
    o = clone_object(prog, 0);
    pc = OBJ2_DYNAMIC_OBJECT(o);
    pc->obj = (id)r;

  // we need to retain the object, because the dynamic_class object 
  // will free it when the object is destroyed.
    [r retain];

    pc->is_instance = 1;
  }

  return o;
}

struct program * wrap_objc_class(Class r)
{
  struct program * prog;
  struct objc_dynamic_class * pc; 
  struct pike_string * ps;
  if(!r) {printf("wrap_objc_class: no object!\n"); return NULL; }
  if(!r->isa) printf("wrap_objc_class: no class!\n");

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
           sval = id_to_svalue(cobj);
		        args_pushed++;
            push_svalue(sval);
//           free(buf);
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
    case 'i':
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
      // class
      case '#':
//        break;
      // selector 
      case 'v': 
        // void return value!
        break;
      case ':':
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

  printf("get_func_by_selector: %s\n", funname);

  // do we need to do this?
  push_text(funname);

  object_index_no_free(sv2, pobject, Pike_sp-1);
  pop_stack();
  free(funname);

  if(sv2->type == PIKE_T_FUNCTION) // jackpot!
  {
    if(!sv2->u.efun) { printf("no fun!\n");}
    else
	    return sv2;
//    printf("Pike_sp[-1]: <%p> <%D>\n", Pike_sp[-1], &Pike_sp[-1]);
//    printf("**> fun refs: %d\n\n", Pike_sp[-1].u.efun->refs); 
  }

  free_svalue(sv2);
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
      printf("^\n");
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

  spsig = CONSTANT_STRLEN("\004\021\020" tMix) + sret;
//printf("allocated %d bytes for signature.\n", spsig);
  psig = malloc(spsig);
  psigo = psig;
  now = 0;
  psig[now++] = '\004';
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


void foo(char * type)
{
    switch(*type)
    {
      case 'c': // char
        break;

      case 'i': // int
        break;

      case 's': // short
        break;

      case 'l': // long
        break;

      case 'q': // long long
        break;

      case 'C': // unsigned char
        break;

      case 'I': // unsigned int
        break;

      case 'S': // unsigned short
        break;

      case 'L': // unsigned long
        break;

      case 'Q': // unsigned long long
        break;

      case 'f': // float
        break;

      case 'd': // double
        break;

      case 'B': // bool
        break;

      case 'v': // void
        break;

      case '*': // char *
        break;

      case '@': // object
        break;

      case '#': // class
        break;

      case ':': // SEL
        break;

      case '[': // array
        break;

      case '{': // struct
        break;

      case '(': // union
        break;

      case 'b':  // bit field
        break;

      case '^':  // pointer
        break;

      case '?':  // unknown (function ptr)
        break;
    }

}
