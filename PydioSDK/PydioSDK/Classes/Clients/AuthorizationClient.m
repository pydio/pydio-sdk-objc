//
//  AuthorizationClient.m
//  PydioSDK
//
//  Created by ME on 06/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "AuthorizationClient.h"
#import "AFHTTPRequestOperationManager.h"
#import "GetSeedResponseSerializer.h"
#import "ServerDataManager.h"
#import "AuthCredentials.h"
#import "NSString+Hash.h"
#import "User.h"
#import "LoginResponse.h"
#import "PydioErrors.h"
#import "XMLResponseSerializer.h"
#import "XMLResponseSerializerDelegate.h"


typedef void(^AFSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);


static NSString * const PING_ACTION = @"index.php?get_action=ping";
static NSString * const GET_SEED_ACTION = @"index.php?get_action=get_seed";
static NSString * const GET_ACTION = @"get_action";
static NSString * const USERID = @"userid";
static NSString * const PASSWORD = @"password";
static NSString * const LOGIN_SEED = @"login_seed";

@interface AuthorizationClient ()
@property (readwrite,nonatomic,assign) BOOL progress;
//@property (nonatomic,copy) void(^pingSuccessBlock)();
//@property (nonatomic,copy) void(^getSeedSuccessBlock)(NSString *seed);
@property (nonatomic,copy) AFSuccessBlock pingSuccessBlock;
@property (nonatomic,copy) AFSuccessBlock seedSuccessBlock;
@property (nonatomic,copy) AFSuccessBlock loginSuccessBlock;
@property (nonatomic,copy) void(^afFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
@property (nonatomic,copy) void(^failureBlock)(NSError* error);
-(void)clearBlocks;
@end

@implementation AuthorizationClient

#pragma mark - Setup process

-(void)clearBlocks {
    _failureBlock = nil;
    self.afFailureBlock = nil;
    _pingSuccessBlock = nil;
    _seedSuccessBlock = nil;
    _loginSuccessBlock = nil;
}

-(void)setFailureBlock:(void (^)(NSError *))failureBlock {
    __weak typeof(self) weakSelf = self;
    _failureBlock = ^(NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.progress = NO;
        failureBlock(error);
        [strongSelf clearBlocks];
    };
}

-(void)setupAFFailureBlock {
    __weak typeof(self) weakSelf = self;
    self.afFailureBlock = ^(AFHTTPRequestOperation *operation,NSError *error){
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.failureBlock(error);
    };
}

-(void)setPingSuccessBlock:(AFSuccessBlock)pingSuccessBlock {
    __weak typeof(self) weakSelf = self;
    _pingSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject){
        __strong typeof(self) strongSelf = weakSelf;
        pingSuccessBlock(operation,responseObject);
//        [strongSelf clearBlocks];
        strongSelf->_pingSuccessBlock = nil;
    };
}

-(void)setSeedSuccessBlock:(AFSuccessBlock)seedSuccessBlock {
    __weak typeof(self) weakSelf = self;
    _seedSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject){
        __strong typeof(self) strongSelf = weakSelf;
        seedSuccessBlock(operation,responseObject);
//        [strongSelf clearBlocks];
        strongSelf->_seedSuccessBlock = nil;
    };
}

-(void)setLoginSuccessBlock:(AFSuccessBlock)loginSuccessBlock {
    __weak typeof(self) weakSelf = self;
    _loginSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject){
        __strong typeof(self) strongSelf = weakSelf;
        loginSuccessBlock(operation,responseObject);
        [strongSelf clearBlocks];
//        strongSelf->_seedSuccessBlock = nil;
    };
}

//-(void)setupPingBlock {
//    __weak typeof(self) weakSelf = self;
//    self.pingSuccessBlock = ^(void){
//        __strong typeof(self) strongSelf = weakSelf;
//        [strongSelf getSeed:strongSelf.getSeedSuccessBlock];
//    };
//}

#pragma mark - Authorization process

-(BOOL)authorizeWithSuccess:(void(^)())success failure:(void(^)(NSError *error))failure {
    if (self.progress) {
        return NO;
    }
    
    self.progress = YES;
    self.failureBlock = failure;
    
    __weak typeof(self) weakSelf = self;
    self.pingSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf getSeed];
    };
    self.seedSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong typeof(self) strongSelf = weakSelf;
        User *user = [[ServerDataManager sharedManager] userForServer:strongSelf.operationManager.baseURL];
        AuthCredentials *authCredentials = [AuthCredentials credentialsWith:user AndSeed:responseObject];
        [strongSelf loginWithCredentials:authCredentials];
    };
    self.loginSuccessBlock = ^(AFHTTPRequestOperation *operation, LoginResponse *response) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.progress = NO;
        if (response.value != LRValueOK) {
            NSError *error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
            failure(error);
        } else {
            [[ServerDataManager sharedManager] setSecureToken:response.secureToken ForServer:strongSelf.operationManager.baseURL];
            success();
        }
    };
    
    [self setupAFFailureBlock];
    
