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

@interface AuthorizationClient : NSObject
@property (nonatomic,strong) AFHTTPRequestOperationManager *operationManager;
@property (readonly,nonatomic,assign) BOOL progress;

-(BOOL)authorizeWithSuccess:(void(^)())success failure:(void(^)(NSError *error))failure;
-(BOOL)loginWithSuccess:(void(^)())success failure:(void(^)(NSError *error))failure;
@end
