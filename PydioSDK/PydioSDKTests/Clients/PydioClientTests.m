//
//  PydioClientTests.m
//  PydioSDK
//
//  Created by ME on 09/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "PydioClient.h"
#import <objc/runtime.h>
#import "BlocksCallResult.h"
#import "UnsignedIntegerBlockCallResult.h"
#import "AuthorizationClient.h"
#import "ServersParamsManager.h"
#import "PydioRequestOperationManager.h"
#import "User.h"
#import "OperationsClient.h"
#import "PydioErrors.h"
#import "ListNodesRequestParams.h"
#import "MkDirRequestParams.h"
#import "DeleteNodesRequestParams.h"
#import "DownloadNodesRequestParams.h"
#import "UploadNodesRequestParams.h"


static const int DEFAULT_TRIES_COUNT = 1;
static NSString * const TEST_SERVER_ADDRESS = @"http://www.testserver.com/";
static NSString * const TEST_USER_ID = @"testid";
static NSString * const TEST_USER_PASSWORD = @"testpassword";

static PydioRequestOperationManager* operationManager = nil;
static AuthorizationClient* authorizationClient = nil;
static OperationsClient* operationsClient = nil;

#pragma mark -

static StateChangeBlock stateChangeBlock = ^(PydioClientState newState){
    
};

#pragma mark - Exposing private members of tested class for test purposes

@interface PydioClient ()
@property(nonatomic,strong) AuthorizationClient* authorizationClient;
@property (nonatomic,copy) void(^operationBlock)();
@property (nonatomic,copy) void(^successBlock)(id response);
@property (nonatomic,copy) void(^failureBlock)(NSError* error);
@property (nonatomic,copy) void(^successResponseBlock)(id responseObject);
@property (nonatomic,copy) void(^failureResponseBlock)(NSError *error);
@property (nonatomic,assign) int authorizationsTriesCount;

-(void)setupCommons:(void(^)(id result))success failure:(void(^)(NSError *))failure;
@end

#pragma mark - Test client deriving original client

@interface TestPydioClient : PydioClient
@property (nonatomic,assign) BOOL wasSetupCommonsCalled;
@end

@implementation TestPydioClient

-(AuthorizationClient*)createAuthorizationClient {
    return authorizationClient;
}

-(PydioRequestOperationManager*)createOperationManager:(NSString*)server {
    return operationManager;
}

-(OperationsClient*)createOperationsClient {
    return operationsClient;
}

-(void)setupCommons:(void (^)(id))success failure:(void (^)(NSError *))failure {
    self.wasSetupCommonsCalled = YES;
    [super setupCommons:success failure:failure];
}

@end

#pragma mark - Tests

@interface PydioClientTests : XCTestCase
@property (nonatomic,strong) TestPydioClient* client;
@property (nonatomic,strong) BlocksCallResult *result;
@property (nonatomic,strong) BlocksCallResult *expectedResult;
@property (nonatomic,assign) SuccessBlock successBlock;
@property (nonatomic,assign) FailureBlock failureBlock;
@property (nonatomic,strong) UnsignedIntegerBlockCallResult *stateChangeUpdateResult;
@property (nonatomic,strong) UnsignedIntegerBlockCallResult *stateChangeExpectedResult;
@end


@implementation PydioClientTests

- (void)setUp
{
    [super setUp];
    operationManager = mock([PydioRequestOperationManager class]);
    authorizationClient = mock([AuthorizationClient class]);
    operationsClient = mock([OperationsClient class]);
    
    self.client = [[TestPydioClient alloc] initWithServer:TEST_SERVER_ADDRESS];
    [given([operationManager baseURL]) willReturn:[self helperServerURL]];
    [self setupAuthorizationClient:NO AndOperationsClient:NO];
}

- (void)tearDown
{
    operationManager = nil;
    authorizationClient = nil;
    operationsClient = nil;
    
    self.client = nil;
    [super tearDown];
}

#pragma mark - Test Basics

-(void)testInitialization
{
    assertThatBool(self.client.progress, equalToBool(NO));
    assertThat(self.client.serverURL, equalTo([self helperServerURL]));
    assertThatUnsignedInteger(self.client.state, equalToUnsignedInteger(PydioClientIdle));
}

