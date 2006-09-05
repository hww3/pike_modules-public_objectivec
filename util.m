#include "piobjc.h"
#import <Foundation/NSInvocation.h>
#import <Foundation/NSMethodSignature.h>
#import "PiObjCObject.h"

/*
 *  util.c: helper functions
 *
 *
 */

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
	
	for(arg = 0; arg < [sig numberOfArguments];arg++)
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
           if([cobj isMemberOfClass: [PiObjCObject class]])
             pobj = [cobj getPikeObject];
           else
             pobj = new_nsobject_object((id)buf);
		   args_pushed++;
           push_object(pobj);
           free(buf);
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
           free(buf);
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

struct callable * get_func_by_selector(struct object * pobject, SEL aSelector)
{
  char * funname;
  int funlen;
  int ind;
  int argcount;

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

  if(Pike_sp[-1].type == PIKE_T_FUNCTION) // jackpot!
    return Pike_sp[-1].u.efun;
  else return 0;
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