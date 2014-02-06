//
//  OperationsClientTests.m
//  PydioSDK
//
//  Created by ME on 17/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OperationsClientBaseTests.h"
#import <objc/runtime.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>
#import "OperationsClient.h"
#import "AFHTTPRequestOperationManager.h"
#import "CookieManager.h"
#import "NotAuthorizedResponse.h"
#import "XMLResponseSerializer.h"
#import "FailingResponseSerializer.h"
#import "XMLResponseSerializerDelegate.h"
#import "PydioErrors.h"


static const NSString * const REGISTERS_URL_PART = @"index.php?get_action=get_xml_registry";
static const NSString * const XPATH_PART = @"&xPath=user/repositories";


@interface OperationsClient ()
-(NSString*)urlStringForGetRegisters;
@end

#pragma mark -

@interface OperationsClientGetWorkspacesTests : OperationsClientBaseTests
@end

@implementation OperationsClientGetWorkspacesTests

- (void)testShouldInitialize
{
    assertThatBool(self.client.progress,equalToBool(NO));
}

#pragma mark - Test Listing Workspaces

-(void)test_ShouldCreateAddressWithSecureToken_WhenPresent
{
    NSURL *server = [NSURL URLWithString:TEST_SERVER];
    [given([self.operationManager baseURL]) willReturn:server];
    [given([getCookieManager() secureTokenForServer:server]) willReturn:TEST_TOKEN];
    
    NSString *address = [self.client urlStringForGetRegisters];
    
    [verify(getCookieManager()) secureTokenForServer:server];
    assertThat(address,equalTo([self urlGetRegistersToken]));
}

-(void)test_ShouldCreateAddressWithoutSecureToken_WhenNotPresent
{
    NSString *address = [self.client urlStringForGetRegisters];
    
    assertThat(address,equalTo([self urlGetRegistersNoToken]));
}

-(void)test_ShouldStartListWorkspaces_WhenNotInProgress
{
    NSURL *server = [NSURL URLWithString:TEST_SERVER];
    [given([self.operationManager baseURL]) willReturn:server];
    [given([getCookieManager() secureTokenForServer:server]) willReturn:TEST_TOKEN];
    
    BOOL startResult = [self.client listWorkspacesWithSuccess:nil failure:nil];
    
    assertThatBool(startResult,equalToBool(YES));
    assertThatBool(self.client.progress,equalToBool(YES));
    
    MKTArgumentCaptor *requestSerializer = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) setRequestSerializer:[requestSerializer capture]];
    assertThat(((AFHTTPRequestSerializer*)[requestSerializer value]).HTTPRequestHeaders,equalTo(self.defaultRequestParams));
    
    MKTArgumentCaptor *responseSerializer = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) setResponseSerializer:[responseSerializer capture]];
    [self assertResponseSerializer:(AFHTTPResponseSerializer*)[responseSerializer value]];
    
    [verify(getCookieManager()) secureTokenForServer:server];
    [verify(self.operationManager) GET:[self urlGetRegistersToken] parameters:nil success:anything() failure:anything()];
    
}

- (void)test_ShouldNotStartListWorkspaces_WhenInProgress
{
    self.client.progress = YES;
    BOOL startResult = [self.client listWorkspacesWithSuccess:nil failure:nil];
    
    assertThatBool(startResult,equalToBool(NO));
    [verifyCount(self.operationManager,never()) setRequestSerializer:anything()];
    [verifyCount(self.operationManager,never()) setResponseSerializer:anything()];
    [verifyCount(self.operationManager, never()) GET:anything() parameters:nil success:anything() failure:anything()];
}

