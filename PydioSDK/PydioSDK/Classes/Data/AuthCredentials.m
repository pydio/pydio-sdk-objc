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

-(BOOL) isEqual:(id)object {
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[AuthCredentials class]])
        return NO;
    
    AuthCredentials *converted = (AuthCredentials*)object;
    
    if (self.userid != converted.userid && ![self.userid isEqualToString:converted.userid]) {
        return NO;
    }

    if (self.password != converted.password && ![self.password isEqualToString:converted.password]) {
        return NO;
    }

    if (self.seed != converted.seed && ![self.seed isEqualToString:converted.seed]) {
        return NO;
    }
    
    return YES;
}

@end
