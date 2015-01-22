//
//  AOTableViewDelegate.m
//  AOMultiproxier
//
//  Created by Alessandro Orrù on 22/01/15.
//  Copyright (c) 2015 Alessandro Orrù. All rights reserved.
//

#import "AOTableViewDelegate.h"

@implementation AOTableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Touched: %tu", indexPath.row);
}

@end
