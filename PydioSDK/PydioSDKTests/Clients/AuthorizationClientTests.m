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
#import <objc/runtime.h>
#import "AFHTTPRequestOperationManager.h"
#import "AFURLRequestSerialization.h"
#import "ServersParamsManager.h"
#import "GetSeedTextResponseSerializer.h"
#import "GetSeedResponseSerializer.h"
#import "GetCaptchaResponseSerializer.h"
#import "NSString+Hash.h"
#import "LoginResponse.h"
#import "SeedResponse.h"
#import "User.h"
#import "XMLResponseSerializer.h"
#import "XMLResponseSerializerDelegate.h"
#import "BlocksCallResult.h"
#import "PydioErrors.h"


typedef void (^AFSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void (^AFFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
typedef void (^ClientPingSuccessResponse)();
typedef void (^ClientFailureResponse)(NSError *error);


static NSString * const PING_ACTION = @"index.php?get_action=ping";
static NSString * const GET_SEED_ACTION = @"index.php?get_action=get_seed";
static NSString * const LOGIN_ACTION = @"";
static NSString * const INDEX = @"index.php";

static ServersParamsManager *serverParamsManager = nil;

static id mockedManager(id self, SEL _cmd) {
    return serverParamsManager;
}

#pragma mark - exposing private methods of tested class

@interface AuthorizationClient ()
@property (readwrite,nonatomic,assign) BOOL progress;
@property (nonatomic,copy) AFSuccessBlock afSuccessBlock;
@property (nonatomic,copy) AFFailureBlock afFailureBlock;
@property (nonatomic,copy) SuccessBlock successBlock;
@property (nonatomic,copy) FailureBlock failureBlock;

-(NSString *)hashedPass:(NSString*)pass WithSeed:(NSString *)seed;
-(void)setupSuccess:(void(^)(id ignored))success AndFailure:(void(^)(NSError*))failure;
-(void)setupSuccess:(SuccessBlock)success;
-(void)setupFailure:(FailureBlock)failure;
-(void)setupGetCaptchaSuccess;
-(void)setupAFFailureBlock;
-(void)setupPingSuccessBlock;
-(void)setupSeedSuccessBlock;
-(void)setupLoginSuccessBlock;
-(void)ping;
-(void)getSeed;
-(void)login:(User*)user WithCaptcha:(NSString*)captcha;
@end

#pragma mark -

@interface AuthorizationClientTests : XCTestCase {
    Method _methodToExchange;
    IMP _originalIMP;
}
@property (nonatomic,strong) AuthorizationClient* client;
@property (nonatomic,strong) AFHTTPRequestOperationManager *operationManager;

@property (nonatomic,assign) BlocksCallResult *result;
@property (nonatomic,assign) BlocksCallResult *expectedResult;
@property (nonatomic,assign) SuccessBlock successBlock;
@property (nonatomic,assign) FailureBlock failureBlock;

@end


@implementation AuthorizationClientTests

- (void)setUp
{
    [super setUp];
    serverParamsManager = mock([ServersParamsManager class]);
    _methodToExchange = class_getClassMethod([ServersParamsManager class], @selector(sharedManager));
    _originalIMP = method_setImplementation(_methodToExchange, (IMP)mockedManager);
    self.operationManager = mock([AFHTTPRequestOperationManager class]);
    self.client = [[AuthorizationClient alloc] init];
    self.client.operationManager = self.operationManager;

}

- (void)tearDown
{
    [self clearAllClientBlocks];
    self.client.operationManager = nil;
    self.client = nil;
    method_setImplementation(_methodToExchange, _originalIMP);
    _originalIMP = nil;
    _methodToExchange = nil;
    serverParamsManager = nil;
    [super tearDown];
}

-(void)testInitialization
{
    //then
    assertThatBool(self.client.progress,equalToBool(NO));
}

#pragma mark - Password hashing

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

#pragma mark -

-(NSDictionary*)createExpectedLoginParamsWithHashedPassword:(User*)user AndSeed:(NSString*)seed AndCaptcha:(NSString *)captcha {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{@"get_action": @"login",
             @"userid": user.userid,
             @"password": [[NSString stringWithFormat:@"%@%@", [user.password md5], seed] md5],
             @"login_seed" : seed
             }];
    
    if (captcha){
        [dict setValue:captcha forKey:@"captcha_code"];
    }
    
    return dict;
}

#pragma mark - Invocation of success and failure blocks

-(void)test_shouldSetupSuccessAndFailureBlocks {
    [self setupEmptyResult];
    [self setupClientSuccessAndFailureBlocks];
    
    assertThat(self.client.successBlock,notNilValue());
    assertThat(self.client.failureBlock,notNilValue());
}

-(void)test_shouldClearAllBlocks_WhenSuccessBlockCalled {
    self.expectedResult = [BlocksCallResult successWithResponse:nil];
    self.client.progress = YES;
    [self setupEmptyResult];
    [self setupClientSuccessAndFailureBlocks];
    
    self.client.successBlock(nil);
    
    [self assertResultEqualsExpectedResult];
    [self assertAllBlocksNiled];
    [self assertProgressIsNO];
}

-(void)test_shouldCallSetFailureBlockAndClearAllBlocks_WhenFailureBlockCalled {
    //given
    [self setupEmptyResult];
    [self setAFBlocksToNotNilValue];
    NSError *error = [NSError errorWithDomain:@"domain" code:1 userInfo:nil];
    self.expectedResult = [BlocksCallResult failureWithError:error];
    self.client.progress = YES;
    [self setupClientSuccessAndFailureBlocks];
    //when
    self.client.failureBlock(error);
    //then
    [self assertResultEqualsExpectedResult];
    [self assertAllBlocksNiled];
    [self assertProgressIsNO];
}

-(void)test_shouldCallFailureBlock_WhenFailureBlockFromAFNetworking {
    [self setupEmptyResult];
    [self setupClientSuccessAndFailureBlocks];
    NSError *error = [NSError errorWithDomain:@"domain" code:1 userInfo:nil];
    self.expectedResult = [BlocksCallResult failureWithError:error];
    [self.client setupAFFailureBlock];

    self.client.afFailureBlock(nil,error);
    
    [self assertResultEqualsExpectedResult];
}

-(void)test_shouldSetupFailureBlockOnly {
    //given
    [self setupEmptyResult];
    //when
    [self.client setupFailure:self.failureBlock];
    //then
    assertThat(self.client.successBlock,nilValue());
    assertThat(self.client.failureBlock,notNilValue());
}

#pragma mark - Invocation of ping

-(void)test_shouldCallAFNetworkingMethodWithParams_WhenPingCalled {
    NSDictionary *expectedParams = @{@"get_action" : @"ping"};
    [self.client setupAFFailureBlock];
    [self.client setupPingSuccessBlock];
    
    [self.client ping];
    
    assertThat(self.client.afSuccessBlock,notNilValue());
    assertThat(self.client.afFailureBlock,notNilValue());
    [verify(self.operationManager) GET:INDEX parameters:expectedParams success:self.client.afSuccessBlock failure:self.client.afFailureBlock];
}

-(void)test_shouldSetupPingResponseBlockAndCallGetSeed_WhenPingSuccessBlockWasCalled {
    //given
    [self.client setupPingSuccessBlock];
    NSDictionary *expectedParams = @{@"get_action" : @"get_seed"};
    //when
    self.client.afSuccessBlock(nil,[[NSObject alloc] init]);
    //then
    [verify(self.operationManager) setResponseSerializer:instanceOf([GetSeedResponseSerializer class])];
    [verify(self.operationManager) GET:INDEX parameters:expectedParams success:self.client.afSuccessBlock failure:self.client.afFailureBlock];
}

#pragma mark - Invocation of Get Seed

-(void)test_shouldCallAFNetworkingMethodWithParams_WhenGetSeedCalled {
    NSDictionary *expectedParams = @{@"get_action" : @"get_seed"};
    [self.client setupAFFailureBlock];
    [self.client setupSeedSuccessBlock];
    
    [self.client getSeed];
    
    assertThat(self.client.afSuccessBlock,notNilValue());
    assertThat(self.client.afFailureBlock,notNilValue());

    [verify(self.operationManager) setResponseSerializer:instanceOf([GetSeedResponseSerializer class])];
    [verify(self.operationManager) GET:INDEX parameters:expectedParams success:self.client.afSuccessBlock failure:self.client.afFailureBlock];
}

-(void)test_shouldSetupSeedResponseBlockAndCallLogin_WhenSeedSuccessBlockWasCalled {
    //given
    User* user = [self exampleUser];
    SeedResponse *seed = [SeedResponse seed:@"1234567"];
    [given([serverParamsManager userForServer:anything()]) willReturn:user];
    [given([serverParamsManager seedForServer:anything()]) willReturn:@"1234567"];
    [self.client setupSeedSuccessBlock];
    NSDictionary *expectedParams = [self createExpectedLoginParamsWithHashedPassword:user AndSeed:@"1234567" AndCaptcha:nil];
    //when
    self.client.afSuccessBlock(nil,seed);
    //then
    [verify(serverParamsManager) userForServer:anything()];
    [verify(serverParamsManager) setSeed:equalTo(seed.seed) ForServer:anything()];
    [verify(self.operationManager) POST:@"" parameters:equalTo(expectedParams) success:anything() failure:anything()];
}

-(void)test_shouldSetupSeedResponseBlockAndCallFailureWithLoginError_WhenReceivedSeedResponseWithCaptcha {
    //given
    SeedResponse *seed = [SeedResponse seedWithCaptcha:@"1234567"];
    [self setupEmptyResult];
    [self setupClientSuccessAndFailureBlocks];
    NSError *error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorGetSeedWithCaptcha userInfo:nil];
    self.expectedResult = [BlocksCallResult failureWithError:error];
    [self.client setupAFFailureBlock];
    [self.client setupSeedSuccessBlock];
    //when
    self.client.afSuccessBlock(nil,seed);
    //then
    [verify(serverParamsManager) setSeed:equalTo(seed.seed) ForServer:anything()];
    [verifyCount(serverParamsManager,never()) userForServer:anything()];
    [verifyCount(self.operationManager,never()) POST:anything() parameters:anything() success:anything() failure:anything()];
    [self assertResultEqualsExpectedResult];
}


