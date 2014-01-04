//
//  LoginResponse.m
//  PydioSDK
//
//  Created by ME on 05/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "LoginResponse.h"

@implementation LoginResponse
-(instancetype)initWithValue:(NSString*)value AndToken:(NSString*)token {
    self = [super init];
    if (self) {
        if ([value compare:@"1"] == NSOrderedSame) {
            _value = LRValueOK;
        } else if ([value compare:@"-1"] == NSOrderedSame) {
            _value = LRValueFail;
        } else if ([value compare:@"-4"] == NSOrderedSame) {
            _value = LRValueLocked;
        }
        
        _secureToken = token;
    }
    
    return self;
}
@end
