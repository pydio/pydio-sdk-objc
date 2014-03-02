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
#import "AuthCredentials.h"
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
@property (nonatomic,copy) AFSuccessBlock pingSuccessBlock;
@property (nonatomic,copy) AFSuccessBlock seedSuccessBlock;
@property (nonatomic,copy) AFSuccessBlock loginSuccessBlock;
@property (nonatomic,copy) void(^afFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
@property (nonatomic,copy) void(^successBlock)();
@property (nonatomic,copy) void(^failureBlock)(NSError* error);

-(NSString *)hashedPass:(NSString*)pass WithSeed:(NSString *)seed;
-(void)setupSuccess:(void(^)())success AndFailure:(void(^)(NSError*))failure;
-(void)setupAFFailureBlock;
-(void)setupPingSuccessBlock;
-(void)setupSeedSuccessBlock;
-(void)setupLoginSuccessBlock;
-(void)ping;
-(void)getSeed;
-(void)loginWithCredentials:(AuthCredentials*)credentials;
@end

#pragma mark - Class made for test purposes

@interface TestedAuthorizationClient : AuthorizationClient
@property (nonatomic,assign) BOOL callTestVariant;
@property (nonatomic,assign) BOOL callSetupsTestVariant;
@property (nonatomic,assign) BOOL wasPingCalled;
@property (nonatomic,assign) BOOL wasGetSeedCalled;
@property (nonatomic,assign) BOOL wasLoginWithCredentialsCalled;

@property (nonatomic,assign) BOOL wasSetupSuccessAndFailureCalled;
@property (nonatomic,assign) BOOL wasSetupPingCalled;
@property (nonatomic,assign) BOOL wasSetupGetSeedCalled;
@property (nonatomic,assign) BOOL wasSetupLoginCalled;
@property (nonatomic,assign) BOOL wasSetupAFFailureCalled;

@property (nonatomic,strong) AuthCredentials* loginAuthCredentials;
@end

@implementation TestedAuthorizationClient

-(void)setupSuccess:(void(^)())success AndFailure:(void(^)(NSError*))failure {
    if (self.callSetupsTestVariant) {
        self.wasSetupSuccessAndFailureCalled = YES;
    } else {
        [super setupSuccess:success AndFailure:failure];
    }
}

-(void)setupAFFailureBlock {
    if (self.callSetupsTestVariant) {
        self.wasSetupAFFailureCalled = YES;
    } else {
        [super setupAFFailureBlock];
    }
}

-(void)setupPingSuccessBlock {
    if (self.callSetupsTestVariant) {
        self.wasSetupPingCalled = YES;
    } else {
        [super setupPingSuccessBlock];
    }
}

-(void)setupSeedSuccessBlock {
    if (self.callSetupsTestVariant) {
        self.wasSetupGetSeedCalled = YES;
    } else {
        [super setupSeedSuccessBlock];
    }
}

-(void)setupLoginSuccessBlock {
    if (self.callSetupsTestVariant) {
        self.wasSetupLoginCalled = YES;
    } else {
        [super setupLoginSuccessBlock];
    }
}


-(void)ping {
    if (self.callTestVariant) {
        self.wasPingCalled = YES;
    } else {
        [super ping];
    }
}

-(void)getSeed {
    if (self.callTestVariant) {
        self.wasGetSeedCalled = YES;
    } else {
        [super getSeed];
    }
}

-(void)loginWithCredentials:(AuthCredentials*)credentials {
    if (self.callTestVariant) {
        self.wasLoginWithCredentialsCalled = YES;
        self.loginAuthCredentials = credentials;
    } else {
        [super loginWithCredentials:credentials];
    }
}

@end

#pragma mark -

@interface AuthorizationClientTests : XCTestCase {
    Method _methodToExchange;
    IMP _originalIMP;
}
@property (nonatomic,strong) TestedAuthorizationClient* client;
@property (nonatomic,strong) AFHTTPRequestOperationManager *operationManager;

@property (nonatomic,assign) BlocksCallResult *result;
@property (nonatomic,assign) BlocksCallResult *expectedResult;
@property (nonatomic,assign) void(^successBlock)();
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
    self.client = [[TestedAuthorizationClient alloc] init];
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

-(NSDictionary*)createExpectedLoginParamsWithHashedPassword:(AuthCredentials*)credentials {
    return @{@"get_action": @"login",
             @"userid": credentials.userid,
             @"password": [[NSString stringWithFormat:@"%@%@", [credentials.password md5], credentials.seed] md5],
             @"login_seed" : credentials.seed
             };
}

#pragma mark - Inocation of success and failure blocks

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
    
    self.client.successBlock();
    
    [self assertResultEqualsExpectedResult];
    [self assertAllBlocksNiled];
    [self assertProgressIsNO];
}

