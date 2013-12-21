//
//  PydioConnector.m
//  PydioSDK
//
//  Created by MINI on 22.12.2013.
//  Copyright (c) 2013 MINI. All rights reserved.
//

#import "PydioConnector.h"
#import "AFNetworking.h"
#import <CommonCrypto/CommonDigest.h>


#define GET_BOOT_CONF "index.php?get_action=get_boot_conf"
#define SECURE_TOKEN_KEY "SECURE_TOKEN"

#define GET_SEED "index.php?get_action=get_seed"

#define LOGIN "index.php"


@implementation NSString (HashCategories)

- (NSString *) md5{
    const char *cStr = [self UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end

@interface PydioConnector ()
@property (strong,nonatomic) AFHTTPRequestOperationManager* afManager;
@end

@implementation PydioConnector

-(AFHTTPRequestOperationManager*)afManager
{
    if (_afManager == nil) {
        _afManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:self.server]];
    }
    
    _afManager.requestSerializer = [self getRequestSerializer];
    
    return _afManager;
}

-(NSString *)server
{
    return @"http://sandbox.ajaxplorer.info/";
}

-(BOOL)requestSecureToken:(void (^)(BOOL success, NSString *error))resultBlock
{
    if (self.requestInProgress)
        return NO;
    
    [self markRequestInProgres];
    [self.afManager GET:@GET_BOOT_CONF parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        _secure_token = [responseObject valueForKey:@SECURE_TOKEN_KEY];
        resultBlock(YES,nil);
        [self markRequestNotInProgres];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        _secure_token = nil;
        resultBlock(NO,error.description);
        [self markRequestNotInProgres];
    }];
    
    return YES;
}

-(BOOL)requestSeed:(void (^)(BOOL success, NSString *error))resultBlock
{
    if (self.requestInProgress)
        return NO;
    
    [self markRequestInProgres];
    self.afManager.responseSerializer = [self getResponseSerializer];
    [self.afManager GET:@GET_SEED parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        _seed = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        resultBlock(YES,nil);
        [self markRequestNotInProgres];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        _seed = nil;
        resultBlock(NO,error.description);
        [self markRequestNotInProgres];
    }];
    
    return YES;
}

-(BOOL)requestLoginWithUserName:(NSString *)username password:(NSString *)password resultBlock:(void (^)(BOOL success, NSString *error))resultBlock
{
    if (self.requestInProgress)
        return NO;
    
    [self markRequestInProgres];
    self.afManager.responseSerializer = [AFXMLParserResponseSerializer serializer];
    NSDictionary *params = @{
                             @"get_action": @"login",
                             @"userid": username,
                             @"password": [[NSString stringWithFormat:@"%@%@", [password md5], self.seed] md5],
                             @"login_seed": self.seed,
                             };
    
    [self.afManager POST:@LOGIN parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        _loggedIn = YES;
        resultBlock(YES,nil);
        [self markRequestNotInProgres];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        _loggedIn = NO;
        resultBlock(NO,error.description);
        [self markRequestNotInProgres];
    }];
    
    return YES;
}

-(AFHTTPRequestSerializer*)getRequestSerializer
{
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    [serializer setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    [serializer setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [serializer setValue:@"en-us" forHTTPHeaderField:@"Accept-Language"];
    [serializer setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    [serializer setValue:@"true" forHTTPHeaderField:@"Ajxp-Force-Login"];
    [serializer setValue:@"ajaxplorer-ios-client/1.0" forHTTPHeaderField:@"User-Agent"];
    
    return serializer;
}

-(AFHTTPResponseSerializer*)getResponseSerializer
{
    AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
    serializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
    
    return serializer;
}

-(void)markRequestInProgres
{
    _requestInProgress = YES;
}

-(void)markRequestNotInProgres
{
    _requestInProgress = NO;
}

@end
