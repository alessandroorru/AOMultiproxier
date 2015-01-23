//
//  AOViewController.m
//  AOMultiproxier
//
//  Created by Alessandro Orrù on 01/22/2015.
//  Copyright (c) 2014 Alessandro Orrù. All rights reserved.
//

#import <AOMultiproxier/AOMultiproxier.h>

#import "AOViewController.h"
#import "AOTableViewDelegate.h"
#import "AOScrollViewDelegate.h"

@interface AOViewController () <UITableViewDataSource>
@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) IBOutlet UILabel * offsetLabel;

@property (nonatomic, strong) AOMultiproxier <UITableViewDelegate> * multiproxyDelegate;

@property (nonatomic, strong) AOTableViewDelegate * tableViewDelegate;
@property (nonatomic, strong) AOScrollViewDelegate * scrollViewDelegate;
@end


@implementation AOViewController
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.scrollViewDelegate = [[AOScrollViewDelegate alloc] init];
    self.scrollViewDelegate.label = self.offsetLabel;
    
    self.tableViewDelegate = [[AOTableViewDelegate alloc] init];

    self.multiproxyDelegate = AOMultiproxierForProtocol(UITableViewDelegate, self.scrollViewDelegate, self.tableViewDelegate);
    
    self.tableView.delegate = self.multiproxyDelegate;
    self.tableView.dataSource = self;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * reuseIdentifier = @"Cell";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%tu", indexPath.row];
    
    return cell;
}

@end
