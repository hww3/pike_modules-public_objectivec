/*!
 * @header OC_Mapping.h
 * @abstract Objective-C proxy for Pike mappings
 * @discussion
 *     This file defines the class that is used to proxy Pike
 *     mappings to Objective-C.
 */

#import "piobjc.h"
#import <Foundation/Foundation.h>

/*!
 * @class OC_Mapping
 * @abstract Objective-C proxy for Pike mappings
 * @discussion
 *      Instances of this class are used as proxies for Pike mappings when 
 *      these are passed to Objective-C functions/methods. Because this class 
 *      is a subclass of NSMutableDictonary Pike mappings can be used
 *      whereever instances of NSDictionary or NSMutableDictionary are expected.
 *
 */
@interface OC_Mapping : NSMutableDictionary
{
	struct mapping * mapping
}

/*!
 * @method newWithPikeObject:
 * @abstract Create a new autoreleased proxy object
 * @param value  A Pike dict
 * @result Returns an autoreleased proxy object for the Pike dict
 *
 * The caller must own the GIL.
 */
+ newWithPikeMapping:(struct mapping*)value;

/*!
 * @method initWithPikeObject:
 * @abstract Initialize a proxy object
 * @param value  A Pike dict
 * @result Returns self
 * @discussion
 *    Makes the proxy object a proxy for the specified Pike dict.
 *
 *    The caller must own the GIL.
 */
- initWithPikeMapping:(struct mapping*)value;

/*!
 * @method dealloc
 * @abstract Deallocate the object
 */
- (void)dealloc;

- (struct mapping *)__ObjCgetPikeMapping;

/*!
 * @method count
 * @abstract Find the number of elements in the mapping
 * @result Returns the size of the wrapped Pike mapping
 */
- (int)count;

/*
 * @method keyEnumerator
 * @abstract Enumerate all keys in the wrapped mapping
 * @result Returns an NSEnumerator instance for iterating over the keys
 */
- (NSEnumerator*)keyEnumerator;

/*
 * @method setObject:forKey:
 * @param object An object
 * @param key    A key, must be hashable.
 */
- (void)setObject:(id)object forKey:(id)key;

/*
 * @method removeObjectForKey:
 * @param key A key, must be hashable
 */
- (void)removeObjectForKey:(id)key;

/*
 * @method objectForKey:
 * @param key A key
 * @result Returns the object corresponding with key, or nil.
 */
- (id)objectForKey:(id)key;

@end /* interface OC_Mapping */
