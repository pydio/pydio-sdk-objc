//
//  AuthorizationClientTests.m
//  PydioSDK
//
//  Created by ME on 06/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "AuthorizationClient.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFURLRequestSerialization.h"
#import "GetSeedResponseSerializer.h"
#import "BootConfResponseSerializer.h"
#import "LoginResponseSerializer.h"
#import "AuthCredentials.h"
#import "NSString+Hash.h"
#import "LoginResponse.h"
#import "User.h"
#import <objc/runtime.h>


@interface AuthorizationClient ()
@property (readwrite,nonatomic,assign) BOOL progress;
-(NSString *)hashedPass:(NSString*)pass WithSeed:(NSString *)seed;
@end

typedef void (^SuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void (^FailureBlock)(AFHTTPRequestOperation *operation, NSError *error);

typedef void (^ClientPingSuccessResponse)();
typedef void (^ClientFailureResponse)(NSError *error);


static NSString * const PING_ACTION = @"index.php?get_action=ping";
static NSString * const GET_SEED_ACTION = @"index.php?get_action=get_seed";
static NSString * const LOGIN_ACTION = @"";


#pragma mark -

@interface AuthorizationClientTests : XCTestCase
@property (nonatomic,strong) AuthorizationClient* client;
@property (nonatomic,strong) AFHTTPRequestOperationManager *operationManager;
@end


@implementation AuthorizationClientTests

- (void)setUp
{
    [super setUp];
    self.operationManager = mock([AFHTTPRequestOperationManager class]);
    self.client = [[AuthorizationClient alloc] init];
    self.client.operationManager = self.operationManager;
}

- (void)tearDown
{
    
    [super tearDown];
}

-(void)testInitialization
{
    //then
    assertThatBool(self.client.progress,equalToBool(NO));
}

#pragma mark - Authorization tests

-(void)testShouldNotStartAuthorizationWhenInProgress
{
    self.client.progress = YES;
    
    BOOL startResult = [self.client authorizeWithSuccess:nil failure:nil];
    
    assertThatBool(startResult,equalToBool(NO));
}

-(void)testShouldStartAuthorizationWhenInProgress
{
    BOOL startResult = [self.client authorizeWithSuccess:nil failure:nil];
    
    assertThatBool(startResult,equalToBool(YES));
}

#pragma mark - Ping Tests

-(void)testPingStart
{
    //when
    BOOL startResult = [self.client ping:nil failure:nil];
    
    //then
    [verify(self.operationManager) GET:PING_ACTION parameters:nil success:anything() failure:anything()];
    assertThatBool(startResult,equalToBool(YES));
}

- (void)testPingSuccess
{
    BOOL __block blockCalled = NO;
    
    //when
    [self.client ping:^{
        blockCalled = YES;
    } failure:nil];
    
    //then
    MKTArgumentCaptor *success = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:PING_ACTION parameters:nil success:[success capture] failure:anything()];
    ((SuccessBlock)[success value])(nil,nil);
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThatBool(blockCalled,equalToBool(YES));
}

- (void)testPingFailure
{
    //given
    BOOL __block blockCalled = NO;
    NSError __block *receivedError = nil;
    NSError *error = [NSError errorWithDomain:@"TEST" code:1 userInfo:nil];
    
    //when
    [self.client ping:nil failure:^(NSError *error){
        receivedError = error;
        blockCalled = YES;
    }];
    
    //then
    MKTArgumentCaptor *failure = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:PING_ACTION parameters:nil success:anything() failure:[failure capture]];
    ((FailureBlock)[failure value])(nil,error);
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThatBool(blockCalled,equalToBool(YES));
    assertThat(receivedError,sameInstance(error));
    
}

#pragma mark - Get Seed Tests

-(void)testGetSeedStart
{
    //when
    BOOL startResult = [self.client getSeed:nil failure:nil];
    
    //then
    [verify(self.operationManager)  setResponseSerializer:instanceOf([GetSeedResponseSerializer class])];
    [verify(self.operationManager) GET:GET_SEED_ACTION parameters:nil success:anything() failure:anything()];
    assertThatBool(startResult,equalToBool(YES));
}

-(void)testGetSeedSuccess
{
    BOOL __block blockCalled = NO;
    NSString __block *responseSeed = nil;
    NSString *seed = @"seed";
    
    //when
    BOOL startResult = [self.client getSeed:^(NSString *seed) {
        blockCalled = YES;
        responseSeed = seed;
    } failure:nil];

    //then 1
    [verify(self.operationManager)  setResponseSerializer:instanceOf([GetSeedResponseSerializer class])];
    MKTArgumentCaptor *success = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:GET_SEED_ACTION parameters:nil success:[success capture] failure:anything()];
    ((SuccessBlock)[success value])(nil,seed);
    assertThatBool(startResult,equalToBool(YES));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThatBool(blockCalled,equalToBool(YES));
    assertThat(responseSeed,sameInstance(seed));
}