-(void)test_shouldClearAllBlocks_WhenFailureBlockCalled {
    NSError *error = [NSError errorWithDomain:@"domain" code:1 userInfo:nil];
    self.expectedResult = [BlocksCallResult failureWithError:error];
    self.client.progress = YES;
    [self setupEmptyResult];
    [self setupClientSuccessAndFailureBlocks];
    
    self.client.failureBlock(error);
    
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

#pragma mark - Invocation of ping

-(void)test_shouldCallAFNetworkingMethodWithParams_WhenPingCalled {
    NSDictionary *expectedParams = @{@"get_action" : @"ping"};
    [self.client setupAFFailureBlock];
    [self.client setupPingSuccessBlock];
    
    [self.client ping];
    
    assertThat(self.client.pingSuccessBlock,notNilValue());
    assertThat(self.client.afFailureBlock,notNilValue());
    [verify(self.operationManager) GET:INDEX parameters:expectedParams success:self.client.pingSuccessBlock failure:self.client.afFailureBlock];
}

-(void)test_shouldSetupPingResponseBlockAndCallGetSeed_WhenPingSuccessBlockWasCalled {
    self.client.callTestVariant = YES;
    
    [self.client setupPingSuccessBlock];
    self.client.pingSuccessBlock(nil,[[NSObject alloc] init]);
    
    assertThatBool(self.client.wasGetSeedCalled,equalToBool(YES));
}

#pragma mark - Invocation of Get Seed

-(void)test_shouldCallAFNetworkingMethodWithParams_WhenGetSeedCalled {
    NSDictionary *expectedParams = @{@"get_action" : @"get_seed"};
    [self.client setupAFFailureBlock];
    [self.client setupSeedSuccessBlock];
    
    [self.client getSeed];
    
    assertThat(self.client.seedSuccessBlock,notNilValue());
    assertThat(self.client.afFailureBlock,notNilValue());

    [verify(self.operationManager) setResponseSerializer:instanceOf([GetSeedResponseSerializer class])];
    [verify(self.operationManager) GET:INDEX parameters:expectedParams success:self.client.seedSuccessBlock failure:self.client.afFailureBlock];
}

-(void)test_shouldSetupSeedResponseBlockAndCallLogin_WhenSeedSuccessBlockWasCalled {
    User* user = [self exampleUser];
    SeedResponse *seed = [SeedResponse seed:@"1234567"];
    AuthCredentials *expectedCredenials = [[AuthCredentials alloc] initWith:user AndSeed:@"1234567"];
    [given([serverParamsManager userForServer:anything()]) willReturn:user];
    self.client.callTestVariant = YES;

    [self.client setupSeedSuccessBlock];
    self.client.seedSuccessBlock(nil,seed);
    
    [verify(serverParamsManager) userForServer:anything()];
    assertThatBool(self.client.wasLoginWithCredentialsCalled,equalToBool(YES));
    assertThat(self.client.loginAuthCredentials,equalTo(expectedCredenials));
}

-(void)test_shouldSetupSeedResponseBlockAndCallFailureWithLoginError_WhenReceivedSeedResponseWithCaptcha {
    SeedResponse *seed = [SeedResponse seedWithCaptcha:@"1234567"];
    [self setupEmptyResult];
    [self setupClientSuccessAndFailureBlocks];
    NSError *error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorGetSeedWithCaptcha userInfo:@{ PydioErrorSeedKey : @"1234567"}];
    self.expectedResult = [BlocksCallResult failureWithError:error];
    [self.client setupAFFailureBlock];
    
    [self.client setupSeedSuccessBlock];
    self.client.seedSuccessBlock(nil,seed);

    [self assertResultEqualsExpectedResult];
}


#pragma mark - Login

