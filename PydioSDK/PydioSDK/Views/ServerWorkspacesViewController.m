//
//  ServerWorkspacesViewController.m
//  PydioSDK
//
//  Created by ME on 04/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "ServerWorkspacesViewController.h"
#import "Workspace.h"
#import "PydioClient.h"
#import "ServerContentViewController.h"


static NSString * const TABLE_CELL_ID = @"TableCell";


@interface ServerWorkspacesViewController ()
@property (nonatomic,strong) NSArray* workspaces;
@end

@implementation ServerWorkspacesViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated {
    self.navigationItem.title = [self.server absoluteString];
    
    PydioClient *client = [[PydioClient alloc] initWithServer:[self.server absoluteString]];
    [client listWorkspacesWithSuccess:^(NSArray *files) {
        self.workspaces = files;
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error);
    }];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.workspaces.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TABLE_CELL_ID forIndexPath:indexPath];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TABLE_CELL_ID];
    }
    
    cell.textLabel.text = ((Workspace*)[self.workspaces objectAtIndex:indexPath.row]).label;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    int row = [self.tableView indexPathForSelectedRow].row;
    
    ServerContentViewController *destination = segue.destinationViewController;
    destination.workspace = (Workspace*)[self.workspaces objectAtIndex:row];
    destination.server = self.server;
    destination.path = @"/";
   
}

@end
