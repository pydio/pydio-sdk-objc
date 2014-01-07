//
//  AuthCredentials.h
//  PydioSDK
//
//  Created by ME on 08/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AuthCredentials : NSObject
@property(nonatomic,strong) NSString* userid;
@property(nonatomic,strong) NSString* password;
@property(nonatomic,strong) NSString* seed;
@end
