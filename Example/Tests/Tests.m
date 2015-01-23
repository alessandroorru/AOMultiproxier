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

    describe(@"create a multiproxier", ^{

        it(@"should attach all objects if they conform to the main protocol", ^{
            id obj1 = OCMStrictProtocolMock(@protocol(AOTestProtocol));
            id obj2 = OCMStrictProtocolMock(@protocol(AOTestProtocol));
            id obj3 = OCMStrictProtocolMock(@protocol(AOTestProtocol));
            AOMultiproxier <AOTestProtocol> * multiproxier = AOMultiproxierForProtocol(AOTestProtocol, obj1, obj2, obj3);

            expect(multiproxier.attachedObjects.count).to.equal(3);
        });
        
        it(@"should attach all objects if they conform to the main protocol or to ancestors", ^{
            id obj1 = OCMStrictProtocolMock(@protocol(UITableViewDelegate));
            id obj2 = OCMStrictProtocolMock(@protocol(UIScrollViewDelegate));
            id obj3 = OCMStrictProtocolMock(@protocol(UIScrollViewDelegate));
            AOMultiproxier <UITableViewDelegate> * multiproxier = AOMultiproxierForProtocol(UITableViewDelegate, obj1, obj2, obj3);
            
            expect(multiproxier.attachedObjects.count).to.equal(3);
        });

        it(@"should attach only the objects that conform (or inherit a conforming protocol)", ^{
            id obj1 = OCMStrictProtocolMock(@protocol(AOTestProtocol));
            id obj2 = OCMStrictProtocolMock(@protocol(AOTestProtocol));
            id obj3 = [NSObject new];
            AOMultiproxier <AOTestProtocol> * multiproxier = AOMultiproxierForProtocol(AOTestProtocol, obj1, obj2, obj3);

            expect(multiproxier.attachedObjects.count).to.equal(2);
        });

        it(@"should return nil if no objects are provided", ^{
            AOMultiproxier <AOTestProtocol> * multiproxier = AOMultiproxierForProtocol(AOTestProtocol, nil);
            expect(multiproxier).to.beNil;
            
            multiproxier = AOMultiproxierForProtocol(AOTestProtocol, @[]);
            expect(multiproxier).to.beNil;
        });
        
        it(@"should return nil if there isn't at least one object that conforms to the main protocol", ^{
            id obj1 = OCMStrictProtocolMock(@protocol(UIScrollViewDelegate));
            id obj2 = OCMStrictProtocolMock(@protocol(UIScrollViewDelegate));
            AOMultiproxier <UITableViewDelegate> * multiproxier = AOMultiproxierForProtocol(UITableViewDelegate, obj1, obj2);
            
            expect(multiproxier).to.beNil;
        });
    });
    
    
    describe(@"each attached object", ^{

        it(@"should receive calls performed on multiproxier of methods defined on main protocol", ^{
            id protocolMock = OCMStrictProtocolMock(@protocol(AOTestProtocol));
            AOMultiproxier <AOTestProtocol> * multiproxier = AOMultiproxierForProtocol(AOTestProtocol, protocolMock);

            OCMExpect([protocolMock call]);
            OCMExpect([protocolMock callWithReturnValue]);
            OCMExpect([protocolMock optionalCall]);
            
            [multiproxier call];
            [multiproxier callWithReturnValue];
            [multiproxier optionalCall];
            
            OCMVerifyAll(protocolMock);
        });
        
        it(@"should receive calls performed on multiproxier of methods defined on protocol ancestors", ^{
            id cvProtocolMock = OCMStrictProtocolMock(@protocol(UICollectionViewDelegateFlowLayout));
            id svProtocolMock = OCMStrictProtocolMock(@protocol(UIScrollViewDelegate));

            AOMultiproxier <UICollectionViewDelegateFlowLayout> * multiproxier = AOMultiproxierForProtocol(UICollectionViewDelegateFlowLayout, cvProtocolMock, svProtocolMock);
            
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

        it(@"should return a value if the method returns it", ^{
            id protocolMock = OCMStrictProtocolMock(@protocol(AOTestProtocol));
            OCMStub([protocolMock callWithReturnValue]).andReturn(@(1));
            
            id protocolMock2 = OCMPartialMock([[AOTestStrictDelegateObject alloc] init]);
            [[protocolMock2 reject] callWithReturnValue];

            AOMultiproxier <AOTestProtocol> * multiproxier = AOMultiproxierForProtocol(AOTestProtocol, protocolMock, protocolMock2);

            NSNumber * returnValue = [multiproxier callWithReturnValue];
            expect([returnValue integerValue]).to.equal(1);
        });
        

        it(@"optional methods should be called only if implemented", ^{
            id protocolMock = OCMPartialMock([[AOTestStrictDelegateObject alloc] init]);
            OCMStub([protocolMock callWithReturnValue]).andReturn(@(1));
            [[protocolMock reject] optionalCall];

            AOMultiproxier <AOTestProtocol> * multiproxier = AOMultiproxierForProtocol(AOTestProtocol, protocolMock);

            [multiproxier optionalCall];
            
            OCMVerifyAll(protocolMock);
        });
    });
});

SpecEnd
