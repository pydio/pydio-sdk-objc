//
//  ViewController.m
//  PydioSDK
//
//  Created by MINI on 21.12.2013.
//  Copyright (c) 2013 MINI. All rights reserved.
//

#import "ServersViewController.h"
#import "CookieManager.h"
#import "User.h"
#import "PydioClient.h"
#import "Workspace.h"
#import "ServerContentViewController.h"


static NSString * const TABLE_CELL_ID = @"RegisterCell";
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
//    self.client = [[PydioClient alloc] initWithServer:@"http://sandbox.ajaxplorer.info/"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    self.servers = [[CookieManager sharedManager] serversList];
    [self.tableView reloadData];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:SERVER_CONTENT_SEGUE]) {
        int row = [self.tableView indexPathForSelectedRow].row;
        
        ServerContentViewController *serverContent = segue.destinationViewController;
        serverContent.server = [self.servers objectAtIndex:row];
    }
}

#pragma mark - UITableViewDataSource

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TABLE_CELL_ID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TABLE_CELL_ID];
    }
    
    cell.textLabel.text = [self.servers objectAtIndex:indexPath.row];
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.servers.count;
}

@end
