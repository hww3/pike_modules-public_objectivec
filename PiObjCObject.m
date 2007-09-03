/* 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 * $Id: PiObjCObject.m,v 1.31 2007-09-03 02:35:56 hww3 Exp $
 */

/*
 * File licensing and authorship information block.
 *
 * Version: MPL 1.1/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Initial Developer of the Original Code is
 *
 * Bill Welliver <hww3@riverweb.com>
 *
 * Portions created by the Initial Developer are Copyright (C) Bill Welliver
 * All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of the LGPL, and not to allow others to use your version
 * of this file under the terms of the MPL, indicate your decision by
 * deleting the provisions above and replace them with the notice
 * and other provisions required by the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL or the LGPL.
 *
 * Significant Contributors to this file are:
 *
 */

/*! @module Public
 */

/*! @module ObjectiveC
 */

/*! @class PiObjCObject
 */

#define _GNU_SOURCE
#define THIS_IS_PIOBJCOBJECT 1

#include "libffi/include/ffi.h"
#include "piobjc.h"
#import <pthread.h>
#import  <Foundation/NSObject.h>
#import  <Foundation/NSMethodSignature.h>
#import  <Foundation/NSInvocation.h>
#import  <Foundation/NSString.h>
#import "PiObjCObject.h"

extern int async_error_mode;
void dispatch_pike_method(struct object * pobject, SEL sel, NSInvocation * anInvocation);

@implementation PiObjCObject

+(id) newWithPikeObject:(struct object *) obj
{              
  id instance;
  instance = (id)unwrap_objc_object(obj);
  if(instance == NULL) 
  {
/*
	printf("Whoo hoo, we have a native pike object!\n");

push_text("Whoo hoo, we have a native pike object: %O\n");
ref_push_object(obj);
f_indices(1);
f_sprintf(2);
printf("%s", Pike_sp[-1].u.string->str);
pop_stack();
*/
    instance = PiObjC_FindObjCProxy(obj);
	if(!instance)
	{
      instance = [[self alloc] initWithPikeObject:obj];
      [instance autorelease];
	  
    }
  }        
  return instance;
}

- (id)initWithPikeObject:(struct object *)obj
{
  printf("PiObjCObject.initWithPikeObject\n");
	if (pobject) {
		PiObjC_UnregisterObjCProxy(pobject, self);
	}
	
  PiObjC_RegisterObjCProxy(obj, self);
  pobject = obj;
  add_ref(obj);
  pinstantiated = YES;
//  [self retain];
  return self;
}

- (id)retain
{
  printf("PiObjCObject.retain()\n");
  if(pobject)
    add_ref(pobject);
  return [super retain];
}

+ (id) allocWithZone:(id) zone
{
	id me;
	NSLog(@"[allocWithZone: called]\n");
	me = [super allocWithZone: zone];
	return [me __create];
}

- (id) __create
{
	NSLog(@"[__create called]\n");
	return self;
}

- (id)release
{
  printf("PiObjCObject.release()\n");
  if(pobject)
    free_object(pobject);
  [super release];
}


- (void)dealloc
{
  printf("PiObjCObject.dealloc()\n");
  PiObjC_UnregisterObjCProxy(pobject, self);
  if(pobject)
  	free_object(pobject);
  [super dealloc];
}

/* NSObject protocol */
- (unsigned)hash
{
	return (unsigned)(&pobject);
}

- (BOOL)isEqual:(id)other
{
	if (other == nil) 
	{
        [NSException raise: NSInvalidArgumentException
                    format: @"nil argument"];
    } 
    else if (self == other) 
    {
        return YES;
    }

    if([other respondsToSelector: @selector(getPikeObject)])
    {
	   if([other getPikeObject] == pobject) return YES;
    }

   return NO;
}

/* NSObject methods */
- (NSComparisonResult)compare:(id)other
{
	if (other == nil) 
	{
        [NSException raise: NSInvalidArgumentException
                    format: @"nil argument"];
    } 
    else if (self == other) 
    {
        return NSOrderedSame;
    }

    if([other respondsToSelector: @selector(getPikeObject)])
    {
	   if([other getPikeObject] == pobject) return NSOrderedSame;
    }

   return NSOrderedDescending;
}

-(BOOL)__ObjCisPikeType
{
  return YES;	
}