-(void)test_shouldCallAFNetworkingMethodWithParams_WhenLoginCalled {
    User* user = [self exampleUser];
    NSString *seed = @"1234567";
    AuthCredentials *credenials = [[AuthCredentials alloc] initWith:user AndSeed:seed];
    NSDictionary *expectedParams = [self createExpectedLoginParamsWithHashedPassword:credenials];
    [self.client setupAFFailureBlock];
    [self.client setupLoginSuccessBlock];

    [self.client loginWithCredentials:credenials];

    assertThat(self.client.loginSuccessBlock,notNilValue());
    assertThat(self.client.afFailureBlock,notNilValue());
    MKTArgumentCaptor *responseSerializer = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager)  setResponseSerializer:[responseSerializer capture]];
    assertThat([responseSerializer value],instanceOf([XMLResponseSerializer class]));
    assertThat(((XMLResponseSerializer*)[responseSerializer value]).serializerDelegate,instanceOf([LoginResponseSerializerDelegate class]));
    [verify(self.operationManager) POST:@"" parameters:equalTo(expectedParams) success:self.client.loginSuccessBlock failure:self.client.afFailureBlock];
}

-(void)test_shouldCallSuccessBlock_WhenLoginResultIsSuccess {
    LoginResponse *response = [[LoginResponse alloc] initWithValue:@"1" AndToken:@"token"];
    [self setupEmptyResult];
    [self setupClientSuccessAndFailureBlocks];
    self.expectedResult = [BlocksCallResult successWithResponse:nil];
    [self.client setupAFFailureBlock];
    [self.client setupLoginSuccessBlock];

    self.client.loginSuccessBlock(nil,response);
    
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
    
    self.client.loginSuccessBlock(nil,response);
    
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
    
    self.client.loginSuccessBlock(nil,response);
    
    [verifyCount(serverParamsManager,never()) setSecureToken:anything() ForServer:anything()];
    [self assertResultEqualsExpectedResult];
    [self assertAllBlocksNiled];
    [self assertProgressIsNO];
}

#pragma mark - Whole Authorization process

-(void)test_shouldStartAuthorizeAndSetupClient_WhenNotInProgress {
    [self setupEmptyResult];
    self.client.callSetupsTestVariant = YES;
    self.client.callTestVariant = YES;
    
    BOOL startResult = [self.client authorizeWithSuccess:self.successBlock failure:self.failureBlock];
    
    assertThatBool(startResult,equalToBool(YES));
    [self assertProgressIsYES];
    [self assertAllSetupsWereCalled];
    assertThatBool(self.client.wasPingCalled,equalToBool(YES));
}

-(void)test_shouldNotStartAuthorizeAndSetupClient_WhenInProgress {
    [self setupEmptyResult];
    self.client.progress = YES;
    self.client.callSetupsTestVariant = YES;
    self.client.callTestVariant = YES;
    
    BOOL startResult = [self.client authorizeWithSuccess:self.successBlock failure:self.failureBlock];

    assertThatBool(startResult,equalToBool(NO));
    [self assertNoneSetupWasCalled];
    assertThatBool(self.client.wasPingCalled,equalToBool(NO));
}

#pragma mark - Tests verification

-(void)assertAllBlocksNiled {
    assertThat(self.client.pingSuccessBlock,nilValue());
    assertThat(self.client.seedSuccessBlock,nilValue());
    assertThat(self.client.loginSuccessBlock,nilValue());
    assertThat(self.client.afFailureBlock,nilValue());
    assertThat(self.client.successBlock,nilValue());
    assertThat(self.client.failureBlock,nilValue());
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

-(void)assertAllSetupsWereCalled {
    assertThatBool(self.client.wasSetupAFFailureCalled,equalToBool(YES));
    assertThatBool(self.client.wasSetupPingCalled,equalToBool(YES));
    assertThatBool(self.client.wasSetupGetSeedCalled,equalToBool(YES));
    assertThatBool(self.client.wasSetupLoginCalled,equalToBool(YES));
    assertThatBool(self.client.wasSetupSuccessAndFailureCalled,equalToBool(YES));
}

-(void)assertNoneSetupWasCalled {
    assertThatBool(self.client.wasSetupAFFailureCalled,equalToBool(NO));
    assertThatBool(self.client.wasSetupPingCalled,equalToBool(NO));
    assertThatBool(self.client.wasSetupGetSeedCalled,equalToBool(NO));
    assertThatBool(self.client.wasSetupLoginCalled,equalToBool(NO));
    assertThatBool(self.client.wasSetupSuccessAndFailureCalled,equalToBool(NO));
}

#pragma mark - Helpers

-(void)setupEmptyResult {
    self.result = [BlocksCallResult result];
    self.successBlock = [self.result voidSuccessBlock];
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
    self.client.pingSuccessBlock = nil;
    self.client.seedSuccessBlock = nil;
    self.client.loginSuccessBlock = nil;
    self.client.afFailureBlock = nil;
    self.client.successBlock = nil;
    self.client.failureBlock = nil;
}

@end
