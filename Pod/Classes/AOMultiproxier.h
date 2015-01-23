//
//  AOMultiproxier.h
//  Pods
//
//  Created by Alessandro Orrù on 21/01/15.
//
//

#import <Foundation/Foundation.h>

#define AOMultiproxierForProtocol(__protocol__, ...) ((AOMultiproxier <__protocol__> *)[AOMultiproxier multiproxierForProtocol:@protocol(__protocol__) withObjects:((NSArray *)[NSArray arrayWithObjects:__VA_ARGS__,nil])])

@interface AOMultiproxier : NSProxy

@property (nonatomic, strong, readonly) Protocol * protocol;
@property (nonatomic, strong, readonly) NSArray * attachedObjects;

+ (instancetype)multiproxierForProtocol:(Protocol*)protocol withObjects:(NSArray*)objects;
@end
