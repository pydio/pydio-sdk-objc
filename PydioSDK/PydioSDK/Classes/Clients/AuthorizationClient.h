//
//  AuthorizationClient.h
//  PydioSDK
//
//  Created by ME on 06/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const PydioErrorDomain;

@class AFHTTPRequestOperationManager;
@class AuthCredentials;
@class LoginResponse;


@interface AuthorizationClient : NSObject
@property (nonatomic,strong) AFHTTPRequestOperationManager *operationManager;
@property (readonly,nonatomic,assign) BOOL progress;

-(BOOL)ping:(void(^)())success failure:(void(^)(NSError *error))failure;
-(BOOL)getSeed:(void(^)(NSString *seed))success failure:(void(^)(NSError *error))failure;
-(BOOL)loginWithCredentials:(AuthCredentials*)credentials success:(void(^)(LoginResponse *resposne))success failure:(void(^)(NSError *error))failure;
@end
