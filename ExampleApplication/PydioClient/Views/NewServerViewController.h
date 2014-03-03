//
//  NewServerViewController.h
//  PydioSDK
//
//  Created by ME on 03/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewServerViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *server;
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;

- (IBAction)addButtonPressed:(id)sender;
@end
