//
//  AOTableViewDelegate.m
//  AOMultiproxier
//
//  Created by Alessandro Orrù on 22/01/15.
//  Copyright (c) 2015 Alessandro Orrù. All rights reserved.
//

#import "AOTableViewDelegate.h"
#import <AOMultiproxier/AOMultiproxier.h>

@protocol AOTestP
- (void)call;
@end


@interface AOTableViewDelegate() <AOTestP>
@end


@implementation AOTableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Touched: %tu", indexPath.row);
    
    if (indexPath.row == 0) {
        
        AOMultiproxier <AOTestP> * mp = AOMultiproxierForProtocol(AOTestP);
        [mp attachObject:self];
        
        for (int i=0; i<1000000; i++) {
            [mp call];
        }
    }
}

- (void)call
{
}
@end