-(int)__ObjCgetPikeType
{
  return PIKE_T_OBJECT;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
  char * argt;
  unsigned arg;
  int ind;
  char * rettype;
  int retsize;
  id sig;
  int args;
  SEL sel;
  struct svalue sv;
  struct thread_state *state;



//  [anInvocation retain];
  sel = [anInvocation selector];

  printf("PiObjCObject.forwardInvocation: %s returns %s\n", (char *)sel, [[anInvocation methodSignature] methodReturnType] );

  if(sel == @selector(description))
  {
	  id res = [self description];   
	  [anInvocation setReturnValue:&res];
    return;
  }

  if(sel == @selector(_copyDescription))
  {
	  id res = [self _copyDescription];   
	  [anInvocation setReturnValue:&res];
    return;
  }

  if(sel == @selector(respondsToSelector:))
  {
    SEL sel2;
    BOOL b;

    [anInvocation getArgument:&sel2 atIndex:2];
   	b = [self respondsToSelector: sel2];
	  [anInvocation setReturnValue:&args];
	  return;
  }

  if((state = thread_state_for_id(th_self()))!=NULL) 
  {
    /* This is a pike thread.  Do we have the interpreter lock? */
    if(!state->swapped) 
    {
      /* Yes.  Go for it... */
        dispatch_pike_method(pobject, sel, anInvocation);      		
    }
    else
    {
      /* Nope, let's get it... */ 
      mt_lock_interpreter();
      SWAP_IN_THREAD(state);

      dispatch_pike_method(pobject, sel, anInvocation);

      /* Restore */
      SWAP_OUT_THREAD(state);
      mt_unlock_interpreter();
     }
   }
    else
    {
      /* Not a pike thread.  Create a temporary thread_id... */
      struct object *thread_obj;
//      printf("creating a temporary thread.\n");
      mt_lock_interpreter();
// printf("got the lock.\n");
      init_interpreter();
      Pike_interpreter.stack_top=((char *)&state)+ (thread_stack_size-16384) * STACK_DIRECTION;
      Pike_interpreter.recoveries = NULL;
      thread_obj = fast_clone_object(thread_id_prog);
      INIT_THREAD_STATE((struct thread_state *)(thread_obj->storage +
        				          thread_storage_offset));
      num_threads++;
      thread_table_insert(Pike_interpreter.thread_state);

      dispatch_pike_method(pobject, sel, anInvocation);

      cleanup_interpret();	/* Must be done before EXIT_THREAD_STATE */
      Pike_interpreter.thread_state->status=THREAD_EXITED;
      co_signal(&Pike_interpreter.thread_state->status_change);
      thread_table_delete(Pike_interpreter.thread_state);
      EXIT_THREAD_STATE(Pike_interpreter.thread_state);
      Pike_interpreter.thread_state=NULL;
      free_object(thread_obj);
      thread_obj = NULL;
      num_threads--;
      mt_unlock_interpreter();      
    }
  //  [anInvocation release];

}

struct object * get_pike_object(id obj, SEL sel)
{
  void * i;
  printf("get_pike_object()\n");
  old_object_getInstanceVariable(obj, "pobject", &i);
  
  return (struct object *)i;
}

void low_create_pike_object(ffi_cif* cif, void* resp, void** args, void* userdata)
{
  SEL sel;
  id obj;
  struct program * prog;
  id rv;
  
  prog = (struct program *)userdata;
  obj = *(id*)args[0];
  sel = *(SEL*)args[1];
  
  printf("low_create_pike_object()\n");
  rv = create_pike_object(prog, obj, sel);

  *(id*) resp = rv;
}


