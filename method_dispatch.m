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

#define HAVE_PPC_CPU 0
#define HAVE_X86_CPU 1

#ifdef HAVE_SPARC_CPU

struct cpu_context {
  unsigned INT32 code[19];
};

extern void low_init_pike_object(ffi_cif* cif, void* resp, void** args, void* userdata);

static void *low_make_stub(struct cpu_context *ctx, void *data, int statc,
			   void (*dispatch)(), int args,
			   int flt_args, int dbl_args)
{
  unsigned INT32 *p = ctx->code;

  if(!statc)
    *p++ = 0xd223a048;  /* st  %o1, [ %sp + 0x48 ] */
  *p++ = 0xd423a04c;  /* st  %o2, [ %sp + 0x4c ] */
  *p++ = 0xd623a050;  /* st  %o3, [ %sp + 0x50 ] */
  *p++ = 0xd823a054;  /* st  %o4, [ %sp + 0x54 ] */
  *p++ = 0xda23a058;  /* st  %o5, [ %sp + 0x58 ] */
  *p++ = 0x9de3bf90;  /* save  %sp, -112, %sp    */

  *p++ = 0x11000000|(((unsigned INT32)data)>>10);
                      /* sethi  %hi(data), %o0   */
  *p++ = 0x90122000|(((unsigned INT32)data)&0x3ff);
                      /* or  %o0, %lo(data), %o0 */

  *p++ = 0x92162000;  /* mov  %i0, %o1           */
  if(statc) {
    *p++ = 0x94100019;  /* mov  %i1, %o2           */
    *p++ = 0x9607a04c;  /* add  %fp, 0x4c, %o3     */
  } else {
    *p++ = 0x94100000;  /* mov  %g0, %o2           */
    *p++ = 0x9607a048;  /* add  %fp, 0x48, %o3     */
  }

  *p++ = 0x19000000|(((unsigned INT32)(void *)dispatch)>>10);
                      /* sethi  %hi(dispatch), %o4   */
  *p++ = 0x98132000|(((unsigned INT32)(void *)dispatch)&0x3ff);
                      /* or  %o4, %lo(dispatch), %o4 */

  *p++ = 0x9fc30000;  /* call  %o4               */
  *p++ = 0x01000000;  /* nop                     */
  *p++ = 0xb0100008;  /* mov %o0,%i0             */
  *p++ = 0xb2100009;  /* mov %o1,%i1             */
  *p++ = 0x81c7e008;  /* ret                     */
  *p++ = 0x81e80000;  /* restore                 */

  return ctx->code;
}

#else
#ifdef HAVE_X86_CPU

struct cpu_context {
  unsigned char code[32];
};

static void *low_make_stub(struct cpu_context *ctx, void *data, int statc,
			   void (*dispatch)(), int args,
			   int flt_args, int dbl_args)
{
  unsigned char *p = ctx->code;

  *p++ = 0x55;               /* pushl  %ebp       */
  *p++ = 0x8b; *p++ = 0xec;  /* movl  %esp, %ebp  */
  *p++ = 0x8d; *p++ = 0x45;  /* lea  n(%ebp),%eax */
  if(statc)
    *p++ = 16;
  else
    *p++ = 12;
  *p++ = 0x50;               /* pushl  %eax       */
  if(statc) {
    *p++ = 0xff; *p++ = 0x75; *p++ = 0x0c;  /* pushl  12(%ebp) */
  } else {
    *p++ = 0x6a; *p++ = 0x00;               /* pushl  $0x0     */
  }
  *p++ = 0xff; *p++ = 0x75; *p++ = 0x08;  /* pushl  8(%ebp)  */
  *p++ = 0x68;               /* pushl  $data          */
  *((unsigned INT32 *)p) = (unsigned INT32)data; p+=4;
  *p++ = 0xb8;               /* movl  $dispatch, %eax */
  *((unsigned INT32 *)p) = (unsigned INT32)dispatch; p+=4;
  *p++ = 0xff; *p++ = 0xd0;  /* call  *%eax          */
  *p++ = 0x8b; *p++ = 0xe5;  /* movl  %ebp, %esp     */
  *p++ = 0x5d;               /* popl  %ebp           */
#ifdef __NT__
  *p++ = 0xc2;               /* ret   n              */
  *((unsigned INT16 *)p) = (unsigned INT16)(args<<2); p+=2;
#else /* !__NT__ */
  *p++ = 0xc3;               /* ret                  */
#endif /* __NT__ */

  return ctx->code;
}