//    [self ping:^{
//        [self getSeed:^(NSString *seed) {
//            User *user = [[ServerDataManager sharedManager] userForServer:self.operationManager.baseURL];;
//            
//            AuthCredentials *authCredentials = [AuthCredentials credentialsWith:user AndSeed:seed];
//            
//            [self loginWithCredentials:authCredentials success:^(LoginResponse *resposne) {
//                self.progress = NO;
//                if (resposne.value != LRValueOK) {
//                    NSError *error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
//                    failure(error);
//                } else {
//                    [[ServerDataManager sharedManager] setSecureToken:resposne.secureToken ForServer:self.operationManager.baseURL];
//                    success();
//                }
//                
//            } failure:self.failureBlock];
//        } failure:self.failureBlock];
//    } failure:self.failureBlock];

    [self ping];
    
    
    return YES;
}

-(BOOL)ping:(void(^)())success failure:(void(^)(NSError *error))failure {
    
//    [self.operationManager GET:PING_ACTION parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        //Ignore result, we just want cookie
//        success();
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        failure(error);
//    }];

    self.pingSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject){
        success(responseObject);
    };
    self.failureBlock = failure;
    [self setupAFFailureBlock];
    [self ping];

    
    return YES;
}

-(void)ping {
    [self.operationManager GET:PING_ACTION parameters:nil success:self.pingSuccessBlock failure:self.afFailureBlock];
}

-(BOOL)getSeed:(void(^)(NSString *seed))success failure:(void(^)(NSError *error))failure {
    
//    self.operationManager.responseSerializer = [[GetSeedResponseSerializer alloc] init];
//    [self.operationManager GET:GET_SEED_ACTION parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        success(responseObject);
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        failure(error);
//    }];

    self.seedSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject){
        success(responseObject);
    };
    self.failureBlock = failure;
    [self setupAFFailureBlock];
    [self getSeed];
    
    return YES;
}

-(void)getSeed {
    self.operationManager.responseSerializer = [[GetSeedResponseSerializer alloc] init];
    [self.operationManager GET:GET_SEED_ACTION parameters:nil success:self.seedSuccessBlock failure:self.afFailureBlock];
    
}

-(BOOL)loginWithCredentials:(AuthCredentials*)credentials success:(void(^)(LoginResponse *response))success failure:(void(^)(NSError *error))failure {
    
//    [self.operationManager.requestSerializer setValue:@"true" forHTTPHeaderField:@"Ajxp-Force-Login"];
//    self.operationManager.responseSerializer = [self createLoginResponseSerializer];
//    NSDictionary *params = @{GET_ACTION : @"login",
//                             USERID : credentials.userid,
//                             PASSWORD : [self hashedPass:credentials.password WithSeed:credentials.seed],
//                             LOGIN_SEED : credentials.seed
//                            };
//    
//    [self.operationManager POST:@"" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        success(responseObject);
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        failure(error);
//    }];

    self.loginSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject){
        success(responseObject);
    };
    self.failureBlock = failure;
    [self setupAFFailureBlock];
    [self loginWithCredentials:credentials];

    
    return YES;
}

-(void)loginWithCredentials:(AuthCredentials*)credentials {
    [self.operationManager.requestSerializer setValue:@"true" forHTTPHeaderField:@"Ajxp-Force-Login"];
    self.operationManager.responseSerializer = [self createLoginResponseSerializer];
    NSDictionary *params = @{GET_ACTION : @"login",
                             USERID : credentials.userid,
                             PASSWORD : [self hashedPass:credentials.password WithSeed:credentials.seed],
                             LOGIN_SEED : credentials.seed
                             };

    [self.operationManager POST:@"" parameters:params success:self.loginSuccessBlock failure:self.afFailureBlock];
}

-(NSString *)hashedPass:(NSString*)pass WithSeed:(NSString *)seed {
    return [seed compare:@"-1"] == NSOrderedSame ? pass : [[NSString stringWithFormat:@"%@%@", [pass md5], seed] md5];
}

-(XMLResponseSerializer*)createLoginResponseSerializer {
    LoginResponseSerializerDelegate *delegate = [[LoginResponseSerializerDelegate alloc] init];
    return [[XMLResponseSerializer alloc] initWithDelegate:delegate];
}

-(void)dealloc {
    NSLog(@"%s",__PRETTY_FUNCTION__);
}
@end
