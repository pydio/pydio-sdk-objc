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
#import "Node.h"
#import "ServerContentViewController.h"
#import "PydioErrors.h"
#import "UIViewController+CaptchaView.h"


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
    [self listWorkspaces];
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
    destination.rootNode = [[Node alloc] init];
    destination.rootNode.path = @"/";
   
}

#pragma mark - Helpers

-(PydioClient *)pydioClient {
    return [[PydioClient alloc] initWithServer:[self.server absoluteString]];
}

-(void)listWorkspaces {
    [[self pydioClient] listWorkspacesWithSuccess:^(NSArray *files) {
        self.workspaces = files;
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        if (error.code == PydioErrorGetSeedWithCaptcha || error.code == PydioErrorLoginWithCaptcha) {
            [self loadCaptcha];
        }
    }];
}

-(void)loadCaptcha {
    
    dispatch_block_t cancelCaptchaBlock = ^{
        [self.navigationController popViewControllerAnimated:YES];
    };
    
    void(^loginSuccessBlock)(id ignored) = ^(id ignored) {
        [self listWorkspaces];
    };
    
    void(^getCaptchaFailureBlock)(NSError *error) = ^(NSError *error) {
        NSLog(@"%s Login with captcha failure %@",__PRETTY_FUNCTION__,error);
        cancelCaptchaBlock();
    };

    void(^loginFailureBlock)(NSError *error) = ^(NSError *error) {
        NSLog(@"%s Login with captcha failure %@",__PRETTY_FUNCTION__,error);
        cancelCaptchaBlock();
    };
    
    void(^sendCaptchaBlock)(NSString *captcha) =  ^(NSString *captcha){
        [[self pydioClient] login:captcha WithSuccess:loginSuccessBlock failure:loginFailureBlock];
    };
    
    void(^getCapcthaSuccessBlock)(NSData *captcha) = ^(NSData *captcha) {
        [self showCaptchaView:captcha Send:sendCaptchaBlock Cancel:cancelCaptchaBlock];
    };
    
    [[self pydioClient] getCaptchaWithSuccess:getCapcthaSuccessBlock failure:getCaptchaFailureBlock];
}

@end
