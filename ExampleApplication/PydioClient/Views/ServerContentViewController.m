//
//  ServerContentViewController.m
//  PydioSDK
//
//  Created by ME on 04/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "ServerContentViewController.h"
#import "NodeResponse.h"
#import "PydioClient.h"
#import "WorkspaceResponse.h"
#import "ListNodesRequestParams.h"
#import "MkDirRequestParams.h"
#import "DeleteNodesRequestParams.h"
#import "CaptchaView.h"
#import "DownloadNodesRequestParams.h"
#import "UploadNodesRequestParams.h"


static NSString * const TABLE_CELL_ID = @"TableCell";
static NSString * const SHOW_DIR_CONTENT = @"ShowDirContent";


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

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteNode:[self fileNodeAt:indexPath.row]];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if (![segue.identifier isEqualToString:SHOW_DIR_CONTENT]) {
        return;
    }
    
    int row = [self.tableView indexPathForSelectedRow].row;
    
    ServerContentViewController *destination = segue.destinationViewController;
    destination.workspace = self.workspace;
    destination.server = self.server;
    destination.rootNode = [self fileNodeAt:row];
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if (![identifier isEqualToString:SHOW_DIR_CONTENT]) {
        return YES;
    }
    
    int row = [self.tableView indexPathForSelectedRow].row;
    
    return ![self fileNodeAt:row].isLeaf;
}

#pragma mark - Helpers

-(PydioClient*)pydioClient {
    PydioClient *client = [[PydioClient alloc] initWithServer:[self.server absoluteString]];
    [client setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        NSLog(@"download progress %s bytesRead: %d totalBytesRead: %lld totalBytesExpectedToRead: %lld",__PRETTY_FUNCTION__,bytesRead,totalBytesRead,totalBytesExpectedToRead);
    }];
    [client setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        NSLog(@"upload progress %s bytesWritten: %d totalBytesWritten: %lld totalBytesExpectedToWrite: %lld",__PRETTY_FUNCTION__,bytesWritten,totalBytesWritten,totalBytesExpectedToWrite);
    }];

    return client;
}

-(void)listFiles {
    PydioClient *client = [self pydioClient];
    [client listNodes:[self listFilesRequest]
          WithSuccess:^(NSArray *files) {
              if (files.count) {
                  self.rootNode.children = ((NodeResponse*)[files objectAtIndex:0]).children;
                  [self.tableView reloadData];
              }
          } failure:^(NSError *error) {
              NSLog(@"%s %@",__PRETTY_FUNCTION__,error);
          }
     ];
}

-(ListNodesRequestParams*)listFilesRequest {
    ListNodesRequestParams *request = [[ListNodesRequestParams alloc] init];
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

-(NodeResponse*)fileNodeAt:(NSInteger)row {
    return (NodeResponse*)[self.rootNode.children objectAtIndex:row];
}

#pragma mark - Add Directory

- (IBAction)addDirClicked:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add directory:"
                                                     message:@"Please provide directory name"
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Add", nil];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1 && [alertView textFieldAtIndex:0].text.length) {
        [self mkDir:[alertView textFieldAtIndex:0].text];
    }
}

-(void)mkDir:(NSString*)dirname {
    PydioClient *client = [self pydioClient];
    [client mkdir:[self mkdirRequestParams:dirname] WithSuccess:^(id ignored){
        [self listFiles];
    } failure:^(NSError *error) {
        NSLog(@"%s FAILURE: %@",__PRETTY_FUNCTION__,error);
    }];
}

-(MkDirRequestParams*)mkdirRequestParams:(NSString*)dirname {
    MkDirRequestParams *params = [[MkDirRequestParams alloc] init];
    params.workspaceId = self.workspace.workspaceId;
    params.dir = self.rootNode.fullPath;
    params.dirname = dirname;
    
    return params;
}

-(void)deleteNode:(NodeResponse*)node {
    PydioClient *client = [self pydioClient];
    [client deleteNodes:[self deleteNodeParams:node] WithSuccess:^{
        [self listFiles];
    } failure:^(NSError *error) {
        NSLog(@"%s FAILURE: %@",__PRETTY_FUNCTION__,error);
    }];    
}

-(DeleteNodesRequestParams *)deleteNodeParams:(NodeResponse*)node {
    DeleteNodesRequestParams *params = [[DeleteNodesRequestParams alloc] init];
    params.workspaceId = self.workspace.workspaceId;
    params.nodes = [NSArray arrayWithObject:node.fullPath];
    
    return params;
}

-(DownloadNodesRequestParams*)downloadNodesRequest:(NodeResponse*)node {
    DownloadNodesRequestParams *request = [[DownloadNodesRequestParams alloc] init];
    request.workspaceId = self.workspace.workspaceId;
    request.nodes = [NSArray arrayWithObject:node.fullPath];
    
    return request;
}

@end