#else
#ifdef HAVE_X86_64_CPU

#error Support for x86_64 not implemented yet!

struct cpu_context {
  unsigned char code[32];
};

static void *low_make_stub(struct cpu_context *ctx, void *data, int statc,
			   void (*dispatch)(), int args,
			   int flt_args, int dbl_args)
{
  unsigned char *p = ctx->code;

  *p++ = 0x55;               /* pushl  %ebp       */
  *p++ = 0x8b; *p++ = 0xec;  /* movl  %esp, %ebp  */
  *p++ = 0x8d; *p++ = 0x45;  /* lea  n(%ebp),%eax */
  if(statc)
    *p++ = 16;
  else
    *p++ = 12;
  *p++ = 0x50;               /* pushl  %eax       */
  if(statc) {
    *p++ = 0xff; *p++ = 0x75; *p++ = 0x0c;  /* pushl  12(%ebp) */
  } else {
    *p++ = 0x6a; *p++ = 0x00;               /* pushl  $0x0     */
  }
  *p++ = 0xff; *p++ = 0x75; *p++ = 0x08;  /* pushl  8(%ebp)  */
  *p++ = 0x68;               /* pushl  $data          */
  *((unsigned INT32 *)p) = (unsigned INT32)data; p+=4;
  *p++ = 0xb8;               /* movl  $dispatch, %eax */
  *((unsigned INT32 *)p) = (unsigned INT32)dispatch; p+=4;
  *p++ = 0xff; *p++ = 0xd0;  /* call  *%eax          */
  *p++ = 0x8b; *p++ = 0xe5;  /* movl  %ebp, %esp     */
  *p++ = 0x5d;               /* popl  %ebp           */
#ifdef __NT__
  *p++ = 0xc2;               /* ret   n              */
  *((unsigned INT16 *)p) = (unsigned INT16)(args<<2); p+=2;
#else /* !__NT__ */
  *p++ = 0xc3;               /* ret                  */
#endif /* __NT__ */

  return ctx->code;
}

#else
#ifdef HAVE_PPC_CPU

#ifdef __linux

/* SVR4 ABI */

#define VARARG_NATIVE_DISPATCH

#define NUM_FP_SAVE 8
#define REG_SAVE_AREA_SIZE (8*NUM_FP_SAVE+4*8+8)
#define STACK_FRAME_SIZE (8+REG_SAVE_AREA_SIZE+12+4)
#define VAOFFS0 (8+REG_SAVE_AREA_SIZE)
#define VAOFFS(x) ((((char*)&((*(va_list*)NULL))[0].x)-(char*)NULL)+VAOFFS0)

struct cpu_context {
  unsigned INT32 code[32+NUM_FP_SAVE];
};

