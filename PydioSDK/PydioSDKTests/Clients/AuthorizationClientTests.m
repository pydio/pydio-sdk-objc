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


@interface AuthorizationClient ()
@property (readwrite,nonatomic,assign) AuthorizationState state;
@property (readwrite,nonatomic,assign) BOOL progress;
@property (readwrite,nonatomic,strong) NSError *lastError;
-(NSString *)hashedPass:(NSString*)pass WithSeed:(NSString *)seed;
@end

typedef void (^SuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void (^FailureBlock)(AFHTTPRequestOperation *operation, NSError *error);

static NSString * const PING_ACTION = @"get_action=ping";
static NSString * const GET_SEED_ACTION = @"get_action=get_seed";
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
    assertThatInt(self.client.state,equalToInt(ASNone));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThat(self.client.lastError,nilValue());
}

#pragma mark - Ping Tests

-(void)testPingStart
{
    //given
    
    //when
    BOOL startResult = [self.client ping];
    
    //then
    [verify(self.operationManager) GET:PING_ACTION parameters:nil success:anything() failure:anything()];
    assertThatBool(startResult,equalToBool(YES));
    assertThatInt(self.client.state,equalToInt(ASPing));
    assertThatBool(self.client.progress,equalToBool(YES));
    assertThat(self.client.lastError,nilValue());
}

-(void)testPingNoStartWhenInProgress
{
    //given
    self.client.progress = YES;
    AuthorizationState prevState = self.client.state;
    
    //when
    BOOL startResult = [self.client ping];
    
    //then
    [verifyCount(self.operationManager, never()) GET:PING_ACTION parameters:nil success:anything() failure:anything()];
    
    assertThatBool(startResult,equalToBool(NO));
    assertThatInt(self.client.state,equalToInt(prevState));
    assertThat(self.client.lastError,nilValue());
}

-(void)testPingNoStartWhenNotNoneState
{
    //given
    self.client.state = ASPing;
    
    //when
    BOOL startResult = [self.client ping];
    
    //then
    [verifyCount(self.operationManager, never()) GET:PING_ACTION parameters:nil success:anything() failure:anything()];
    assertThatBool(startResult,equalToBool(NO));
    assertThat(self.client.lastError,nilValue());
}

- (void)testPingSuccess
{
    //when
    [self.client ping];
    
    //then 1
    MKTArgumentCaptor *success = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:PING_ACTION parameters:nil success:[success capture] failure:anything()];
    ((SuccessBlock)[success value])(nil,nil);
    
    //then 2
    assertThatInt(self.client.state,equalToInt(ASPing));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThat(self.client.lastError,nilValue());
}

- (void)testPingFailure
{
    //given
    NSError *error = [NSError errorWithDomain:@"TEST" code:1 userInfo:nil];
    
    //when
    [self.client ping];
    
    //then 1
    MKTArgumentCaptor *failure = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:PING_ACTION parameters:nil success:anything() failure:[failure capture]];
    ((FailureBlock)[failure value])(nil,error);
    
    //then 2
    assertThatInt(self.client.state,equalToInt(ASPing));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThat(self.client.lastError,sameInstance(error));
}

#pragma mark - Get Seed Tests

-(void)testGetSeedStart
{
    //given
    self.client.state = ASPing;
    
    //when
    BOOL startResult = [self.client getSeed];
    
    //then
    [verify(self.operationManager)  setResponseSerializer:instanceOf([GetSeedResponseSerializer class])];
    [verify(self.operationManager) GET:GET_SEED_ACTION parameters:nil success:anything() failure:anything()];
    assertThatBool(startResult,equalToBool(YES));
    assertThatInt(self.client.state,equalToInt(ASGetSeed));
    assertThatBool(self.client.progress,equalToBool(YES));
    assertThat(self.client.lastError,nilValue());
}

-(void)testGetSeedNotStartedIfInProgress
{
    //given
    self.client.state = ASPing;
    self.client.progress = YES;
    
    //when
    BOOL startResult = [self.client getSeed];
    
    //then
    [verifyCount(self.operationManager,never()) GET:GET_SEED_ACTION parameters:nil success:anything() failure:anything()];
    assertThatBool(startResult,equalToBool(NO));
    assertThatInt(self.client.state,equalToInt(ASPing));
    assertThat(self.client.lastError,nilValue());
}

-(void)testGetSeedNotStartedIfStateNotPing
{
    //given
    AuthorizationState prevState = self.client.state;
    
    //when
    BOOL startResult = [self.client getSeed];
    
    //then
    [verifyCount(self.operationManager,never()) GET:GET_SEED_ACTION parameters:nil success:anything() failure:anything()];
    assertThatBool(startResult,equalToBool(NO));
    assertThatInt(self.client.state,equalToInt(prevState));
    assertThat(self.client.lastError,nilValue());
}