// we call create() on the object once alloc has completed.
id create_pike_object(struct program  * prog, id obj, SEL sel)
{
    struct thread_state *state;
    printf("create_pike_object()\n");

    if(!prog || !obj || !sel)
    {
	   printf("AIEEEEE!\n");
    }

	if(prog)
	{
      if((state = thread_state_for_id(th_self()))!=NULL)
      {
        /* This is a pike thread.  Do we have the interpreter lock? */
        if(1 || !state->swapped)
        {
          /* Yes.  Go for it... */
          instantiate_pike_native_class(prog, obj, sel);
        }
        else
        {
          /* Nope, let's get it... */
          mt_lock_interpreter();
          SWAP_IN_THREAD(state);

          instantiate_pike_native_class(prog, obj, sel);

          /* Restore */
          SWAP_OUT_THREAD(state);
          mt_unlock_interpreter();
         }
       }
       else
       {
          /* Not a pike thread.  Create a temporary thread_id... */
          struct object *thread_obj;
          mt_lock_interpreter();
          init_interpreter();
          Pike_interpreter.stack_top=((char *)&state)+ (thread_stack_size-16384) * STACK_DIRECTION;
          Pike_interpreter.recoveries = NULL;
          thread_obj = fast_clone_object(thread_id_prog);
          INIT_THREAD_STATE((struct thread_state *)(thread_obj->storage +
                                                      thread_storage_offset));
          num_threads++;
          thread_table_insert(Pike_interpreter.thread_state);

          instantiate_pike_native_class(prog, obj, sel);


          cleanup_interpret();      /* Must be done before EXIT_THREAD_STATE */
          Pike_interpreter.thread_state->status=THREAD_EXITED;
          co_signal(&Pike_interpreter.thread_state->status_change);
          thread_table_delete(Pike_interpreter.thread_state);
          EXIT_THREAD_STATE(Pike_interpreter.thread_state);
          Pike_interpreter.thread_state=NULL;
          free_object(thread_obj);
          thread_obj = NULL;
          num_threads--;
          mt_unlock_interpreter();     
       }

		return obj;
	}
	else
	{
	  printf("[PIKE PROGRAM init]: no program!\n");
	  return nil;
	}
}

void instantiate_pike_native_class(struct program * prog, id obj, SEL sel)
{
  struct object * pobject;
// printf("creating a clone of the program.\n");	
  pobject = clone_object(prog, 0);	
			
//	pobject = Pike_sp[-1].u.object;
//  add_ref(pobject);
  add_ref(prog);
//printf("setting the object's instance variable\n");

//	object_setInstanceVariable(obj, "pobject",  pobject);
	old_object_setInstanceVariable(obj, "pobject",  pobject);
//printf("done\n");
}

#define LOW_SVALUE_STACK_MARGIN 20
#define SVALUE_STACK_MARGIN (100 + LOW_SVALUE_STACK_MARGIN)
#define C_STACK_MARGIN (20000 + LOW_C_STACK_MARGIN)
#define LOW_C_STACK_MARGIN 500

PMOD_EXPORT void piobjc_call_handle_error(void)
{
  dmalloc_touch_svalue(&throw_value);
printf("piobjc_call_handle_error()\n");
  if (Pike_interpreter.svalue_stack_margin > LOW_SVALUE_STACK_MARGIN) {
    int old_t_flag = Pike_interpreter.trace_level;
    Pike_interpreter.trace_level = 0;
    Pike_interpreter.svalue_stack_margin = LOW_SVALUE_STACK_MARGIN;
    Pike_interpreter.c_stack_margin = LOW_C_STACK_MARGIN;

    if (get_master()) {         /* May return NULL at odd times. */
      ONERROR tmp; 
      SET_ONERROR(tmp,exit_on_error,"cocoa_gui_error_handler failure!");
      push_text("Public.ObjectiveC.cocoa_gui_error_handler");
      APPLY_MASTER("resolv", 1);
      UNSET_ONERROR(tmp);

      *(Pike_sp++) = throw_value;
      dmalloc_touch_svalue(Pike_sp-1);
      throw_value.type=T_INT;

      apply_svalue(Pike_sp-2, 1);

    }
    else {
      dynamic_buffer save_buf;
      char *s;
      fprintf (stderr, "There's no master to handle the error. Dumping it raw:\n");
      init_buf(&save_buf);
      safe_describe_svalue (Pike_sp - 1, 0, 0);
      s=simple_free_buf(&save_buf);
      fprintf(stderr,"%s\n",s);
      free(s);
      if (Pike_sp[-1].type == PIKE_T_OBJECT && Pike_sp[-1].u.object->prog) {
        int fun = find_identifier("backtrace", Pike_sp[-1].u.object->prog);
        if (fun != -1) {
          fprintf(stderr, "Attempting to extract the backtrace.\n");
          safe_apply_low2(Pike_sp[-1].u.object, fun, 0, 0);
          init_buf(&save_buf);
          safe_describe_svalue(Pike_sp - 1, 0, 0);
          pop_stack();
          s=simple_free_buf(&save_buf);
          fprintf(stderr,"%s\n",s);
          free(s);
        }
      }
    }

    pop_stack();
    Pike_interpreter.svalue_stack_margin = SVALUE_STACK_MARGIN;
    Pike_interpreter.c_stack_margin = C_STACK_MARGIN;
    Pike_interpreter.trace_level = old_t_flag;
  }

  else {
    free_svalue(&throw_value);
	    throw_value.type=T_INT;
	  }
	}