static void *low_make_stub(struct cpu_context *ctx, void *data, int statc,
			   void (*dispatch)(), int args,
			   int flt_args, int dbl_args)
{
  unsigned INT32 *p = ctx->code;
  int i;

  *p++ = 0x7c0802a6;  /* mflr r0         */
  *p++ = 0x90010004;  /* stw r0,4(r1)    */
  *p++ = 0x94210000|(0xffff&-STACK_FRAME_SIZE);
		      /* stwu r1,-STACK_FRAME_SIZE(r1) */
  if(!statc)
    *p++ = 0x9081000c;  /* stw r4,12(r1)   */
  *p++ = 0x90a10010;  /* stw r5,16(r1)   */
  *p++ = 0x90c10014;  /* stw r6,20(r1)   */
  *p++ = 0x90e10018;  /* stw r7,24(r1)   */
  *p++ = 0x9101001c;  /* stw r8,28(r1)   */
  *p++ = 0x91210020;  /* stw r9,32(r1)   */
  *p++ = 0x91410024;  /* stw r10,36(r1)  */

  *p++ = 0x40a60000|(4*NUM_FP_SAVE+4);
		      /* bne+ cr1,.nofpsave */
  for(i=0; i<NUM_FP_SAVE; i++)
    *p++ = 0xd8010000|((i+1)<<21)|(8+4*8+8*i);
		      /* stfd fN,M(r1)   */

		      /* .nofpsave:      */
  if(statc) {
    *p++ = 0x7c852378;  /* mr r5,r4        */
    *p++ = 0x38000002;  /* li r0,2	   */
  } else {
    *p++ = 0x38a00000;  /* li r5,0         */
    *p++ = 0x38000001;  /* li r0,1	   */
  }
  
  *p++ = 0x7c641b78;  /* mr r4,r3        */
  *p++ = 0x98010000|VAOFFS(gpr);
		      /* stb r0,gpr      */
  *p++ = 0x38000000;  /* li r0,0         */
  *p++ = 0x98010000|VAOFFS(fpr);
		      /* stb r0,fpr      */
  *p++ = 0x38010000|(STACK_FRAME_SIZE+8);
		      /* addi r0,r1,STACK_FRAME_SIZE+8   */
  *p++ = 0x90010000|VAOFFS(overflow_arg_area);
		      /* stw r0,overflow_arg_area        */
  *p++ = 0x38010008;  /* addi r0,r1,8                    */
  *p++ = 0x90010000|VAOFFS(reg_save_area);
		      /* stw r0,reg_save_area            */

  *p++ = 0x38c10000|VAOFFS0;
		      /* addi r6,r1,va_list              */

  *p++ = 0x3c600000|(((unsigned INT32)(void *)data)>>16);
                      /* lis r3,hi16(data)          */
  *p++ = 0x60630000|(((unsigned INT32)(void *)data)&0xffff);
                      /* ori r3,r3,lo16(data)       */
 
  *p++ = 0x3d800000|(((unsigned INT32)(void *)dispatch)>>16);
                      /* lis r12,hi16(dispatch)     */
  *p++ = 0x618c0000|(((unsigned INT32)(void *)dispatch)&0xffff);
                      /* ori r12,r12,lo16(dispatch) */

  *p++ = 0x7d8803a6;  /* mtlr r12        */
  *p++ = 0x4e800021;  /* blrl            */

  *p++ = 0x80210000;  /* lwz r1,0(r1)    */
  *p++ = 0x80010004;  /* lwz r0,4(r1)    */
  *p++ = 0x7c0803a6;  /* mtlr r0         */
  *p++ = 0x4e800020;  /* blr             */

  return ctx->code;
}

#else /* __linux */

/* PowerOpen ABI */

struct cpu_context {
  unsigned INT32 code[23];
};

#define FLT_ARG_OFFS (args+wargs)

static void *low_make_stub(struct cpu_context *ctx, void *data, int statc,
			   void (*dispatch)(), int args,
			   int flt_args, int dbl_args)
{
  unsigned INT32 *p = ctx->code;

  *p++ = 0x7c0802a6;  /* mflr r0         */
  *p++ = 0x90010008;  /* stw r0,8(r1)    */
  *p++ = 0x9421ffc8;  /* stwu r1,-56(r1) */
  if(!statc)
    *p++ = 0x90810054;  /* stw r4,84(r1)   */
#ifdef __APPLE__
  {
    int i, fp=1;
    for(i=0; i<6; i++)
      if(flt_args&(1<<i))
	*p++ = 0xd0010000|((fp++)<<21)|(4*i+88);  /* stfs fN,X(r1)   */	
      else if(i<5 && dbl_args&(1<<i)) {
	*p++ = 0xd8010000|((fp++)<<21)|(4*i+88);  /* stfd fN,X(r1)   */	
	i++;
      } else
	*p++ = 0x90010000|((i+5)<<21)|(4*i+88);  /* stw rN,X(r1)   */
  }
#else
  *p++ = 0x90a10058;  /* stw r5,88(r1)   */
  *p++ = 0x90c1005c;  /* stw r6,92(r1)   */
  *p++ = 0x90e10060;  /* stw r7,96(r1)   */
  *p++ = 0x91010064;  /* stw r8,100(r1)  */
  *p++ = 0x91210068;  /* stw r9,104(r1)  */
  *p++ = 0x9141006c;  /* stw r10,108(r1) */
#endif

  if(statc) {
    *p++ = 0x7c852378;  /* mr r5,r4        */
    *p++ = 0x38c10058;  /* addi r6,r1,88   */
  } else {
    *p++ = 0x38a00000;  /* li r5,0         */
    *p++ = 0x38c10054;  /* addi r6,r1,84   */
  }
  
  *p++ = 0x7c641b78;  /* mr r4,r3        */

  *p++ = 0x3c600000|(((unsigned INT32)(void *)data)>>16);
                      /* lis r3,hi16(data)          */
  *p++ = 0x60630000|(((unsigned INT32)(void *)data)&0xffff);
                      /* ori r3,r3,lo16(data)       */
 
  *p++ = 0x3d800000|(((unsigned INT32)(void *)dispatch)>>16);
                      /* lis r12,hi16(dispatch)     */
  *p++ = 0x618c0000|(((unsigned INT32)(void *)dispatch)&0xffff);
                      /* ori r12,r12,lo16(dispatch) */

  *p++ = 0x7d8803a6;  /* mtlr r12        */
  *p++ = 0x4e800021;  /* blrl            */

  *p++ = 0x80210000;  /* lwz r1,0(r1)    */
  *p++ = 0x80010008;  /* lwz r0,8(r1)    */
  *p++ = 0x7c0803a6;  /* mtlr r0         */
  *p++ = 0x4e800020;  /* blr             */

  return ctx->code;
}