-(void)testGetSeedFailure
{
    //given
    BOOL __block blockCalled = NO;
    NSError __block *receivedError = nil;
    NSError *error = [NSError errorWithDomain:@"TEST" code:1 userInfo:nil];
    
    //when
    BOOL startResult = [self.client getSeed:nil failure:^(NSError *error) {
        blockCalled = YES;
        receivedError = error;
    }];
    
    //then 1
    [verify(self.operationManager)  setResponseSerializer:instanceOf([GetSeedResponseSerializer class])];
    MKTArgumentCaptor *failure = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:GET_SEED_ACTION parameters:nil success:anything() failure:[failure capture]];
    ((SuccessBlock)[failure value])(nil,error);
    assertThatBool(startResult,equalToBool(YES));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThatBool(blockCalled,equalToBool(YES));
    assertThat(receivedError,sameInstance(error));
}

#pragma mark - Login Tests

-(void)testHashedPassword
{
    NSString *expectedPass = [[NSString stringWithFormat:@"%@%@", [@"password" md5], @"seed"] md5];
    NSString *pass = [self.client hashedPass:@"password" WithSeed:@"seed"];
    
    assertThat(pass,equalTo(expectedPass));
}

-(void)testPlainPassword
{
    NSString *expectedPass = @"password";
    NSString *pass = [self.client hashedPass:@"password" WithSeed:@"-1"];
    
    assertThat(pass,equalTo(expectedPass));
}

-(void)testLoginStart
{
    //given
    AFHTTPRequestSerializer *serializer = mock([AFHTTPRequestSerializer class]);
    [given([self.operationManager requestSerializer]) willReturn:serializer];
    AuthCredentials *credentials = [self createAuthCredentials:@"userid" WithPass:@"pass" AndSeed:@"seed"];
    NSDictionary *expectedParams = [self createExpectedLoginParamsWithHashedPassword:credentials];
    
    //when
    BOOL startResult = [self.client loginWithCredentials:credentials success:nil failure:nil];
    
    [verify(serializer) setValue:@"true" forHTTPHeaderField:@"Ajxp-Force-Login"];
    [verify(self.operationManager)  setResponseSerializer:instanceOf([LoginResponseSerializer class])];
    MKTArgumentCaptor *actualParams = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) POST:LOGIN_ACTION parameters:[actualParams capture] success:anything() failure:anything()];
    assertThat([actualParams value],equalTo(expectedParams));
    assertThatBool(startResult,equalToBool(YES));
}

-(void)testLoginSuccess
{
    //given
    BOOL __block blockCalled = NO;
    LoginResponse __block *receivedResponse = nil;
    LoginResponse *response = [[LoginResponse alloc] init];
    AFHTTPRequestSerializer *serializer = mock([AFHTTPRequestSerializer class]);
    [given([self.operationManager requestSerializer]) willReturn:serializer];
    AuthCredentials *credentials = [self createAuthCredentials:@"userid" WithPass:@"pass" AndSeed:@"seed"];
    
    //when
    [self.client loginWithCredentials:credentials success:^(LoginResponse *response) {
        blockCalled = YES;
        receivedResponse = response;
    } failure:nil];
    
    //then
    MKTArgumentCaptor *success = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) POST:LOGIN_ACTION parameters:anything() success:[success capture] failure:anything()];
    ((SuccessBlock)[success value])(nil,response);
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThatBool(blockCalled,equalToBool(YES));
    assertThat(receivedResponse,sameInstance(response));
}

-(void)testLoginFailure
{
    BOOL __block blockCalled = NO;
    NSError __block *receivedError = nil;
    NSError *error = [NSError errorWithDomain:@"TEST" code:1 userInfo:nil];

    //given
    AFHTTPRequestSerializer *serializer = mock([AFHTTPRequestSerializer class]);
    [given([self.operationManager requestSerializer]) willReturn:serializer];
    AuthCredentials *credentials = [self createAuthCredentials:@"userid" WithPass:@"pass" AndSeed:@"seed"];
    
    //when
    [self.client loginWithCredentials:credentials success:nil failure:^(NSError *error) {
        blockCalled = YES;
        receivedError = error;
    }];

    //then
    MKTArgumentCaptor *failure = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) POST:LOGIN_ACTION parameters:anything() success:anything() failure:[failure capture]];
    ((SuccessBlock)[failure value])(nil,error);
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThatBool(blockCalled,equalToBool(YES));
    assertThat(receivedError,sameInstance(error));
}

#pragma mark -

-(NSDictionary*)createExpectedLoginParamsWithHashedPassword:(AuthCredentials*)credentials {
    return @{@"get_action": @"login",
             @"userid": credentials.userid,
             @"password": [[NSString stringWithFormat:@"%@%@", [credentials.password md5], credentials.seed] md5],
             @"login_seed" : credentials.seed
             };
}

-(AuthCredentials*)createAuthCredentials:(NSString *)userid WithPass:(NSString*)pass AndSeed:(NSString*)seed{
    User *user = [User userWithId:userid AndPassword:pass];
    AuthCredentials *credentials = [AuthCredentials credentialsWith:user AndSeed:seed];
    
    return credentials;
}

@end
