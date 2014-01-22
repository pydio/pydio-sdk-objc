//
//  AuthCredentials.h
//  PydioSDK
//
//  Created by ME on 08/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;

@interface AuthCredentials : NSObject
@property(readonly,nonatomic,strong) NSString* userid;
@property(readonly,nonatomic,strong) NSString* password;
@property(readonly,nonatomic,strong) NSString* seed;

+(instancetype)credentialsWith:(User*)user AndSeed:(NSString*)seed;
-(instancetype)initWith:(User*)user AndSeed:(NSString*)seed;
@end