#pragma mark - Login

-(void)test_shouldCallAFNetworkingMethodWithParams_WhenLoginCalled {
    User* user = [self exampleUser];
    NSString *seed = @"1234567";
    [given([serverParamsManager seedForServer:anything()]) willReturn:@"1234567"];
    NSDictionary *expectedParams = [self createExpectedLoginParamsWithHashedPassword:user AndSeed:seed AndCaptcha:nil];
    [self.client setupAFFailureBlock];
    [self.client setupLoginSuccessBlock];
    //when
    [self.client login:user WithCaptcha:nil];
    //then
    assertThat(self.client.afSuccessBlock,notNilValue());
    assertThat(self.client.afFailureBlock,notNilValue());
    [self assertLoginResponseSerializer];
    [verify(serverParamsManager) seedForServer:anything()];
    [verify(self.operationManager) POST:@"" parameters:equalTo(expectedParams) success:self.client.afSuccessBlock failure:self.client.afFailureBlock];
}

-(void)test_shouldCallAFNetworkingMethodWithParams_WhenLoginWithCaptchaCalled {
    User* user = [self exampleUser];
    NSString *seed = @"1234567";
    NSString *captcha = @"captcha";
    [given([serverParamsManager seedForServer:anything()]) willReturn:@"1234567"];
    NSDictionary *expectedParams = [self createExpectedLoginParamsWithHashedPassword:user AndSeed:seed AndCaptcha:captcha];
    [self.client setupAFFailureBlock];
    [self.client setupLoginSuccessBlock];
    //when
    [self.client login:user WithCaptcha:captcha];
    //then
    assertThat(self.client.afSuccessBlock,notNilValue());
    assertThat(self.client.afFailureBlock,notNilValue());
    [self assertLoginResponseSerializer];
    [verify(serverParamsManager) seedForServer:anything()];
    [verify(self.operationManager) POST:@"" parameters:equalTo(expectedParams) success:self.client.afSuccessBlock failure:self.client.afFailureBlock];
}

