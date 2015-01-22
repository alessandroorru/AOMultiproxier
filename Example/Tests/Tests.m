//
//  AOMultiproxierTests.m
//  AOMultiproxierTests
//
//  Created by Alessandro Orrù on 01/21/2015.
//  Copyright (c) 2014 Alessandro Orrù. All rights reserved.
//

#import <AOMultiproxier/AOMultiproxier.h>
#import <UIKit/UIKit.h>
#import <OCMock/OCMock.h>

#import "AOTestProtocol.h"
#import "AOTestStrictDelegateObject.h"


SpecBegin(InitialSpecs)
describe(@"AOMultiproxier", ^{
    __block AOMultiproxier <AOTestProtocol> * multiproxier;
    
    beforeEach(^{
        multiproxier = AOMultiproxierForProtocol(AOTestProtocol);
    });

    describe(@"attaching an object", ^{
        it(@"should have no effects if no object is provided", ^{
            [multiproxier attachObject:nil];
            expect(multiproxier.attachedObjects.count).to.equal(0);
        });
        
        it(@"should have no effects if an object that doesn't conform to the given protocol is attached", ^{
            NSObject * anyObject = [[NSObject alloc] init];
            [multiproxier attachObject:anyObject];
            expect(multiproxier.attachedObjects.count).to.equal(0);
        });

        it(@"should attach an object if a valid one is provided", ^{
            AOTestStrictDelegateObject * delegateObject1 = [[AOTestStrictDelegateObject alloc] init];
            [multiproxier attachObject:delegateObject1];
            expect(multiproxier.attachedObjects.count).to.equal(1);
            
            AOTestStrictDelegateObject * delegateObject2 = [[AOTestStrictDelegateObject alloc] init];
            [multiproxier attachObject:delegateObject2];
            expect(multiproxier.attachedObjects.count).to.equal(2);
        });
        
        it(@"should not attach an object if it is already attached", ^{
            AOTestStrictDelegateObject * delegateObject = [[AOTestStrictDelegateObject alloc] init];
            [multiproxier attachObject:delegateObject];
            [multiproxier attachObject:delegateObject];
            expect(multiproxier.attachedObjects.count).to.equal(1);
        });
    });
    
    describe(@"attaching multiple objects", ^{
        it(@"should have no effects if no array is provided", ^{
            [multiproxier attachObjects:nil];
            expect(multiproxier.attachedObjects.count).to.equal(0);
        });
        
        it(@"should have no effects if an empty is provided", ^{
            [multiproxier attachObjects:@[]];
            expect(multiproxier.attachedObjects.count).to.equal(0);
        });

        it(@"should include only the valid objects", ^{
            AOTestStrictDelegateObject * delegateObject = [[AOTestStrictDelegateObject alloc] init];
            NSObject * invalidObject = [NSObject new];
            [multiproxier attachObjects:@[delegateObject, invalidObject]];
            expect(multiproxier.attachedObjects.count).to.equal(1);
        });
    });
    
    describe(@"detaching all objects", ^{
        it(@"should clear the attached objects", ^{
            AOTestStrictDelegateObject * delegateObject1 = [[AOTestStrictDelegateObject alloc] init];
            AOTestStrictDelegateObject * delegateObject2 = [[AOTestStrictDelegateObject alloc] init];
            [multiproxier attachObjects:@[delegateObject1, delegateObject2]];
            [multiproxier detachAllObjects];
            expect(multiproxier.attachedObjects.count).to.equal(0);
        });
    });
    
    describe(@"detaching an object", ^{
        __block AOTestStrictDelegateObject * attachedObject;
        
        beforeEach(^{
            attachedObject = [[AOTestStrictDelegateObject alloc] init];
            [multiproxier attachObject:attachedObject];
        });
        
        it(@"should have no effect if no object is provided", ^{
            [multiproxier detachObject:nil];
            expect(multiproxier.attachedObjects.count).to.equal(1);
        });
        
        it(@"should have no effect if an unattached object is provided", ^{
            NSObject * unattachedObject = [[NSObject alloc] init];
            [multiproxier detachObject:unattachedObject];
            expect(multiproxier.attachedObjects.count).to.equal(1);
        });
        
        it(@"should detach an object if an attached one is provided", ^{
            [multiproxier detachObject:attachedObject];
            expect(multiproxier.attachedObjects.count).to.equal(0);
        });
    });
    
    describe(@"attached objects array", ^{
        it(@"should be a empty if no object is attached", ^{
            expect(multiproxier.attachedObjects.count).to.equal(0);
        });
        
        it(@"should contain only the right objects if some are provided", ^{
            AOTestStrictDelegateObject * attachedObject = [[AOTestStrictDelegateObject alloc] init];
            [multiproxier attachObject:attachedObject];
            expect(multiproxier.attachedObjects.count).to.equal(1);
            expect([multiproxier.attachedObjects containsObject:attachedObject]).to.equal(true);
        });
    });
    
    describe(@"each attached object", ^{

        it(@"should receive method calls performed on multiproxier", ^{
            id protocolMock = OCMStrictProtocolMock(@protocol(AOTestProtocol));
            [multiproxier attachObject:protocolMock];

            OCMExpect([protocolMock call]);
            OCMExpect([protocolMock callWithReturnValue]);
            OCMExpect([protocolMock optionalCall]);
            
            [multiproxier call];
            [multiproxier callWithReturnValue];
            [multiproxier optionalCall];
            
            OCMVerifyAll(protocolMock);
        });
        
        it(@"should receive also method calls of ancestor protocols performed on multiproxier", ^{
            AOMultiproxier <UICollectionViewDelegateFlowLayout> * multiproxier = AOMultiproxierForProtocol(UICollectionViewDelegateFlowLayout);
            
            id cvProtocolMock = OCMStrictProtocolMock(@protocol(UICollectionViewDelegateFlowLayout));
            id svProtocolMock = OCMStrictProtocolMock(@protocol(UIScrollViewDelegate));
            [multiproxier attachObject:cvProtocolMock];
            [multiproxier attachObject:svProtocolMock];
            
            OCMExpect([cvProtocolMock collectionView:nil layout:nil sizeForItemAtIndexPath:nil]);
            OCMExpect([cvProtocolMock scrollViewDidScroll:OCMOCK_ANY]);
            OCMExpect([svProtocolMock scrollViewDidScroll:OCMOCK_ANY]);
            
            if ([multiproxier respondsToSelector:@selector(scrollViewDidScroll:)]) {
                [multiproxier scrollViewDidScroll:nil];
            }
            if ([multiproxier respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
                [multiproxier collectionView:nil layout:nil sizeForItemAtIndexPath:nil];
            }
            
            OCMVerifyAll(cvProtocolMock);
            OCMVerifyAll(svProtocolMock);
        });

        it(@"should give a return value if the method returns it", ^{
            id protocolMock = OCMStrictProtocolMock(@protocol(AOTestProtocol));
            OCMStub([protocolMock callWithReturnValue]).andReturn(@(1));
            
            id protocolMock2 = OCMPartialMock([[AOTestStrictDelegateObject alloc] init]);
            [[protocolMock2 reject] callWithReturnValue];

            [multiproxier attachObject:protocolMock];
            [multiproxier attachObject:protocolMock2];

            NSNumber * returnValue = [multiproxier callWithReturnValue];
            expect([returnValue integerValue]).to.equal(1);
        });
        
        
        it(@"optional methods should be called only if implemented", ^{
            id protocolMock = OCMPartialMock([[AOTestStrictDelegateObject alloc] init]);
            OCMStub([protocolMock callWithReturnValue]).andReturn(@(1));
            [[protocolMock reject] optionalCall];

            [multiproxier attachObject:protocolMock];

            [multiproxier optionalCall];
            
            OCMVerifyAll(protocolMock);
        });
    });
});

SpecEnd
