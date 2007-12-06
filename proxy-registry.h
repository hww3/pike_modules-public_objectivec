/*!
 * @header   proxy-registry.h
 * @abstract Maintain a registry of proxied objects
 * @discussion
 * 	Object-identity is important in several Cocoa API's. For that
 * 	reason we need to make sure that at most one proxy object is 
 * 	alive for every Pike or Objective-C object.
 */
#ifndef PiObjC_PROXY_REGISTRY_H
#define PiObjC_PROXY_REGISTRY_H

int PiObjC_InitProxyRegistry(void);

int PiObjC_RegisterPikeProxy(id original, struct object * proxy);
int PiObjC_RegisterObjCProxy(struct object * original, id proxy);

void PiObjC_UnregisterPikeProxy(id original, struct object * proxy);
void PiObjC_UnregisterObjCProxy(struct object * original, id proxy);

id PiObjC_FindObjCProxy(struct object* original);
struct object * PiObjC_FindPikeProxy(id original);

#endif /* PiObjC_PROXY_REGISTRY_H */
