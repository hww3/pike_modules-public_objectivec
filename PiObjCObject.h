#import <Foundation/NSProxy.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSMethodSignature.h>

@interface PiObjCObject : NSProxy
{
	struct object * pobject;
	struct program * pprogram;
	bool pinstantiated;
}

+ (id)newWithPikeObject:(struct object *) obj;

- (void)forwardInvocation:(NSInvocation *) anInvocation;
- (NSMethodSignature *)methodSignatureForSelector:(SEL) aSelector;

/* plus an initialization method */
- (id)initWithPikeObject:(struct object *)obj;
- (struct object *) getPikeObject;
//- (id)init;
- (struct object *)__ObjCgetPikeObject;
+(id)alloc;
+(id)allocWithZone:(id) zone;

/* some other housekeeping methods */
- (void)dealloc;
- (NSString *)description;
- (NSString*) _copyDescription;
- (BOOL) isProxy;
- (BOOL) __ObjCisPikeType;
-(int)__ObjCgetPikeType;
@end