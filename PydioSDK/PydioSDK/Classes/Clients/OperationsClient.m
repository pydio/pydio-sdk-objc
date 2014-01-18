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


@interface OperationsClient ()
@property (readwrite,nonatomic,assign) BOOL progress;

-(NSString*)urlStringForGetRegisters;
@end

@implementation OperationsClient
-(BOOL)listFilesWithSuccess:(void(^)(NSArray *files))success failure:(void(^)(NSError *error))failure {
    if (self.progress) {
        return NO;
    }
    self.progress = YES;
    
    NSString *listRegisters = [self urlStringForGetRegisters];
    [self.operationManager GET:listRegisters parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.progress = NO;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.progress = NO;
    }];
    
    
    return YES;
}

-(NSString*)urlStringForGetRegisters {
    NSString *secureToken = [[CookieManager sharedManager] secureTokenForServer:self.operationManager.baseURL];
    
    /*
     static const NSString * const REGISTERS_URL_PART = ;
     static const NSString * const SECURE_TOKEN_PART = ;
     static const NSString * const XPATH_PART = ;
     */
    
    NSString *base = @"index.php?get_action=get_xml_registry";
    if (secureToken) {
        base = [base stringByAppendingFormat:@"&secure_token=%@",secureToken];
    }
    base = [base stringByAppendingString:@"&xPath=user/repositories"];
    
    return base;
}
@end
