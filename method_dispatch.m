/* low_make_stub() returns the address of a function in ctx that
 * prepends data to the list of arguments, and then calls dispatch()
 * with the resulting argument list.
 *
 * Arguments:
 *   ctx	Context, usually just containing space for the machine code.
 *   data	Value to prepend in the argument list.
 *   statc	dispatch is a static method.
 *   dispatch	Function to call.
 *   args	Number of integer equvivalents to pass along.
 *   flt_args	bitfield: There are float arguments at these positions.
 *   dbl_args	bitfield: There are double arguments at these positions.
 */

#import  <Foundation/NSString.h>
#include "libffi/include/ffi.h"
#include "piobjc.h"

#define HAVE_PPC_CPU 1
#define HAVE_X86_CPU 0

extern void low_init_pike_object(ffi_cif* cif, void* resp, void** args, void* userdata);

void * make_init_stub(struct program * prog)
{
  static ffi_cif* init_cif = NULL;
  ffi_closure * closure = NULL;
  ffi_status rv;
  ffi_type** cl_arg_types;
  ffi_type* cl_ret_type;
  const char* rettype;
  void (*disp)(ffi_cif*,void*,void**,void*) = low_init_pike_object;

  // since Objective-C classes cannot be un-registered, we just add a reference and forget about it.
  // technically this is not a leak, i think.
  add_ref(prog);

  if(init_cif == NULL)
  {
    cl_arg_types = malloc(sizeof(ffi_type *) * 2);
    if(cl_arg_types == NULL)
    {
      Pike_error("quick_make_stub: out of memory\n");
    }
    
    cl_arg_types[0] = &ffi_type_pointer;
    cl_arg_types[1] = &ffi_type_pointer;

    init_cif = malloc(sizeof(ffi_cif));

    rv = ffi_prep_cif(init_cif, FFI_DEFAULT_ABI, 2, &ffi_type_pointer, cl_arg_types);
    if(rv != FFI_OK)
    {
      free(init_cif);
      Pike_error("Cannot create FFI interface.\n");
    }
  }

  closure = malloc(sizeof(ffi_closure));
  
  if(closure == NULL)
  {
    Pike_error("quick_make_stub: out of memory\n");
  }
  
  rv = ffi_prep_closure(closure, init_cif, disp, prog);

  if(rv != FFI_OK)
  {
    free(closure);
    Pike_error("Cannot create FFI closure.\n");
  }

  return (void *)closure;
}

void * quick_make_stub(void * dta, void * func)
{
  static ffi_cif* init_cif = NULL;
  ffi_closure * closure = NULL;
  ffi_status rv;
  ffi_type** cl_arg_types;
  ffi_type* cl_ret_type;
  const char* rettype;
  
  if(init_cif == NULL)
  {
    cl_arg_types = malloc(sizeof(ffi_type *) * 2);
    if(cl_arg_types == NULL)
    {
      Pike_error("quick_make_stub: out of memory\n");
    }
    
    cl_arg_types[0] = &ffi_type_pointer;
    cl_arg_types[1] = &ffi_type_uint32;

    init_cif = malloc(sizeof(ffi_cif));

    rv = ffi_prep_cif(init_cif, FFI_DEFAULT_ABI, 2, &ffi_type_pointer, cl_arg_types);
    if(rv != FFI_OK)
    {
      free(init_cif);
      Pike_error("Cannot create FFI interface.\n");
    }
  }

  closure = malloc(sizeof(ffi_closure));
  
  if(closure == NULL)
  {
    Pike_error("quick_make_stub: out of memory\n");
  }
  
  rv = ffi_prep_closure(closure, init_cif, func, dta);

  if(rv != FFI_OK)
  {
    free(closure);
    Pike_error("Cannot create FFI closure.\n");
  }

  return (void *)closure;
}


void * make_static_stub(void * dta, void * func)
{
  static ffi_cif* init_cif = NULL;
  ffi_closure * closure = NULL;
  ffi_status rv;
  ffi_type** cl_arg_types;
  ffi_type* cl_ret_type;
  const char* rettype;
  
  if(init_cif == NULL)
  {
    cl_arg_types = malloc(sizeof(ffi_type *) * 2);
    if(cl_arg_types == NULL)
    {
      Pike_error("quick_make_stub: out of memory\n");
    }
    
    cl_arg_types[0] = &ffi_type_pointer;
    cl_arg_types[1] = &ffi_type_uint32;

    init_cif = malloc(sizeof(ffi_cif));

    rv = ffi_prep_cif(init_cif, FFI_DEFAULT_ABI, 2, &ffi_type_void, cl_arg_types);
    if(rv != FFI_OK)
    {
      free(init_cif);
      Pike_error("Cannot create FFI interface.\n");
    }
  }

  closure = malloc(sizeof(ffi_closure));
  
  if(closure == NULL)
  {
    Pike_error("quick_make_stub: out of memory\n");
  }
  
  rv = ffi_prep_closure(closure, init_cif, func, dta);

  if(rv != FFI_OK)
  {
    free(closure);
    Pike_error("Cannot create FFI closure.\n");
  }
  else
    return (void *)closure;
}


/*
void * make_stub(struct program * prog)
{
  struct cpu_context * ctx;
  void (*disp)() = (void (*)())init_pike_object;

  // since Objective-C classes cannot be un-registered, we just add a reference and forget about it.
  // technically this is not a leak, i think.
  add_ref(prog);

  ctx = malloc(sizeof(struct cpu_context));
  return low_make_stub(ctx, prog, 0, disp, 2, 0, 0);
 //return disp;
}

void * quick_make_stub(void * dta, void * func)
{
  struct cpu_context * ctx;
  void (*disp)() = (void (*)())func;

  ctx = malloc(sizeof(struct cpu_context));
  return low_make_stub(ctx, dta, 0, disp, 2, 0, 0);
 //return disp;
}
*/
