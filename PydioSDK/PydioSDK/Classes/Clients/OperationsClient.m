//
//  OperationsClient.m
//  PydioSDK
//
//  Created by ME on 14/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "OperationsClient.h"
#import "AFHTTPRequestOperationManager.h"
#import "CookieManager.h"
#import "XMLResponseSerializer.h"
#import "XMLResponseSerializerDelegate.h"
//#import "NotAuthorizedResponseSerializer.h"
//#import "RepositoriesResponseSerializer.h"
#import "NotAuthorizedResponse.h"
#import "PydioErrors.h"

extern NSString * const PydioErrorDomain;

@interface OperationsClient ()
@property (readwrite,nonatomic,assign) BOOL progress;

-(NSString*)urlStringForGetRegisters;
@end

@implementation OperationsClient
-(BOOL)listWorkspacesWithSuccess:(void(^)(NSArray *files))success failure:(void(^)(NSError *error))failure {
    if (self.progress) {
        return NO;
    }
    self.progress = YES;
    
    NSString *listRegisters = [self urlStringForGetRegisters];
    self.operationManager.requestSerializer = [self defaultRequestSerializer];
    self.operationManager.responseSerializer = [self responseSerializer];
    
    [self.operationManager GET:listRegisters parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.progress = NO;
        NSError *error = [self authorizationError:responseObject];
        if (error) {
            failure(error);
        } else if (((NSArray*)responseObject).count == 0) {
            NSError *error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
            failure(error);
        } else {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.progress = NO;
        failure(error);
    }];
    
    
    return YES;
}

#pragma mark -

-(NSString*)urlStringForGetRegisters {
    NSString *secureToken = [[CookieManager sharedManager] secureTokenForServer:self.operationManager.baseURL];

    NSString *base = @"index.php?get_action=get_xml_registry";
    if (secureToken) {
        base = [base stringByAppendingFormat:@"&secure_token=%@",secureToken];
    }
    base = [base stringByAppendingString:@"&xPath=user/repositories"];
    
    return base;
}

-(AFHTTPRequestSerializer*)defaultRequestSerializer {
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    [serializer setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    [serializer setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [serializer setValue:@"en-us" forHTTPHeaderField:@"Accept-Language"];
    [serializer setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    [serializer setValue:@"true" forHTTPHeaderField:@"Ajxp-Force-Login"];
    [serializer setValue:@"ajaxplorer-ios-client/1.0" forHTTPHeaderField:@"User-Agent"];
    
    return serializer;
}

-(AFHTTPResponseSerializer*)responseSerializer {
    
    NSMutableArray *serializers = [NSMutableArray array];
    [serializers addObject:[self createSerializerForNotAuthorized]];
    [serializers addObject:[self createSerializerForRepositories]];
    
    AFCompoundResponseSerializer *serializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:serializers];
        
    return serializer;
}

-(XMLResponseSerializer*)createSerializerForNotAuthorized {
    NotAuthorizedResponseSerializerDelegate *delegate = [[NotAuthorizedResponseSerializerDelegate alloc] init];
    return [[XMLResponseSerializer alloc] initWithDelegate:delegate];
}

-(XMLResponseSerializer*)createSerializerForRepositories {
    WorkspacesResponseSerializerDelegate *delegate = [[WorkspacesResponseSerializerDelegate alloc] init];
    return [[XMLResponseSerializer alloc] initWithDelegate:delegate];
}

-(NSError *)authorizationError:(id)potentialError {
    NSError *error = nil;
    if ([potentialError isKindOfClass:[NotAuthorizedResponse class]]) {
        error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
    }
    
    return error;
}
@end