-(void)test_shouldCallSuccessBlock_WhenLoginResultIsSuccess {
    LoginResponse *response = [[LoginResponse alloc] initWithValue:@"1" AndToken:@"token"];
    [self setupEmptyResult];
    [self setupClientSuccessAndFailureBlocks];
    self.expectedResult = [BlocksCallResult successWithResponse:nil];
    [self.client setupAFFailureBlock];
    [self.client setupLoginSuccessBlock];

    self.client.afSuccessBlock(nil,response);
    
    [verify(serverParamsManager) setSecureToken:equalTo(@"token") ForServer:anything()];
    [self assertResultEqualsExpectedResult];
    [self assertAllBlocksNiled];
    [self assertProgressIsNO];
}

-(void)test_shouldCallFailureBlock_WhenLoginResultISNotSuccessfulLogin {
    LoginResponse *response = [[LoginResponse alloc] initWithValue:@"-1" AndToken:@"token"];
    [self setupEmptyResult];
    [self setupClientSuccessAndFailureBlocks];
    NSError *error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
    self.expectedResult = [BlocksCallResult failureWithError:error];
    [self.client setupAFFailureBlock];
    [self.client setupLoginSuccessBlock];
    
    self.client.afSuccessBlock(nil,response);
    
    [verifyCount(serverParamsManager,never()) setSecureToken:anything() ForServer:anything()];
    [self assertResultEqualsExpectedResult];
    [self assertAllBlocksNiled];
    [self assertProgressIsNO];
}

