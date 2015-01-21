//
//  AOTestProtocol.h
//  AOMultiproxier
//
//  Created by Alessandro Orrù on 21/01/15.
//  Copyright (c) 2015 Alessandro Orrù. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AOTestProtocol <NSObject>
- (void)call;

@optional
- (NSNumber*)callWithReturnValue;
- (void)optionalCall;
@end