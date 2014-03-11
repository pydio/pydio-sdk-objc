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

@end

@implementation CaptchaView

-(instancetype)init {
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        UIView *contentView = [[UIView alloc] init];
        contentView.backgroundColor = [UIColor redColor];
        [self addSubview:contentView];
        self.contentView = contentView;
        
    }
    
    return self;
}

-(void)show {
    [[UIApplication sharedApplication].delegate.window addSubview:self];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = CGRectMake(20, 20, CGRectGetWidth(self.bounds)-40, CGRectGetHeight(self.bounds)/4);
    self.contentView.frame = rect;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
