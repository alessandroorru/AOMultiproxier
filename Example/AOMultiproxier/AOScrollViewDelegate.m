//
//  AOScrollViewDelegate.m
//  AOMultiproxier
//
//  Created by Alessandro Orrù on 22/01/15.
//  Copyright (c) 2015 Alessandro Orrù. All rights reserved.
//

#import "AOScrollViewDelegate.h"

@implementation AOScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.label.text = [NSString stringWithFormat:@"%.2f", scrollView.contentOffset.y];
}
@end
