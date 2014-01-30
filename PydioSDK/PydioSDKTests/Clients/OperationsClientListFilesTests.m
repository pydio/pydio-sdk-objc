//
//  OpeartionsClientListFilesTests.m
//  PydioSDK
//
//  Created by ME on 30/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "OperationsClientBaseTests.h"
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "CookieManager.h"
#import "AFHTTPRequestOperationManager.h"
#import "OperationsClient.h"
#import "XMLResponseSerializer.h"
#import "XMLResponseSerializerDelegate.h"
#import "NotAuthorizedResponse.h"
#import "PydioErrors.h"


static const NSString * const LS_ACTION_URL_PART = @"index.php?get_action=ls";

@interface OperationsClient ()
-(NSString*)urlStringForListFiles;
@end

@interface OperationsClientListFilesTests : OperationsClientBaseTests

@end

@implementation OperationsClientListFilesTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

-(void)test_ShouldCreateAddressWithSecureToken_WhenTokenPresent
{
    NSURL *server = [NSURL URLWithString:TEST_SERVER];
    [given([self.operationManager baseURL]) willReturn:server];
    [given([getCookieManager() secureTokenForServer:server]) willReturn:TEST_TOKEN];
    
    NSString *address = [self.client urlStringForListFiles];
    
    [verify(getCookieManager()) secureTokenForServer:server];
    assertThat(address,equalTo([self urlListFilesToken]));
    
}

-(void)test_ShouldCreateAddressWithoutSecureToken_WhenTokenNotPresent
{
    NSString *address = [self.client urlStringForListFiles];
    
    assertThat(address,equalTo([self urlListFilesNoToken]));
}

- (void)test_ShouldNotStartListFiles_WhenInProgress
{
    NSDictionary *params = [NSDictionary dictionary];
    self.client.progress = YES;
    BOOL startResult = [self.client listFiles:params WithSuccess:nil failure:nil];
    
    assertThatBool(startResult,equalToBool(NO));
    [verifyCount(self.operationManager,never()) setRequestSerializer:anything()];
    [verifyCount(self.operationManager,never()) setResponseSerializer:anything()];
    [verifyCount(self.operationManager, never()) GET:anything() parameters:nil success:anything() failure:anything()];
}

- (void)test_ShouldStartListFiles_WhenNotInProgress
{
    NSDictionary *params = [NSDictionary dictionary];
    NSURL *server = [NSURL URLWithString:TEST_SERVER];
    [given([self.operationManager baseURL]) willReturn:server];
    
    
    BOOL startResult = [self.client listFiles:params WithSuccess:nil failure:nil];

    
    assertThatBool(startResult,equalToBool(YES));
    assertThatBool(self.client.progress,equalToBool(YES));
    
    MKTArgumentCaptor *requestSerializer = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) setRequestSerializer:[requestSerializer capture]];
    assertThat(((AFHTTPRequestSerializer*)[requestSerializer value]).HTTPRequestHeaders,equalTo(self.defaultRequestParams));
    
    MKTArgumentCaptor *responseSerializer = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) setResponseSerializer:[responseSerializer capture]];
    [self assertResponseSerializer:(AFHTTPResponseSerializer*)[responseSerializer value]];
    
    [verify(getCookieManager()) secureTokenForServer:server];
    [verify(self.operationManager) GET:[self urlListFilesNoToken] parameters:params success:anything() failure:anything()];
}

-(void)test_ListFilesShouldFailureWithUnableToLoginError_WhenUnauthorized
{
    NSDictionary *params = [NSDictionary dictionary];
    NSURL *server = [NSURL URLWithString:TEST_SERVER];
    [given([self.operationManager baseURL]) willReturn:server];
    NotAuthorizedResponse *response = [[NotAuthorizedResponse alloc] init];
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    __block NSError *receivedError = nil;
    
    [self.client listFiles:params WithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
        receivedError = error;
    }];
    
    MKTArgumentCaptor *success = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:[self urlListFilesNoToken] parameters:params success:[success capture] failure:anything()];
    ((SuccessBlock)[success value])(nil,response);
    assertThatBool(successBlockCalled,equalToBool(NO));
    assertThatBool(failureBlockCalled,equalToBool(YES));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThat(receivedError,notNilValue());
    assertThat(receivedError.domain,equalTo(PydioErrorDomain));
    assertThatInteger(receivedError.code,equalToInteger(PydioErrorUnableToLogin));
}

-(void)test_ListFilesShouldFailure_WhenOtherErrorThanAuthorization
{
    NSDictionary *params = [NSDictionary dictionary];
    NSURL *server = [NSURL URLWithString:TEST_SERVER];
    [given([self.operationManager baseURL]) willReturn:server];
    NSError *error = [NSError errorWithDomain:@"TEST" code:1 userInfo:nil];
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    __block NSError *receivedError = nil;
    
    [self.client listFiles:params WithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
        receivedError = error;
    }];
    
    MKTArgumentCaptor *failure = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:[self urlListFilesNoToken] parameters:params success:anything() failure:[failure capture]];
    ((FailureBlock)[failure value])(nil,error);
    assertThatBool(successBlockCalled,equalToBool(NO));
    assertThatBool(failureBlockCalled,equalToBool(YES));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThat(receivedError,sameInstance(error));
}

-(void)test_ListFilesShouldSuccess_WhenReceivedResponse
{
    NSDictionary *params = [NSDictionary dictionary];
    NSArray *response = [NSArray arrayWithObject:@"register1"];
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    __block NSArray *receivedArray = nil;
    
    [self.client listFiles:params WithSuccess:^(NSArray *files) {
        successBlockCalled = YES;
        receivedArray = files;
    } failure:^(NSError *error) {
        failureBlockCalled = YES;
    }];
    
    MKTArgumentCaptor *success = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) GET:[self urlListFilesNoToken] parameters:params success:[success capture] failure:anything()];
    ((SuccessBlock)[success value])(nil,response);
    assertThatBool(successBlockCalled,equalToBool(YES));
    assertThatBool(failureBlockCalled,equalToBool(NO));
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThat(receivedArray,sameInstance(response));
}


#pragma mark - Asserts

-(void)assertResponseSerializer:(AFHTTPResponseSerializer*)serializer {
    assertThat(serializer,instanceOf([AFCompoundResponseSerializer class]));
    AFCompoundResponseSerializer* compoundSerializer = (AFCompoundResponseSerializer*)serializer;
    assertThatUnsignedInteger(compoundSerializer.responseSerializers.count,equalToUnsignedInteger(2));
    assertThat([compoundSerializer.responseSerializers objectAtIndex:0],instanceOf([XMLResponseSerializer class]));
    assertThat([compoundSerializer.responseSerializers objectAtIndex:1],instanceOf([XMLResponseSerializer class]));
    assertThat([self xmlResponseSerializerFrom:compoundSerializer AtIndex:0],instanceOf([NotAuthorizedResponseSerializerDelegate class]));
    assertThat([self xmlResponseSerializerFrom:compoundSerializer AtIndex:1],instanceOf([ListFilesResponseSerializerDelegate class]));
}

#pragma mark - Helpers

-(NSString*)urlListFilesToken
{
    return [NSString stringWithFormat:@"%@%@%@",LS_ACTION_URL_PART,SECURE_TOKEN_PART,TEST_TOKEN];
}

-(NSString*)urlListFilesNoToken
{
    return [NSString stringWithFormat:@"%@",LS_ACTION_URL_PART];
}

@end
