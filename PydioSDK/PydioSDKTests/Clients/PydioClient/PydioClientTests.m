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
#import "AuthorizationClient.h"
#import "CookieManager.h"
#import <objc/runtime.h>
#import "AFHTTPRequestOperationManager.h"
#import "User.h"
#import "OperationsClient.h"
#import "PydioErrors.h"
#import "Commons.h"


typedef void (^ListWorkspacesSuccessBlock)(NSArray* files);


@interface PydioClientTests : XCTestCase
@property (nonatomic,strong) TestedPydioClient* client;
@end


@implementation PydioClientTests

- (void)setUp
{
    [super setUp];
    operationManager = mock([AFHTTPRequestOperationManager class]);
    authorizationClient = mock([AuthorizationClient class]);
    operationsClient = mock([OperationsClient class]);
    
    self.client = [[TestedPydioClient alloc] initWithServer:TEST_SERVER_ADDRESS];
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

-(void)testShouldBeProgressWhenAuthorizationProgress
{
    [self setupAuthorizationClient:YES AndOperationsClient:NO];
    
    assertThatBool(self.client.progress, equalToBool(YES));
}

-(void)testShouldBeProgressWhenOperationsProgress
{
    [self setupAuthorizationClient:NO AndOperationsClient:YES];
    
    assertThatBool(self.client.progress, equalToBool(YES));
}

#pragma mark - Generic Tests

-(void)test_ShouldCallPerformAuthorizationAndOperation_WhenReceivedAuthorizationErrorAndTriesCountIsGreaterThan0
{
    self.client.callTestPerformAuthorizationAndOperation = YES;
    self.client.authorizationsTriesCount = 1;
    NSError *authorizationError = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
    
    [self.client handleOperationFailure:authorizationError];
    
    assertThatInt(self.client.performAuthorizationAndOperationCallCount,equalToInt(1));
}

-(void)test_ShouldCallFailureBlock_WhenReceivedNotAuthorizationErrorAndTriesCountIsGreaterThan0
{
    __block BOOL blockCalled = NO;
    __block NSError *receivedError = nil;
    self.client.failureBlock = ^(NSError *error){
        blockCalled = YES;
        receivedError = error;
    };
    self.client.operationBlock = ^{};
    self.client.callTestPerformAuthorizationAndOperation = YES;
    self.client.authorizationsTriesCount = 1;
    NSError *error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToParseAnswer userInfo:nil];
    
    [self.client handleOperationFailure:error];
    
    assertThatInt(self.client.performAuthorizationAndOperationCallCount,equalToInt(0));
    assertThatBool(blockCalled,equalToBool(YES));
    assertThat(receivedError,sameInstance(error));
    assertThat(self.client.failureBlock,nilValue());
    assertThat(self.client.operationBlock,nilValue());
}

-(void)test_ShouldCallFailureBlock_WhenReceivedAuthorizationErrorAndTriesCountIs0
{
    __block BOOL blockCalled = NO;
    __block NSError *receivedError = nil;
    self.client.failureBlock = ^(NSError *error){
        blockCalled = YES;
        receivedError = error;
    };
    self.client.operationBlock = ^{};
    self.client.callTestPerformAuthorizationAndOperation = YES;
    self.client.authorizationsTriesCount = 0;
    NSError *error = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
    
    [self.client handleOperationFailure:error];
    
    assertThatInt(self.client.performAuthorizationAndOperationCallCount,equalToInt(0));
    assertThatBool(blockCalled,equalToBool(YES));
    assertThat(receivedError,sameInstance(error));
    assertThat(self.client.failureBlock,nilValue());
    assertThat(self.client.operationBlock,nilValue());
}

#pragma mark - Perform Authorization And Operation Tests