#endif /* __linux */

#else
#ifdef HAVE_ALPHA_CPU

/* NB: Assumes that pointers are 64bit! */

#define GET_NATIVE_ARG(ty) (((args)=((void**)(args))+1),*(ty *)(((void**)(args))-1))

struct cpu_context {
  void *code[10];
};

static void *low_make_stub(struct cpu_context *ctx, void *data, int statc,
			   void (*dispatch)(), int args,
			   int flt_args, int dbl_args)
{
  unsigned INT32 *p = (unsigned INT32 *)ctx->code;

  /* lda sp,-48(sp) */
  *p++ = 0x23deffd0;
  /* stq ra,0(sp) */
  *p++ = 0xb75e0000;
  if(!statc)
    /* stq a1,8(sp) */
    *p++ = 0xb63e0008;
  if(dbl_args & (1<<0))
    /* stt $f18,16(sp) */
    *p++ = 0x9e5e0010;
  else if(flt_args & (1<<0))
    /* sts $f18,16(sp) */
    *p++ = 0x9a5e0010;
  else
    /* stq a2,16(sp) */
    *p++ = 0xb65e0010;
  if(dbl_args & (1<<1))
    /* stt $f19,24(sp) */
    *p++ = 0x9e7e0018;
  else if(flt_args & (1<<1))
    /* sts $f19,24(sp) */
    *p++ = 0x9a7e0018;
  else
    /* stq a3,24(sp) */
    *p++ = 0xb67e0018;
  if(dbl_args & (1<<2))
    /* stt $f20,32(sp) */
    *p++ = 0x9e9e0020;
  else if(flt_args & (1<<2))
    /* sts $f20,32(sp) */
    *p++ = 0x9a9e0020;
  else
    /* stq a4,32(sp) */
    *p++ = 0xb69e0020;
  if(dbl_args & (1<<3))
    /* stt $f21,40(sp) */
    *p++ = 0x9ebe0028;
  else if(flt_args & (1<<3))
    /* sts $f21,40(sp) */
    *p++ = 0x9abe0028;
  else
    /* stq a5,40(sp) */
    *p++ = 0xb6be0028;
  if(statc) { 
    /* mov a1,a2 */
    *p++ = 0x46310412;
    /* lda a3,16(sp) */
    *p++ = 0x227e0010;
  } else { 
    /* clr a2 */
    *p++ = 0x47ff0412;
    /* lda a3,8(sp) */
    *p++ = 0x227e0008;
  } 
  /* mov a0,a1 */
  *p++ = 0x46100411;
  /* ldq a0,64(t12) */
  *p++ = 0xa61b0040;
  /* ldq t12,72(t12) */
  *p++ = 0xa77b0048;
  /* jsr ra,(t12) */
  *p++ = 0x6b5b4000;
  /* ldq ra,0(sp) */
  *p++ = 0xa75e0000;
  /* lda sp,48(sp) */
  *p++ = 0x23de0030;
  /* ret zero,(ra) */
  *p++ = 0x6bfa8001;

  ctx->code[8] = data;
  ctx->code[9] = dispatch;

  return ctx->code;
}

#else
#error How did you get here?  It should never happen.
#endif /* HAVE_ALPHA_CPU */
#endif /* HAVE_PPC_CPU */
#endif /* HAVE_X86_64_CPU */
#endif /* HAVE_X86_CPU */
#endif /* HAVE_SPARC_CPU */

#ifdef VARARG_NATIVE_DISPATCH

#define ARGS_TYPE va_list*
#define GET_NATIVE_ARG(ty) va_arg(*args,ty)
#define NATIVE_ARG_JFLOAT_TYPE jdouble

#else

#ifndef ARGS_TYPE
#define ARGS_TYPE void*
#endif

#ifndef GET_NATIVE_ARG
#define GET_NATIVE_ARG(ty) (((args)=((ty *)(args))+1),(((ty *)(args))[-1]))
#endif

#endif

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
