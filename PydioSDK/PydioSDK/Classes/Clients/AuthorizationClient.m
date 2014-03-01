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
#import "SeedResponse.h"
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
@property (nonatomic,copy) AFSuccessBlock pingSuccessBlock;
@property (nonatomic,copy) AFSuccessBlock seedSuccessBlock;
@property (nonatomic,copy) AFSuccessBlock loginSuccessBlock;
@property (nonatomic,copy) void(^afFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
@property (nonatomic,copy) void(^successBlock)();
@property (nonatomic,copy) void(^failureBlock)(NSError* error);

-(void)clearBlocks;
-(void)setupSuccess:(void(^)())success AndFailure:(void(^)(NSError*))failure;
-(void)setupAFFailureBlock;
-(void)setupPingSuccessBlock;
-(void)setupSeedSuccessBlock;
-(void)setupLoginSuccessBlock;
-(void)ping;
-(void)getSeed;
-(void)loginWithCredentials:(AuthCredentials*)credentials;
@end

@implementation AuthorizationClient

#pragma mark - Setup process

-(void)clearBlocks {
    self.failureBlock = nil;
    self.successBlock = nil;
    self.afFailureBlock = nil;
    _pingSuccessBlock = nil;
    _seedSuccessBlock = nil;
    _loginSuccessBlock = nil;
}

-(void)setupSuccess:(void(^)())success AndFailure:(void(^)(NSError*))failure {

    __weak typeof(self) weakSelf = self;
    self.successBlock = ^{
        __strong typeof(self) strongSelf = weakSelf;
        success();
        strongSelf->_progress = NO;
        [strongSelf clearBlocks];
    };
    
    self.failureBlock = ^(NSError *error){
        __strong typeof(self) strongSelf = weakSelf;
        failure(error);
        strongSelf->_progress = NO;
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

-(void)setupPingSuccessBlock {
    __weak typeof(self) weakSelf = self;
    self.pingSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf getSeed];
    };
}

-(void)setupSeedSuccessBlock {
    __weak typeof(self) weakSelf = self;
    self.seedSuccessBlock = ^(AFHTTPRequestOperation *operation, SeedResponse *seed) {
        __strong typeof(self) strongSelf = weakSelf;
        User *user = [[ServerDataManager sharedManager] userForServer:strongSelf.operationManager.baseURL];
        if (!seed.captcha) {
            AuthCredentials *authCredentials = [AuthCredentials credentialsWith:user AndSeed:seed.seed];
            [strongSelf loginWithCredentials:authCredentials];
        } else {
            NSError *error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorGetSeedWithCaptcha userInfo:@{ PydioErrorSeedKey : seed.seed}];
            strongSelf.failureBlock(error);
        }
    };
}

-(void)setupLoginSuccessBlock {
    __weak typeof(self) weakSelf = self;
    self.loginSuccessBlock = ^(AFHTTPRequestOperation *operation, LoginResponse *response) {
        __strong typeof(self) strongSelf = weakSelf;
        if (response.value != LRValueOK) {
            NSError *error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
            strongSelf.failureBlock(error);
        } else {
            [[ServerDataManager sharedManager] setSecureToken:response.secureToken ForServer:strongSelf.operationManager.baseURL];
            strongSelf.successBlock();
        }
    };

}

#pragma mark - Authorization process

-(BOOL)authorizeWithSuccess:(void(^)())success failure:(void(^)(NSError *error))failure {
    if (self.progress) {
        return NO;
    }
    
    self.progress = YES;
    [self setupSuccess:success AndFailure:failure];    
    [self setupPingSuccessBlock];
    [self setupSeedSuccessBlock];
    [self setupLoginSuccessBlock];
    [self setupAFFailureBlock];
    
    [self ping];
    
    return YES;
}

-(void)ping {
    [self.operationManager GET:@"index.php" parameters:@{GET_ACTION : @"ping"} success:self.pingSuccessBlock failure:self.afFailureBlock];
}

-(void)getSeed {
    self.operationManager.responseSerializer =  [GetSeedResponseSerializer serializer];
    [self.operationManager GET:@"index.php" parameters:@{GET_ACTION : @"get_seed"} success:self.seedSuccessBlock failure:self.afFailureBlock];
    
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
    return [seed isEqualToString:@"-1"] ? pass : [[NSString stringWithFormat:@"%@%@", [pass md5], seed] md5];
}

-(XMLResponseSerializer*)createLoginResponseSerializer {
    LoginResponseSerializerDelegate *delegate = [[LoginResponseSerializerDelegate alloc] init];
    return [[XMLResponseSerializer alloc] initWithDelegate:delegate];
}

@end
