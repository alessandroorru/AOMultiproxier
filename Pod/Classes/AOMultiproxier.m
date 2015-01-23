//
//  AOMultiproxier.m
//  Pods
//
//  Created by Alessandro Orrù on 21/01/15.
//
//

#import "AOMultiproxier.h"
#import <objc/runtime.h>

@interface AOMultiproxier()
@property (nonatomic, strong) dispatch_queue_t innerQueue;
@property (nonatomic, strong) Protocol * protocol;
@property (nonatomic, strong) NSMutableSet * objects;

@property (nonatomic, strong) NSCache * protocolCache;
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


#pragma mark - Forward methods
- (BOOL)respondsToSelector:(SEL)selector {
    BOOL responds = NO;
    BOOL isMandatory = NO;
    
    struct objc_method_description methodDescription = [self _methodDescriptionForSelector:selector isMandatory:&isMandatory];
    
    if (isMandatory) {
        responds = YES;
    }
    else if (methodDescription.name != NULL) {
        responds = [self _checkIfAttachedObjectsRespondToSelector:selector];
    }

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

    BOOL isMandatory = NO;
    struct objc_method_description methodDescription = [self _methodDescriptionForSelector:selector isMandatory:&isMandatory];
    
    if (methodDescription.name == NULL) {
        return nil;
    }
    
    theMethodSignature = [NSMethodSignature signatureWithObjCTypes:methodDescription.types];

    return theMethodSignature;
}



#pragma mark - Utility methods

- (struct objc_method_description)_methodDescriptionForSelector:(SEL)selector isMandatory:(BOOL *)isMandatory
{
    NSValue * cachedMethod = [self.protocolCache objectForKey:NSStringFromSelector(selector)];
    if (cachedMethod) {
        struct objc_method_description method;
        [cachedMethod getValue:&method];
        return method;
    }
    

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
    
    NSValue * boxedMethod = [NSValue valueWithBytes:&method objCType:@encode(struct objc_method_description)];
    [self.protocolCache setObject:boxedMethod forKey:NSStringFromSelector(selector)];
    
    return method;
}


- (struct objc_method_description)_methodDescriptionInProtocol:(Protocol *)protocol selector:(SEL)selector isMandatory:(BOOL *)isMandatory
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

