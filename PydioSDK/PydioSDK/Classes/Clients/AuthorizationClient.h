//
//  AuthorizationClient.h
//  PydioSDK
//
//  Created by ME on 06/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AFHTTPRequestOperationManager;

typedef NS_ENUM(NSUInteger, AuthorizationState) {
    ASNone,
    ASPing
};

@interface AuthorizationClient : NSObject
@property (nonatomic,strong) AFHTTPRequestOperationManager *operationManager;
@property (readonly,nonatomic,assign) AuthorizationState state;
@property (readonly,nonatomic,assign) BOOL progress;
@property (readonly,nonatomic,strong) NSError *lastError;

-(BOOL)ping;
@end
