
#import <Foundation/NSString.h>
#import "PiObjCObject.h"
#include "piobjc.h"
#undef THIS
#define THIS ((struct objc_dynamic_class *)(Pike_interpreter.frame_pointer->current_storage))
#define OBJ2_OBJC_OBJECT_HOLDER(o) ((struct objc_object_holder_struct *)get_storage(o, objc_object_holder_program))
#define THIS_OBJC ((struct _struct *)(Pike_interpreter.frame_pointer->current_storage))

extern id global_autorelease_pool;
extern struct mapping * global_class_cache;
extern struct mapping * global_classname_cache;

void f_objc_dynamic_create(INT32 args)
{
  Class cls;
  id obj;
  char * classname;
printf("dynamic_create()\n");
  if(args!=0)
  {
    Pike_error("too many arguments to create()\n");
    return;
  }

  cls = OBJ2_OBJC_OBJECT_HOLDER(Pike_fp->current_object->prog->constants[0].sval.u.object)->class;
  
  if(cls == nil)
  {
    Pike_error("unable to get class.\n");
    return;
  }  

  /* TODO: we have to figure out how to deal with objects that are created outside of pike, then returned
           for wrapping. In this case, we don't free up the alloced object, and have other odd behavior. */

  THIS->obj = [cls alloc];
  THIS->is_instance = 1;
  [cls retain];
}

void f_objc_dynamic_instance_method(INT32 args)
{
  struct pike_string * name;
  struct program * prog;
  id obj;
  struct svalue sval;
  struct objc_object_holder_struct * pobj;
  SEL select;
  
  name = ID_FROM_INT(Pike_fp->current_object->prog, Pike_fp->fun)->name;
  prog = Pike_fp->current_object->prog;
  obj = THIS->obj;        

  select = selector_from_pikename(name);

  f_call_objc_method(args, 1, select, obj);
}