void dispatch_pike_method(struct object * pobject, SEL sel, NSInvocation * anInvocation)
{
  int args;
  struct svalue * c;
  struct svalue func;
  id sig;
  int x;
  JMP_BUF recovery;

  printf("dispatch_pike_method(%s)\n", sel);
  c = get_func_by_selector(pobject, sel);
  if(c) // jackpot!
  {
    void * buf = NULL;
    pthread_t tid;

    sig = [anInvocation methodSignature];

    args = push_objc_types(sig, anInvocation);
    // printf("making the call.\n");

    if(async_error_mode)
    {
	  free_svalue(& throw_value);
	  throw_value.type=T_INT;
	  if(SETJMP_SP(recovery, args))
	  {
	      piobjc_call_handle_error();
	      push_int(0);
	  }else{
	      apply_svalue (c, args);
	      printf("Dealing with the return value for call to %s...", (char *) sel);
	      piobjc_set_return_value(sig, anInvocation, &Pike_sp[-1]);
	      pop_stack();
	      printf(" done.\n");

	      printf("done making the call.\n");
	  }
	  UNSETJMP(recovery);
    }
    else
    {
       apply_svalue (c, args);
      // now, we should deal with the return value.
      printf("Dealing with the return value for call to %s...", (char *) sel);
      piobjc_set_return_value(sig, anInvocation, &Pike_sp[-1]);
      pop_stack();
      printf(" done.\n");

      printf("done making the call.\n");
    }

    free_svalue(c);
    free(c);
  }
  else
  {
    [NSException raise:NSInvalidArgumentException format:@"no such selector: %s", (char *)[anInvocation selector]];	
  //  [anInvocation release];
  }

}

/* Undocumented method used by NSLog, this seems to work. */
- (NSString*) _copyDescription
{
	return [[self description] retain];
}

- (struct object *) getPikeObject
{
  printf("getPikeObject()\n");
	return pobject;
}

- (struct object *)  __piobjc_PikeObject__
{
	printf("PiObjCObject.__piobjc_PikeObject__\n");
	return pobject;
}

