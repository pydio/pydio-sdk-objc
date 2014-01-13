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


static NSString * const TEST_SERVER_ADDRESS = @"http://www.testserver.com/";
static NSString * const TEST_USER_ID = @"testid";
static NSString * const TEST_USER_PASSWORD = @"testpassword";
static CookieManager *cookieManager = nil;
static AFHTTPRequestOperationManager* operationManager = nil;
static AuthorizationClient* authorizationClient = nil;

id mockedCookieManager(id self, SEL _cmd) {
    return cookieManager;
}

#pragma mark - Tested derived object

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
@end

#pragma mark -

@interface PydioClientTests : XCTestCase {
    Method _methodToExchange;
    IMP _originalIMP;
}
@property (nonatomic,strong) TestedPydioClient* client;
//@property (nonatomic,strong) AuthorizationClient* authorizationClient;
@end


@implementation PydioClientTests

- (void)setUp
{
    [super setUp];
    _methodToExchange = class_getClassMethod([CookieManager class], @selector(sharedManager));
    _originalIMP = method_setImplementation(_methodToExchange, (IMP)mockedCookieManager);
    cookieManager = mock([CookieManager class]);
    operationManager = mock([AFHTTPRequestOperationManager class]);
    authorizationClient = mock([AuthorizationClient class]);
    
    self.client = [[TestedPydioClient alloc] initWithServer:TEST_SERVER_ADDRESS];
}

- (void)tearDown
{
    method_setImplementation(_methodToExchange, _originalIMP);
    cookieManager = nil;
    operationManager = nil;
    authorizationClient = nil;
    self.client = nil;
    [super tearDown];
}

#pragma mark - Tests

-(void)testInitialization
{
    assertThatBool(self.client.progress, equalToBool(NO));
}

-(void)testShouldStartAuthorizationWhenNoCookie
{
    //given
    [self setupClassesResponses:[self helperUser]];
    
    //when
    BOOL startResult = [self.client listFiles];
    
    //then
    assertThatBool(startResult, equalToBool(YES));
    assertThatBool(self.client.progress, equalToBool(YES));
    [verify(cookieManager) isCookieSet:equalTo([self helperServerURL])];
    [verify(cookieManager) userForServer:equalTo([self helperServerURL])];
    [verify(authorizationClient) authorize:equalTo([self helperUser])];
}

-(void)testShouldNotStartWhenThereIsOperationInProgress
{
    //given
    [self setupClassesResponses:[self helperUser]];
    self.client.progress = YES;
    
    //when
    BOOL startResult = [self.client listFiles];
    
    //then
    assertThatBool(startResult, equalToBool(NO));
    [verifyCount(cookieManager,never()) isCookieSet:equalTo([self helperServerURL])];
}

-(void)testShouldNotStartWhenThereIsNoUserForServer
{
    //given
    [self setupClassesResponses:nil];
    
    //when
    BOOL startResult = [self.client listFiles];
    
    //then
    assertThatBool(startResult, equalToBool(NO));
    assertThatBool(self.client.progress, equalToBool(NO));
    [verify(cookieManager) isCookieSet:equalTo([self helperServerURL])];
    [verify(cookieManager) userForServer:equalTo([self helperServerURL])];
    [verifyCount(authorizationClient,never()) authorize:equalTo([self helperUser])];
}

//if cookie set then no checking for authorization only download list of files
//Check finishing of authorization with succes and failure
//Check what will happen if not authorized message will appear

//-(void)testShouldNotAuthorizeAndOnlyListFilesWhenCookieIsPresent
//{
//    
//}
//
////should not start authorization when no cookie
//
//-(void)testShouldAuthorizeWhenReceivedNotAuthorizedResponse
//{
//    
//}

-(void)setupClassesResponses:(User*)user {
    [given([operationManager baseURL]) willReturn:[self helperServerURL]];
    [given([cookieManager isCookieSet:equalTo([self helperServerURL])]) willReturnBool:NO];
    [given([cookieManager userForServer:equalTo([self helperServerURL])]) willReturn:user];
}

#pragma mark - Helpers

-(NSURL*)helperServerURL {
    return [NSURL URLWithString:TEST_SERVER_ADDRESS];
}

-(User *)helperUser {
    return [User userWithId:TEST_USER_ID AndPassword:TEST_USER_PASSWORD];
}

@end
