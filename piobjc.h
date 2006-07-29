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

struct program * NSObject_program;
struct program * NSClass_program;
struct program * MethodWrapper_program;

typedef struct
{    
  struct pike_string *classname;
  id class;
} NSCLASS_OBJECT_DATA;

typedef struct
{
  id object;
} NSOBJECT_OBJECT_DATA;

typedef struct
{
	id object;
	SEL selector;
	struct objc_method * method;
} METHODWRAPPER_OBJECT_DATA;

#define NEW_NSCLASS() clone_object(NSClass_program, 0)
#define NEW_NSOBJECT() clone_object(NSObject_program, 0)
#define NEW_METHODWRAPPER() clone_object(MethodWrapper_program, 0);

#undef OBJ2_NSCLASS
#define OBJ2_NSCLASS(o) ((struct NSClass_struct *)get_storage(o, NSClass_program))

#ifndef THIS_IS_NSOBJECT

struct NSObject_struct {
NSOBJECT_OBJECT_DATA   *object_data;
};

#undef OBJ2_NSOBJECT
#define OBJ2_NSOBJECT(o) ((struct NSObject_struct *)get_storage(o, NSObject_program))

#define THIS_NSOBJECT ((struct NSObject_struct *)(Pike_interpreter.frame_pointer->current_storage))

#endif

#ifndef THIS_IS_METHODWRAPPER
struct MethodWrapper_struct {
  METHODWRAPPER_OBJECT_DATA *object_data;	
};

#undef OBJ2_METHODWRAPPER
#define OBJ2_METHODWRAPPER(o) ((struct MethodWrapper_struct *)get_storage(o, MethodWrapper_program))

#define THIS_METHODWRAPPER ((struct MethodWrapper_struct *)(Pike_interpreter.frame_pointer->current_storage))
#endif

#ifndef THIS_IS_NSCLASS

struct NSClass_struct {
NSCLASS_OBJECT_DATA   *object_data;
};


#undef OBJ2_NSCLASS
#define OBJ2_NSCLASS(o) ((struct NSClass_struct *)get_storage(o, NSClass_program))

#define THIS_NSCLASS ((struct NSClass_struct *)(Pike_interpreter.frame_pointer->current_storage))

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

unsigned pike_objc_type_alignment(char** typeptr);
unsigned pike_objc_type_size(char** typeptr);

