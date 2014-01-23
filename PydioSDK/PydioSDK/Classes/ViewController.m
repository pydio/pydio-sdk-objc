//
//  ViewController.m
//  PydioSDK
//
//  Created by MINI on 21.12.2013.
//  Copyright (c) 2013 MINI. All rights reserved.
//

#import "ViewController.h"
#import "CookieManager.h"
#import "User.h"
#import "PydioClient.h"


@interface ViewController ()
@property(nonatomic,strong) PydioClient *client;
@end

@implementation ViewController

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
}

- (IBAction)pressMeClicked:(id)sender {
    if ([self isUsernameAndPassEntered]) {
        CookieManager *manager = [CookieManager sharedManager];
        User* user = [User userWithId:self.username.text AndPassword:self.password.text];
        [manager setUser:user ForServer:self.client.serverURL];
        
        [self.client listFilesWithSuccess:^(NSArray *files) {
            NSLog(@"success %s %@",__PRETTY_FUNCTION__,files);
        } failure:^(NSError *error) {
            NSLog(@"failure %s %@",__PRETTY_FUNCTION__,error);
        }];
    }
}

-(BOOL)isUsernameAndPassEntered
{
    return self.username.text.length && self.password.text.length;
}

#pragma mark - ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.client = [[PydioClient alloc] initWithServer:@"http://sandbox.ajaxplorer.info/"];
    
    [self setupGestureRecognizerForDissmissingKeyboard];
    [self.button setTitle:@"Login" forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
