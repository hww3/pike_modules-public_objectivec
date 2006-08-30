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
 * $Id: PiObjCObject.m,v 1.1 2006-08-30 02:28:07 hww3 Exp $
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
#include "PiObjCObject.h"

#import  <Foundation/NSObject.h>
#import  <Foundation/NSMethodSignature.h>
#import  <Foundation/NSInvocation.h>
#import "PiObjCObject.h"

@implementation PiObjCObject

+ newWithPikeObject:(struct object *) obj
{                       
        id instance;
		instance = get_NSObject_from_Object(obj);
        if(instance != NULL) 
        {
          instance = [[self alloc] initWithPikeObject:obj];
          [instance autorelease];
        }        
        return instance;
}

- initWithPikeObject:(struct object *)obj
{
  pobject = obj;
  add_ref(obj);
}

- (void)dealloc()
{
  free_object(obj);
  [super dealloc];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
  char * argt;
  char * funname;
  int funlen;
  int arg;
  id sig;

  // first, we perty up the selector.
  funlen = strlen((char *)[anInvocation selector]);

  funname = malloc(funlen);

  if(funname == NULL)
  {
    Pike_error("unable to allocate selector storage.\n");
  }

  strncpy(funname, (char *)[anInvocation selector], funlen);

  for(ind = 0; ind < funlen; ind++)
  {
    if(funame[ind] == ':')
      funname[ind] = '_';
  }  
  funname[ind] = '\0';

  push_object(pobject);

  // do we need to do this?
  add_ref(pobject);
  push_text(funname);

  f_index(2);

  if(Pike_sp[-1].type == PIKE_T_FUNCTION) // jackpot!
  {
    sig = [anInvocation methodSignature];

    for(arg = 0; arg < [anInvocation numberOfArguments];arg++)
    {
	  // now, we push the argth argument onto the stack.
	  argt = [sig getArgumentTypeAtIndex: arg];
	  
	}
  }  
  else
  {
    [NSException raise:NSInvalidArgumentException format:@"no such selector: %s", funname];	
  }
  	
}

// we use a really, really lame method for calculating the number of arguments
// to a method: we count the number of colons. it's ugly, and it would be 
// far better to parse the type information for the argument count. that, 
// however, would be a lot of work, and i'm not up for that right now.
– (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
  char * funname;
  int funlen;
  char * encoding;
  int argcount;

  // first, we perty up the selector.
  funlen = strlen((char *)aSelector);

  funname = malloc(funlen);

  if(funname == NULL)
  {
    Pike_error("unable to allocate selector storage.\n");
  }

  strncpy(funname, aSelector, funlen);
  
  for(ind = 0; ind < funlen; ind++)
  {
    if(funame[ind] == ':')
      funname[ind] = '_';
      argcount++;
  }  
  funname[ind] = '\0';

  push_object(pobject);

  // do we need to do this?
  add_ref(pobject);
  push_text(funname);

  f_index(2);

  if(Pike_sp[-1].type == PIKE_T_FUNCTION) // jackpot!
  {
    	 
    encoding = alloca(argcount+4);
    memset(encoding, '@', argcount+3);
    encoding[argcount+3] = '\0';
    encoding[2] = ':';

    return [NSMethodSignature signatureWithObjCTypes:encoding];
  }  
  else
  {
    [NSException raise:NSInvalidArgumentException format:@"no such selector: %s", funname];	
  }

}

@end 

/*! @endclass
 */

/*! @endmodule
 */

/*! @endmodule
 */