-(void)test_ShouldCallOperationBlock_WhenAuthorizationSuccess {
    self.client.authorizationsTriesCount = 1;
    __block BOOL operationBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    self.client.operationBlock = ^{
        operationBlockCalled = YES;
    };
    self.client.failureBlock = ^(NSError *error){
        failureBlockCalled = YES;
    };
    
    [self.client performAuthorizationAndOperation];
    
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(0));
    MKTArgumentCaptor *authSuccess = [[MKTArgumentCaptor alloc] init];
    [verify(authorizationClient) authorizeWithSuccess:[authSuccess capture] failure:anything()];
    ((void(^)())[authSuccess value])();
    assertThatBool(operationBlockCalled,equalToBool(YES));
    assertThatBool(failureBlockCalled,equalToBool(NO));
}

-(void)test_ShouldCallFailureBlock_WhenAuthorizationFailure {
    self.client.authorizationsTriesCount = 1;
    __block BOOL operationBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    __block NSError *receivedError = nil;
    self.client.operationBlock = ^{
        operationBlockCalled = YES;
    };
    self.client.failureBlock = ^(NSError *error){
        failureBlockCalled = YES;
        receivedError = error;
    };
    NSError *error = [NSError errorWithDomain:@"TestDomain" code:1 userInfo:nil];
    
    [self.client performAuthorizationAndOperation];
    
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(0));
    MKTArgumentCaptor *authFailure = [[MKTArgumentCaptor alloc] init];
    [verify(authorizationClient) authorizeWithSuccess:anything() failure:[authFailure capture]];
    ((FailureBlock)[authFailure value])(error);
    assertThatBool(operationBlockCalled,equalToBool(NO));
    assertThatBool(failureBlockCalled,equalToBool(YES));
}

#pragma mark - Test List Workspaces

-(void)test_ShouldNotStartListWorkspaces_WhenInProgress
{
    [self setupAuthorizationClient:YES AndOperationsClient:NO];
    
    void(^failureBlock)(NSError *) = ^(NSError *error) {
    };
    
    BOOL startResult = [self.client listWorkspacesWithSuccess:^(NSArray *files) {
    } failure:failureBlock];
    
    [self assertNotStartInProgress:startResult];
    [verifyCount(operationsClient,never()) listWorkspacesWithSuccess:anything() failure:anything()];
}

-(void)test_ShouldStartListWorkspaces_WhenNotInProgress
{
    FailureBlock failureBlock = ^(NSError *error) {
    };
    
    BOOL startResult = [self.client listWorkspacesWithSuccess:^(NSArray *files) {
    } failure:failureBlock];
    
    [self assertStartNotInProgress:startResult failure:failureBlock];
    [verify(operationsClient) listWorkspacesWithSuccess:anything() failure:anything()];
}

-(void)test_ShouldCallSuccessBlock_WhenSuccessInOperationsClientListWorkspaces
{
    NSArray *responseArray = [NSArray array];
    __block NSArray *receivedArray = nil;
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    
    [self.client listWorkspacesWithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
        receivedArray = files;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
    }];
    
    MKTArgumentCaptor *success = [[MKTArgumentCaptor alloc] init];
    [verify(operationsClient) listWorkspacesWithSuccess:[success capture] failure:anything()];
    ((ListWorkspacesSuccessBlock)[success value])(responseArray);
    
    assertThatBool(successBlockCalled,equalToBool(YES));
    assertThatBool(failureBlockCalled,equalToBool(NO));
    assertThat(receivedArray,sameInstance(responseArray));
}

-(void)test_ShouldCallHandleOperationFailure_WhenOperationsClientListWithWorkspacesError
{
    self.client.callTestHandleOperationFailure = YES;
    NSError *error = [NSError errorWithDomain:@"TestDomain" code:1 userInfo:nil];
    
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    
    [self.client listWorkspacesWithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
    }];
    
    [self operationsClientListFailure:error];
    
    assertThatInt(self.client.handleOperationFailureOperationCallCount,equalToInt(1));
    assertThatBool(successBlockCalled,equalToBool(NO));
    assertThatBool(failureBlockCalled,equalToBool(NO));
}

#pragma mark - Test List Files