-(void)test_shouldBeProgress_whenAuthorizationProgress
{
    self.client.authorizationClient = authorizationClient;
    [self setupAuthorizationClient:YES AndOperationsClient:NO];
    
    assertThatBool(self.client.progress, equalToBool(YES));
}

-(void)test_shouldBeProgress_whenOperationsProgress
{
    [self setupAuthorizationClient:NO AndOperationsClient:YES];
    
    assertThatBool(self.client.progress, equalToBool(YES));
}

-(void)test_shouldSetupAllBlocksAndResetTriesCount_whenSetingCommons
{
    [self setupEmptyResult];
    [self.client setupCommons:self.successBlock failure:self.failureBlock];
    
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(DEFAULT_TRIES_COUNT));
    [self assertClientBlocksSet];
}

#pragma mark - Test common handling of error and success responses

-(void)test_shouldTryToAuthorizeWithBlocksAsArguments_WhenReceivedAuthorizationErrorAndTriesCountIsGreaterThan0
{
    //given
    NSError *errorResponse = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorRequireAuthorization userInfo:nil];
    [self setupExpectedAndEmptyResult];
    [self setupClientForBlockResponse];
    self.client.operationBlock = ^{};
    [self setupStateChangeBlock:PydioClientAuthorization];
    //when
    self.client.failureResponseBlock(errorResponse);
    //then
    assertThat(self.result,equalTo(self.expectedResult));
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(0));
    [verify(authorizationClient) authorizeWithSuccess:self.client.operationBlock failure:self.client.failureResponseBlock];
    [self assertStateChangeExpectedResult];
}

-(void)test_shouldFailureAndNotTryToAuthorize_WhenReceivedAuthorizationErrorAndTriesCountIs0
{
    //given
    NSError *errorResponse = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
    self.expectedResult = [BlocksCallResult failureWithError:errorResponse];
    [self setupEmptyResult];
    [self setupClientForBlockResponse];
    self.client.authorizationsTriesCount = 0;
    [self setupStateChangeBlock:PydioClientFinished];
    //when
    self.client.failureResponseBlock(errorResponse);
    //then
    assertThat(self.result,equalTo(self.expectedResult));
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(0));
    assertThat(self.client.authorizationClient,nilValue());
    [verifyCount(authorizationClient,never()) authorizeWithSuccess:anything() failure:anything()];
    [self assertClientBlocksNiled];
    [self assertStateChangeExpectedResult];
}

-(void)test_shouldFailureAndNotTryToAuthorize_WhenReceivedSomeError
{
    //given
    NSError *errorResponse = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToParseAnswer userInfo:nil];
    self.expectedResult = [BlocksCallResult failureWithError:errorResponse];
    [self setupEmptyResult];
    [self setupClientForBlockResponse];
    [self setupStateChangeBlock:PydioClientFinished];
    //when
    self.client.failureResponseBlock(errorResponse);
    //then
    assertThat(self.result,equalTo(self.expectedResult));
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(DEFAULT_TRIES_COUNT));
    assertThat(self.client.authorizationClient,nilValue());
    [verifyCount(authorizationClient,never()) authorizeWithSuccess:anything() failure:anything()];
    [self assertClientBlocksNiled];
    [self assertStateChangeExpectedResult];
}

-(void)test_shouldCallSuccessBlock_WhenReceivedSuccessAnswer
{
    //given
    NSObject *object = [[NSObject alloc] init];
    self.expectedResult = [BlocksCallResult successWithResponse:object];
    [self setupEmptyResult];
    [self setupClientForBlockResponse];
    [self setupStateChangeBlock:PydioClientFinished];
    //when
    self.client.successResponseBlock(object);
    //then
    assertThat(self.result,equalTo(self.expectedResult));
    [self assertClientBlocksNiled];
    [self assertStateChangeExpectedResult];
}

#pragma mark - Test List Workspaces