f_call_objc_method(INT32 args, int is_instance, SEL select, id obj)
{
    struct objc_method * method;
    int arguments, x;
    id wrapper;
    void * result;
    marg_list argumentList = NULL;
    int argumentOffset=0;
    char * type = NULL;
    struct NSObject_struct * d;
    id pool;
    int ind;

    pool = [global_autorelease_pool getAutoreleasePool];
    
    printf("select: %s, is_instance: %d\n", (char *) select, is_instance);
    if(is_instance)
      method = class_getInstanceMethod(obj->isa, select);
    else
      method = class_getClassMethod(obj, select);
    
    if(!method) 
    {
      Pike_error("unable to find the method.\n");
    }
    printf("%s`()\n", (char * ) select);
    arguments = method_getNumberOfArguments(method);

    if((args) != (arguments-2))
      Pike_error("incorrect number of arguments to method provided.\n");
   

    marg_malloc(argumentList,method);
    if(!argumentList)
      Pike_error("Insufficient memory (Could not allocate method argument buffer).");

    // arguments 0 and 1 are the object to receive the message and the selector, respectively.
    for(x = 2; x < arguments; x++)
    {
      int offset;
      struct svalue * sv;
      sv = Pike_sp-args+(x-2);

      method_getArgumentInfo(method, x, (const char **)(&type), &offset);
printf("argument %d %s\n", x, type);
      while((*type)&&(*type=='r' || *type =='n' || *type =='N' || *type=='o' || *type=='O' || *type =='V'))
  		type++;

      switch(*type)
      {
        case 'c': 
           if(sv->type!=T_INT)
             Pike_error("Type mismatch for method argument.");
           marg_setValue(argumentList,offset,char, (char)sv->u.integer);
  	 break;

        case 'C': 
           if(sv->type!=T_INT)
             Pike_error("Type mismatch for method argument.");
           marg_setValue(argumentList,offset, int, (int)sv->u.integer);
  	 break;

        case 'd':
           if(sv->type!=T_FLOAT)
             Pike_error("Type mismatch for method argument.");
           marg_setValue(argumentList,offset,double , (double)sv->u.float_number);
  	 break;

        case 'f':
           if(sv->type!=T_FLOAT)
             Pike_error("Type mismatch for method argument.");
           marg_setValue(argumentList,offset,float , (float)sv->u.float_number);
  	 break;

        case 'i': 
           if(sv->type!=T_INT)
             Pike_error("Type mismatch for method argument.");
           marg_setValue(argumentList,offset,int, sv->u.integer);
  	 break;

        case 'I': 
           if(sv->type!=T_INT)
             Pike_error("Type mismatch for method argument.");
           marg_setValue(argumentList,offset,unsigned int, sv->u.integer);
  	 break;

        case 'l':
           if(sv->type!=T_INT)
             Pike_error("Type mismatch for method argument.");
           marg_setValue(argumentList,offset,long , (long)sv->u.integer);
  	 break;

        case 'L':
           if(sv->type!=T_INT)
             Pike_error("Type mismatch for method argument.");
           marg_setValue(argumentList,offset,unsigned long , (unsigned long)sv->u.integer);
  	 break;

        case 'q':
           if(sv->type!=T_INT)
             Pike_error("Type mismatch for method argument.");
           marg_setValue(argumentList,offset,long long , (long long)sv->u.integer);
  	 break;

        case 'Q':
           if(sv->type!=T_INT)
             Pike_error("Type mismatch for method argument.");
           marg_setValue(argumentList,offset,unsigned long long , (unsigned long long)sv->u.integer);
  	 break;

        case 's':
           if(sv->type!=T_INT)
             Pike_error("Type mismatch for method argument.");
           marg_setValue(argumentList,offset,short , (short)sv->u.integer);
  	 break;

        case 'S':
           if(sv->type!=T_INT)
             Pike_error("Type mismatch for method argument.");
           marg_setValue(argumentList,offset,unsigned short , (unsigned short)sv->u.integer);
  	 break;

        case '*': 
           if(sv->type!=T_STRING)
             Pike_error("Type mismatch for method argument..");
           marg_setValue(argumentList,offset,char *, sv->u.string->str);
  	 break;
  	      case ':':
  	//Pike_error("unable to support type :\n");
  	           marg_setValue(argumentList,offset,SEL , sel_registerName(sv->u.string->str));
  	         break;

        case '@': 
 			/* TODO: we should check to see if the object is a Pike level object, or just a wrapper around an NSObject. */
           if(sv->type==T_OBJECT)
           {
             struct object * o = sv->u.object;
  			 // if we don't have a wrapped object, we should make a pike object wrapper.
  			 wrapper = [PiObjCObject newWithPikeObject: o];
             marg_setValue(argumentList, offset, id, wrapper);
push_text("%O\n");
push_object(o);
f_werror(2);
  		   }
           else if(sv->type == T_INT)
           {
              // let's wrap the string as an NSString object.
              id num;
			  if(sizeof(INT_TYPE) == sizeof(long))
                num = [NSNumber numberWithLong: sv->u.integer];
			  else if(sizeof(INT_TYPE) == sizeof(long long))
                num = [NSNumber numberWithLongLong: sv->u.integer];

              marg_setValue(argumentList,offset,id, num);
           }

           else if(sv->type == T_STRING)
           {
              // let's wrap the string as an NSString object.
              id str;
              NSStringEncoding enc;
              enc =  NSUTF8StringEncoding;
              push_svalue(sv);
              f_string_to_utf8(1);
              sv = &Pike_sp[-1];
              str = [[NSString alloc] stringWithBytes: sv->u.string->str length: sv->u.string->len encoding: enc];
              pop_stack();
              marg_setValue(argumentList,offset,id, str);
           }
  		 else
  		    Pike_error("Type mismatch for method argument..");

  	 break;

  /* TODO: How should we support these? */
        case '#':
  Pike_error("unable to support type #\n");
  //           marg_setValue(argumentList,offset,Class , OBJ2_NSOBJECT(o)->object_data->object);
           break;


        case '^':
  Pike_error("unable to support type ^\n");
  //           marg_setValue(argumentList,offset,void , OBJ2_NSOBJECT(o)->object_data->object);
           break;
        case '[':
        case '{':
        case '(':
        case 'b':
        case 'v':
        default:
           Pike_error("unsupported argument type.\n");

        }
     }

    type = method->method_types;

    while((*type)&&(*type=='r' || *type =='n' || *type =='N' || *type=='o' || *type=='O' || *type =='V'))
  		type++;

    printf("RETURN TYPE: %s\n", type);
   

    @try
    {

    switch(*type){
      case 'c':
  	  THREADS_ALLOW();
        result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
  	 *(INT_TYPE *)result = (INT_TYPE)((pike_objc_unsigned_char_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
        break;

      case 'C':
  	  THREADS_ALLOW();
       result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
  	 *(INT_TYPE *)result =     (INT_TYPE)((pike_objc_unsigned_char_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
        break;

      case 'i':
  	  THREADS_ALLOW();
      result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
  	 *(INT_TYPE *)result =      (INT_TYPE)((pike_objc_int_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
        break;
      // TODO: fix the casting... should we support auto objectize for bignums?

      case 'l':
  	  THREADS_ALLOW();
      result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
  	 *(INT_TYPE *)result =     (INT_TYPE)((pike_objc_long_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
        break;

      case 'L':
  	  THREADS_ALLOW();
      result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
  	 *(INT_TYPE *)result = (INT_TYPE)((pike_objc_unsigned_long_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
        break;

      case 'I':
  	  THREADS_ALLOW();
        result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
        *(INT_TYPE *)result = (INT_TYPE)((pike_objc_unsigned_int_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
        break;

      case 'd':
  	  THREADS_ALLOW();
      result = (FLOAT_TYPE *) malloc(sizeof(FLOAT_TYPE)); 
      *(FLOAT_TYPE *)result = (FLOAT_TYPE)((pike_objc_double_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
        push_float(*(FLOAT_TYPE *)result);
        break;

      case 'f':
  	  THREADS_ALLOW();
        result = (FLOAT_TYPE *) malloc(sizeof(FLOAT_TYPE)); 
        *(FLOAT_TYPE *)result =  (FLOAT_TYPE)((pike_objc_float_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
        push_float(*(FLOAT_TYPE *)result);
        break;

      case 'q':
  	  THREADS_ALLOW();
        result = (FLOAT_TYPE *) malloc(sizeof(FLOAT_TYPE)); 
        *(FLOAT_TYPE *)result = (FLOAT_TYPE)((pike_objc_long_long_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
        push_float(*(FLOAT_TYPE *)result);
        break;

      case 'Q':
  	  THREADS_ALLOW();
        result = (FLOAT_TYPE *) malloc(sizeof(FLOAT_TYPE)); 
        *(FLOAT_TYPE *)result =     (FLOAT_TYPE)((pike_objc_unsigned_long_long_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
        push_float(*(FLOAT_TYPE *)result);
        break;

      case 's':
  	  THREADS_ALLOW();
        result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
        *(INT_TYPE *)result =     (INT_TYPE)((pike_objc_short_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
        break;

      case 'S':
  	  THREADS_ALLOW();
        result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
        *(INT_TYPE *)result =     (INT_TYPE)((pike_objc_unsigned_short_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
        break;

      case 'v':
      printf("SEL: %s\n", (char *)select);
        void_dispatch_method(obj,select,method,argumentList);
        push_int(0);
        break;

      case '*':
  	  THREADS_ALLOW();
        result = (char *) malloc(sizeof(char *)); 
        result = (char *)objc_msgSendv(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
        push_text(result);
        break;
      case '@':
        {
          struct object * o;
          id r;

  	  	o = object_dispatch_method(obj, select, method, argumentList);
        if(o)
		{
			printf("pushing an object as return value.\n");
        	push_object(o);
		}
  		}
        break;
      case '#':
        {
          struct object * o;
          Class c;
  THREADS_ALLOW();
          c = objc_msgSendv(obj,select,method_getSizeOfArguments(method),argumentList);
  THREADS_DISALLOW();
  
  /* TODO! This isn't completely compatible with dynamic classes being worked on now. */
/*          o = NEW_NSCLASS();
          OBJ2_NSCLASS(o)->object_data->class = (id)c;
          c = [(id)c retain];
          push_object(o);
          */
        }
        break;
      case 'b':
        Pike_error("Invalid return type for method.");
      case '?':
        Pike_error("Unknown return type for method.");
      case '[':
      case '{':
      case '(':{
        char* temp=method->method_types;
        result=xmalloc(pike_objc_type_size(&temp));
  	  THREADS_ALLOW();
        objc_msgSendv_stret(result,obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
  // TODO: do something with the result!
        break;
      }
    }
    [pool release];
    stack_pop_n_elems_keep_top(args);

    }
    @catch (NSException * e)
    {

      pop_n_elems(args);
      Pike_error("%s: %s\n", [(NSString *)[e name] UTF8String], [(NSString *)[e reason] UTF8String]);
    }

    if(argumentList) 
      marg_free(argumentList);


}

void f_objc_dynamic_class_sprintf(INT32 args)
{
    char * desc;
    int hash;
	if(THIS->obj && THIS->obj->isa)
      desc = malloc(strlen(THIS->obj->isa->name) + strlen("()") + 15);
    else 
	{
		pop_n_elems(args);
		push_text("GAH!()");
		return;
	}
	
    if(desc == NULL)
      Pike_error("unable to allocate string.\n");

    pop_n_elems(args);
   
@try{
// hash = [THIS->obj hash];
  }
  @catch (NSException * e)
  {
  }
  
    sprintf(desc, "%s(%u)", THIS->obj->isa->name, hash);


    push_text(desc);
    free(desc);

}

void objc_dynamic_class_init()
{
   THIS->obj = NULL;
}

void objc_dynamic_class_exit()
{
 if(THIS->obj) [THIS->obj release];
}

int find_dynamic_program_in_cache(struct program * prog)
{
  struct svalue * c = NULL;
  push_program(prog);
  c = low_mapping_lookup(global_classname_cache, Pike_sp-1);	
  pop_stack();

  if(c != NULL) return 1;
  else return 0;
}

struct program * pike_create_objc_dynamic_class(struct pike_string * classname)
{
  struct svalue * c = NULL;
  struct program * p;
  
  /* first, we look up the requested name to see if it's been cached. */
  c = low_mapping_string_lookup(global_class_cache, classname);

  if(c == NULL)
  {
    p = pike_low_create_objc_dynamic_class(classname->str);
    if(!p) return 0;
    push_program(p);
    //add_ref(classname);
    mapping_string_insert(global_class_cache, classname, Pike_sp-1);
    push_string(classname);
    low_mapping_insert(global_classname_cache, Pike_sp-2, Pike_sp-1, 1);
    pop_stack();
    pop_stack();
    return p;
  }
  else 
    return c->u.program;  
}

struct program * pike_low_create_objc_dynamic_class(char * classname)
{
  char * ncn;
  struct program * dclass;
  static ptrdiff_t dclass_storage_offset;
  int num = -1;
  id class;
  struct object * p;
  struct pike_string * psq;

  void *iterator = 0;
  struct objc_method_list *methodList;
  int index;
  SEL selector;
  Class isa;
  
  /* get the objc class to make sure it exists, first. */
  isa = objc_getClass(classname);
  if(isa == nil)
  {
    printf("Objective-C class %s does not exist.\n", classname);
    return 0;
  }
  
  start_new_program();
  p = NEW_OBJC_OBJECT_HOLDER();
  OBJ2_OBJC_OBJECT_HOLDER(p)->class = isa;
  add_ref(p);
  add_object_constant("__objc_class", p, ID_STATIC);
  add_string_constant("__objc_classname", classname, ID_STATIC);
  
  dclass_storage_offset = ADD_STORAGE(struct objc_dynamic_class);

  /* first, we should set up any inherits.
  low_inherit(NSObject_program, NULL, -1, 0, 0, NULL);
  */
  
  /* next, we need to add all of the class methods. */
  while (methodList = class_nextMethodList(isa->isa, &iterator)) 
  {
    for (index = 0; index < methodList->method_count; index++) 
    {
      char * pikename;
      struct object * cmethod;
      struct objc_class_method_struct * cms;
      
      selector = methodList->method_list[index].method_name;
      pikename = make_pike_name_from_selector(selector);
      push_program(objc_class_method_program);
      apply_svalue(Pike_sp-1, 0);
      cmethod = Pike_sp[-1].u.object;
      add_ref(cmethod);
      cms = OBJ2_OBJC_CLASS_METHOD(cmethod);
      cms->class = isa;
      cms->selector = selector;
      add_object_constant((char *)pikename, cmethod, 0);
      free(pikename);
    }
  }  

  /* todo we should work more on the optimizations. */
  ADD_FUNCTION("create", f_objc_dynamic_create, tFunc(tNone,tVoid), 0);  
  ADD_FUNCTION("_sprintf", f_objc_dynamic_class_sprintf, tFunc(tAnd(tInt,tMixed),tVoid), 0);  

  /* then, we add the instance methods. */

  iterator = 0;
  methodList = 0;
  selector = 0;

  while (methodList = class_nextMethodList(isa, &iterator)) 
  {
    for (index = 0; index < methodList->method_count; index++) 
    {
      char * pikename;
      char * psig;
      int q;
      int siglen;
      selector = methodList->method_list[index].method_name;
      // for some reason, some classes have class and instance methods of the same name.
      if(class_getClassMethod(isa, selector)) 
      {
        continue;
        // printf("Skipping %s, as it's already a class method.\n", selector);
      }
//	printf("Adding %s, as an instance method.\n", selector);
        pikename = make_pike_name_from_selector(selector);
        psig = pike_signature_from_objc_signature(&methodList->method_list[index], &siglen);
        quick_add_function((char *)pikename, strlen((char *)pikename), f_objc_dynamic_instance_method, psig,
                           siglen, 0, 
                           OPT_SIDE_EFFECT|OPT_EXTERNAL_DEPEND);
        free(pikename);
        free(psig);
    }
  }

  isa = isa->super_class;
  while (isa && isa->super_class && isa->super_class != isa)
  {
    iterator = 0;
    methodList = 0;
    selector = 0;

    printf("name: %s\n", isa->name);
    while (methodList = class_nextMethodList(isa, &iterator)) 
    {
      for (index = 0; index < methodList->method_count; index++) 
      {
        char * pikename;
        char * psig;
        int q;
        int siglen;
        selector = methodList->method_list[index].method_name;
        // for some reason, some classes have class and instance methods of the same name.
        if(class_getClassMethod(isa, selector) || class_getInstanceMethod(isa, selector)) 
        {
          continue;
          // printf("Skipping %s, as it's already a class method.\n", selector);
        }
          pikename = make_pike_name_from_selector(selector);
          psig = pike_signature_from_objc_signature(&methodList->method_list[index], &siglen);
          quick_add_function((char *)pikename, strlen((char *)pikename), f_objc_dynamic_instance_method, psig,
                           siglen, 0, 
                           OPT_SIDE_EFFECT|OPT_EXTERNAL_DEPEND);
          free(pikename);
          free(psig);
      }
    }
    if(isa->super_class)
      isa = isa->super_class;
    else break;
  }
  /* finally, we add the low level setup callbacks */
  set_init_callback(objc_dynamic_class_init);
  set_exit_callback(objc_dynamic_class_exit);

  dclass = end_program();

  return dclass;
}
