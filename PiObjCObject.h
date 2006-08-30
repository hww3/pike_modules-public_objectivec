#import <Foundation/NSProxy.h>

@interface PiObjCObject : NSProxy
{
	struct object * pobject;
}

/* we have to impliment these at the very least */
– (void)forwardInvocation:(NSInvocation *)anInvocation;
– (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;

/* plus an initialization method */
- initWithPikeObject:(struct object *)obj;
+ newWithPikeObject:(struct object *) obj;

/* some other housekeeping methods */
- (void)dealloc;
- (NSString *)description

@end