-(void)test_ShouldNotStartListWorkspaces_WhenInProgress
{
    [self setupAuthorizationClient:NO AndOperationsClient:YES];
    [self setupExpectedAndEmptyResult];
    
    BOOL startResult = [self.client listWorkspacesWithSuccess:self.successBlock failure:self.successBlock];
    
    [verifyCount(operationsClient,never()) listWorkspacesWithSuccess:anything() failure:anything()];
    [self assertNotStartedOperationSetup:startResult];
}

-(void)test_ShouldStartListWorkspaces_WhenNotInProgress
{
    //given
    [self setupEmptyResult];
    [self setupStateChangeBlock:PydioClientOperation];
    //when
    BOOL startResult = [self.client listWorkspacesWithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [self assertStartedOperationSetupDefaultAuthTries:startResult];
    [verify(operationsClient) listWorkspacesWithSuccess:self.client.successResponseBlock failure:self.client.failureResponseBlock];
    [self assertStateChangeExpectedResult];
}

#pragma mark - Test List Files

-(void)test_ShouldNotStartListFiles_WhenInProgress
{
    ListNodesRequestParams *request = [self exampleListFilesRequest];
    [self setupAuthorizationClient:NO AndOperationsClient:YES];
    [self setupExpectedAndEmptyResult];
    
    BOOL startResult = [self.client listNodes:request WithSuccess:self.successBlock failure:self.failureBlock];
    
    [verifyCount(operationsClient,never()) listFiles:anything() WithSuccess:anything() failure:anything()];
    [self assertNotStartedOperationSetup:startResult];
}

-(void)test_ShouldStartListFiles_WhenNotInProgress
{
    //given
    ListNodesRequestParams *request = [self exampleListFilesRequest];
    NSDictionary *expectedParams = [self exampleListFilesDictionary];
    [self setupEmptyResult];
    [self setupStateChangeBlock:PydioClientOperation];
    //when
    BOOL startResult = [self.client listNodes:request WithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [self assertStartedOperationSetupDefaultAuthTries:startResult];
    [verify(operationsClient) listFiles:equalTo(expectedParams) WithSuccess:self.client.successResponseBlock failure:self.client.failureResponseBlock];
    [self assertStateChangeExpectedResult];
}

#pragma mark - Test mkdir

-(void)test_ShouldNotStartMkDir_WhenInProgress
{
    MkDirRequestParams *request = [self exampleMkDirRequestParams];
    [self setupAuthorizationClient:NO AndOperationsClient:YES];
    [self setupExpectedAndEmptyResult];
    
    BOOL startResult = [self.client mkdir:request WithSuccess:self.successBlock failure:self.failureBlock];
    
    [verifyCount(operationsClient,never()) mkdir:anything() WithSuccess:anything() failure:anything()];
    [self assertNotStartedOperationSetup:startResult];
}

-(void)test_ShouldStartMkDir_WhenNotInProgress
{
    //given
    MkDirRequestParams *request = [self exampleMkDirRequestParams];
    NSDictionary *expectedParams = [self exampleMkDirRequestParamsDictionary];
    [self setupEmptyResult];
    [self setupStateChangeBlock:PydioClientOperation];
    //when
    BOOL startResult = [self.client mkdir:request WithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [self assertStartedOperationSetupDefaultAuthTries:startResult];
    [verify(operationsClient) mkdir:equalTo(expectedParams) WithSuccess:self.client.successResponseBlock failure:self.client.failureResponseBlock];
    [self assertStateChangeExpectedResult];
}

#pragma mark - Test authorize

-(void)test_ShouldNotStartAuthorize_WhenInProgress
{
    [self setupAuthorizationClient:NO AndOperationsClient:YES];
    [self setupExpectedAndEmptyResult];
    
    BOOL startResult = [self.client authorizeWithSuccess:self.successBlock failure:self.failureBlock];
    
    [verifyCount(authorizationClient,never()) authorizeWithSuccess:anything() failure:anything()];
    [self assertNotStartedOperationSetup:startResult];
}

-(void)test_ShouldStartAuthorize_WhenNotInProgress
{
    //given
    [self setupEmptyResult];
    [self setupStateChangeBlock:PydioClientAuthorization];
    //when
    BOOL startResult = [self.client authorizeWithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [self assertStartedOperationSetup0AuthTries:startResult];
    [verify(authorizationClient) authorizeWithSuccess:self.client.successResponseBlock failure:self.client.failureResponseBlock];
    [self assertStateChangeExpectedResult];
}

#pragma mark - Test delete nodes

-(void)test_ShouldNotStartDeleteNodes_WhenInProgress
{
    DeleteNodesRequestParams *request = [self exampleDeleteNodesRequestParams];
    [self setupAuthorizationClient:NO AndOperationsClient:YES];
    [self setupExpectedAndEmptyResult];
    
    BOOL startResult = [self.client deleteNodes:request WithSuccess:self.successBlock failure:self.failureBlock];
    
    [verifyCount(operationsClient,never()) deleteNodes:anything() WithSuccess:anything() failure:anything()];
    [self assertNotStartedOperationSetup:startResult];
}

-(void)test_ShouldStartDeleteNodes_WhenNotInProgress
{
    //given
    DeleteNodesRequestParams *request = [self exampleDeleteNodesRequestParams];
    NSDictionary *expectedParams = [self exampleDeleteNodesDictionary];
    [self setupEmptyResult];
    [self setupStateChangeBlock:PydioClientOperation];
    //when
    BOOL startResult = [self.client deleteNodes:request WithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [self assertStartedOperationSetupDefaultAuthTries:startResult];
    [verify(operationsClient) deleteNodes:equalTo(expectedParams) WithSuccess:self.client.successResponseBlock failure:self.client.failureResponseBlock];
    [self assertStateChangeExpectedResult];
}

#pragma mark - Test login with captcha

-(void)test_shouldNotStartLogin_whenInProgress
{
    //given
    NSString *captcha = @"captcha";
    [self setupAuthorizationClient:NO AndOperationsClient:YES];
    [self setupExpectedAndEmptyResult];
    //when
    BOOL startResult = [self.client login:captcha WithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [self assertNotStartedOperationSetup:startResult];
    [verifyCount(authorizationClient,never()) login:anything() WithSuccess:anything() failure:anything()];
}

-(void)test_shouldStartLogin_whenNotInProgress
{
    //given
    NSString *captcha = @"captcha";
    [self setupEmptyResult];
    [self setupStateChangeBlock:PydioClientAuthorization];
    //when
    BOOL startResult = [self.client login:captcha WithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [self assertStartedOperationSetup0AuthTries:startResult];
    [verify(authorizationClient) login:equalTo(captcha) WithSuccess:self.client.successResponseBlock failure:self.client.failureResponseBlock];
    [self assertStateChangeExpectedResult];
}

#pragma mark - Get Captcha

-(void)test_shouldNotStartGetCaptcha_whenInProgress
{
    //given
    [self setupAuthorizationClient:NO AndOperationsClient:YES];
    [self setupExpectedAndEmptyResult];
    //when
    BOOL startResult = [self.client getCaptchaWithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [self assertNotStartedOperationSetup:startResult];
    [verifyCount(authorizationClient,never()) getCaptchaWithSuccess:anything() failure:anything()];
}

-(void)test_shouldStartGetCaptcha_whenNotInProgress
{
    //given
    [self setupEmptyResult];
    [self setupStateChangeBlock:PydioClientOperation];
    //when
    BOOL startResult = [self.client getCaptchaWithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [self assertStartedOperationSetup0AuthTries:startResult];
    [verify(authorizationClient) getCaptchaWithSuccess:self.client.successResponseBlock failure:self.client.failureResponseBlock];
    [self assertStateChangeExpectedResult];
}

#pragma mark - Download Nodes

-(void)test_shouldNotStartDownloadNodes_WhenInProgress
{
    //given
    DownloadNodesRequestParams *request = [self exampleDownloadNodesRequestParams];
    [self setupAuthorizationClient:NO AndOperationsClient:YES];
    [self setupExpectedAndEmptyResult];
    //when
    BOOL startResult = [self.client downloadNodes:request WithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [verifyCount(operationsClient,never()) downloadNodes:anything() WithSuccess:anything() failure:anything()];
    [self assertNotStartedOperationSetup:startResult];
}

-(void)test_shouldNotStartDownloadNodes_WhenNotInProgress
{
    //given
    DownloadNodesRequestParams *request = [self exampleDownloadNodesRequestParams];
    NSDictionary *expectedParams = [self exampleDownloadNodesDictionary];
    [self setupEmptyResult];
    [self setupStateChangeBlock:PydioClientOperation];
    //when
    BOOL startResult = [self.client downloadNodes:request WithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [self assertStartedOperationSetupDefaultAuthTries:startResult];
    [verify(operationsClient) downloadNodes:equalTo(expectedParams) WithSuccess:self.client.successResponseBlock failure:self.client.failureResponseBlock];
    [self assertStateChangeExpectedResult];
}

#pragma mark - Download Nodes

-(void)test_shouldNotStartUploadNodes_WhenInProgress
{
    //given
    UploadNodesRequestParams *request = [self exampleUploadNodesRequestParams];
    [self setupAuthorizationClient:NO AndOperationsClient:YES];
    [self setupExpectedAndEmptyResult];
    //when
    BOOL startResult = [self.client uploadNodes:request WithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [verifyCount(operationsClient,never()) uploadNodes:anything() WithSuccess:anything() failure:anything()];
    [self assertNotStartedOperationSetup:startResult];
}

-(void)test_shouldNotStartUploadNodes_WhenNotInProgress
{
    //given
    UploadNodesRequestParams *request = [self exampleUploadNodesRequestParams];
    NSDictionary *expectedParams = [self exampleUploadNodesDictionary];
    [self setupEmptyResult];
    [self setupStateChangeBlock:PydioClientOperation];
    //when
    BOOL startResult = [self.client uploadNodes:request WithSuccess:self.successBlock failure:self.failureBlock];
    //then
    [self assertStartedOperationSetupDefaultAuthTries:startResult];
    [verify(operationsClient) uploadNodes:equalTo(expectedParams) WithSuccess:self.client.successResponseBlock failure:self.client.failureResponseBlock];
    [self assertStateChangeExpectedResult];
}

#pragma mark - Tests Verification

-(void)setupAuthorizationClient:(BOOL) authProgress AndOperationsClient: (BOOL)operationsProgress {
    [given([authorizationClient progress]) willReturnBool:authProgress];
    [given([operationsClient progress]) willReturnBool:operationsProgress];
}

-(void)assertClientBlocksNiled {
    assertThat(self.client.operationBlock,nilValue());
    assertThat(self.client.successBlock,nilValue());
    assertThat(self.client.failureBlock,nilValue());
    assertThat(self.client.successResponseBlock,nilValue());
    assertThat(self.client.failureResponseBlock,nilValue());
}

-(void)assertClientBlocksSet {
    assertThat(self.client.successBlock,sameInstance(self.successBlock));
    assertThat(self.client.failureBlock,sameInstance(self.failureBlock));
    assertThat(self.client.successResponseBlock,notNilValue());
    assertThat(self.client.failureResponseBlock,notNilValue());
}

-(void)assertStartedOperationSetupDefaultAuthTries:(BOOL)startResult {
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(DEFAULT_TRIES_COUNT));
    [self assertStartedOperationSetup:startResult];
}

-(void)assertStartedOperationSetup0AuthTries:(BOOL)startResult {
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(0));
    [self assertStartedOperationSetup:startResult];
}

-(void)assertStartedOperationSetup:(BOOL)startResult {
    assertThatBool(self.client.wasSetupCommonsCalled, equalToBool(YES));
    assertThatBool(startResult, equalToBool(YES));
    [self assertClientBlocksSet];
    assertThat(self.client.operationBlock,notNilValue());
}

-(void)assertNotStartedOperationSetup:(BOOL)startResult {
    assertThatBool(self.client.wasSetupCommonsCalled, equalToBool(NO));
    assertThatBool(startResult, equalToBool(NO));
    assertThat(self.result,equalTo(self.expectedResult));
    [self assertClientBlocksNiled];
}

-(void)assertStateChangeExpectedResult {
    assertThat(self.stateChangeUpdateResult,equalTo(self.stateChangeExpectedResult));
    assertThatUnsignedInteger(self.client.state, equalToUnsignedInteger(self.stateChangeExpectedResult.argument));
}

#pragma mark - Helpers

-(void)setupExpectedAndEmptyResult {
    self.expectedResult = [BlocksCallResult result];
    [self setupEmptyResult];
}

-(void)setupEmptyResult {
    self.result = [BlocksCallResult result];
    self.successBlock = [self.result successBlock];
    self.failureBlock = [self.result failureBlock];
}

-(void)setupStateChangeBlock:(PydioClientState)expectedState {
    self.stateChangeUpdateResult = [[UnsignedIntegerBlockCallResult alloc] init];
    self.client.stateChangeBlock = [self.stateChangeUpdateResult block];
    self.stateChangeExpectedResult = [UnsignedIntegerBlockCallResult blockCalledWith:expectedState];
}

-(void)setupClientForBlockResponse {
    [self.client setupCommons:self.successBlock failure:self.failureBlock];
}

-(NSURL*)helperServerURL {
    return [NSURL URLWithString:TEST_SERVER_ADDRESS];
}

-(User *)helperUser {
    return [User userWithId:TEST_USER_ID AndPassword:TEST_USER_PASSWORD];
}

-(ListNodesRequestParams*) exampleListFilesRequest {
    ListNodesRequestParams *request = [[ListNodesRequestParams alloc] init];
    request.workspaceId = @"testworkspaceid";
    request.path = @"/testpath";
    
    return request;
}

-(NSDictionary*) exampleListFilesDictionary {
    return @{
             @"tmp_repository_id": @"testworkspaceid",
             @"dir" : @"/testpath",
             @"options" : @"al"
             };
}

-(MkDirRequestParams*) exampleMkDirRequestParams {
    MkDirRequestParams *request = [[MkDirRequestParams alloc] init];
    request.workspaceId = @"testworkspaceid";
    request.dir = @"/testdir/testdir";
    request.dirname = @"nameofdir";
    
    return request;
}

-(NSDictionary*) exampleMkDirRequestParamsDictionary {
    return @{
             @"tmp_repository_id": @"testworkspaceid",
             @"dir" : @"/testdir/testdir",
             @"dirname" : @"nameofdir"
             };
}

-(DeleteNodesRequestParams*)exampleDeleteNodesRequestParams {
    DeleteNodesRequestParams *params = [[DeleteNodesRequestParams alloc] init];
    params.workspaceId = @"testworkspaceid";
    params.nodes = [NSArray arrayWithObject:@"/testdir/testdir"];
    
    return params;
}

-(NSDictionary*)exampleDeleteNodesDictionary {
    return @{
             @"tmp_repository_id": @"testworkspaceid",
             @"nodes" : [NSArray arrayWithObject:@"/testdir/testdir"]
             };
}

-(DownloadNodesRequestParams*)exampleDownloadNodesRequestParams {
    DownloadNodesRequestParams *params = [[DownloadNodesRequestParams alloc] init];
    params.workspaceId = @"testworkspaceid";
    params.nodes = [NSArray arrayWithObject:@"/testdir/testdir"];
    
    return params;
}

-(NSDictionary*)exampleDownloadNodesDictionary {
    return @{
             @"tmp_repository_id": @"testworkspaceid",
             @"nodes" : [NSArray arrayWithObject:@"/testdir/testdir"]
             };
}

-(UploadNodesRequestParams*)exampleUploadNodesRequestParams {
    UploadNodesRequestParams *params = [[UploadNodesRequestParams alloc] init];
    params.workspaceId = @"testworkspaceid";
    params.node = @"/testdir/testdir";
    params.fileName = @"filename";
    params.data = [@"data" dataUsingEncoding:NSUTF8StringEncoding];
    
    return params;
}

-(NSDictionary*)exampleUploadNodesDictionary {
    return @{
             @"tmp_repository_id": @"testworkspaceid",
             @"node" : @"/testdir/testdir",
             @"urlencoded_filename" : @"filename",
             @"filename" : [@"data" dataUsingEncoding:NSUTF8StringEncoding]
            };
}


@end
