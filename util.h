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
#import <Foundation/NSAutoreleasePool.h>

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

struct object * new_nsobject_object(id obj);
struct callable * get_func_by_selector(struct object * pobject, SEL aSelector);
void piobjc_set_return_value(id sig, id invocation, struct svalue * svalue);
id get_NSObject_from_Object(struct object *o);

@interface OC_NSAutoreleasePoolCollector: NSObject
{ id release_pool; id main_thread;}
-(void)newAutoreleasePool;
-(id)getAutoreleasePool;
-(void)targetForBecomingMultiThreaded:(id)sender;
@end
