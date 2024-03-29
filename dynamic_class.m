#import <Foundation/NSString.h>
#import "PiObjCObject.h"
#include "libffi/include/ffi.h"
#import "OC_Array.h"
#import "OC_Mapping.h"
#include "piobjc.h"

#undef THIS
#define THIS OBJ2_DYNAMIC_OBJECT(Pike_fp->current_object)
//#define OBJ2_OBJC_OBJECT_HOLDER(o) ((struct objc_object_holder_struct *)get_storage(o, objc_object_holder_program))
#define THIS_OBJC ((struct _struct *)(Pike_interpreter.frame_pointer->current_storage))

extern id global_autorelease_pool;
extern struct mapping * global_mixin_dict;
extern struct mapping * global_class_cache;
extern struct mapping * global_classname_cache;
extern object_getInstanceVariableProc old_object_getInstanceVariable;
static char *lfun_getter_type_string = NULL;
static char *lfun_setter_type_string = NULL;

void f_objc_dynamic_create(Class cls, INT32 args)
{
  id obj;
  struct objc_object_holder_struct * pobj;
  char * classname;
  int i;
  struct program_constant c;
  struct svalue sval;
  struct pike_string * cname;
  
 printf("dynamic_create: %s()\n", cls->isa->name);

  if(args!=0)
  {
    printf("args: %d\n", args);
    Pike_error("too many arguments to create()\n");
    return;
  }
  
  i = 0;
  pobj = NULL;
  
  if(cls == nil)
  {
    Pike_error("unable to get class.\n");
    return;
  }  

  /* TODO: we have to figure out how to deal with objects that are created outside of pike, then returned
           for wrapping. In this case, we don't free up the alloced object, and have other odd behavior. */

  THIS->obj = [cls alloc];
// [THIS->obj retain];
  THIS->is_instance = 1;
// printf("finished  object.\n");
	printf("created: %s(%p/%p)\n", THIS->obj->isa->name, Pike_fp->current_object, THIS);
  PiObjC_RegisterPikeProxy(THIS->obj, Pike_fp->current_object);
}

void low_f_objc_runner_method(ffi_cif* cif, void* resp, void** args, void* userdata)
{
  INT32 pargs;
  char * m;
  m = (char *)userdata;
  pargs = *((INT32 *)args[0]);
  printf("low_f_call_objc_class_method()\n");
  f_objc_runner_method(m, pargs);	
}

void f_objc_runner_method(char * selector, INT32 args)
{	
	SEL select;
	id obj;
	
	obj = THIS->obj;        

	select = selector;
	
	printf("f_objc_runner_method: %s\n", select);

	f_call_objc_method(args, 1, select, obj);
}


void low_f_objc_dynamic_instance_method(ffi_cif* cif, void* resp, void** args, void* userdata)
{
	INT32 margs;
	char * function_name;
	  
  	function_name = (char *)userdata;
  	margs = *((INT32*)args[0]);
	printf("low_f_objc_dynamic_instance_method(%s, %d)\n", function_name, margs);
	
  	f_objc_dynamic_instance_method(margs, function_name);
}

void f_objc_dynamic_instance_method(INT32 args, char * function_name)
{
  struct pike_string * name;
  id obj;
  struct svalue sval;
  struct objc_object_holder_struct * pobj;
  SEL select = NULL;

//obj = Pike_fp->current_object;
printf("Pike_fp: %p\n", Pike_fp);
printf("Pike_fp->current_object: %p\n", Pike_fp->current_object);
if(!THIS) printf("NO THIS!\n\n");
printf("refs: %d\n", Pike_fp->current_object->refs);
// TODO this doesn't seem right:
add_ref(Pike_fp->current_object);

 obj = THIS->obj;

	name = make_shared_binary_string(function_name, strlen(function_name));

  select = selector_from_pikename(name);

printf("f_objc_dynamic_instance_method: pike:%p->%s, objc:%p->%s\n", THIS, name->str, obj, select);

free_string(name);

  f_call_objc_method(args, 1, select, obj);
}

