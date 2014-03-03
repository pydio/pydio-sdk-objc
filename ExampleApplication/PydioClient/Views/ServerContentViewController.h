//
//  ServerContentViewController.h
//  PydioSDK
//
//  Created by ME on 04/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Workspace;
@class Node;

@interface ServerContentViewController : UITableViewController

@property (nonatomic,strong) NSURL *server;
@property (nonatomic,strong) Workspace *workspace;
@property (nonatomic,strong) Node* rootNode;

- (IBAction)addDirClicked:(id)sender;
@end
