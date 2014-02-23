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
#import "AuthorizationClient.h"
#import "ServerDataManager.h"
#import "AFHTTPRequestOperationManager.h"
#import "User.h"
#import "OperationsClient.h"
#import "PydioErrors.h"
#import "ListNodesRequestParams.h"
#import "MkDirRequestParams.h"


static const int DEFAULT_TRIES_COUNT = 1;
static NSString * const TEST_SERVER_ADDRESS = @"http://www.testserver.com/";
static NSString * const TEST_USER_ID = @"testid";
static NSString * const TEST_USER_PASSWORD = @"testpassword";

static AFHTTPRequestOperationManager* operationManager = nil;
static AuthorizationClient* authorizationClient = nil;
static OperationsClient* operationsClient = nil;

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
@end

@implementation TestPydioClient

-(AuthorizationClient*)createAuthorizationClient {
    return authorizationClient;
}

-(AFHTTPRequestOperationManager*)createOperationManager:(NSString*)server {
    return operationManager;
}

-(OperationsClient*)createOperationsClient {
    return operationsClient;
}

@end

#pragma mark - Testing class

@interface PydioClientTests : XCTestCase
@property (nonatomic,strong) TestPydioClient* client;
@end


@implementation PydioClientTests

- (void)setUp
{
    [super setUp];
    operationManager = mock([AFHTTPRequestOperationManager class]);
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
}

-(void)test_shouldBeProgress_whenAuthorizationProgress
{
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
    BlocksCallResult *result = [BlocksCallResult result];
    SuccessBlock successBlock = [result successBlock];
    FailureBlock failureBlock = [result failureBlock];
    [self.client setupCommons:successBlock failure:failureBlock];
    
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(DEFAULT_TRIES_COUNT));
    assertThat(self.client.successBlock,sameInstance(successBlock));
    assertThat(self.client.failureBlock,sameInstance(failureBlock));
    assertThat(self.client.successResponseBlock,notNilValue());
    assertThat(self.client.failureResponseBlock,notNilValue());
}

#pragma mark - Test common handling of error and success responses

-(void)test_shouldTryToAuthorizeWithBlocksAsArguments_WhenReceivedAuthorizationErrorAndTriesCountIsGreaterThan0
{
    NSError *errorResponse = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
    BlocksCallResult *expectedResult = [BlocksCallResult result];
    BlocksCallResult *result = [BlocksCallResult result];
    [self setupClientForBlockResponse:result];
    self.client.operationBlock = ^{};
    
    self.client.failureResponseBlock(errorResponse);
    
    assertThat(result,equalTo(expectedResult));
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(0));
    [verify(self.client.authorizationClient) authorizeWithSuccess:self.client.operationBlock failure:self.client.failureResponseBlock];
}

-(void)test_shouldFailureAndNotTryToAuthorize_WhenReceivedAuthorizationErrorAndTriesCountIs0
{
    NSError *errorResponse = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
    BlocksCallResult *expectedResult = [BlocksCallResult failureWithError:errorResponse];
    BlocksCallResult *result = [BlocksCallResult result];
    [self setupClientForBlockResponse:result];
    self.client.authorizationsTriesCount = 0;
    
    self.client.failureResponseBlock(errorResponse);
    
    assertThat(result,equalTo(expectedResult));
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(0));
    [verifyCount(self.client.authorizationClient,never()) authorizeWithSuccess:anything() failure:anything()];
    [self assertClientBlocksNiled];
}

-(void)test_shouldFailureAndNotTryToAuthorize_WhenReceivedSomeError
{
    NSError *errorResponse = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToParseAnswer userInfo:nil];
    BlocksCallResult *expectedResult = [BlocksCallResult failureWithError:errorResponse];
    BlocksCallResult *result = [BlocksCallResult result];
    [self setupClientForBlockResponse:result];
    
    self.client.failureResponseBlock(errorResponse);
    
    assertThat(result,equalTo(expectedResult));
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(DEFAULT_TRIES_COUNT));
    [verifyCount(self.client.authorizationClient,never()) authorizeWithSuccess:anything() failure:anything()];
    [self assertClientBlocksNiled];
}

-(void)test_shouldCallSuccessBlock_WhenReceivedSuccessAnswer
{
    NSObject *object = [[NSObject alloc] init];
    BlocksCallResult *expectedResult = [BlocksCallResult successWithResponse:object];
    BlocksCallResult *result = [BlocksCallResult result];
    [self setupClientForBlockResponse:result];

    self.client.successResponseBlock(object);
    
    assertThat(result,equalTo(expectedResult));
    [self assertClientBlocksNiled];
}

#pragma mark - Test List Workspaces

-(void)test_ShouldNotStartListWorkspaces_WhenInProgress
{
    [self setupAuthorizationClient:YES AndOperationsClient:NO];
    BlocksCallResult *expectedResult = [BlocksCallResult result];
    BlocksCallResult *result = [BlocksCallResult result];
    
    BOOL startResult = [self.client listWorkspacesWithSuccess:[result successBlock] failure:[result failureBlock]];
    
    assertThatBool(startResult, equalToBool(NO));
    assertThat(result,equalTo(expectedResult));
    [verifyCount(operationsClient,never()) listWorkspacesWithSuccess:anything() failure:anything()];
    [self assertClientBlocksNiled];
}

