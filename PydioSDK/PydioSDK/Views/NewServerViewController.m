//
//  NewServerViewController.m
//  PydioSDK
//
//  Created by ME on 03/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "NewServerViewController.h"
#import "CookieManager.h"
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
        CookieManager *manager = [CookieManager sharedManager];
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
