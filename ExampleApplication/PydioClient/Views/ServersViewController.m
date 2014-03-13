//
//  ViewController.m
//  PydioSDK
//
//  Created by MINI on 21.12.2013.
//  Copyright (c) 2013 MINI. All rights reserved.
//

#import "ServersViewController.h"
#import "ServersParamsManager.h"
#import "User.h"
#import "PydioClient.h"
#import "Workspace.h"
#import "ServerWorkspacesViewController.h"
#import "CaptchaView.h"


static NSString * const TABLE_CELL_ID = @"ServerCell";
static NSString * const SERVER_CONTENT_SEGUE = @"ServerContent";


@interface ServersViewController ()
@property(nonatomic,strong) NSArray *servers;
@end

@implementation ServersViewController

#pragma mark - ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.dataSource = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    self.servers = [[ServersParamsManager sharedManager] serversList];
    [self.tableView reloadData];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:SERVER_CONTENT_SEGUE]) {
        int row = [self.tableView indexPathForSelectedRow].row;
        
        ServerWorkspacesViewController *serverWorkspaces = segue.destinationViewController;
        serverWorkspaces.server = [self.servers objectAtIndex:row];
    }
}

#pragma mark - UITableViewDataSource

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TABLE_CELL_ID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TABLE_CELL_ID];
    }
    
    cell.textLabel.text = [[self.servers objectAtIndex:indexPath.row] absoluteString];
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.servers.count;
}

@end