-(void)testGetSeedNotStartedIfLastErrorNotNil
{
    //given
    self.client.state = ASPing;
    NSError *error = [NSError errorWithDomain:PydioErrorDomain code:99 userInfo:nil];
    self.client.lastError = error;
    
    //when
    BOOL startResult = [self.client getSeed];
    
    //then
    [verifyCount(self.operationManager,never()) GET:GET_SEED_ACTION parameters:nil success:anything() failure:anything()];
    assertThatBool(startResult,equalToBool(NO));
    assertThatInt(self.client.state,equalToInt(ASPing));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThat(self.client.lastError,sameInstance(error));
}

-(void)testGetSeedSuccess
{
    //given
    self.client.state = ASPing;
   
    //when
    BOOL startResult = [self.client getSeed];
    
    //then 1
    MKTArgumentCaptor *success = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:GET_SEED_ACTION parameters:nil success:[success capture] failure:anything()];
    ((SuccessBlock)[success value])(nil,nil);
    
    //then 2
    [verify(self.operationManager)  setResponseSerializer:instanceOf([GetSeedResponseSerializer class])];
    assertThatBool(startResult,equalToBool(YES));
    assertThatInt(self.client.state,equalToInt(ASGetSeed));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThat(self.client.lastError,nilValue());
}

-(void)testGetSeedFailure
{
    //given
    self.client.state = ASPing;
    NSError *error = [NSError errorWithDomain:@"TEST" code:1 userInfo:nil];
    
    //when
    BOOL startResult = [self.client getSeed];
    
    //then 1
    MKTArgumentCaptor *failure = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:GET_SEED_ACTION parameters:nil success:anything() failure:[failure capture]];
    ((SuccessBlock)[failure value])(nil,error);
    
    //then 2
    [verify(self.operationManager)  setResponseSerializer:instanceOf([GetSeedResponseSerializer class])];
    assertThatBool(startResult,equalToBool(YES));
    assertThatInt(self.client.state,equalToInt(ASGetSeed));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThat(self.client.lastError,sameInstance(error));
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
    self.client.state = ASGetSeed;
    
    //when
    BOOL startResult = [self.client loginWithCredentials:credentials];
    
    [verify(serializer) setValue:@"true" forHTTPHeaderField:@"Ajxp-Force-Login"];
    [verify(self.operationManager)  setResponseSerializer:instanceOf([LoginResponseSerializer class])];
    MKTArgumentCaptor *actualParams = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) POST:LOGIN_ACTION parameters:[actualParams capture] success:anything() failure:anything()];
    assertThat([actualParams value],equalTo(expectedParams));
    assertThatBool(startResult,equalToBool(YES));
    assertThatInt(self.client.state,equalToInt(ASLogin));
    assertThatBool(self.client.progress,equalToBool(YES));
    assertThat(self.client.lastError,nilValue());
}

-(void)testLoginNotStartedIfInProgress
{
    self.client.state = ASGetSeed;
    self.client.progress = YES;
    
    //when
    BOOL startResult = [self.client loginWithCredentials:nil];
    
    //then
    [verifyCount(self.operationManager,never()) POST:LOGIN_ACTION parameters:anything() success:anything() failure:anything()];
    assertThatBool(startResult,equalToBool(NO));
    assertThat(self.client.lastError,nilValue());
}

-(void)testLoginNotStartedIfStateNotGetSeed
{
    //when
    BOOL startResult = [self.client loginWithCredentials:nil];
    
    //then
    [verifyCount(self.operationManager,never()) POST:LOGIN_ACTION parameters:anything() success:anything() failure:anything()];
    assertThatBool(startResult,equalToBool(NO));
    assertThat(self.client.lastError,nilValue());
}

-(void)testLoginNotStartedIfLastErrorNotNil
{
    self.client.state = ASGetSeed;
    NSError *error = [NSError errorWithDomain:PydioErrorDomain code:99 userInfo:nil];
    self.client.lastError = error;
    
    //when
    BOOL startResult = [self.client loginWithCredentials:nil];
    
    //then
    [verifyCount(self.operationManager,never()) POST:LOGIN_ACTION parameters:anything() success:anything() failure:anything()];
    assertThatBool(startResult,equalToBool(NO));
    assertThat(self.client.lastError,sameInstance(error));
}

//Response with success, response with failure

-(NSDictionary*)createExpectedLoginParamsWithHashedPassword:(AuthCredentials*)credentials {
    return @{@"get_action": @"login",
             @"userid": credentials.userid,
             @"password": [[NSString stringWithFormat:@"%@%@", [credentials.password md5], credentials.seed] md5],
             @"login_seed" : credentials.seed
             };
}

-(AuthCredentials*)createAuthCredentials:(NSString *)userid WithPass:(NSString*)pass AndSeed:(NSString*)seed{
    AuthCredentials *credentials = [[AuthCredentials alloc] init];
    credentials.userid = userid;
    credentials.password = pass;
    credentials.seed = seed;
    
    return credentials;
}

@end
