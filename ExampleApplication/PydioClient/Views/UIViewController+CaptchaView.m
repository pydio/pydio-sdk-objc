//
//  UIView+CaptchaView.m
//  PydioClient
//
//  Created by Michal Kloczko on 14/03/14.
//  Copyright (c) 2014 Pydio. All rights reserved.
//

#import "UIViewController+CaptchaView.h"
#import "CaptchaView.h"

@implementation UIViewController (CaptchaView)
-(void)showCaptchaView:(NSData*)image Send:(void(^)(NSString *captcha))send Cancel:(void(^)())cancel {
    CaptchaView *captchaView = [[CaptchaView alloc] initWithImage:image send:send cancel:cancel];
    
    [captchaView show];
}
@end
