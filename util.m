#import "piobjc.h"
#import <Foundation/NSInvocation.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSString.h>
#import "PiObjCObject.h"
#import "ObjC.h"
/*
 *  util.c: helper functions and objects.
 *
 *
 */

/* this code is from pyobjc-1.4. */

 static struct pike_type *a_markers[10], *b_markers[10];


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
  THREADS_ALLOW();
  objc_msgSendv(obj,select,method_getSizeOfArguments(method),argumentList);
  THREADS_DISALLOW();
}

struct object * object_dispatch_method(id obj, SEL select, struct objc_method * method, marg_list argumentList)
{
  struct object * o;
  id r;
  
  THREADS_ALLOW();
  r = objc_msgSendv(obj,select,method_getSizeOfArguments(method),argumentList);
  THREADS_DISALLOW();
  
  if([r isKindOfClass: [PiObjCObject class]] == YES)
	{
	  o = [r getPikeObject];
	}
	else
	{
    if([r isKindOfClass: [NSString class]])
    {
      printf("String Value: %s", [r UTF8String]);
    }
    o = wrap_objc_object(r);
    if(!o) { printf("AAAH! no object to push...\n");}
	}
	if(! [(id)r isKindOfClass: [NSAutoreleasePool class]])
  	r = [(id)r retain];

  return o;
}

id unwrap_objc_object(struct object * o)
{
  struct objc_dynamic_class * s = get_storage(o, o->prog);

  /* TODO: we need to be a little more careful here. what if the pike object doesn't have an objc object? */
  if(!s) return nil;
  
  else return s->obj;
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

struct object * wrap_objc_object(id r)
{
  struct object * o;
  struct program * prog;
  struct objc_dynamic_class * pc; 
  struct pike_string * ps;
  if(!r) {printf("wrap_objc_object: no object!\n"); return NULL; }
  if(!r->isa) printf("wrap_objc_object: no class!\n");
  ps = make_shared_string(r->isa->name);
  prog = pike_create_objc_dynamic_class(ps);
	o = clone_object(prog, 0);
	pc = OBJ2_DYNAMIC_OBJECT(o);
	pc->obj = (id)r;

  // we need to retain the object, because the dynamic_class object 
  // will free it when the object is destroyed.
	[r retain];

	pc->is_instance = 1;

  return o;
}

int push_objc_types(NSMethodSignature* sig, NSInvocation* invocation)
{
	char * type = NULL;
    void * buf = NULL;
	int arg = 0;
	id cobj = NULL;
	struct object * pobj = NULL;
	int args_pushed = 0;
 	// args 0 and 1 are the object and the method, respectively.

	for(arg = 2; arg < [sig numberOfArguments];arg++)
    {
	  // now, we push the argth argument onto the stack.
	  type = (char*)[sig getArgumentTypeAtIndex: arg];
      while((*type)&&(*type=='r' || *type =='n' || *type =='N' || *type=='o' || *type=='O' || *type =='V'))
		type++;

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
           if(cobj->isa == [PiObjCObject class])
           {
	         printf("got a pike object as argument!\n");
             pobj = [cobj getPikeObject];
           }
           else
            pobj = wrap_objc_object(cobj);
            if(!pobj) { printf("AAAAAH! no object to push!\n");}
		        args_pushed++;
            push_object(pobj);
//           free(buf);
	       break;
	     case '#':
	       // int
	       buf = (Class)malloc(sizeof(Class));
           if(buf == NULL)
             Pike_error("unable to allocate memory.\n");
           [invocation getArgument: &buf atIndex: arg];
           pobj = wrap_objc_object((Class)buf);
if(!pobj){printf("AAAAAH! No object to push.\n");}
		   args_pushed++;
           push_object(pobj);
//           free(buf);
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
	type = [sig methodReturnType];
    while((*type)&&(*type=='r' || *type =='n' || *type =='N' || *type=='o' || *type=='O' || *type =='V'))
	  type++;
   printf("return value type is %s -> %d\n", type, svalue->subtype);
   printf("arg 0 type is %s\n", [sig getArgumentTypeAtIndex: 2]);

  //  printf("returned value type is %d\n", svalue->type);
    switch(*type)
    {
	  // id
    case 'i':
      if(svalue->type == T_INT)
      {
        [invocation setReturnValue: &svalue->u.integer];    
      }
      else
      {
        printf("AAAARG! not an integer returned from function!\n");
      }
      break;
	  case '@':
	      if(svalue->type == T_INT)
	      {
          id num;
           printf("Sending an integer.\n");           
//          num = [NSNumber numberWithLong: svalue->u.integer];
//          [invocation setReturnValue: num]; 
           [invocation setReturnValue: &svalue->u.integer];
	      }
	      else if(svalue->type == T_STRING) // we need to wrap the value as a string.
	      {
            // let's wrap the string as an NSString object.
            id str;
            NSStringEncoding enc;
            enc =  NSUTF8StringEncoding;
            push_svalue(svalue);
            f_string_to_utf8(1);
            svalue = &Pike_sp[-1];
            str = [[NSString alloc] initWithBytes: svalue->u.string->str length: svalue->u.string->len encoding: enc];
            [str autorelease];
            pop_stack();
            [invocation setReturnValue: str];
	        
	      }
	      else if(svalue->type == T_OBJECT)
        {
          o = svalue->u.object;
		    printf("Whee! We're wrappin' an object for a return value!\n");
		    // if we don't have a wrapped object, we should make a pike object wrapper.
		        wrapper = [PiObjCObject newWithPikeObject: o];
		        wrapper = [wrapper retain];
		  	    [invocation setReturnValue: wrapper];		    
/*          else 
          {
	         id res;
	         res = unwrap_objc_object(svalue->u.object);
	         [invocation setReturnValue: &res];
          }
          */
        }
        else
          Pike_error("expected object return value.\n");
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
  
  push_text( "Public.ObjectiveC.get_signature_for_func"); 
  SAFE_APPLY_MASTER("resolv", 1 );
   
  numargs = get_argcount_by_selector(selector);

  push_svalue(func);
  push_int(numargs);
  // arg is at top, function is 1 down from the top 
  apply_svalue( Pike_sp-3, 2 );

  // result is at top of the stack, function is still one down 
  // and we want to pop it. 
  stack_swap(); 
  pop_stack();

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
  struct svalue * sv;

  
  funlen = strlen((char *)aSelector);

  funname = malloc(funlen);

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


  push_object(pobject);

  // do we need to do this?
  add_ref(pobject);
  push_text(funname);

  f_index(2);

  free(funname);

  if(Pike_sp[-1].type != PIKE_T_FUNCTION) // jackpot!
   return 0;
  sv = (struct svalue *) malloc(sizeof(struct svalue));
  assign_svalue(sv, &Pike_sp[-1]);
  return sv;
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
                        if(aSelector == methodList->method_list[index].method_name) return YES;
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
    method_getArgumentInfo(nssig, x, &type, &offset);

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
