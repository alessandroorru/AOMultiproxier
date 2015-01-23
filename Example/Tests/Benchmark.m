//
//  Benchmark.m
//  AOMultiproxier
//
//  Created by Alessandro Orrù on 22/01/15.
//  Copyright (c) 2015 Alessandro Orrù. All rights reserved.
//

#import "Benchmark.h"
#import "AOTestStrictDelegateObject.h"

#import <AOMultiproxier/AOMultiproxier.h>

#define ITERATIONS 1000000

@interface Benchmark()
@property (nonatomic, strong) AOTestStrictDelegateObject * delegate1;
@property (nonatomic, strong) AOTestStrictDelegateObject * delegate2;
@end


@implementation Benchmark

- (void)setUp
{
    [super setUp];
    
    self.delegate1 = [[AOTestStrictDelegateObject alloc] init];
    self.delegate2 = [[AOTestStrictDelegateObject alloc] init];
}

- (void)testPerformSelectorWithSingleCalls
{
    [self measureBlock:^{
        for (int i=0; i<ITERATIONS; i++) {
            [self.delegate1 call];
            [self.delegate2 call];
        }
    }];
}

- (void)testPerformSelectorWithSingleCallsWithSelectorCheck
{
    [self measureBlock:^{
        for (int i=0; i<ITERATIONS; i++) {
            if ([self.delegate1 respondsToSelector:@selector(call)]) {
                [self.delegate1 call];
            }
            if ([self.delegate2 respondsToSelector:@selector(call)]) {
                [self.delegate2 call];
            }
        }
    }];
}


- (void)testPerformSelectorWithMultiproxier
{
    AOMultiproxier <AOTestProtocol> * multiproxier = AOMultiproxierForProtocol(AOTestProtocol, (@[self.delegate1, self.delegate2]));

    [self measureBlock:^{
        for (int i=0; i<ITERATIONS; i++) {
            [multiproxier call];
        }
    }];
}

@end
