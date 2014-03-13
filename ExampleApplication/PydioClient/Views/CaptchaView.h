//
//  CaptchaView.h
//  PydioClient
//
//  Created by Michal Kloczko on 11/03/14.
//  Copyright (c) 2014 Pydio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CaptchaView : UIView <UITextFieldDelegate>
-(instancetype)initWithImage:(NSData *)data send:(void(^)(NSString *captcha))send cancel:(void(^)())cancel;
-(void)show;
@end
