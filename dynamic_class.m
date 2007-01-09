
#import <Foundation/NSString.h>
#import "PiObjCObject.h"
#include "libffi/include/ffi.h"
#import "OC_Array.h"
#import "OC_Mapping.h"
#include "piobjc.h"

#undef THIS
#define THIS ((struct objc_dynamic_class *)(Pike_interpreter.frame_pointer->current_storage))
#define OBJ2_OBJC_OBJECT_HOLDER(o) ((struct objc_object_holder_struct *)get_storage(o, objc_object_holder_program))
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
  [THIS->obj retain];
  THIS->is_instance = 1;

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
  if(select)
    free(select);
}

void low_f_call_objc_class_method(ffi_cif* cif, void* resp, void** args, void* userdata)
{
  INT32 pargs;
  struct objc_class_method_desc * m;
  m = (struct objc_class_method_desc *)userdata;
  pargs = *((INT32 *)args[0]);

//  printf("low_f_call_objc_class_method: %d\n", pargs);

  f_call_objc_class_method(m, pargs);
//  stack_dup();
//  push_text(">> RETURNING FROM CLASS METHOD: %O\n");
//  stack_swap();
//  f_werror(2);
}

void low_f_objc_dynamic_class_sprintf(ffi_cif* cif, void* resp, void** args, void* userdata)
{
  INT32 pargs;
  Class m = (Class)userdata;
  pargs = *((INT32 *)args[0]);

  f_objc_dynamic_class_sprintf(m, pargs);
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
//  printf("calling class method [%s %s]\n", m->class->name, (char *)m->select);
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
	
    pool = [global_autorelease_pool getAutoreleasePool];
    
//    printf("select: %s, is_instance: %d\n", (char *) select, is_instance);
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

    arguments = method_getNumberOfArguments(method);

//    printf("%s(%d args), expecting %d\n", (char * ) select, args, arguments-2);

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
// printf("argument %d %s\n", x, type);
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
           ((double *)argumentList)[num_float_arguments] = (double)(sv->u.float_number);
           num_float_arguments ++;
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
// TODO: do we need to integrate this with svalue_to_id()?
          if(sv->type==T_OBJECT)
          {
            struct object * o = sv->u.object;
            // wrapper = unwrap_objc_object(o);
            // if we don't have a wrapped object, we should make a pike object wrapper.
            // if(!wrapper)
            // seems that PiObjCObject newWithPikeObject does unwrapping. 
//            add_ref(o);
//            add_ref(o->prog);
    	    wrapper = [PiObjCObject newWithPikeObject: o];
            marg_setValue(argumentList, offset, id, wrapper);
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
          Pike_error("expected program as argument of type class\n");
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

//    printf("SENDING MESSAGE %s WITH RETURN TYPE: %s\n", select, type);

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
//printf("VOID\n");
        printf("SEL:: %s\n", (char *)select);
        void_dispatch_method(obj,select,method,argumentList);
        push_int(0);
//printf("Pushed zero.\n");
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
          struct svalue * o;

          o = object_dispatch_method(obj, select, method, argumentList);

          if(o)
          {
            push_svalue(o);
			if(o) free(o);
          }
		  else
		  {
			push_undefined();
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
  }

  @catch (NSException * e)
  {
    Pike_error("%s: %s\n", [(NSString *)[e name] UTF8String], [(NSString *)[e reason] UTF8String]);
  }

  if(argumentList) 
    marg_free(argumentList);
}

void f_objc_dynamic_class_sprintf(Class cls, INT32 args)
{
    char * desc;
    int hash;
	if(cls)
      desc = malloc(strlen(cls->name) + strlen("()") + 15);
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
  
    sprintf(desc, "%s(%u)", cls->name, hash);


    push_text(desc);
    free(desc);

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

  pop_n_elems(args);
  vardef = old_object_getInstanceVariable(THIS->obj, vn, var);
  
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
 if(THIS->obj) [THIS->obj release];
}

int find_dynamic_program_in_cache(struct program * prog)
{
  struct svalue * c = NULL;
  ref_push_program(prog);
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
    ref_push_program(p);
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

static void event_handler(int ev) {
  switch(ev) {

  case PROG_EVENT_INIT: objc_dynamic_class_init(); break;
  case PROG_EVENT_EXIT: objc_dynamic_class_exit(); break;
 
  default: break;
  }
}


struct program * pike_low_create_objc_dynamic_class(char * classname)
{
  char * ncn;
  struct program * dclass;
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
  
  start_new_program();

  add_string_constant("__objc_classname", classname, ID_STATIC);
  
  dclass_storage_offset = ADD_STORAGE(struct objc_dynamic_class);


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

      add_function_constant((char *)pikename, (void *)make_static_stub(desc, low_f_call_objc_class_method), "function(mixed...:mixed)", 0);
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
  ADD_FUNCTION("_sprintf", (void *)make_static_stub(isa, low_f_objc_dynamic_class_sprintf), tFunc(tAnd(tInt,tMixed),tVoid), 0);  

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
        quick_add_function((char *)pikename, strlen((char *)pikename), f_objc_dynamic_instance_method, psig,
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
  while ((isa && isa->super_class && isa->super_class != isa))
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

          quick_add_function((char *)pikename, strlen((char *)pikename), f_objc_dynamic_instance_method, psig,
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
    if(isa->super_class)
      isa = isa->super_class;
    else break;
  }
  
  free_mapping(m);
  /* finally, we add the low level setup callbacks */

  pike_set_prog_event_callback(event_handler);
  //set_init_callback(objc_dynamic_class_init);
  //set_exit_callback(objc_dynamic_class_exit);

  dclass = end_program();
//  add_ref(dclass);
  return dclass;
}

