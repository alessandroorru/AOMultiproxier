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
@end

@implementation AOMultiproxier

+ (instancetype)multiproxierForProtocol:(Protocol*)protocol
{
    AOMultiproxier * multiproxier = [[super alloc] initWithProtocol:protocol];
    return multiproxier;
}

+ (BOOL)conformsToProtocol:(Protocol*)protocol
{
    return YES;
}

- (instancetype)initWithProtocol:(Protocol*)protocol
{
    _protocol = protocol;
    _objects = [NSMutableSet set];
    _innerQueue = dispatch_queue_create("com.alessandroorru.aomultiproxier", DISPATCH_QUEUE_SERIAL);
    return self;
}

- (void)attachObject:(id)object
{
    if (object == nil) return;
    if (![object conformsToProtocol:self.protocol]) return;
    
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
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    SEL selector = [anInvocation selector];
    BOOL isMandatory = NO;

    struct objc_method_description methodDescription = [self methodDescriptionForSelector:selector isMandatory:&isMandatory];
    
    if (methodDescription.name == NULL) {
        [super forwardInvocation:anInvocation];
        return;
    }
    
    for (id object in self.attachedObjects) {
        if (isMandatory || [object respondsToSelector:selector]) {
            [anInvocation invokeWithTarget:object];
        }
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    BOOL isMandatory = NO;
    struct objc_method_description methodDescription = [self methodDescriptionForSelector:aSelector isMandatory:&isMandatory];
    
    if (methodDescription.name == NULL) {
        return nil;
    }
    
    NSMethodSignature * theMethodSignature = [NSMethodSignature signatureWithObjCTypes:methodDescription.types];
    
    return theMethodSignature;
}

- (struct objc_method_description) methodDescriptionForSelector:(SEL)selector isMandatory:(BOOL *)isMandatory
{
    struct objc_method_description mandatoryMethod = protocol_getMethodDescription(self.protocol, selector, YES, YES);
    if (mandatoryMethod.name != NULL) {
        *isMandatory = YES;
        return mandatoryMethod;
    }
    
    *isMandatory = NO;
    return protocol_getMethodDescription(self.protocol, selector, NO, YES);
}
@end
