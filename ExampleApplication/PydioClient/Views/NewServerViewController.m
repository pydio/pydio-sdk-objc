//
//  NewServerViewController.m
//  PydioSDK
//
//  Created by ME on 03/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "NewServerViewController.h"
#import "ServersParamsManager.h"
#import "User.h"


@interface NewServerViewController ()

@end

@implementation NewServerViewController

#pragma mark - UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupGestureRecognizerForDissmissingKeyboard];
    
    self.server.text = @"http://sandbox.ajaxplorer.info";
    self.username.text = @"michal";
    self.password.text = @"michalK1";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Interface builder

- (IBAction)addButtonPressed:(id)sender {
    if ([self isUsernameAndPassEntered]) {
        [self dismissKeyboardByRemovingFocus];
        ServersParamsManager *manager = [ServersParamsManager sharedManager];
        [manager clearAllCookies:[NSURL URLWithString:self.server.text]];
        [manager clearSecureToken:[NSURL URLWithString:self.server.text]];
        User* user = [User userWithId:self.username.text AndPassword:self.password.text];
        [manager setUser:user ForServer:[NSURL URLWithString:self.server.text]];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - 

- (void)setupGestureRecognizerForDissmissingKeyboard
{
    UITapGestureRecognizer *gRecognizer = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(dismissKeyboardByRemovingFocus)];
    [self.view addGestureRecognizer:gRecognizer ];
}

- (void)dismissKeyboardByRemovingFocus {
    [self.username resignFirstResponder];
    [self.password resignFirstResponder];
    [self.server resignFirstResponder];
}

-(BOOL)isUsernameAndPassEntered
{
    return self.username.text.length && self.password.text.length && self.server.text.length;
}

@end
