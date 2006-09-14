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
 * $Id: PiObjCObject.m,v 1.7 2006-09-14 23:10:47 hww3 Exp $
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

#include "piobjc.h"
#import <pthread.h>
#import  <Foundation/NSObject.h>
#import  <Foundation/NSMethodSignature.h>
#import  <Foundation/NSInvocation.h>
#import "PiObjCObject.h"

@implementation PiObjCObject

+(id) newWithPikeObject:(struct object *) obj
{                       
  id instance;
  add_ref(obj);
  instance = (id)get_NSObject_from_Object(obj);
  if(instance == NULL) 
  {
    instance = [[self alloc] initWithPikeObject:obj];
    [instance autorelease];
  }        
  return instance;
}

- (id)initWithPikeObject:(struct object *)obj
{
  printf("PiObjCObject.initWithPikeObject\n");
  pobject = obj;
  add_ref(obj);
//  [self retain];
  return self;
}

- (id)retain
{
  printf("PiObjCObject.retain()\n");
  add_ref(pobject);
  return [super retain];
}

- (void)dealloc
{
  printf("PiObjCObject.dealloc()\n");
  free_object(pobject);
  [super dealloc];
}

- (BOOL)isProxy
{
  return YES;	
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



  [anInvocation retain];
  sel = [anInvocation selector];

  printf("PiObjCObject.forwardInvocation: %s\n", (char *)sel );

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

void dispatch_pike_method(struct object * pobject, SEL sel, NSInvocation * anInvocation)
{
  int args;
  struct svalue * func;
  id sig;
  
  func = get_func_by_selector(pobject, sel);
  printf("have func.\n");
  if(func) // jackpot!
  {
    void * buf = NULL;
    pthread_t tid;

    sig = [anInvocation methodSignature];
    args = push_objc_types(sig, anInvocation);
    tid = pthread_self();
    printf("pushed types, thread=%d\n", (int)tid);
    apply_svalue(func, args);

// now, we should deal with the return value.
    printf("dealing with the return value for call to %s\n", (char *) sel);
    piobjc_set_return_value(sig, anInvocation, &Pike_sp[-1]);
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
	return pobject;
}

// we use a really, really lame method for calculating the number of arguments
// to a method: we count the number of colons. it's ugly, and it would be 
// far better to parse the type information for the argument count. that, 
// however, would be a lot of work, and i'm not up for that right now.
- (NSMethodSignature *) methodSignatureForSelector: (SEL)aSelector
{
  char * encoding;
  struct callable * func;
  int argcount = 0;
  struct thread_state *state;
//  printf("PiObjCObject.methodSignatureForSelector: %s\n", (char *)aSelector);

  if((state = thread_state_for_id(th_self()))!=NULL)
  {
    /* This is a pike thread.  Do we have the interpreter lock? */
    if(!state->swapped)
    {
//printf("methodSignatureForSelector: in pike thread, with the lock.\n");
      /* Yes.  Go for it... */
      func = get_func_by_selector(pobject, aSelector);
      argcount = get_argcount_by_selector(pobject, aSelector);
    }
    else
    {
//printf("methodSignatureForSelector: in pike thread, getting the lock.\n");
      /* Nope, let's get it... */
      mt_lock_interpreter();
      SWAP_IN_THREAD(state);
      // first, we perty up the selector.
      func = get_func_by_selector(pobject, aSelector);
      argcount = get_argcount_by_selector(pobject, aSelector);
      /* Restore */
      SWAP_OUT_THREAD(state);
      mt_unlock_interpreter();
     }
   }
   else
   {
//printf("methodSignatureForSelector: not in pike thread.\n");
      /* Not a pike thread.  Create a temporary thread_id... */
      struct object *thread_obj;
//      printf("creating a temporary thread.\n");
      mt_lock_interpreter();
//printf("got the lock.\n");
      init_interpreter();
      Pike_interpreter.stack_top=((char *)&state)+ (thread_stack_size-16384) * STACK_DIRECTION;
      Pike_interpreter.recoveries = NULL;
      thread_obj = fast_clone_object(thread_id_prog);
      INIT_THREAD_STATE((struct thread_state *)(thread_obj->storage +
                                                  thread_storage_offset));
      num_threads++;
      thread_table_insert(Pike_interpreter.thread_state);

      func = get_func_by_selector(pobject, aSelector);
      argcount = get_argcount_by_selector(pobject, aSelector);

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



  if(func)
  {
    encoding = alloca(argcount+4);
    memset(encoding, '@', argcount+3);
    encoding[argcount+3] = '\0';
    encoding[2] = ':';
printf("encoding: %s\n", encoding);
    return [NSMethodSignature signatureWithObjCTypes:encoding];
  }  
  else
  {
    [NSException raise:NSInvalidArgumentException format:@"no such selector: %s", (char *)aSelector];	
  }

}

- (BOOL) respondsToSelector:(SEL) aSelector
{
  struct callable * func;
  printf("respondsToSelector: %s\n", (char*) aSelector);

  has_objc_method(self, aSelector);

  func = get_func_by_selector(pobject, aSelector);
  if(func) return YES;
  else return NO;
}

- (NSString *)description
{
  return @"Foo";	
}

@end 

/*! @endclass
 */

/*! @endmodule
 */

/*! @endmodule
 */