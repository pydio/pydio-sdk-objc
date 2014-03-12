//
//  CaptchaView.m
//  PydioClient
//
//  Created by Michal Kloczko on 11/03/14.
//  Copyright (c) 2014 Pydio. All rights reserved.
//

#import "CaptchaView.h"

@interface CaptchaView ()
@property (nonatomic,weak) UIView *contentView;
@property (nonatomic,weak) UIImageView *captchaImageView;
@property (nonatomic,weak) UITextField *captchaTextField;
@property (nonatomic,weak) UIButton *cancelButton;
@property (nonatomic,weak) UIButton *sendButton;
@end

@implementation CaptchaView

-(instancetype)init {
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        [self setupContentView];
        [self setupCaptchaView];
        [self setupInputView];
        [self setupButtons];
    }
    
    return self;
}

-(void)setupContentView {
    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = [UIColor redColor];
    [self addSubview:contentView];
    self.contentView = contentView;
}

-(void)setupCaptchaView {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TOOLBAR.png"]];
    [self addSubview:imageView];
    self.captchaImageView = imageView;
}

-(void)setupInputView {
    UITextField *textField = [[UITextField alloc] init];
    
    [textField setFont:[UIFont systemFontOfSize:12]];
    [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    [textField setReturnKeyType:UIReturnKeySend];
    
    [self addSubview:textField];
    self.captchaTextField = textField;
}

-(void)setupButtons {
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cancelButton setTitle:NSLocalizedString(@"Cancel", @"Captcha View") forState:UIControlStateNormal];
 
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sendButton setTitle:NSLocalizedString(@"Send", @"Captcha View") forState:UIControlStateNormal];
    
    [self addSubview:cancelButton];
    [self addSubview:sendButton];
    
    self.cancelButton = cancelButton;
    self.sendButton = sendButton;
}

-(void)show {
    [[UIApplication sharedApplication].delegate.window addSubview:self];
    [self.captchaTextField becomeFirstResponder];
}

-(void)hide {
    [self removeFromSuperview];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGFloat left = 20;
    CGFloat top = 20;
    CGFloat width = [UIImage imageNamed:@"TOOLBAR.png"].size.width;
    CGRect rect = CGRectMake(left, top, CGRectGetWidth(self.bounds)-40, CGRectGetHeight(self.bounds)/4);
    self.contentView.frame = rect;
    
    CGFloat totalPadding = CGRectGetWidth(rect) - width;
    if (totalPadding < 0) {
        totalPadding = 0;
    }
    
    left += totalPadding/2;
    top +=5;
    rect = CGRectMake(left, top, width, [UIImage imageNamed:@"TOOLBAR.png"].size.height);
    self.captchaImageView.frame = rect;
    top += CGRectGetHeight(rect) + 5;
    
    [self.captchaTextField sizeToFit];
    
    rect = CGRectMake(left, top, width, CGRectGetHeight(self.captchaTextField.bounds));
    self.captchaTextField.frame = rect;
    top += CGRectGetHeight(rect);
    
    [self.cancelButton sizeToFit];
    rect = CGRectMake(left, top, CGRectGetWidth(self.cancelButton.bounds), CGRectGetHeight(self.cancelButton.bounds));
    self.cancelButton.frame = rect;
    
    left += CGRectGetWidth(self.cancelButton.bounds);
    [self.sendButton sizeToFit];
    rect = CGRectMake(left, top, CGRectGetWidth(self.sendButton.bounds), CGRectGetHeight(self.sendButton.bounds));
    self.sendButton.frame = rect;
}

@end
