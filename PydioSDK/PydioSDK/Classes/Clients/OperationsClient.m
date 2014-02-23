//
//  OperationsClient.m
//  PydioSDK
//
//  Created by ME on 14/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "OperationsClient.h"
#import "AFHTTPRequestOperationManager.h"
#import "ServerDataManager.h"
#import "XMLResponseSerializer.h"
#import "XMLResponseSerializerDelegate.h"
#import "FailingResponseSerializer.h"
#import "NotAuthorizedResponse.h"
#import "PydioErrorResponse.h"
#import "PydioErrors.h"


extern NSString * const PydioErrorDomain;

@interface OperationsClient ()
@property (readwrite,nonatomic,assign) BOOL progress;
@property (nonatomic,copy) void(^successBlock)(id response);
@property (nonatomic,copy) void(^failureBlock)(NSError* error);
@property (nonatomic,copy) void(^successResponseBlock)(AFHTTPRequestOperation *operation, id responseObject);
@property (nonatomic,copy) void(^failureResponseBlock)(AFHTTPRequestOperation *operation, NSError *error);

-(NSString*)actionWithTokenIfNeeded:(NSString*)action;
-(NSString*)urlStringForGetRegisters;
-(NSString*)urlStringForListFiles;
@end

@implementation OperationsClient

-(void)setupResponseBlocks {
    [self setupSuccessResponseBlock];
    [self setupFailureResponseBlock];
}

-(void)setupSuccessResponseBlock {
    __weak typeof(self) weakSelf = self;
    self.successResponseBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.progress = NO;
        NSError *error = [strongSelf identifyError:responseObject];
        if (error) {
            strongSelf.failureBlock(error);
        } else {
            strongSelf.successBlock(responseObject);
        }
        [strongSelf clearBlocks];
    };
}

-(void)setupFailureResponseBlock {
    __weak typeof(self) weakSelf = self;
    self.failureResponseBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.progress = NO;
        strongSelf.failureBlock(error);
        [strongSelf clearBlocks];
    };
}

-(void)clearBlocks {
    _successBlock = nil;
    _failureBlock = nil;
    _failureResponseBlock = nil;
    _successResponseBlock = nil;
}

#pragma mark - Public operations

-(BOOL)listWorkspacesWithSuccess:(void(^)(NSArray *workspaces))success failure:(void(^)(NSError *error))failure {
    if (self.progress) {
        return NO;
    }

    [self setupCommons:success failure:failure];
    self.operationManager.responseSerializer = [self responseSerializerForGetRegisters];
    
    [self.operationManager GET:[self urlStringForGetRegisters] parameters:nil success:self.successResponseBlock failure:self.failureResponseBlock];
    
    return YES;
}

-(BOOL)listFiles:(NSDictionary*)params WithSuccess:(void(^)(NSArray* files))success failure:(void(^)(NSError* error))failure {
    if (self.progress) {
        return NO;
    }

    [self setupCommons:success failure:failure];
    self.operationManager.responseSerializer = [self responseSerializerForListFiles];
    
    [self.operationManager GET:[self urlStringForListFiles] parameters:params success:self.successResponseBlock failure:self.failureResponseBlock];

    return YES;
}

-(BOOL)mkdir:(NSDictionary*)params WithSuccess:(void(^)(NSArray* files))success failure:(void(^)(NSError* error))failure {
    if (self.progress) {
        return NO;
    }
    
    [self setupCommons:success failure:failure];
    self.operationManager.responseSerializer = [self responseSerializerForMkdir];
    params = [self paramsForMkDir:params];
    
    [self.operationManager POST:@"index.php" parameters:params success:self.successResponseBlock failure:self.failureResponseBlock];
    
    return YES;
}

#pragma mark - Helper methods

-(void)setupCommons:(void(^)(id result))success failure:(void(^)(NSError *))failure {
    self.progress = YES;
    
    self.operationManager.requestSerializer = [self defaultRequestSerializer];
    
    self.successBlock = success;
    self.failureBlock = failure;
    [self setupResponseBlocks];
}

