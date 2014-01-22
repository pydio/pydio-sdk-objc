//
//  AuthCredentials.m
//  PydioSDK
//
//  Created by ME on 08/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "AuthCredentials.h"
#import "User.h"

@implementation AuthCredentials

+(instancetype)credentialsWith:(User*)user AndSeed:(NSString*)seed {
    return [[AuthCredentials alloc] initWith:user AndSeed:seed];
}

-(instancetype)initWith:(User*)user AndSeed:(NSString*)seed {
    self = [super init];
    if (self) {
        _userid = user.userid;
        _password = user.password;
        _seed = seed;
    }
    
    return self;
}

@end
