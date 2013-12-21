//
//  ViewController.m
//  PydioSDK
//
//  Created by MINI on 21.12.2013.
//  Copyright (c) 2013 MINI. All rights reserved.
//

#import "ViewController.h"
#import "PydioConnector.h"

@interface ViewController ()
@property (strong, nonatomic) PydioConnector* pydioConnector;
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
    if (self.pydioConnector.requestInProgress || ![self isUsernameAndPassEntered])
        return;
    
    //    if (self.pydioConnector.requestInProgress) {
    //        NSLog(@"%s Request in progress",__PRETTY_FUNCTION__);
    //    } else if (self.pydioConnector.secure_token == nil) {
    //        [self.pydioConnector requestSecureToken:^(BOOL result,NSString *error) {
    //            NSLog(@"%s result:%d token:%@ error:%@",__PRETTY_FUNCTION__,result,self.pydioConnector.secure_token,error);
    //        }];
    //    }
    //    else
    
    if (self.pydioConnector.seed == nil) {
        [self.pydioConnector requestSeed:^(BOOL result,NSString *error) {
            NSLog(@"%s result:%d error:%@",__PRETTY_FUNCTION__,result,error);
            
            if (result)
                [self.button setTitle:@"Login" forState:UIControlStateNormal];
        }];
    } else if (!self.pydioConnector.loggedIn) {
        [self.pydioConnector requestLoginWithUserName:self.username.text password:self.password.text resultBlock:^(BOOL success, NSString *error) {
            NSLog(@"%s error:%@",__PRETTY_FUNCTION__,error);
            
            if (success)
                [self.button setTitle:@"Logged" forState:UIControlStateNormal];
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
    [self setupGestureRecognizerForDissmissingKeyboard];
	self.pydioConnector = [[PydioConnector alloc] init];
    [self.button setTitle:@"Seed" forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