-(void)test_shouldCallFailureWithCaptchaErrorBlock_WhenLoginResultIsCaptchaRequired {
    LoginResponse *response = [[LoginResponse alloc] initWithValue:@"-4" AndToken:@"token"];
    [self setupEmptyResult];
    [self setupClientSuccessAndFailureBlocks];
    NSError *error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorLoginWithCaptcha userInfo:nil];
    self.expectedResult = [BlocksCallResult failureWithError:error];
    [self.client setupAFFailureBlock];
    [self.client setupLoginSuccessBlock];
    
    self.client.afSuccessBlock(nil,response);
    
    [verifyCount(serverParamsManager,never()) setSecureToken:anything() ForServer:anything()];
    [self assertResultEqualsExpectedResult];
    [self assertAllBlocksNiled];
    [self assertProgressIsNO];
}

#pragma mark - Login process with blocks

-(void)test_shouldStartLoginWithCaptchaAndSetupLoginResponse_whenNotInProgress {
    //given
    User* user = [self exampleUser];
    NSString *captcha = @"captcha";
    NSString *seed = @"seed";
    [given([serverParamsManager userForServer:anything()]) willReturn:user];
    [given([serverParamsManager seedForServer:anything()]) willReturn:seed];
    [self setupEmptyResult];
    NSDictionary *expectedParams = [self createExpectedLoginParamsWithHashedPassword:user AndSeed:seed AndCaptcha:captcha];
    //when
    BOOL startResult = [self.client login:captcha WithSuccess:self.successBlock failure:self.failureBlock];
    //then
    assertThatBool(startResult,equalToBool(YES));
    [self assertProgressIsYES];
    [self assertAllBlocksNotNiled];
    [verify(self.operationManager) POST:@"" parameters:equalTo(expectedParams) success:self.client.afSuccessBlock failure:self.client.afFailureBlock];
}

-(void)test_shouldNotStartLoginWithCaptchaAndSetupLoginResponse_whenInProgress {
    //given
    [self setupEmptyResult];
    self.client.progress = YES;
    NSString *captcha = @"captcha";
    [self setupEmptyResult];
    //when
    BOOL startResult = [self.client login:captcha WithSuccess:self.successBlock failure:self.failureBlock];
    //then
    assertThatBool(startResult,equalToBool(NO));
    [verifyCount(serverParamsManager,never()) seedForServer:anything()];
    [self assertAllBlocksNiled];
    [verifyCount(self.operationManager,never()) POST:anything() parameters:anything() success:anything() failure:anything()];
}

#pragma mark - Whole Authorization process

-(void)test_shouldStartAuthorizeAndSetupClient_WhenNotInProgress {
    //given
    [self setupEmptyResult];
    //when
    BOOL startResult = [self.client authorizeWithSuccess:self.successBlock failure:self.failureBlock];
    //then
    assertThatBool(startResult,equalToBool(YES));
    [self assertProgressIsYES];
    [self assertAllBlocksNotNiled];
    [verify(self.operationManager) GET:INDEX parameters:@{@"get_action" : @"ping"} success:self.client.afSuccessBlock failure:self.client.afFailureBlock];
}

-(void)test_shouldNotStartAuthorizeAndSetupClient_WhenInProgress {
    //given
    [self setupEmptyResult];
    self.client.progress = YES;
    //when
    BOOL startResult = [self.client authorizeWithSuccess:self.successBlock failure:self.failureBlock];
    //then
    assertThatBool(startResult,equalToBool(NO));
    [self assertAllBlocksNiled];
    [verifyCount(self.operationManager,never()) GET:anything() parameters:anything() success:anything() failure:anything()];
}

