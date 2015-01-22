//
//  AOMultiproxier.h
//  Pods
//
//  Created by Alessandro Orrù on 21/01/15.
//
//

#import <Foundation/Foundation.h>

#define AOMultiproxierForProtocol(__protocol__) ((AOMultiproxier <__protocol__> *)[AOMultiproxier multiproxierForProtocol:@protocol(__protocol__)])

@interface AOMultiproxier : NSProxy

@property (nonatomic, strong, readonly) Protocol * protocol;
@property (nonatomic, strong, readonly) NSArray * attachedObjects;

+ (instancetype)multiproxierForProtocol:(Protocol*)protocol;
- (void)attachObject:(id)object;
- (void)attachObjects:(NSArray*)objects;

- (void)detachObject:(id)object;
- (void)detachAllObjects;
@end