-(void)test_ShouldNotStartListFiles_WhenInProgress
{
    NSDictionary *params = [NSDictionary dictionary];
    [self setupAuthorizationClient:YES AndOperationsClient:NO];

    FailureBlock failureBlock = ^(NSError *error) {
    };
    
    BOOL startResult = [self.client listFiles:params WithSuccess:^(NSArray *files) {
    } failure:failureBlock];

    [self assertNotStartInProgress:startResult];
    [verifyCount(operationsClient,never()) listFiles:params WithSuccess:anything() failure:anything()];
}

-(void)test_ShouldStartListFiles_WhenNotInProgress
{
    NSDictionary *params = [NSDictionary dictionary];
    FailureBlock failureBlock = ^(NSError *error) {
    };
    
    BOOL startResult = [self.client listFiles:params WithSuccess:^(NSArray *files) {
    } failure:failureBlock];
    
    [self assertStartNotInProgress:startResult failure:failureBlock];
    [verify(operationsClient) listFiles:params WithSuccess:anything() failure:anything()];
}

-(void)test_ShouldCallSuccessBlock_WhenSuccessInOperationsClientListFiles
{
    NSDictionary *params = [NSDictionary dictionary];
    NSArray *responseArray = [NSArray array];
    __block NSArray *receivedArray = nil;
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    
    [self.client listFiles:params WithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
        receivedArray = files;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
    }];
    
    MKTArgumentCaptor *success = [[MKTArgumentCaptor alloc] init];
    [verify(operationsClient) listFiles:params WithSuccess:[success capture] failure:anything()];
    ((ListWorkspacesSuccessBlock)[success value])(responseArray);
    
    assertThatBool(successBlockCalled,equalToBool(YES));
    assertThatBool(failureBlockCalled,equalToBool(NO));
    assertThat(receivedArray,sameInstance(responseArray));
}

-(void)test_ShouldCallHandleOperationFailure_WhenOperationsClientListFilesWorkspacesError
{
    NSDictionary *params = [NSDictionary dictionary];
    self.client.callTestHandleOperationFailure = YES;
    NSError *error = [NSError errorWithDomain:@"TestDomain" code:1 userInfo:nil];
    
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    
    [self.client listFiles:params WithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
    }];
    
    MKTArgumentCaptor *failure = [[MKTArgumentCaptor alloc] init];
    [verify(operationsClient) listFiles:params WithSuccess:anything() failure:[failure capture]];
    ((FailureBlock)[failure value])(error);
    
    assertThatInt(self.client.handleOperationFailureOperationCallCount,equalToInt(1));
    assertThatBool(successBlockCalled,equalToBool(NO));
    assertThatBool(failureBlockCalled,equalToBool(NO));
}

#pragma mark - Test Verification

-(void)operationsClientListFailure:(NSError*)error
{
    MKTArgumentCaptor *failure = [[MKTArgumentCaptor alloc] init];
    [verify(operationsClient) listWorkspacesWithSuccess:anything() failure:[failure capture]];
    ((FailureBlock)[failure value])(error);
}

-(void)setupAuthorizationClient:(BOOL) authProgress AndOperationsClient: (BOOL)operationsProgress {
    [given([authorizationClient progress]) willReturnBool:authProgress];
    [given([operationsClient progress]) willReturnBool:operationsProgress];
}

-(void)assertNotStartInProgress:(BOOL)startResult
{
    assertThatBool(startResult, equalToBool(NO));
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(0));
    assertThat(self.client.failureBlock,nilValue());
    assertThat(self.client.operationBlock,nilValue());
}

-(void)assertStartNotInProgress:(BOOL)startResult failure:(FailureBlock)failureBlock
{
    assertThatBool(startResult, equalToBool(YES));
    assertThatInt(self.client.authorizationsTriesCount,equalToInt(1));
    assertThat(self.client.failureBlock,sameInstance(failureBlock));
    assertThat(self.client.operationBlock,notNilValue());
}

#pragma mark - Helpers

-(NSURL*)helperServerURL {
    return [NSURL URLWithString:TEST_SERVER_ADDRESS];
}

-(User *)helperUser {
    return [User userWithId:TEST_USER_ID AndPassword:TEST_USER_PASSWORD];
}

@end
