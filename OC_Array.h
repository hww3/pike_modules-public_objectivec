/*!
 * @header OC_Array.h 
 * @abstract Objective-C proxy class for Pike arrays
 * @discussion
 *     This file defines the class that is used to represent Pike arrays
 *     in Objective-C.
 */

#import "piobjc.h"
#import <Foundation/Foundation.h>

/*!
 * @class       OC_Array
 * @abstract    Objective-C proxy class for Pike arrays
 * @discussion  Instances of this class are used as proxies for Pike 
 * 	        arrays when these are passed to Objective-C code. Because 
 * 	        this class is a subclass of NSArray, Pike arrays 
 * 	        can be used everywhere where NSArray objects 
 * 	        are expected.
 */
@interface OC_Array : NSArray
{
	struct array * array;
}

/*!
 * @method newWithPikeObject:
 * @abstract Create a new OC_PikeArray for a specific Pike sequence
 * @param value A Pike sequence
 * @result Returns an autoreleased instance representing value
 *
 * Caller must own the GIL.
 */
+ newWithPikeArray:(struct array*)value;

/*!
 * @method initWithPikeObject:
 * @abstract Initialise a OC_PikeArray for a specific Pike sequence
 * @param value A Pike sequence
 * @result Returns self
 *
 * Caller must own the GIL.
 */
- initWithPikeArray:(struct array*)value;

/*!
 * @method dealloc
 * @abstract Deallocate the object
 */
-(void)dealloc;

/*!
 * @method dealloc
 * @abstract Access the wrapped Pike sequence
 * @result  Returns a new reference to the wrapped Pike sequence.
 */
-(struct array*)__ObjCgetPikeArray;

/*!
 * @method count
 * @result  Returns the length of the wrapped Pike sequence
 */
-(int)count;

/*!
 * @method objectAtIndex:
 * @param idx An index
 * @result  Returns the object at the specified index in the wrapped Pike
 *          sequence
 */
- (id)objectAtIndex:(int)idx;

/*!
 * @method replaceObjectAtIndex:withObject:
 * @abstract Replace the current value at idx by the new value
 * @discussion This method will raise an exception when the wrapped Pike
 *             sequence is immutable.
 * @param idx An index
 * @param newValue A replacement value
 */
-(void)replaceObjectAtIndex:(int)idx withObject:newValue;

/*!
 * @method getObjects:inRange:
 * @abstract Fetch objects in the specified range
 * @discussion The output buffer must have enough space to contain all
 *             requested objects, the range must be valid.
 *
 *             This method is not documented in the NSArray interface, but
 *             is used by Cocoa on MacOS X 10.3 when an instance of this
 *             class is used as the value for -setObject:forKey: in
 *             NSUserDefaults.
 * @param buffer  The output buffer
 * @param range   The range of objects to fetch.
 */
//-(void)getObjects:(id*)buffer inRange:(NSRange)range;

@end