// we use a really, really lame method for calculating the number of arguments
// to a method: we count the number of colons. it's ugly, and it would be 
// far better to parse the type information for the argument count. that, 
// however, would be a lot of work, and i'm not up for that right now.
- (NSMethodSignature *) methodSignatureForSelector: (SEL)aSelector
{
  char * encoding = NULL;
  struct svalue * func;
  struct thread_state *state;
  printf("PiObjCObject.methodSignatureForSelector: %s\n", (char *)aSelector);

  if(aSelector == @selector(respondsToSelector:))
  {
    return [NSMethodSignature signatureWithObjCTypes:"c@::"]; 	
  }

  if(aSelector == @selector(methodDescriptionForSelector:))
  {
    return [NSMethodSignature signatureWithObjCTypes:"^{objc_method_description=:*}@::"]; 	
  }

  if(!pobject) return nil;

  if((state = thread_state_for_id(th_self()))!=NULL)
  {
    /* This is a pike thread.  Do we have the interpreter lock? */
    if(!state->swapped)
    {
      /* Yes.  Go for it... */
      func = get_func_by_selector(pobject, aSelector);
      if(func)
      {
        encoding = (char *)get_signature_for_func(func, aSelector);
        free_svalue(func);
		free(func);
      }
    }
    else
    {
      /* Nope, let's get it... */
      mt_lock_interpreter();
      SWAP_IN_THREAD(state);

      // first, we perty up the selector.
      func = get_func_by_selector(pobject, aSelector);
      if(func)
      {
        encoding = (char *)get_signature_for_func(func, aSelector);
        free_svalue(func);
		free(func);
      }
      
      /* Restore */
      SWAP_OUT_THREAD(state);
      mt_unlock_interpreter();
     }
   }
   else
   {
      /* Not a pike thread.  Create a temporary thread_id... */
      struct object *thread_obj;
      mt_lock_interpreter();
      init_interpreter();
      Pike_interpreter.stack_top=((char *)&state)+ (thread_stack_size-16384) * STACK_DIRECTION;
      Pike_interpreter.recoveries = NULL;
      thread_obj = fast_clone_object(thread_id_prog);
      INIT_THREAD_STATE((struct thread_state *)(thread_obj->storage +
                                                  thread_storage_offset));
      num_threads++;
      thread_table_insert(Pike_interpreter.thread_state);

      func = get_func_by_selector(pobject, aSelector);
      if(func)
      {
        encoding = (char *)get_signature_for_func(func, aSelector);
        free_svalue(func);
		free(func);
      }
      
      cleanup_interpret();      /* Must be done before EXIT_THREAD_STATE */
      Pike_interpreter.thread_state->status=THREAD_EXITED;
      co_signal(&Pike_interpreter.thread_state->status_change);
      thread_table_delete(Pike_interpreter.thread_state);
      EXIT_THREAD_STATE(Pike_interpreter.thread_state);
      Pike_interpreter.thread_state=NULL;
      free_object(thread_obj);
      thread_obj = NULL;
      num_threads--;
      mt_unlock_interpreter();     
   }

  if(encoding)
  {
	id sig;
    printf("encoding: %s\n", encoding);
    sig = [NSMethodSignature signatureWithObjCTypes:encoding];
    free(encoding);
    return sig;
  }  

  if(aSelector == @selector(respondsToSelector:))
  {
    return [NSMethodSignature signatureWithObjCTypes:"c@::"];
  }

  if(aSelector == @selector(methodDescriptionForSelector:))
  {
    return [NSMethodSignature signatureWithObjCTypes:"^{objc_method_description=:*}@::"];
  }

  if(aSelector == @selector(getPikeObject))
  {
	id i;
	char * enc;
	char * e = @encode(struct object *);
	enc = malloc(strlen(e) + 2);
	strcpy(enc, e);
//    free(e);
	strcat(enc, "@:");
    i = [NSMethodSignature signatureWithObjCTypes: enc];
    return i;
  }


  return nil;
//  [NSException raise:NSInvalidArgumentException format:@"no such selector: %s", (char *)aSelector];	
//  return [super methodSignatureForSelector: aSelector];
//  return nil;
}


- (BOOL) respondsToSelector:(SEL) aSelector
{
  struct svalue * func;
  struct objc_method_list* lst;
  void* cookie;

  printf("PiObjCObject.respondsToSelector: %s? ", (char*) aSelector);

	/*
	 * We cannot rely on NSProxy, it doesn't implement most of the
	 * NSObject interface anyway.
	 */

	cookie = NULL;
	lst = PiObjCRT_NextMethodList(self->isa, &cookie);
	while (lst != NULL) {
		int i;

		for (i = 0; i < lst->method_count; i++) {
//			printf("method: %s\n", lst->method_list[i].method_name);
			if (lst->method_list[i].method_name == aSelector) {
				printf("YES\n");
				return YES;
			}
		}
		lst = PiObjCRT_NextMethodList(self->isa, &cookie);
   }

	cookie = NULL;
	lst = PiObjCRT_NextMethodList(self->isa->super_class, &cookie);
	while (lst != NULL) {
		int i;

		for (i = 0; i < lst->method_count; i++) {
//			printf("method: %s\n", lst->method_list[i].method_name);
			if (lst->method_list[i].method_name == aSelector) {
				printf("YES\n");
				return YES;
			}
		}
		lst = PiObjCRT_NextMethodList(self->isa->super_class, &cookie);
   }

/*

  if(aSelector == @selector(__ObjCgetPikeArray))
  {
	return NO;
  }

  if(aSelector == @selector(__ObjCgetPikeMapping))
  {
	return NO;
  }

*/

  func = get_func_by_selector(pobject, aSelector);

  if(func) { printf("YES (1)\n"); free_svalue(func); free(func); return YES;}
  else if(has_objc_method(self, aSelector)) { printf("YES (2)\n"); return YES;}
  else { printf("NO\n");  return NO; }
}

- (NSString *)description
{
	id desc;
	push_text("%O");
	ref_push_object(pobject);
	f_sprintf(2);
	desc = [NSString stringWithUTF8String: Pike_sp[-1].u.string->str];
	pop_stack();
  return desc;	
}

@end 

/*! @endclass
 */

/*! @endmodule
 */

/*! @endmodule
 */
