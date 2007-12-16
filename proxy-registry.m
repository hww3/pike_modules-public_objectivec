#include "piobjc.h"

static NSMapTable* pike_proxies = NULL;
static NSMapTable* objc_proxies = NULL;

int PiObjC_InitProxyRegistry(void)
{
	pike_proxies = NSCreateMapTable(
			PiObjCUtil_PointerKeyCallBacks,
			PiObjCUtil_PointerValueCallBacks,
			500);
	if (pike_proxies == NULL) {
		Pike_error("Cannot create NSMapTable for pike_proxies");
		return -1;
	}

	objc_proxies = NSCreateMapTable(
			PiObjCUtil_PointerKeyCallBacks,
			PiObjCUtil_PointerValueCallBacks,
			500);
	if (objc_proxies == NULL) {
		Pike_error("Cannot create NSMapTable for objc_proxies\n");
		return -1;
	}
	return 0;
}

int PiObjC_RegisterPikeProxy(id original, struct object * proxy)
{
#ifdef DEBUG
	printf("registering pi proxy: id: %p, po: %p\n", original, proxy);
#endif

	NSMapInsert(pike_proxies, original, proxy);
	NSMapInsert(objc_proxies, proxy, original);
	return 0;
}

int PiObjC_RegisterObjCProxy(struct object * original, id proxy)
{
#ifdef DEBUG
	printf("registering oc proxy: id: %p, po: %p\n", proxy, original);
#endif

	NSMapInsert(objc_proxies, original, proxy);
	NSMapInsert(pike_proxies, proxy, original);
	return 0;
}

void PiObjC_UnregisterPikeProxy(id original, struct object * proxy)
{
	struct object * v;

#ifdef DEBUG
	printf("unregistering pi proxy: id: %p, po: %p\n", original, proxy);
#endif

	if (original == nil) return;

	v = NSMapGet(pike_proxies, original);
	if (v == proxy) {
		NSMapRemove(pike_proxies, original);
	}

	v = NSMapGet(objc_proxies, proxy);
	if (v == proxy) {
		NSMapRemove(objc_proxies, proxy);
	}

}

void PiObjC_UnregisterObjCProxy(struct object * original, id proxy)
{
	id v;
#ifdef DEBUG	
	printf("unregistering oc proxy: id: %p, po: %p\n", proxy, original);
#endif

	if (original == NULL) return;

	v = NSMapGet(objc_proxies, original);
	if (v == proxy) {
		NSMapRemove(objc_proxies, original);
	}

	v = NSMapGet(pike_proxies, proxy);
	if (v == proxy) {
		NSMapRemove(pike_proxies, proxy);
	}
	
}

void describe_proxy()
{
	NSMapEnumerator e;
	void * key;
	void * val;

	printf("%p has entries.\n", pike_proxies);

	e = NSEnumerateMapTable(pike_proxies);

	while(NSNextMapEnumeratorPair(&e,&key,&val))
	{
		printf("k: %p, v: %p %d\n", key, val, ((struct object *)val)->refs);
	}
}

struct object * PiObjC_FindPikeProxy(id original)
{
	struct object * v;
	NSMapEnumerator e;
	void * key;
	void * val;
	

#ifdef DEBUG
	printf("looking for proxy, id: %p\n", original);

	describe_proxy();

#endif
	
    if (original == nil) {
        v = NULL;
    } else {
        v = NSMapGet(pike_proxies, original);
    }
	return v;
}

id PiObjC_FindObjCProxy(struct object * original)
{
	struct object * v;
	NSMapEnumerator e;
	void * key;
	void * val;
	
#ifdef DEBUG
	printf("looking for proxy, po: %p\n", original);
	printf("%p has entries.\n", pike_proxies);

	e = NSEnumerateMapTable(pike_proxies);

	while(NSNextMapEnumeratorPair(&e,&key,&val))
	{
		printf("k: %p, v: %p\n", key, val);
	}
#endif

    if (original == NULL) {
        return nil;
    } else {
        return NSMapGet(objc_proxies, original);
    }
}
