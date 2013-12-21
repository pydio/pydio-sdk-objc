//
//  ViewController.h
//  PydioSDK
//
//  Created by MINI on 21.12.2013.
//  Copyright (c) 2013 MINI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIButton *button;

- (IBAction)pressMeClicked:(id)sender;

@end
