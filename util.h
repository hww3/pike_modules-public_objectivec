/* Standard Pike include files. */
#include "bignum.h"
#include "array.h"
#include "builtin_functions.h"
#include "constants.h"
#include "interpret.h"
#include "mapping.h"
#include "multiset.h"
#include "module_support.h"
#include "object.h"
#include "pike_macros.h"
#include "pike_types.h"
#include "program.h"
#include "stralloc.h"
#include "svalue.h"
#include "threads.h"
#include "version.h"
#include "operators.h"
#include "backend.h"
#import <Foundation/NSAutoreleasePool.h>
#import "OC_NSAutoreleasePoolCollector.h"

#if (PIKE_MAJOR_VERSION == 7 && PIKE_MINOR_VERSION == 1 && PIKE_BUILD_VERSION >= 12) || PIKE_MAJOR_VERSION > 7 || (PIKE_MAJOR_VERSION == 7 && PIKE_MINOR_VERSION > 1)
# include "pike_error.h"
#else
# include "error.h"
# ifndef Pike_error
#  define Pike_error error
# endif
#endif

#ifndef ARG
/* Get argument # _n_ */
#define ARG(_n_) Pike_sp[-((args - _n_) + 1)]
#endif

unsigned piobjc_type_size(char** type_encoding);
void low_f_objc_runner_method(ffi_cif* cif, void* resp, void** args, void* userdata);

id id_from_object(struct object * o);
struct object * new_nsobject_object(id obj);
struct svalue * get_func_by_selector(struct object * pobject, SEL aSelector);
void piobjc_set_return_value(id sig, id invocation, struct svalue * svalue);
id get_NSObject_from_Object(struct object *o);

char * get_signature_for_func(struct svalue * func, SEL selector);
id unwrap_objc_object(struct object * o);
char * pike_signature_from_nsmethodsignature(id nssig, int * lenptr);
struct object * new_method_runner(struct object * obj, SEL selector);
