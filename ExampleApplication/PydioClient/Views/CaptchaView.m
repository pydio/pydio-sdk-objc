
//  CaptchaView.m
//  PydioClient
//
//  Created by Michal Kloczko on 11/03/14.
//  Copyright (c) 2014 Pydio. All rights reserved.
//

#import "CaptchaView.h"

@interface CaptchaView ()
@property (nonatomic,weak) UILabel *label;
@property (nonatomic,weak) UIView *contentView;
@property (nonatomic,weak) UIImageView *captchaImageView;
@property (nonatomic,weak) UITextField *captchaTextField;
@property (nonatomic,weak) UIButton *cancelButton;
@property (nonatomic,weak) UIButton *sendButton;
@property (nonatomic,copy) void(^sendBlock)(NSString *captcha);
@property (nonatomic,copy) void(^cancelBlock)();
@end

@implementation CaptchaView

-(instancetype)initWithImage:(NSData *)data send:(void(^)(NSString *captcha))send cancel:(void(^)())cancel  {
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        self.sendBlock = send;
        self.cancelBlock = cancel;
        [self setupContentView];
        [self setupLabel];
        [self setupCaptchaView:data];
        [self setupInputView];
        [self setupButtons];
    }
    return self;
}

-(void)setupContentView {
    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = [UIColor whiteColor];
    contentView.layer.cornerRadius = 5;
    [self addSubview:contentView];
    self.contentView = contentView;
}

-(void)setupLabel {
    UILabel *label = [[UILabel alloc] init];
    label.text = NSLocalizedString(@"Please provide captcha:", @"Captcha View");
    [label setFont:[UIFont systemFontOfSize:12]];
    [self.contentView addSubview:label];
    self.label = label;
}

-(void)setupCaptchaView:(NSData*)data {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:data]];
    [self.contentView addSubview:imageView];
    self.captchaImageView = imageView;
}

-(void)setupInputView {
    UITextField *textField = [[UITextField alloc] init];
    
    [textField setFont:[UIFont systemFontOfSize:12]];
    [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    [textField setReturnKeyType:UIReturnKeySend];
    textField.delegate = self;
    
    [self.contentView addSubview:textField];
    self.captchaTextField = textField;
}

-(void)setupButtons {
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cancelButton setTitle:NSLocalizedString(@"Cancel", @"Captcha View") forState:UIControlStateNormal];
 
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sendButton setTitle:NSLocalizedString(@"Send", @"Captcha View") forState:UIControlStateNormal];
    
    [self.contentView addSubview:cancelButton];
    [self.contentView addSubview:sendButton];
    
    self.cancelButton = cancelButton;
    self.sendButton = sendButton;
    
    [self.cancelButton addTarget:self action:@selector(cancelClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton addTarget:self action:@selector(sendClicked) forControlEvents:UIControlEventTouchUpInside];
}

-(void)show {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[UIApplication sharedApplication].delegate.window addSubview:self];
    [self.captchaTextField becomeFirstResponder];
}

-(void)hide {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.captchaTextField resignFirstResponder];
    [self removeFromSuperview];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    [self.label sizeToFit];
    [self.captchaImageView sizeToFit];
    [self.captchaTextField sizeToFit];
    [self.cancelButton sizeToFit];
    [self.sendButton sizeToFit];
    
    CGFloat maxWidth = CGRectGetWidth(self.frame) < CGRectGetHeight(self.frame) ? CGRectGetWidth(self.frame) : CGRectGetHeight(self.frame);
    maxWidth *= 0.8;
    
    CGFloat totalWidth = CGRectGetWidth(self.frame)*0.6f;
    if (CGRectGetWidth(self.captchaImageView.frame) > totalWidth)
        totalWidth = CGRectGetWidth(self.captchaImageView.frame);
    
    if (totalWidth > maxWidth)
        totalWidth = maxWidth;
    
    CGFloat totalHeight = CGRectGetHeight(self.label.frame) + CGRectGetHeight(self.captchaImageView.frame) + CGRectGetHeight(self.captchaTextField.frame) + CGRectGetHeight(self.cancelButton.frame);
    CGFloat top = 0;
    
    CGRect rect = self.label.frame;
    rect = CGRectMake((CGRectGetWidth(self.frame) - totalWidth)/2,CGRectGetMinY(self.contentView.frame) ,totalWidth, totalHeight);
//    NSLog(@"%s %f %f %f %f",__PRETTY_FUNCTION__,rect.origin.x,rect.origin.y,CGRectGetWidth(rect),CGRectGetHeight(rect));
    self.contentView.frame = rect;
    
    rect = self.label.frame;
    rect.origin = CGPointMake((CGRectGetWidth(self.contentView.frame) - CGRectGetWidth(self.label.frame))/2,top);
    self.label.frame = rect;
    top += CGRectGetHeight(rect);

    rect = self.captchaImageView.frame;
    rect.origin = CGPointMake(rect.origin.x,top);
    self.captchaImageView.frame = rect;
    top += CGRectGetHeight(rect);
    
    rect = self.captchaTextField.frame;
    rect.origin = CGPointMake(rect.origin.x,top);
    rect.size.width = totalWidth;
    self.captchaTextField.frame = rect;
    top += CGRectGetHeight(rect);
    
    rect = self.cancelButton.frame;
    rect.origin = CGPointMake(rect.origin.x,top);
    rect.size.width = totalWidth/2;
    self.cancelButton.frame = rect;
    
    rect = self.sendButton.frame;
    rect.origin = CGPointMake(CGRectGetWidth(self.cancelButton.frame),top);
    rect.size.width = totalWidth/2;
    self.sendButton.frame = rect;
}

#pragma mark - Keyboard notification

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    CGRect rect = self.contentView.frame;
    rect.origin.y = (CGRectGetHeight(self.frame) - kbSize.height - CGRectGetHeight(self.contentView.frame))/2;
    self.contentView.frame = rect;
}

#pragma mark - UITextFielDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendClicked];
    
    return YES;
}

#pragma mark - Buttons

-(void)cancelClicked {
    if (self.cancelBlock)
        self.cancelBlock();
    
    [self hide];
}

-(void)sendClicked {
    if (self.captchaTextField.text.length == 0)
        return;
    
    if (self.sendBlock)
        self.sendBlock(self.captchaTextField.text);
    
    [self hide];
    
}

-(void)dealloc {
    NSLog(@"%s",__PRETTY_FUNCTION__);
}
@end