-(NSString*)actionWithTokenIfNeeded:(NSString*)action {
    NSString *secureToken = [[ServerDataManager sharedManager] secureTokenForServer:self.operationManager.baseURL];
    
    NSString *result = [NSString stringWithFormat:@"index.php?get_action=%@",action];
    if (secureToken) {
        result = [result stringByAppendingFormat:@"&secure_token=%@",secureToken];
    }
    
    return result;
}

-(NSString*)urlStringForGetRegisters {
    return [[self actionWithTokenIfNeeded:@"get_xml_registry"] stringByAppendingString:@"&xPath=user/repositories"];
}

-(NSString*)urlStringForListFiles {
    return [self actionWithTokenIfNeeded:@"ls"];
}

-(NSDictionary*)paramsWithTokenIfNeeded:(NSDictionary*)params forAction:(NSString*)action {
    NSString *secureToken = [[ServerDataManager sharedManager] secureTokenForServer:self.operationManager.baseURL];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:params];
    
    if (secureToken) {
        [dict setValue:secureToken forKey:@"secure_token"];
    }
    [dict setValue:action forKey:@"get_action"];
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

-(NSDictionary*)paramsForMkDir:(NSDictionary*)params {
    return [self paramsWithTokenIfNeeded:params forAction:@"mkdir"];
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

-(AFHTTPResponseSerializer*)responseSerializerForGetRegisters {
    NSArray *serializers = [self defaultResponseSerializersWithSerializer:[self createSerializerForRepositories]];
    
    return [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:serializers];
}

-(AFHTTPResponseSerializer*)responseSerializerForListFiles {
    NSArray *serializers = [self defaultResponseSerializersWithSerializer:[self createSerializerForListFiles]];
    
    return [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:serializers];
}

-(AFHTTPResponseSerializer*)responseSerializerForMkdir {
    NSArray *serializers = [self defaultResponseSerializersWithSerializer:[self createSerializerForMkdir]];
    
    return [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:serializers];
}

-(NSArray*)defaultResponseSerializersWithSerializer:(XMLResponseSerializer*)serializer {
    return @[
             [self createSerializerForNotAuthorized],
             [self createSerializerForErrorResponse],
             serializer,
             [self createFailingSerializer]
            ];
}

-(XMLResponseSerializer*)createSerializerForNotAuthorized {
    NotAuthorizedResponseSerializerDelegate *delegate = [[NotAuthorizedResponseSerializerDelegate alloc] init];
    return [[XMLResponseSerializer alloc] initWithDelegate:delegate];
}

-(XMLResponseSerializer*)createSerializerForErrorResponse {
    ErrorResponseSerializerDelegate *delegate = [[ErrorResponseSerializerDelegate alloc] init];
    return [[XMLResponseSerializer alloc] initWithDelegate:delegate];
}

-(XMLResponseSerializer*)createSerializerForRepositories {
    WorkspacesResponseSerializerDelegate *delegate = [[WorkspacesResponseSerializerDelegate alloc] init];
    return [[XMLResponseSerializer alloc] initWithDelegate:delegate];
}

-(XMLResponseSerializer*)createSerializerForListFiles {
    ListFilesResponseSerializerDelegate *delegate = [[ListFilesResponseSerializerDelegate alloc] init];
    return [[XMLResponseSerializer alloc] initWithDelegate:delegate];
}

-(XMLResponseSerializer*)createSerializerForMkdir {
    MkdirResponseSerializerDelegate *delegate = [[MkdirResponseSerializerDelegate alloc] init];
    return [[XMLResponseSerializer alloc] initWithDelegate:delegate];
}

-(FailingResponseSerializer*)createFailingSerializer {
    return [[FailingResponseSerializer alloc] init];
}

-(NSError *)identifyError:(id)potentialError {
    NSError *error = nil;
    if ([potentialError isKindOfClass:[NotAuthorizedResponse class]]) {
        error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
    } else if ([potentialError isKindOfClass:[PydioErrorResponse class]]) {
        error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorErrorResponse userInfo:
                 @{NSLocalizedFailureReasonErrorKey: [potentialError message]}];
    }
    
    return error;
}

@end