void low_f_call_objc_class_method(ffi_cif* cif, void* resp, void** args, void* userdata)
{
  INT32 pargs;
  struct objc_class_method_desc * m;
  m = (struct objc_class_method_desc *)userdata;
  pargs = *((INT32 *)args[0]);
  printf("low_f_call_objc_class_method()\n");
  f_call_objc_class_method(m, pargs);
}

void low_f_objc_dynamic_class_sprintf(ffi_cif* cif, void* resp, void** args, void* userdata)
{
  INT32 pargs;
  Class m = (Class)userdata;
  pargs = *((INT32 *)args[0]);

  f_objc_dynamic_class_sprintf(m, pargs);
}

void low_f_objc_dynamic_class_isa(ffi_cif* cif, void* resp, void** args, void* userdata)
{
  INT32 pargs;
  Class m = (Class)userdata;
  pargs = *((INT32 *)args[0]);

  f_objc_dynamic_class_isa(m, pargs);
}

void low_f_objc_dynamic_create(ffi_cif* cif, void* resp, void** args, void* userdata)
{
  INT32 pargs;
  Class m = (Class)userdata;
  pargs = *((INT32 *)args[0]);

  f_objc_dynamic_create(m, pargs);
}

void f_call_objc_class_method(struct objc_class_method_desc * m, INT32 args)
{
  printf("calling class method [%s %s]\n", m->class->name, (char *)m->select);
  f_call_objc_method(args, 0, m->select, m->class);
}

void f_call_objc_method(INT32 args, int is_instance, SEL select, id obj)
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
	int num_float_arguments = 0;
	int num_pointer_return_arguments = 0;
		
    pool = [global_autorelease_pool getAutoreleasePool];
	//describe_proxy();
