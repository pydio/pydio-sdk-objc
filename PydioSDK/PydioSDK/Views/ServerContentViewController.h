//
//  ServerContentViewController.h
//  PydioSDK
//
//  Created by ME on 03/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Workspace;


@interface ServerContentViewController : UITableViewController
@property (nonatomic,strong) NSURL *server;
@property (nonatomic,strong) Workspace *workspace;
@property (nonatomic,strong) NSString *path;
@end