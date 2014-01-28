//
//  TestedPydioClient.h
//  PydioSDK
//
//  Created by ME on 28/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "PydioClient.h"

typedef void (^FailureBlock)(NSError *error);


static NSString * const TEST_SERVER_ADDRESS = @"http://www.testserver.com/";
static NSString * const TEST_USER_ID = @"testid";
static NSString * const TEST_USER_PASSWORD = @"testpassword";

static AFHTTPRequestOperationManager* operationManager = nil;
static AuthorizationClient* authorizationClient = nil;
static OperationsClient* operationsClient = nil;


#pragma mark - Deriving from Tested class

@interface PydioClient ()
@property(nonatomic,strong) AFHTTPRequestOperationManager* operationManager;
@property (readwrite,nonatomic,assign) BOOL progress;
@end

@interface TestedPydioClient : PydioClient
@end

@implementation TestedPydioClient

-(AuthorizationClient*)createAuthorizationClient {
    return authorizationClient;
}

-(AFHTTPRequestOperationManager*)createOperationManager:(NSString*)server {
    return operationManager;
}

-(OperationsClient*)createOperationsClient {
    return operationsClient;
}
@end
