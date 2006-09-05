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
 * $Id: PiObjCObject.m,v 1.2 2006-09-05 23:37:56 hww3 Exp $
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

#import  <Foundation/NSObject.h>
#import  <Foundation/NSMethodSignature.h>
#import  <Foundation/NSInvocation.h>
#import "PiObjCObject.h"

@implementation PiObjCObject

+(id) newWithPikeObject:(struct object *) obj
{                       
        id instance;
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

- (void)dealloc
{
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
  struct callable * func;
  SEL sel;

  sel = [anInvocation selector];

  printf("PiObjCObject.forwardInvocation: %s", (char *)sel );

  if(sel == @selector(description))
  {
	  id res = [self description];   
	  [anInvocation setReturnValue:&res];
  }

  if(sel == @selector(_copyDescription))
  {
	  id res = [self _copyDescription];   
	  [anInvocation setReturnValue:&res];
  }

  if(sel == @selector(respondsToSelector:))
  {
      SEL     sel2;
      BOOL    b;

      [anInvocation getArgument:&sel2 atIndex:2];
   	  b = [self respondsToSelector: sel2];
	  [anInvocation setReturnValue:&args];
  }


  func = get_func_by_selector(pobject, sel);

  if(func) // jackpot!
  {
	void * buf = NULL;
    buf = malloc(sizeof(int));
    (*(int *)buf) = 2;
    sig = [anInvocation methodSignature];
    args = push_objc_types(sig, anInvocation);
    apply_svalue(&Pike_sp[0-(args+1)], args);
//    [anInvocation setReturnValue:&buf];
  }  
  else
  {
    [NSException raise:NSInvalidArgumentException format:@"no such selector: %s", (char *)[anInvocation selector]];	
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

  printf("PiObjCObject.methodSignatureForSelector: %s\n", (char *)aSelector);
  // first, we perty up the selector.
  func = get_func_by_selector(pobject, aSelector);
  argcount = get_argcount_by_selector(pobject, aSelector);
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