-(void)test_ShouldStartListWorkspaces_WhenNotInProgress
{
    BlocksCallResult *result = [BlocksCallResult result];
    SuccessBlock successBlock = [result successBlock];
    FailureBlock failureBlock = [result failureBlock];
    
    BOOL startResult = [self.client listWorkspacesWithSuccess:successBlock failure:failureBlock];
    
    [self assertOperationSetupDefaultAuthTries:startResult success:successBlock failure:failureBlock];
    [verify(operationsClient) listWorkspacesWithSuccess:self.client.successResponseBlock failure:self.client.failureResponseBlock];
}

#pragma mark - Test List Files

-(void)test_ShouldNotStartListFiles_WhenInProgress
{
    ListNodesRequestParams *request = [self exampleListFilesRequest];
    [self setupAuthorizationClient:YES AndOperationsClient:NO];
    BlocksCallResult *expectedResult = [BlocksCallResult result];
    BlocksCallResult *result = [BlocksCallResult result];
    
    BOOL startResult = [self.client listNodes:request WithSuccess:[result successBlock] failure:[result failureBlock]];

    assertThatBool(startResult, equalToBool(NO));
    assertThat(result,equalTo(expectedResult));
    [verifyCount(operationsClient,never()) listFiles:anything() WithSuccess:anything() failure:anything()];
    [self assertClientBlocksNiled];
}

-(void)test_ShouldStartListFiles_WhenNotInProgress
{
    ListNodesRequestParams *request = [self exampleListFilesRequest];
    NSDictionary *expectedParams = [self exampleListFilesDictionary];
    BlocksCallResult *result = [BlocksCallResult result];
    SuccessBlock successBlock = [result successBlock];
    FailureBlock failureBlock = [result failureBlock];
    
    BOOL startResult = [self.client listNodes:request WithSuccess:successBlock failure:failureBlock];
    
    [self assertOperationSetupDefaultAuthTries:startResult success:successBlock failure:failureBlock];
    [verify(operationsClient) listFiles:equalTo(expectedParams) WithSuccess:self.client.successResponseBlock failure:self.client.failureResponseBlock];
}

#pragma mark - Test mkdir

-(void)test_ShouldNotStartMkDir_WhenInProgress
{
    MkDirRequestParams *request = [self exampleMkDirRequestParams];
    [self setupAuthorizationClient:YES AndOperationsClient:NO];
    BlocksCallResult *expectedResult = [BlocksCallResult result];
    BlocksCallResult *result = [BlocksCallResult result];
    
    BOOL startResult = [self.client mkdir:request WithSuccess:[result successBlock] failure:[result failureBlock]];
    
    assertThatBool(startResult, equalToBool(NO));
    assertThat(result,equalTo(expectedResult));
    [verifyCount(operationsClient,never()) mkdir:anything() WithSuccess:anything() failure:anything()];
    [self assertClientBlocksNiled];
}

-(void)test_ShouldStartMkDir_WhenNotInProgress
{
    MkDirRequestParams *request = [self exampleMkDirRequestParams];
    NSDictionary *expectedParams = [self exampleMkDirRequestParamsDictionary];
    BlocksCallResult *result = [BlocksCallResult result];
    SuccessBlock successBlock = [result successBlock];
    FailureBlock failureBlock = [result failureBlock];
    
    BOOL startResult = [self.client mkdir:request WithSuccess:successBlock failure:failureBlock];
    
    [self assertOperationSetupDefaultAuthTries:startResult success:successBlock failure:failureBlock];
    [verify(operationsClient) mkdir:equalTo(expectedParams) WithSuccess:self.client.successResponseBlock failure:self.client.failureResponseBlock];
}

#pragma mark - Test authorize

-(void)test_ShouldNotStartAuthorize_WhenInProgress
{
    [self setupAuthorizationClient:YES AndOperationsClient:NO];
    BlocksCallResult *expectedResult = [BlocksCallResult result];
    BlocksCallResult *result = [BlocksCallResult result];
    
    BOOL startResult = [self.client authorizeWithSuccess:[result successBlock] failure:[result failureBlock]];
    
    assertThatBool(startResult, equalToBool(NO));
    assertThat(result,equalTo(expectedResult));
    [verifyCount(authorizationClient,never()) authorizeWithSuccess:anything() failure:anything()];
    [self assertClientBlocksNiled];
}

-(void)test_ShouldStartAuthorize_WhenNotInProgress
{
    BlocksCallResult *result = [BlocksCallResult result];
    SuccessBlock successBlock = [result successBlock];
    FailureBlock failureBlock = [result failureBlock];
    
    BOOL startResult = [self.client authorizeWithSuccess:successBlock failure:failureBlock];
    
    [self assertOperationSetup0AuthTries:startResult success:successBlock failure:failureBlock];
    [verify(authorizationClient) authorizeWithSuccess:self.client.successResponseBlock failure:self.client.failureResponseBlock];
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

-(void)assertOperationSetupDefaultAuthTries:(BOOL)startResult success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock {
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(DEFAULT_TRIES_COUNT));
    [self assertOperationSetup:startResult success:successBlock failure:failureBlock];
}

-(void)assertOperationSetup0AuthTries:(BOOL)startResult success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock {
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(0));
    [self assertOperationSetup:startResult success:successBlock failure:failureBlock];
}

-(void)assertOperationSetup:(BOOL)startResult success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock {
    assertThatBool(startResult, equalToBool(YES));
    assertThat(self.client.successBlock,sameInstance(successBlock));
    assertThat(self.client.failureBlock,sameInstance(failureBlock));
    assertThat(self.client.operationBlock,notNilValue());
}

#pragma mark - Helpers

-(void)setupClientForBlockResponse:(BlocksCallResult*)result {
    [self.client setupCommons:[result successBlock] failure:[result failureBlock]];
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

@end
