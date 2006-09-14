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
  
    if([r isKindOfClass: [NSString class]] == YES)

	{
	  struct NSObject_struct * d;
  		o = NEW_NSSTRING();
  		d = (struct NSObject_struct *) get_storage(o, NSObject_program);
  		if(d == NULL)
     		Pike_error("Object is not an NSObject!\n");
  		d->object_data->object = (id)r;
  		r = [(id)r retain];
	}
	else
	{
  		o = NEW_NSOBJECT();
  		OBJ2_NSOBJECT(o)->object_data->object = (id)r;
	}
	if(! [(id)r isKindOfClass: [NSAutoreleasePool class]])
  	r = [(id)r retain];

  return o;
}

id get_NSObject()
{
  struct object * o;
  struct NSObject_struct * d;

  o = Pike_fp->current_object;

  d = (struct NSObject_struct *) get_storage(o, NSObject_program);
  if(d == NULL)
  Pike_error("Object is not an NSObject!\n");

  return d->object_data->object;

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
printf("push_objc_types\n");

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
             pobj = new_nsobject_object(cobj);
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
           pobj = new_nsobject_object((Class)buf);
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

int get_argcount_by_selector(struct object * pobject, SEL aSelector)
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
//printf("piobjc_set_return_value()\n");
 	  // now, we push the argth argument onto the stack.
	type = [sig methodReturnType];
    while((*type)&&(*type=='r' || *type =='n' || *type =='N' || *type=='o' || *type=='O' || *type =='V'))
	  type++;
  //  printf("return value type is %s\n", type);
  //  printf("returned value type is %d\n", svalue->type);
    switch(*type)
    {
	  // id
	  case '@':
	      if(svalue->type == T_INT)
	      {

            id num;
            
            num = [NSNumber newWithLong: svalue->u.integer];
            [invocation setReturnValue: &num];
	        
	      }
	      if(svalue->type == T_STRING) // we need to wrap the value as a string.
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
            [invocation setReturnValue: &str];
	        
	      }
	      else if(svalue->type == T_OBJECT)
        {
          o = svalue->u.object;
          if(!get_storage(o, NSObject_program))
          {
//		    printf("Whee! We're wrappin' an object for a return value!\n");
		    // if we don't have a wrapped object, we should make a pike object wrapper.
		        wrapper = [PiObjCObject newWithPikeObject: o];
		        wrapper = [wrapper retain];
		  	    [invocation setReturnValue: wrapper];		    
          }
          else 
          {
	         id res;
	         res = get_NSObject_from_Object(svalue->u.object);
	         [invocation setReturnValue: &res];
          }
        }
        else
          Pike_error("expected object return value.\n");
  	    break;
      // class
      case '#':
        break;
      // selector 
      case ':':
        break;
 	}
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

id get_NSObject_from_Object(struct object *o)
{
  struct NSObject_struct * d;
 
  d = (struct NSObject_struct *) get_storage(o, NSObject_program);
  if(d == NULL)
   return NULL;

  return d->object_data->object;

}

struct object * new_nsobject_object(id obj)
{
  struct object * nobject;

  [ obj retain ];
  printf("OBJECT: %s\n", obj->isa->name);
  if(strcmp("NSString", obj->isa->name) == 0)
  {
    struct NSObject_struct * d;

    nobject = NEW_NSSTRING();
    d = (struct NSObject_struct *) get_storage(nobject, NSObject_program);
    if(d == NULL)
      Pike_error("Object is not an NSObject!\n");
    d->object_data->object = obj;
  }
  else
  {
    nobject = NEW_NSOBJECT();
    OBJ2_NSOBJECT(nobject)->object_data->object = obj;
  }

  return nobject;
}

int is_nsobject_initialized()
{
struct object * o;
struct NSObject_struct * d;

o = Pike_fp->current_object;

d = (struct NSObject_struct *) get_storage(o, NSObject_program);  
if(d == NULL)
  Pike_error("Object is not an NSObject!\n");

  if(d->object_data->object == NULL)
    return 0;
  else return 1;
}
