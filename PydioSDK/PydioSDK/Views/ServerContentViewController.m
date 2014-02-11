//
//  ServerContentViewController.m
//  PydioSDK
//
//  Created by ME on 04/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "ServerContentViewController.h"
#import "Node.h"
#import "PydioClient.h"
#import "Workspace.h"
#import "ListFilesRequest.h"


static NSString * const TABLE_CELL_ID = @"TableCell";

@implementation ServerContentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.activityIndicator stopAnimating];
    self.tableView.dataSource = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.rootNode.children.count) {
        [self listFiles];
    }
    
    self.navigationItem.title = self.workspace.label;
}

#pragma mark - UITableViewDataSource

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TABLE_CELL_ID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TABLE_CELL_ID];
    }
    
    cell.textLabel.text = [self fileNameAt:indexPath.row];
    cell.accessoryType = [self fileNodeAt:indexPath.row].isLeaf ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rootNode.children.count;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    int row = [self.tableView indexPathForSelectedRow].row;
    
    ServerContentViewController *destination = segue.destinationViewController;
    destination.workspace = self.workspace;
    destination.server = self.server;
    destination.rootNode = [self fileNodeAt:row];
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    int row = [self.tableView indexPathForSelectedRow].row;
    
    return ![self fileNodeAt:row].isLeaf;
}

#pragma mark - Helpers

-(void)listFiles {
    PydioClient *client = [[PydioClient alloc] initWithServer:[self.server absoluteString]];
    [client listNodes:[self listFilesRequest]
          WithSuccess:^(NSArray *files) {
              if (files.count) {
                  self.rootNode.children = ((Node*)[files objectAtIndex:0]).children;
                  [self.tableView reloadData];
              }
          } failure:^(NSError *error) {
              NSLog(@"%s %@",__PRETTY_FUNCTION__,error);
          }
     ];
}

-(ListFilesRequest*)listFilesRequest {
    ListFilesRequest *request = [[ListFilesRequest alloc] init];
    request.workspaceId = self.workspace.workspaceId;
    request.path = self.rootNode.fullPath;
//    request.additional = @{
//                           @"recursive": @"true",
//                           @"max_depth" : @"2"
//                           };

    return request;
}

-(NSString*)fileNameAt:(NSInteger)row {
    return [self fileNodeAt:row].name;
}

-(Node*)fileNodeAt:(NSInteger)row {
    return (Node*)[self.rootNode.children objectAtIndex:row];
}

@end
