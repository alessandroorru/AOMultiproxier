//
//  AOTextOwnerObject.h
//  AOMultiproxier
//
//  Created by Alessandro Orrù on 21/01/15.
//  Copyright (c) 2015 Alessandro Orrù. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AOTestProtocol.h"

@interface AOTestOwnerObject : NSObject
@property (nonatomic, weak) id <AOTestProtocol> delegate;
@end
