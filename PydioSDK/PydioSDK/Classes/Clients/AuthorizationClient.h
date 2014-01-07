//
//  AuthorizationClient.h
//  PydioSDK
//
//  Created by ME on 06/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const PydioErrorDomain;

typedef NS_ENUM(NSUInteger, AuthorizationState) {
    ASNone,
    ASPing,
    ASGetSeed,
    ASLogin
};

@class AFHTTPRequestOperationManager;
@class AuthCredentials;


@interface AuthorizationClient : NSObject
@property (nonatomic,strong) AFHTTPRequestOperationManager *operationManager;
@property (readonly,nonatomic,assign) AuthorizationState state;
@property (readonly,nonatomic,assign) BOOL progress;
@property (readonly,nonatomic,strong) NSError *lastError;

-(BOOL)ping;
-(BOOL)getSeed;
-(BOOL)loginWithCredentials:(AuthCredentials*)credentials;
@end
