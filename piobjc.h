#include "objectivec_config.h"

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
 
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

#import <ffi.h>
#import <fficonfig.h>
  
#ifdef HAVE_OBJC_OBJC_RUNTIME_H
#include <objc/objc-runtime.h>
#endif

#include <Foundation/NSException.h>

#include "util.h"

#ifndef THIS_IS_FOUNDATION
extern struct program * Foundation_NSStructWrapper_program;
static ptrdiff_t Foundation_NSStructWrapper_storage_offset;

struct Foundation_NSStructWrapper_struct
{
	void * value;
	void * decode;
	void * encode;
};
#define OBJ2_NSSTRUCTWRAPPER(o) ((struct Foundation_NSStructWrapper_struct *)(o->storage+Foundation_NSStructWrapper_storage_offset))
#endif

#ifndef THIS_IS_OBJC_OBJECT_HOLDER
static ptrdiff_t objc_class_method_storage_offset;
#define OBJ2_OBJC_CLASS_METHOD(o) ((struct objc_class_method_struct *)(o->storage+objc_class_method_storage_offset))
#endif


struct objc_object_holder_struct {
  id class;
};

struct objc_dynamic_class
{
  id obj;
  int is_instance;
};

#define OBJ2_DYNAMIC_OBJECT(o) ((struct objc_dynamic_class *)get_storage(o, objc_object_container_program))


struct program * objc_object_container_program;

void start_mixins();
void stop_mixins();

typedef void(*MixinRegistrationCallback)(struct mapping *);

void add_mixin_callback(const char * classname, MixinRegistrationCallback c);

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
id create_pike_object(struct program * prog, id obj, SEL sel);
BOOL RegisterDynamicMethod( const char * dynamicMethodName, const char * className, IMP method, char * methodTypes );
BOOL RegisterInstanceVariables(Class cls, struct program * prog);

id get_objc_object(id obj, SEL sel);
struct object * get_pike_object(id obj, SEL sel);

void low_create_pike_object(ffi_cif* cif, void* resp, void** args, void* userdata);
void _convert(id obj, SEL sel);
void instantiate_pike_native_class(struct program * prog, id obj, SEL sel);
struct program * pike_create_objc_dynamic_class(struct pike_string * classname);
void add_piobjcclass(char * name, struct program * prog);
void low_f_call_objc_class_method(ffi_cif* cif, void* resp, void** args, void* userdata);
void f_objc_dynamic_class_sprintf(Class cls, INT32 args);
void f_call_objc_method(INT32 args, int is_instance, SEL select, id obj);
void f_call_objc_class_method(struct objc_class_method_desc * m, INT32 args);
SEL selector_from_pikename(struct pike_string * name);
struct svalue * object_dispatch_method(id obj, SEL select, struct objc_method * method, marg_list argumentList);
char * make_pike_name_from_selector(SEL s);
char * pike_signature_from_objc_signature(struct objc_method * nssig, int * lenptr);
struct svalue * id_to_svalue(id obj);
id svalue_to_id(struct svalue * sv);
struct svalue * low_ptr_to_svalue(void * ptr, char * type, int prefer_native);

typedef Ivar (* object_setInstanceVariableProc)(id object, const char *name, void  *value);
Ivar new_object_setInstanceVariable(id object, const char *name, void *value);

typedef Ivar (* object_getInstanceVariableProc)(id object, const char *name, void  **value);
Ivar new_object_getInstanceVariable(id object, const char *name, void **value);

object_setInstanceVariableProc old_object_setInstanceVariable;
object_getInstanceVariableProc old_object_getInstanceVariable;

int piobjc_classhandler_callback(const char* className);
Class get_objc_proxy_class(struct program * prog);
struct program * wrap_objc_class(Class r);

#include <Foundation/NSMapTable.h>
extern NSMapTableKeyCallBacks PiObjCUtil_PointerKeyCallBacks;
extern NSMapTableValueCallBacks PiObjCUtil_PointerValueCallBacks;

extern NSMapTableKeyCallBacks PiObjCUtil_ObjCIdentityKeyCallBacks;
extern NSMapTableValueCallBacks PiObjCUtil_ObjCValueCallBacks;

struct object * wrap_real_id(id r);

static inline struct objc_method_list *
PiObjCRT_NextMethodList(Class c, void ** p)
{
	return class_nextMethodList(c, p);
}
