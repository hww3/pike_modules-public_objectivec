#include "objectivec_config.h"

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
 
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
 
#ifdef HAVE_FFI_H
#include <ffi.h>
#endif
 
#ifdef HAVE_FFI_CONFIG_H
#include <ffi_config.h>
#endif
  
#ifdef HAVE_OBJC_OBJC_RUNTIME_H
#include <objc/objc-runtime.h>
#endif

#include <Foundation/NSException.h>

#include "util.h"

struct program * NSString_program;
struct program * NSObject_program;
struct program * NSClass_program;
struct program * MethodWrapper_program;
struct program * objc_object_holder_program;
struct program * objc_class_method_program;

struct objc_dynamic_class
{
  id obj;
  int is_instance;
};

#define NEW_OBJC_OBJECT_HOLDER() clone_object(objc_object_holder_program, 0)
#define NEW_NSCLASS() clone_object(NSClass_program, 0)
#define NEW_NSSTRING() clone_object(NSString_program, 0)
#define NEW_NSOBJECT() clone_object(NSObject_program, 0)
#define NEW_METHODWRAPPER() clone_object(MethodWrapper_program, 0);

#define OBJ2_DYNAMIC_OBJECT(o) ((struct objc_dynamic_class *)get_storage(o, o->prog))


#ifndef THIS_IS_OBJC_OBJECT_HOLDER
static ptrdiff_t objc_class_method_storage_offset;
#define OBJ2_OBJC_CLASS_METHOD(o) ((struct objc_class_method_struct *)(o->storage+objc_class_method_storage_offset))
struct objc_object_holder_struct {
  id class;
};

struct objc_class_method_struct
{
  id class;
  SEL selector;
};

struct _struct {
  NSAutoreleasePool * pool;
  struct mapping * class_cache;
};
#endif

typedef char(*pike_objc_char_msgSendv)(id,SEL,unsigned,marg_list);
typedef unsigned char(*pike_objc_unsigned_char_msgSendv)(id,SEL,unsigned,marg_list);
	
typedef short(*pike_objc_short_msgSendv)(id,SEL,unsigned,marg_list);
typedef unsigned short(*pike_objc_unsigned_short_msgSendv)(id,SEL,unsigned,marg_list);
	
typedef int(*pike_objc_int_msgSendv)(id,SEL,unsigned,marg_list);
typedef unsigned int(*pike_objc_unsigned_int_msgSendv)(id,SEL,unsigned,marg_list);
	
typedef long(*pike_objc_long_msgSendv)(id,SEL,unsigned,marg_list);
typedef unsigned long(*pike_objc_unsigned_long_msgSendv)(id,SEL,unsigned,marg_list);
	
typedef long long(*pike_objc_long_long_msgSendv)(id,SEL,unsigned,marg_list);
typedef unsigned long long(*pike_objc_unsigned_long_long_msgSendv)(id,SEL,unsigned,marg_list);
	
typedef float(*pike_objc_float_msgSendv)(id,SEL,unsigned,marg_list);
typedef double(*pike_objc_double_msgSendv)(id,SEL,unsigned,marg_list);

typedef void*(*pike_objc_pointer_msgSendv)(id,SEL,unsigned,marg_list);


#define pike_objc_type_skip_name(type) { \
        while((*type)&&(*type!='=')) \
                type++; \
        if(*type) \
                type++; \
        }
  
#define pike_objc_type_skip_number(type) { \
        if(*type=='+') \
                type++; \
        if(*type=='-') \
                type++; \
        while((*type)&&(*type>='0')&&(*type<='9')) \
                type++; \
        }
      
#define pike_objc_type_skip_past_char(type,char) { \
        while((*type)&&(*type!=char)) \
                type++; \
        if((*type)&&(*type==char)) \
                type++; \
        else \
                result=0;\
        }
        
struct objc_class_method_desc
{
  SEL select;
  Class class;
};
        
void f_objc_dynamic_class_method(INT32 args);
void f_objc_dynamic_instance_method(INT32 args);
void objc_dynamic_class_exit();
void objc_dynamic_class_init();
void f_objc_dynamic_create(Class cls, INT32 args);
struct object * wrap_objc_object(id r);
struct program * pike_low_create_objc_dynamic_class(char * classname);
unsigned pike_objc_type_alignment(char** typeptr);
unsigned pike_objc_type_size(char** typeptr);
BOOL CreateClassDefinition( const char * name, 
        const char * superclassName, struct program * prog );
void * make_stub(struct program * prog);
id init_pike_object(struct program * prog, id obj, SEL sel);
BOOL RegisterDynamicMethod( const char * dynamicMethodName, const char * className, IMP method, char * methodTypes );
id get_objc_object(id obj, SEL sel);