// printf("\ncall\n");    
//   printf("class: %s, select: %s, is_instance: %d\n", obj->isa->name, (char *) select, is_instance);
    if(is_instance)
      method = class_getInstanceMethod(obj->isa, select);
    else
    {
      obj = objc_getClass(obj->isa->name);
      method = class_getClassMethod(obj, select);
    }
    
    if(!method) 
    {
      Pike_error("unable to find the method.\n");
    }

	num_pointer_return_arguments = get_num_pointer_return_arguments(method);

    arguments = method_getNumberOfArguments(method);

    printf("%s(%d args), expecting %d, returning %d\n", (char * ) select, args, arguments-2, num_pointer_return_arguments+1);

	// the number of required arguments is:
	// the total number of arguments for the method - (2 (standard objc args) + the number of pointer return args)
    if((args) < (arguments-(2 + num_pointer_return_arguments)))
      Pike_error("incorrect number of arguments to method provided.\n");
   

    marg_malloc(argumentList,method);
    if(!argumentList)
      Pike_error("Insufficient memory (Could not allocate method argument buffer).");

    // arguments 0 and 1 are the object to receive the message and the selector, respectively.
    for(x = 2; x < arguments; x++)
    {
      int offset;
      struct svalue * sv;

      // make sure that we have an argument to pass, otherwise it's null.
      // this should only be a factor when pointer return args are present, and nothing is passed in them.
      if((x-2) <= args)
        sv = Pike_sp-args+(x-2);
	  else sv = NULL;
	
      method_getArgumentInfo(method, x, (const char **)(&type), &offset);
      //printf("argument %d %s\n", x, type);
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
#if defined(powerpc) || defined(__POWERPC__) 
         ((double *)argumentList)[num_float_arguments] = (double)(sv->u.float_number);
         num_float_arguments ++;
#else
           marg_setValue(argumentList,offset,double , (double)sv->u.float_number);
#endif
  	 break;

        case 'f':
           if(sv->type!=T_FLOAT)
             Pike_error("Type mismatch for method argument.");
#if	defined(powerpc) || defined(__POWERPC__) 
           ((float *)argumentList)[num_float_arguments] = (float)(sv->u.float_number);
           num_float_arguments ++;
#else
           marg_setValue(argumentList,offset,float , (float)sv->u.float_number);
#endif
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
             Pike_error("Type mismatch for method argument.");
           marg_setValue(argumentList,offset,char *, sv->u.string->str);
  	 break;
  	      case ':':
  	//Pike_error("unable to support type :\n");
  	           marg_setValue(argumentList,offset,SEL , sel_registerName(sv->u.string->str));
  	         break;

		
		//	marg_setValue(argumentList,offset,void *, (unsigned short)sv->u.integer);
		
		
		
        case '@': 
// TODO: do we need to integrate this with svalue_to_id()?
          if(sv->type==T_OBJECT)
          {
            struct object * o = sv->u.object;

			if(isNSNil(sv)) marg_setValue(argumentList,offset,int,nil);
			else
            {
			  Class cls;
      	      wrapper = id_from_object(o);
              marg_setValue(argumentList, offset, id, wrapper);
			}
  		  } 
		  else if(sv->type == T_ARRAY)
		  {
			id rv;
			rv = [OC_Array newWithPikeArray: sv->u.array];
            marg_setValue(argumentList,offset,id, rv);
		  }
			
		  else if(sv->type == T_MAPPING)
		  {
			id rv;
			rv = [OC_Mapping newWithPikeMapping: sv->u.mapping];
            marg_setValue(argumentList,offset,id, rv);
		  }
          else if(sv->type == T_INT)
          {
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
              str = [[NSString alloc] initWithBytes: sv->u.string->str length: sv->u.string->len encoding: enc];
              pop_stack();
              marg_setValue(argumentList,offset,id, str);
           }
  		 else
  		    Pike_error("Type mismatch for method argument.");

  	 break;

  /* TODO: How should we support these? */
        case '#':
        if(Pike_sp[-1].type != T_PROGRAM)
        {
//          printf("got %d\n", Pike_sp[-1].type);
          Pike_error("expected program as argument.\n");
        }
        else
        {
          Class c;
          struct svalue * sval;
          char * classname;

          sval = low_mapping_lookup(global_classname_cache, Pike_sp-1);

          if(!sval)
          {
            Pike_error("unable to find program in cache.\n");
          }
          c = objc_getClass(sval->u.string->str);
          
          marg_setValue(argumentList,offset,Class, c);
        }
        break;

        case '{':
		{
			struct Foundation_NSStructWrapper_struct * s;
           if(sv->type!=T_OBJECT)
             Pike_error("Type mismatch for method argument.\n");

			s = get_storage(sv->u.object, Foundation_NSStructWrapper_program);
			if(!s) Pike_error("Expected Struct object.\n");
			memcpy(marg_getRef(argumentList,offset,void),(struct Foundation_NSStructWrapper_struct *)s->value,piobjc_type_size(&type));				
			printf("set the value.\n");
		//	marg_setValue(argumentList, offset, )
		}
			break;

        case '^':
        {
			void * buf;
			int len;
			len = piobjc_type_size(&type);
			buf = malloc(len);
			if(sv)
			{
				// TODO: we need to actually set values here, if they're passed.
			}
printf("unable to support type ^: passing empty placeholder, len is %d\n", len);
             marg_setValue(argumentList,offset,void *, buf);
        }
           break;
        case '[':
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

    printf("SENDING MESSAGE %s WITH RETURN TYPE: %s\n", select, type);

    pop_n_elems(args);

    @try
    {
      switch(*type){
        case 'c':
  	  THREADS_ALLOW();
          result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
   	  *(INT_TYPE *)result = (INT_TYPE)((pike_objc_unsigned_char_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	  THREADS_DISALLOW();
//printf("PUSHING INT: %d\n", *(INT_TYPE *)result);
          push_int(*(INT_TYPE *)result);
		free(result);
          break;

       case 'C':
         THREADS_ALLOW();
         result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
  	 *(INT_TYPE *)result =     (INT_TYPE)((pike_objc_unsigned_char_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	 THREADS_DISALLOW();
         push_int(*(INT_TYPE *)result);
		free(result);
         break;

       case 'i':
         THREADS_ALLOW();
         result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
  	 *(INT_TYPE *)result =      (INT_TYPE)((pike_objc_int_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
  	 THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
		free(result);
        break;
      // TODO: fix the casting... should we support auto objectize for bignums?

      case 'l':
        THREADS_ALLOW();
        result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
        *(INT_TYPE *)result =     (INT_TYPE)((pike_objc_long_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
        THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
		free(result);
        break;

      case 'L':
        THREADS_ALLOW();
        result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
  	*(INT_TYPE *)result = (INT_TYPE)((pike_objc_unsigned_long_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
        THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
		free(result);
        break;

      case 'I':
        THREADS_ALLOW();
        result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
        *(INT_TYPE *)result = (INT_TYPE)((pike_objc_unsigned_int_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
        THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
		free(result);
        break;

      case 'd':
        THREADS_ALLOW();
        result = (FLOAT_TYPE *) malloc(sizeof(FLOAT_TYPE)); 
        *(FLOAT_TYPE *)result = (FLOAT_TYPE)((pike_objc_double_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
        THREADS_DISALLOW();
        push_float(*(FLOAT_TYPE *)result);
		free(result);
        break;

      case 'f':
        THREADS_ALLOW();
        result = (FLOAT_TYPE *) malloc(sizeof(FLOAT_TYPE)); 
        *(FLOAT_TYPE *)result =  (FLOAT_TYPE)((pike_objc_float_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
        THREADS_DISALLOW();
        push_float(*(FLOAT_TYPE *)result);
		free(result);
        break;

      case 'q':
        THREADS_ALLOW();
        result = (FLOAT_TYPE *) malloc(sizeof(FLOAT_TYPE)); 
        *(FLOAT_TYPE *)result = (FLOAT_TYPE)((pike_objc_long_long_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
        THREADS_DISALLOW();
        push_float(*(FLOAT_TYPE *)result);
		free(result);
        break;

      case 'Q':
        THREADS_ALLOW();
        result = (FLOAT_TYPE *) malloc(sizeof(FLOAT_TYPE)); 
        *(FLOAT_TYPE *)result =     (FLOAT_TYPE)((pike_objc_unsigned_long_long_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
        THREADS_DISALLOW();
        push_float(*(FLOAT_TYPE *)result);
		free(result);
        break;

      case 's':
        THREADS_ALLOW();
        result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
        *(INT_TYPE *)result =     (INT_TYPE)((pike_objc_short_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
        THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
		free(result);
        break;

      case 'S':
        THREADS_ALLOW();
        result = (INT_TYPE *) malloc(sizeof(INT_TYPE)); 
        *(INT_TYPE *)result =     (INT_TYPE)((pike_objc_unsigned_short_msgSendv)objc_msgSendv)(obj,select,method_getSizeOfArguments(method),argumentList);
        THREADS_DISALLOW();
        push_int(*(INT_TYPE *)result);
		free(result);
        break;

      case 'v':
//printf("VOID\n");
        printf("SEL:: %s\n", (char *)select);
        void_dispatch_method(obj,select,method,argumentList);
        push_int(0);
//printf("Pushed zero.\n");
        break;

      case '*':
		{
			char * result;
	        THREADS_ALLOW();
        result = (char *)objc_msgSendv(obj,select,method_getSizeOfArguments(method),argumentList);
        THREADS_DISALLOW();
        push_text(result);
//		free(result);
		}
        break;

      case '@':
        {
          struct svalue * o;

          o = object_dispatch_method(obj, select, method, argumentList);

          if(o)
          {
   		    push_svalue(o);
			free_svalue(o);
			free(o);
          }
		  else
		  {
			push_undefined();
		  }
        }
        break;

// TODO: do we need to look for memory leaks here?
      case '#':
        {
          struct object * o;
          Class c;
          THREADS_ALLOW();
          c = objc_msgSendv(obj,select,method_getSizeOfArguments(method),argumentList);
          THREADS_DISALLOW();
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
      [pool release];
    }


    // now, the fun begins. if we have "pointer return" parameters, we need to get that sorted out here.
    if(num_pointer_return_arguments)
    {
	  num_pointer_return_arguments = push_objc_pointer_return_type(method, argumentList);
      f_aggregate(num_pointer_return_arguments + 1);
    }
  }

  @catch (NSException * e)
  {
	pop_stack();
	printf("%s: %s\n", [(NSString *)[e name] UTF8String], [(NSString *)[e reason] UTF8String]);
//    Pike_error("%s: %s\n", [(NSString *)[e name] UTF8String], [(NSString *)[e reason] UTF8String]);
  }

  if(argumentList) 
    marg_free(argumentList);
}

void f_objc_dynamic_class_sprintf(Class cls, INT32 args)
{
    char * desc;
    int hash;
	int len;
	
	if(cls)
	{
	  len = strlen(cls->name) + strlen("()") + 15;
      desc = malloc(len);
    }
    else 
	{
		pop_n_elems(args);
		push_text("GAH!()");
		return;
	}
	
    if(desc == NULL)
      Pike_error("unable to allocate string.\n");
	snprintf(desc, len, "%s(%p)", cls->name, THIS->obj);
    pop_n_elems(args);
    push_text(desc);
    free(desc);
}

void f_objc_dynamic_class_isa(Class cls, INT32 args)
{
    pop_n_elems(args);

	if(cls)
      push_text(cls->name);	
	else 
		push_text("GAH!()");
}

void low_f_objc_dynamic_getter(ffi_cif* cif, void* resp, void** args, void* userdata)
{
  INT32 pargs;
  char * vn;
  vn = (char *)userdata;
  pargs = *((INT32 *)args[0]);
  f_objc_dynamic_getter(vn, pargs);
}

void low_f_objc_dynamic_setter(ffi_cif* cif, void* resp, void** args, void* userdata)
{
  INT32 pargs;
  char * vn;
  vn = (char *)userdata;
  pargs = *((INT32 *)args[0]);

  f_objc_dynamic_setter(vn, pargs);
}

// TODO: should this give us native types, or just wrappers when the variable type is an object?
void f_objc_dynamic_getter(char * vn, INT32 args)
{
  void * var;
  Ivar vardef;
  struct svalue * sv = NULL;

  vardef = old_object_getInstanceVariable(THIS->obj, vn, var);
  
  pop_n_elems(args);
  sv = ptr_to_svalue(var, vardef->ivar_type);

  push_svalue(sv);

  free(sv);
}

void f_objc_dynamic_setter(char * vn, INT32 args)
{
  void * var;
  Ivar vardef;
  printf("f_objc_dynamic_setter(%s)\n", vn);

  vardef = class_getInstanceVariable(THIS->obj->isa, vn);
  
  var = svalue_to_ptr(var, vardef->ivar_type);
  pop_n_elems(args);
  
  old_object_setInstanceVariable(THIS->obj, vn, var);
}

void objc_dynamic_class_init()
{
   THIS->obj = NULL;	
}

void objc_dynamic_class_exit()
{
	struct objc_dynamic_class * ps;
	
//	push_text("obj: %O\n");
//	push_object(Pike_fp->current_object);
//	f_sprintf(2);
//	printf("%s", Pike_sp[-1].u.string->str);
//	printf("exiting: %p\n", Pike_fp->current_object); //, THIS->obj->isa->name, Pike_fp->current_object);
//	printf("storage: %p\n", Pike_fp->current_storage);
	
	// TODO: this is probably not the appropriate place to do this; we should add an exit handler on 
	// the inherited class instead of doing it here.
	
	ps = (struct objc_dynamic_class *)Pike_fp->current_storage;
   if(ps && ps->obj) {
//	NSLog([THIS->obj description]);
    PiObjC_UnregisterPikeProxy(ps->obj, Pike_fp->current_object);
    [ps->obj release]; 
  }
}

void objc_dynamic_runner_init()
{
   THIS->obj = NULL;
}

void objc_dynamic_runner_exit()
{
 if(THIS->obj) {
    [THIS->obj release]; 
  }
}
int find_dynamic_program_in_cache(struct program * prog)
{
  int rv = 0;
  struct svalue * c = NULL;

  ref_push_program(prog);
  c = low_mapping_lookup(global_classname_cache, Pike_sp-1);	
  pop_stack();

  if(c != NULL) { rv = 1; }
  else rv = 0;
//  if(c)
//    free_svalue(c);
  return rv;
}

struct program * pike_create_objc_dynamic_class(struct pike_string * classname)
{
  struct svalue * c = NULL;
  struct svalue * cn = NULL;
  struct program * p;
  
  /* first, we look up the requested name to see if it's been cached. */

  c = low_mapping_string_lookup(global_class_cache, classname);

  if(c == NULL)
  {
    p = pike_low_create_objc_dynamic_class(classname->str);
    if(!p) return 0;

 	c = malloc(sizeof(struct svalue));
    cn = malloc(sizeof(struct svalue));

    c->type = T_PROGRAM;
    c->u.program = p;

    cn->type = T_STRING;
    cn->u.string = classname;

//    add_ref(classname);
//    add_ref(p);

    low_mapping_insert(global_class_cache, cn, c, 1);
    low_mapping_insert(global_classname_cache, c, cn, 1);

    free_svalue(c);
    free_svalue(cn);
    free(c);
    free(cn);

    return p;
  }
  else
  {
//    printf("Found %s in cache.\n", classname->str);
    return c->u.program;
  }
}

void dynamic_class_event_handler(int ev) {
  switch(ev) {

  case PROG_EVENT_INIT: objc_dynamic_class_init(); break;
  case PROG_EVENT_EXIT: objc_dynamic_class_exit(); break;
 
  default: break;
  }
}

void dynamic_runner_event_handler(int ev) {
  switch(ev) {

  case PROG_EVENT_INIT: objc_dynamic_runner_init(); break;
  case PROG_EVENT_EXIT: objc_dynamic_runner_exit(); break;
 
  default: break;
  }
}


//! this method generates a pike class for a given objective-c class
//! using reflection.
struct program * pike_low_create_objc_dynamic_class(char * classname)
{
  char * ncn;
  struct program * dclass = NULL;
  static ptrdiff_t dclass_storage_offset;
  int num = -1;
  int ivarnum = 0;
  id class;
  struct object * p;
  struct pike_string * psq;
  struct objc_ivar_list * ivar_list;
  struct objc_ivar ivar;
  struct mapping * m;

  void *iterator = 0;
  struct objc_method_list *methodList;
  int index;
  SEL selector;
  Class isa;
  struct svalue * c = NULL;
  
  char * vn;
  char * sg;
  char * ss;
  
  /* get the objc class to make sure it exists, first. */
  isa = objc_getClass(classname);
  if(isa == nil)
  {
    printf("Objective-C class %s does not exist.\n", classname);
    return 0;
  }

  printf("CREATING DYNAMIC CLASS %s\n", classname);
  enter_compiler(NULL, 0);
//  enter_compiler(NULL, 0);
  start_new_program();

  low_inherit(objc_object_container_program, NULL, -1, 0, 0, NULL);
  add_string_constant("__objc_classname", classname, ID_PUBLIC);
  
  /* first, we should add the instance variables. */
  ivar_list = isa->ivars;

//  printf("|-> have %d ivars.\n", ivar_list->ivar_count);

  m = allocate_mapping(100);
  if(!lfun_getter_type_string)
    lfun_getter_type_string = tFuncV(tNone, tVoid, tMix);
  if(!lfun_setter_type_string)
    lfun_setter_type_string = tFuncV(tVoid, tVoid, tMix);

  if(ivar_list && ivar_list->ivar_count)
  {
    for(ivarnum = 0; ivarnum < ivar_list->ivar_count; ivarnum++)
    {
      int vl;
 
      ivar = ivar_list->ivar_list[ivarnum];
      vn = (ivar.ivar_name);

//      if(vn[0] == '_') continue;

      c = NULL;
      c = simple_mapping_string_lookup(m, vn);

      if(c)
        continue;

      vl = strlen(vn);

      sg = malloc(vl + 8);
      ss = malloc(vl + 9);

      snprintf(sg, vl+8, "`->var_%s", vn);
      snprintf(ss, vl+9, "`->var_%s=", vn);
    
//      printf("registering var %s\n", vn);

      quick_add_function((const char *)sg, vl+7, (void *)quick_make_stub(vn, low_f_objc_dynamic_getter), 
                 lfun_getter_type_string, 
                 strlen(lfun_getter_type_string), 0, OPT_SIDE_EFFECT|OPT_EXTERNAL_DEPEND);  
      quick_add_function((const char *)ss, vl+8, (void *)quick_make_stub(vn, low_f_objc_dynamic_setter), 
                 lfun_setter_type_string, 
                 strlen(lfun_setter_type_string), 0, OPT_SIDE_EFFECT|OPT_EXTERNAL_DEPEND);  
      free(ss);
      free(sg);
    
      push_text(vn);
      // add_ref(Pike_sp[-1].u.string);
//	  free(vn);
      push_int(1);
      mapping_string_insert(m, Pike_sp[-2].u.string, Pike_sp-1);
      pop_n_elems(2);
    }

  }


  /* next, we need to add all of the class methods. */

  c = simple_mapping_string_lookup(global_mixin_dict, classname);

  if(c)
  {
    MixinRegistrationCallback rc = c->u.ptr;
    if(rc)  rc(m);	
  }

  while ((methodList = class_nextMethodList(isa->isa, &iterator))) 
  {
    for (index = 0; index < methodList->method_count; index++) 
    {
      char * pikename;
      struct object * cmethod;
      struct objc_class_method_struct * cms;
      struct objc_class_method_desc * desc;
      
      selector = methodList->method_list[index].method_name;
 
      // for some reason, some classes have class and instance methods of the same name.

      c = NULL;
      c = simple_mapping_string_lookup(m, selector);

      if(!c)
       {        
      pikename = make_pike_name_from_selector(selector);
      desc = malloc(sizeof(struct objc_class_method_desc));
      desc->class = isa;
      desc->select = selector; 

      add_function_constant((char *)pikename, (void *)make_static_stub(desc, low_f_call_objc_class_method), "function(mixed...:mixed)", OPT_SIDE_EFFECT);
      push_text(selector);
    //  add_ref(Pike_sp[-1].u.string);
      push_int(1);
      mapping_string_insert(m, Pike_sp[-2].u.string, Pike_sp-1);
      pop_n_elems(2);
      free(pikename);
    }
    }
  }  

  /* todo we should work more on the optimizations. */
  ADD_FUNCTION("create", (void *)make_static_stub(isa, low_f_objc_dynamic_create), tFunc(tNone,tVoid), 0);  

//  ADD_FUNCTION("_sprintf", (void *)make_static_stub(isa, low_f_objc_dynamic_class_sprintf), tFunc(tAnd(tInt,tMixed),tVoid), 0);  

  ADD_FUNCTION("__isa", (void *)make_static_stub(isa, low_f_objc_dynamic_class_isa), tFunc(tAnd(tVoid,tMixed),tVoid), 0);  

  /* then, we add the instance methods. */

  iterator = 0;
  methodList = 0;
  selector = 0;

  while ((methodList = class_nextMethodList(isa, &iterator))) 
  {
    for (index = 0; index < methodList->method_count; index++) 
    {
      char * pikename;
      char * psig;
      int q;
      int siglen;
      selector = methodList->method_list[index].method_name;

      if(((char *)selector)[0] == '_') continue;

      // for some reason, some classes have class and instance methods of the same name.
      c = NULL;
      c = simple_mapping_string_lookup(m, selector);

      if(!c)
{
//	printf("Adding %s, as an instance method.\n", selector);
        pikename = make_pike_name_from_selector(selector);
        psig = pike_signature_from_objc_signature(&methodList->method_list[index], &siglen);
        quick_add_function((char *)pikename, strlen((char *)pikename), make_dynamic_method_stub((char*)pikename), psig,
                           siglen, 0, 	
                           OPT_SIDE_EFFECT|OPT_EXTERNAL_DEPEND);
         push_text(selector);
         // printf("added %s to mapping.\n", Pike_sp[-1].u.string->str);
  //       add_ref(Pike_sp[-1].u.string);
         push_int(1);
         mapping_string_insert(m, Pike_sp[-2].u.string, Pike_sp-1);
         pop_n_elems(2);

        free(pikename);
        free(psig);
      }
    }
  }

  isa = isa->super_class;
  while (isa)
  {
    iterator = 0;
    methodList = 0;
    selector = 0;
//    printf("name: %s\n", isa->name);
    while (methodList = class_nextMethodList(isa, &iterator)) 
    {
//      printf("methods in list: %d\n", methodList->method_count);
      
      for (index = 0; index < methodList->method_count; index++) 
      {
        char * pikename;
        char * psig;
        int q;
        int siglen;
        selector = methodList->method_list[index].method_name;

          // for some reason, some classes have class and instance methods of the same name.
        c = NULL;
        c = simple_mapping_string_lookup(m, selector);

        if(!c)
        {
          if(((char *)selector)[0] == '_') continue;
          pikename = make_pike_name_from_selector(selector);
          psig = pike_signature_from_objc_signature(&methodList->method_list[index], &siglen);

          quick_add_function((char *)pikename, strlen((char *)pikename), make_dynamic_method_stub((char*)pikename), psig,
                           siglen, 0, 
                           OPT_SIDE_EFFECT|OPT_EXTERNAL_DEPEND);

           push_text(selector);
           add_ref(Pike_sp[-1].u.string);
           push_int(1);
           mapping_string_insert(m, Pike_sp[-2].u.string, Pike_sp-1);
           pop_n_elems(2);

          free(pikename);
          free(psig);
        }
      }
    }
    if(isa->super_class && isa == isa->super_class)
{
//	printf("breakin'\n");
		break;
	}
	else if(isa->super_class)
      isa = isa->super_class;
	else isa = 0;
  }
  
  free_mapping(m);
  /* finally, we add the low level setup callbacks */

  pike_set_prog_event_callback(dynamic_class_event_handler);

  dclass = end_program();
  exit_compiler();

  if(dclass && strlen(classname))
  {

    if(get_master())
    {
      push_text("Public.ObjectiveC.register_new_dynamic_program");
      APPLY_MASTER("resolv", 1);
      if(Pike_sp[-1].type != T_FUNCTION)
      {
        pop_stack();
        Pike_error("unable to find Public.ObjectiveC.register_new_dynamic_program.\n");
      }
      push_text(classname);
      add_ref(Pike_sp[-1].u.string);
      ref_push_program(dclass);
      apply_svalue(Pike_sp-3, 2);
      // remove the return result, as well as the function we got from resolv()
      pop_n_elems(2);
	return dclass;
    }
  }
  return dclass;
}
