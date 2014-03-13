//
//  UIView+CaptchaView.h
//  PydioClient
//
//  Created by Michal Kloczko on 14/03/14.
//  Copyright (c) 2014 Pydio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (CaptchaView)
-(void)showCaptchaView:(NSData*)image Send:(void(^)(NSString *captcha))send Cancel:(void(^)())cancel;
@end