#pragma mark - Invocation of Get Captcha

-(void)test_shouldSetupAndCallGetCaptchaBlock_whenSuccessResponseFromAFNetworking {
    //given
    NSData *data = [@"data" dataUsingEncoding:NSUTF8StringEncoding];
    self.expectedResult = [BlocksCallResult successWithResponse:data];
    [self setupEmptyResult];
    self.successBlock = nil;
    [self.client setupGetCaptchaSuccess];
    [self.client setupFailure:self.failureBlock];
    [self.client setupSuccess:[self.result successBlock]];
    self.client.progress = YES;
    //when
    self.client.afSuccessBlock(nil,data);
    //then
    [self assertResultEqualsExpectedResult];
    [self assertAllBlocksNiled];
    [self assertProgressIsNO];
}

-(void)test_shouldStartGetCaptcha_whenNotInProgress {
    //given
    NSDictionary *expectedParams = @{@"get_action": @"get_captcha"};
    [self setupEmptyResult];
    self.successBlock = [self.result successBlock];
    //when
    BOOL startResult = [self.client getCaptchaWithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [verify(self.operationManager) setResponseSerializer:instanceOf([GetCaptchaResponseSerializer class])];
    assertThatBool(startResult,equalToBool(YES));
    [self assertProgressIsYES];
    [self assertAllBlocksNotNiled];
    [verify(self.operationManager) GET:INDEX parameters:expectedParams success:self.client.afSuccessBlock failure:self.client.afFailureBlock];
}

-(void)test_shouldNotStartGetCaptcha_whenInProgress {
    //given
    self.client.progress = YES;
    [self setupEmptyResult];
    //when
    BOOL startResult = [self.client getCaptchaWithSuccess:nil failure:self.failureBlock];
    //then
    assertThatBool(startResult,equalToBool(NO));
    [self assertAllBlocksNiled];
    [verifyCount(self.operationManager,never()) GET:INDEX parameters:anything() success:anything() failure:anything()];
}

#pragma mark - Tests verification

-(void)assertAllBlocksNiled {
    assertThat(self.client.afSuccessBlock,nilValue());
    assertThat(self.client.afFailureBlock,nilValue());
    assertThat(self.client.successBlock,nilValue());
    assertThat(self.client.failureBlock,nilValue());
}

-(void)assertAllBlocksNotNiled {
    assertThat(self.client.afFailureBlock,notNilValue());
    assertThat(self.client.afSuccessBlock,notNilValue());
    assertThat(self.client.failureBlock,notNilValue());
    assertThat(self.client.successBlock,notNilValue());
}

-(void)assertResultEqualsExpectedResult {
    assertThat(self.result,equalTo(self.expectedResult));
}

-(void)assertProgressIsNO {
    assertThatBool(self.client.progress,equalToBool(NO));
}

-(void)assertProgressIsYES {
    assertThatBool(self.client.progress,equalToBool(YES));
}

-(void)assertLoginResponseSerializer {
    MKTArgumentCaptor *responseSerializer = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager)  setResponseSerializer:[responseSerializer capture]];
    assertThat([responseSerializer value],instanceOf([XMLResponseSerializer class]));
    assertThat(((XMLResponseSerializer*)[responseSerializer value]).serializerDelegate,instanceOf([LoginResponseSerializerDelegate class]));
}

#pragma mark - Helpers

-(void)setupEmptyResult {
    self.result = [BlocksCallResult result];
    self.successBlock = [self.result successBlock];
    self.failureBlock = [self.result failureBlock];
}

-(void)setupClientSuccessAndFailureBlocks {
    [self.client setupSuccess:self.successBlock AndFailure:self.failureBlock];
}

-(User*)exampleUser {
    User *user = [User userWithId:@"userid" AndPassword:@"pass"];
    
    return user;
}

-(void)clearAllClientBlocks {
    self.client.afSuccessBlock = nil;
    self.client.afFailureBlock = nil;
    self.client.successBlock = nil;
    self.client.failureBlock = nil;
}

-(void)setAFBlocksToNotNilValue {
    AFSuccessBlock block = ^(AFHTTPRequestOperation *operation, id responseObject){
    };
    self.client.afSuccessBlock = block;
    self.client.afFailureBlock = block;
}

@end