-(void)test_ListWorkspacesShouldUnableToLoginError_WhenUnauthorized
{
    NSURL *server = [NSURL URLWithString:TEST_SERVER];
    [given([self.operationManager baseURL]) willReturn:server];
    [given([getCookieManager() secureTokenForServer:server]) willReturn:TEST_TOKEN];
    NotAuthorizedResponse *response = [[NotAuthorizedResponse alloc] init];
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    __block NSError *receivedError = nil;
    
    [self.client listWorkspacesWithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
        receivedError = error;
    }];
    
    MKTArgumentCaptor *success = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:[self urlGetRegistersToken] parameters:nil success:[success capture] failure:anything()];
    ((SuccessBlock)[success value])(nil,response);
    assertThatBool(successBlockCalled,equalToBool(NO));
    assertThatBool(failureBlockCalled,equalToBool(YES));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThat(receivedError,notNilValue());
    assertThat(receivedError.domain,equalTo(PydioErrorDomain));
    assertThatInteger(receivedError.code,equalToInteger(PydioErrorUnableToLogin));
}

-(void)test_ListWorkspacesShouldFailure_WhenOtherError
{
    NSURL *server = [NSURL URLWithString:TEST_SERVER];
    [given([self.operationManager baseURL]) willReturn:server];
    [given([getCookieManager() secureTokenForServer:server]) willReturn:TEST_TOKEN];
    NSError *error = [NSError errorWithDomain:@"TEST" code:1 userInfo:nil];
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    __block NSError *receivedError = nil;
    
    [self.client listWorkspacesWithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
        receivedError = error;
    }];
    
    MKTArgumentCaptor *failure = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:[self urlGetRegistersToken] parameters:nil success:anything() failure:[failure capture]];
    ((FailureBlock)[failure value])(nil,error);
    assertThatBool(successBlockCalled,equalToBool(NO));
    assertThatBool(failureBlockCalled,equalToBool(YES));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThat(receivedError,sameInstance(error));
}

-(void)test_ListWorkspacesShouldSuccess_WhenReceivedWorkspaces
{
    NSArray *response = [NSArray arrayWithObject:@"register1"];
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    __block NSArray *receivedArray = nil;
    
    [self.client listWorkspacesWithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
        receivedArray = files;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
    }];
    
    MKTArgumentCaptor *success = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:[self urlGetRegistersNoToken] parameters:nil success:[success capture] failure:anything()];
    ((SuccessBlock)[success value])(nil,response);
    assertThatBool(successBlockCalled,equalToBool(YES));
    assertThatBool(failureBlockCalled,equalToBool(NO));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThat(receivedArray,sameInstance(response));
}


#pragma mark -

-(NSString *)urlGetRegistersNoToken {
    return [NSString stringWithFormat:@"%@%@",REGISTERS_URL_PART,XPATH_PART];
}

-(NSString *)urlGetRegistersToken {
    return [NSString stringWithFormat:@"%@%@%@%@",REGISTERS_URL_PART,SECURE_TOKEN_PART,TEST_TOKEN,XPATH_PART];
}

-(void)assertResponseSerializer:(AFHTTPResponseSerializer*)serializer {
    assertThat(serializer,instanceOf([AFCompoundResponseSerializer class]));
    AFCompoundResponseSerializer* compoundSerializer = (AFCompoundResponseSerializer*)serializer;
    assertThatUnsignedInteger(compoundSerializer.responseSerializers.count,equalToUnsignedInteger(3));
    assertThat([compoundSerializer.responseSerializers objectAtIndex:0],instanceOf([XMLResponseSerializer class]));
    assertThat([compoundSerializer.responseSerializers objectAtIndex:1],instanceOf([XMLResponseSerializer class]));
    assertThat([compoundSerializer.responseSerializers objectAtIndex:2],instanceOf([FailingResponseSerializer class]));
    assertThat([self xmlResponseSerializerFrom:compoundSerializer AtIndex:0],instanceOf([NotAuthorizedResponseSerializerDelegate class]));
    assertThat([self xmlResponseSerializerFrom:compoundSerializer AtIndex:1],instanceOf([WorkspacesResponseSerializerDelegate class]));
}

@end
