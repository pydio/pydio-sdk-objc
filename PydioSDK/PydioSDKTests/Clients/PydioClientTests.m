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


typedef void (^FailureBlock)(NSError *error);
typedef void (^ListFilesSuccessBlock)(NSArray* files);


static NSString * const TEST_SERVER_ADDRESS = @"http://www.testserver.com/";
static NSString * const TEST_USER_ID = @"testid";
static NSString * const TEST_USER_PASSWORD = @"testpassword";

static AFHTTPRequestOperationManager* operationManager = nil;
static AuthorizationClient* authorizationClient = nil;
static OperationsClient* operationsClient = nil;


#pragma mark - Deriving from Tested class

@interface PydioClient ()
@property(nonatomic,strong) AFHTTPRequestOperationManager* operationManager;
@property (readwrite,nonatomic,assign) BOOL progress;
@end

@interface TestedPydioClient : PydioClient
@end

@implementation TestedPydioClient

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

#pragma mark -

@interface PydioClientTests : XCTestCase {
    Method _methodToExchange;
    IMP _originalIMP;
}
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

#pragma mark - Tests

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

-(void)testShouldStartListFilesWhenNotInProgress
{
    BOOL startResult = [self.client listFilesWithSuccess:^(NSArray *files) {
    } failure:^(NSError *error) {
    }];
    
    assertThatBool(startResult, equalToBool(YES));
    [verify(operationsClient) listFilesWithSuccess:anything() failure:anything()];
}

-(void)testShouldNotStartListFilesWhenInProgress
{
    [self setupAuthorizationClient:YES AndOperationsClient:NO];
    
    BOOL startResult = [self.client listFilesWithSuccess:^(NSArray *files) {
    } failure:^(NSError *error) {
    }];
    
    assertThatBool(startResult, equalToBool(NO));
    [verifyCount(operationsClient,never()) listFilesWithSuccess:anything() failure:anything()];
}

-(void)testShouldReceiveArrayWhenSuccess
{
    NSArray *responseArray = [NSArray array];
    __block NSArray *receivedArray = nil;
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    
    [self.client listFilesWithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
        receivedArray = files;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
    }];
    
    MKTArgumentCaptor *success = [[MKTArgumentCaptor alloc] init];
    [verify(operationsClient) listFilesWithSuccess:[success capture] failure:anything()];
    ((ListFilesSuccessBlock)[success value])(responseArray);
    
    assertThatBool(successBlockCalled,equalToBool(YES));
    assertThatBool(failureBlockCalled,equalToBool(NO));
    assertThat(receivedArray,sameInstance(responseArray));
}

-(void)test_ShouldInvokeAuthorize_WhenNotLogged
{
    NSError *authorizationError = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];

    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    
    [self.client listFilesWithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
    }];

    [self operationsClientListFailure:authorizationError];
    
    [verify(authorizationClient) authorizeWithSuccess:anything() failure:anything()];
    assertThatBool(successBlockCalled,equalToBool(NO));
    assertThatBool(failureBlockCalled,equalToBool(NO));
}

-(void)test_ShouldFailure_WhenReceivedNotAuthorizedTwoTimes
{
    NSError *authorizationError = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
    __block NSError *receivedError = nil;
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    
    [self.client listFilesWithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
        receivedError = error;
    }];

    [self operationsClientListFailure:authorizationError];
    
    MKTArgumentCaptor *authFailure = [[MKTArgumentCaptor alloc] init];
    [verify(authorizationClient) authorizeWithSuccess:anything() failure:[authFailure capture]];
    ((FailureBlock)[authFailure value])(authorizationError);
    
    assertThatBool(successBlockCalled,equalToBool(NO));
    assertThatBool(failureBlockCalled,equalToBool(YES));
    assertThat(receivedError,sameInstance(authorizationError));
}

-(void)test_ShouldSuccess_WhenReceivedResponseWithArray_AfterAuthorizationForSecondTime {
    NSError *authorizationError = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
    NSArray *responseArray = [NSArray array];
    __block NSArray *receivedArray = nil;
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    
    [self.client listFilesWithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
        receivedArray = files;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
    }];
    
    [self operationsClientListFailure:authorizationError];
    
    [self authorizationClientAuthorizeSuccess];
    
    MKTArgumentCaptor *success = [[MKTArgumentCaptor alloc] init];
    [verifyCount(operationsClient,times(2)) listFilesWithSuccess:[success capture] failure:anything()];
    ((ListFilesSuccessBlock)[success value])(responseArray);
    
    assertThatBool(successBlockCalled,equalToBool(YES));
    assertThatBool(failureBlockCalled,equalToBool(NO));
    assertThat(receivedArray,sameInstance(responseArray));
}

-(void)test_ShouldFailure_WhenReceivedErrorAfterListingFiles_AfterSuccessAuthorization_afterAuthorizationFailure {
    NSError *authorizationError = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil];
    __block NSError *receivedError = nil;
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    
    [self.client listFilesWithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
        receivedError = error;
    }];
    
    [self operationsClientListFailure:authorizationError];
    
    [self authorizationClientAuthorizeSuccess];
    
    MKTArgumentCaptor *failure = [[MKTArgumentCaptor alloc] init];
    [verifyCount(operationsClient,times(2)) listFilesWithSuccess:anything() failure:[failure capture]];
    ((FailureBlock)[failure value])(authorizationError);
    
    assertThatBool(successBlockCalled,equalToBool(NO));
    assertThatBool(failureBlockCalled,equalToBool(YES));
    assertThat(receivedError,sameInstance(authorizationError));
}


-(void)test_ShouldFailureWhenOtherErrorThanAuthorizationError
{
    NSError *otherError = [NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToParseAnswer userInfo:nil];
    __block NSError *receivedError = nil;
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    
    [self.client listFilesWithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
        receivedError = error;
    }];
    
    [self operationsClientListFailure:otherError];
    
    [verifyCount(authorizationClient,never()) authorizeWithSuccess:anything() failure:anything()];
    assertThatBool(successBlockCalled,equalToBool(NO));
    assertThatBool(failureBlockCalled,equalToBool(YES));
    assertThat(receivedError,sameInstance(otherError));
}

#pragma mark -

-(void)operationsClientListFailure:(NSError*)error
{
    MKTArgumentCaptor *failure = [[MKTArgumentCaptor alloc] init];
    [verify(operationsClient) listFilesWithSuccess:anything() failure:[failure capture]];
    ((FailureBlock)[failure value])(error);
}

-(void)authorizationClientAuthorizeSuccess
{
    MKTArgumentCaptor *authSuccess = [[MKTArgumentCaptor alloc] init];
    [verify(authorizationClient) authorizeWithSuccess:[authSuccess capture] failure:anything()];
    ((void(^)())[authSuccess value])();
}

-(void)setupAuthorizationClient:(BOOL) authProgress AndOperationsClient: (BOOL)operationsProgress {
    [given([authorizationClient progress]) willReturnBool:authProgress];
    [given([operationsClient progress]) willReturnBool:operationsProgress];
}

#pragma mark - Helpers

-(NSURL*)helperServerURL {
    return [NSURL URLWithString:TEST_SERVER_ADDRESS];
}

-(User *)helperUser {
    return [User userWithId:TEST_USER_ID AndPassword:TEST_USER_PASSWORD];
}

@end
