//
//  ServerContentViewController.h
//  PydioSDK
//
//  Created by ME on 04/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Workspace;

@interface ServerContentViewController : UIViewController<UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic,strong) NSURL *server;
@property (nonatomic,strong) Workspace *workspace;
@property (nonatomic,strong) NSString *path;
@end
