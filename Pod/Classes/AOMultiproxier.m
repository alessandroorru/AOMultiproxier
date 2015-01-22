//
//  AOMultiproxier.m
//  Pods
//
//  Created by Alessandro Orrù on 21/01/15.
//
//

#import "AOMultiproxier.h"
#import <objc/runtime.h>

#define CACHE_ENABLED 0

@interface AOMultiproxier()
@property (nonatomic, strong) dispatch_queue_t innerQueue;
@property (nonatomic, strong) Protocol * protocol;
@property (nonatomic, strong) NSMutableSet * objects;

#if CACHE_ENABLED
@property (nonatomic, assign) CFMutableDictionaryRef respondsToSelectorCache;
@property (nonatomic, assign) CFMutableDictionaryRef methodSignatureCache;
@property (nonatomic, assign) CFMutableDictionaryRef methodDescriptionCache;
#endif
@end

@implementation AOMultiproxier

+ (instancetype)multiproxierForProtocol:(Protocol*)protocol
{
    AOMultiproxier * multiproxier = [[super alloc] initWithProtocol:protocol];
    return multiproxier;
}

- (instancetype)initWithProtocol:(Protocol*)protocol
{
    _protocol = protocol;
    _objects = [NSMutableSet set];
    _innerQueue = dispatch_queue_create("com.alessandroorru.aomultiproxier", DISPATCH_QUEUE_SERIAL);
    
#if CACHE_ENABLED
    _respondsToSelectorCache = CFDictionaryCreateMutable(kCFAllocatorMalloc, 0, NULL, NULL);
    _methodSignatureCache = CFDictionaryCreateMutable(kCFAllocatorMalloc, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    _methodDescriptionCache = CFDictionaryCreateMutable(kCFAllocatorMalloc, 0, NULL, NULL);
#endif
    
    return self;
}

+ (BOOL)conformsToProtocol:(Protocol*)protocol
{
    return YES;
}

- (void)attachObject:(id)object
{
    if (object == nil) return;
    if (![self _object:object inheritsProtocolOrAncestorOfProtocol:self.protocol]) {
        NSLog(@"AOMultiproxier WARNING: tried to attach object %@ that doesn't conform to %@ or any of its ancestors", [object debugDescription], NSStringFromProtocol(self.protocol));
        return;
    }
    
    dispatch_sync(self.innerQueue, ^{
        [self.objects addObject:object];
    });
}

- (void)attachObjects:(NSArray *)objects
{
    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self attachObject:obj];
    }];
}

- (void)detachObject:(id)object
{
    if (!object) return;
    
    dispatch_sync(self.innerQueue, ^{
        [self.objects removeObject:object];
    });
}

- (void)detachAllObjects
{
    dispatch_sync(self.innerQueue, ^{
        _objects = [NSMutableSet set];
    });
}

- (NSArray *)attachedObjects
{
    __block NSArray * objects = nil;
    dispatch_sync(self.innerQueue, ^{
        objects = [self.objects allObjects];
    });
    return objects;
}

- (void)dealloc
{
#if CACHE_ENABLED
    CFRelease(_respondsToSelectorCache);
    _respondsToSelectorCache = NULL;
    
    CFRelease(_methodSignatureCache);
    _methodSignatureCache = NULL;
    
    CFRelease(_methodDescriptionCache);
    _methodDescriptionCache = NULL;
#endif
}


#pragma mark - Forward methods
- (BOOL)respondsToSelector:(SEL)selector {
#if CACHE_ENABLED
    CFBooleanRef cachedResponds = (CFBooleanRef)CFDictionaryGetValue(self.respondsToSelectorCache, selector);
    if (cachedResponds != NULL) {
        return CFBooleanGetValue(cachedResponds);
    }
#endif
    
    BOOL responds = NO;
    BOOL isMandatory = NO;
    
    struct objc_method_description methodDescription = [self _methodDescriptionForSelector:selector isMandatory:&isMandatory];
    
    if (isMandatory) {
        responds = YES;
    }
    else if (methodDescription.name != NULL) {
        responds = [self _checkIfAttachedObjectsRespondToSelector:selector];
    }

#if CACHE_ENABLED
    CFDictionarySetValue(self.respondsToSelectorCache, selector, responds ? kCFBooleanTrue : kCFBooleanFalse);
#endif
    return responds;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return protocol_conformsToProtocol(self.protocol, aProtocol);
}


- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    SEL selector = [anInvocation selector];

    BOOL isMandatory = NO;

    struct objc_method_description methodDescription = [self _methodDescriptionForSelector:selector isMandatory:&isMandatory];
    
    if (methodDescription.name == NULL) {
        [super forwardInvocation:anInvocation];
        return;
    }
    
    BOOL someoneResponded = NO;
    for (id object in self.objects) {
        if ([object respondsToSelector:selector]) {
            [anInvocation invokeWithTarget:object];
            someoneResponded = YES;
        }
    }

    // If a mandatory method has not been implemented by any attached object, this would provoke a crash
    if (isMandatory && !someoneResponded) {
        [super forwardInvocation:anInvocation];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature * theMethodSignature;

#if CACHE_ENABLED
    theMethodSignature = CFDictionaryGetValue(self.methodSignatureCache, selector);
    if (theMethodSignature != nil) {
        return theMethodSignature;
    }
#endif

    BOOL isMandatory = NO;
    struct objc_method_description methodDescription = [self _methodDescriptionForSelector:selector isMandatory:&isMandatory];
    
    if (methodDescription.name == NULL) {
        return nil;
    }
    
    theMethodSignature = [NSMethodSignature signatureWithObjCTypes:methodDescription.types];

#if CACHE_ENABLED
    CFDictionarySetValue(self.methodSignatureCache, selector, (__bridge const void *)(theMethodSignature));
#endif
    
    return theMethodSignature;
}



#pragma mark - Utility methods

- (struct objc_method_description)_methodDescriptionForSelector:(SEL)selector isMandatory:(BOOL *)isMandatory
{
#if CACHE_ENABLED
    struct objc_method_description * cachedMethodDescription = (struct objc_method_description *)CFDictionaryGetValue(self.methodDescriptionCache, selector);
    if (cachedMethodDescription != NULL) {
        return *cachedMethodDescription;
    }
#endif
    
    struct objc_method_description method = {NULL, NULL};
 
    // First check on main protocol
    method = [self _methodDescriptionInProtocol:self.protocol selector:selector isMandatory:isMandatory];
    
    // If no method is known on main protocol, try on ancestor protocols
    if (method.name == NULL) {
        unsigned int count = 0;
        Protocol * __unsafe_unretained * list = protocol_copyProtocolList(self.protocol, &count);
        for (NSUInteger i = 0; i < count; i++) {
            Protocol * aProtocol = list[i];

            // Skip root protocol
            if ([NSStringFromProtocol(aProtocol) isEqualToString:@"NSObject"]) continue;
            
            method = [self _methodDescriptionInProtocol:aProtocol selector:selector isMandatory:isMandatory];
            if (method.name != NULL) {
                break;
            }
        }
        free(list);
    }
    
#if CACHE_ENABLED
    struct objc_method_description * heapHold = malloc(sizeof * heapHold);
    if (heapHold == NULL) {
    } else {
        memcpy(heapHold, &method, sizeof *heapHold);
    }
    CFDictionarySetValue(self.methodDescriptionCache, selector, heapHold);
#endif
    
    return method;
}


- (struct objc_method_description)_methodDescriptionInProtocol:(Protocol *)protocol selector:(SEL)selector isMandatory:(BOOL *)isMandatory __attribute__((const))
{
    struct objc_method_description method = {NULL, NULL};

    method = protocol_getMethodDescription(protocol, selector, YES, YES);
    if (method.name != NULL) {
        *isMandatory = YES;
        return method;
    }
    
    method = protocol_getMethodDescription(protocol, selector, NO, YES);
    if (method.name != NULL) {
        *isMandatory = NO;
    }
    
    return method;
}



- (BOOL)_checkIfAttachedObjectsRespondToSelector:(SEL)selector
{
    for (id object in self.objects) {
        if ([object respondsToSelector:selector]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)_object:(id)object inheritsProtocolOrAncestorOfProtocol:(Protocol*)protocol
{
    if ([object conformsToProtocol:protocol]) {
        return YES;
    }
    
    BOOL conforms = NO;
    
    unsigned int count = 0;
    Protocol * __unsafe_unretained * list = protocol_copyProtocolList(protocol, &count);
    for (NSUInteger i = 0; i < count; i++) {
        Protocol * aProtocol = list[i];

        // Skip root protocol
        if ([NSStringFromProtocol(aProtocol) isEqualToString:@"NSObject"]) continue;
        
        if ([self _object:object inheritsProtocolOrAncestorOfProtocol:aProtocol]) {
            conforms = YES;
            break;
        }
    }
    free(list);
    
    return conforms;
}

@end

