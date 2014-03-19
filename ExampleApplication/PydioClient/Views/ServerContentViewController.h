//
//  ServerContentViewController.h
//  PydioSDK
//
//  Created by ME on 04/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WorkspaceResponse;
@class NodeResponse;

@interface ServerContentViewController : UITableViewController

@property (nonatomic,strong) NSURL *server;
@property (nonatomic,strong) WorkspaceResponse *workspace;
@property (nonatomic,strong) NodeResponse* rootNode;

- (IBAction)addDirClicked:(id)sender;
@end
