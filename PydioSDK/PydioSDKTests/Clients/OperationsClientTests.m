//
//  OperationsClientTests.m
//  PydioSDK
//
//  Created by ME on 17/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
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
#import "XMLResponseSerializerDelegate.h"
#import "PydioErrors.h"


static const NSString * const REGISTERS_URL_PART = @"index.php?get_action=get_xml_registry";
static const NSString * const SECURE_TOKEN_PART = @"&secure_token=";
static const NSString * const XPATH_PART = @"&xPath=user/repositories";
static const NSString * const TEST_TOKEN = @"j9tJRcVJYjKyfphibjRX47YgyVN1eoIv";
static NSString * const TEST_SERVER = @"http://www.testserver.com";

static CookieManager *cookieManager = nil;

typedef void (^SuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void (^FailureBlock)(AFHTTPRequestOperation *operation, NSError *error);

#pragma mark -

id mockedCookieManager(id self, SEL _cmd) {
    return cookieManager;
}

@interface OperationsClient ()
@property (readwrite,nonatomic,assign) BOOL progress;

-(NSString*)urlStringForGetRegisters;
@end

#pragma mark -

@interface OperationsClientTests : XCTestCase {
    Method _methodToExchange;
    IMP _originalIMP;
}
@property (nonatomic,strong) AFHTTPRequestOperationManager *operationManager;
@property (nonatomic,strong) OperationsClient *client;
@end

@implementation OperationsClientTests 

- (void)setUp
{
    [super setUp];
    _methodToExchange = class_getClassMethod([CookieManager class], @selector(sharedManager));
    _originalIMP = method_setImplementation(_methodToExchange, (IMP)mockedCookieManager);
    cookieManager = mock([CookieManager class]);
    self.operationManager = mock([AFHTTPRequestOperationManager class]);
    self.client = [[OperationsClient alloc] init];
    self.client.operationManager = self.operationManager;
}

- (void)tearDown
{
    self.client = nil;
    self.operationManager = nil;
    cookieManager = nil;
    method_setImplementation(_methodToExchange, _originalIMP);
    _originalIMP = nil;
    _methodToExchange = nil;
    [super tearDown];
}

- (void)testShouldInitialize
{
    assertThatBool(self.client.progress,equalToBool(NO));
}

-(void)testShouldCreateAddressWithSecureTokenWhenPresent
{
    NSURL *server = [NSURL URLWithString:TEST_SERVER];
    [given([self.operationManager baseURL]) willReturn:server];
    [given([cookieManager secureTokenForServer:server]) willReturn:TEST_TOKEN];
    
    NSString *address = [self.client urlStringForGetRegisters];
    
    [verify(cookieManager) secureTokenForServer:server];
    assertThat(address,equalTo([self urlGetRegistersToken]));
}

-(void)testShouldCreateAddressWithoutSecureTokenWhenNotPresent
{
    NSString *address = [self.client urlStringForGetRegisters];
    
    assertThat(address,equalTo([self urlGetRegistersNoToken]));
}

-(void)testShouldStartListFiles
{
    NSURL *server = [NSURL URLWithString:TEST_SERVER];
    [given([self.operationManager baseURL]) willReturn:server];
    [given([cookieManager secureTokenForServer:server]) willReturn:TEST_TOKEN];
    
    BOOL startResult = [self.client listFilesWithSuccess:nil failure:nil];
    
    assertThatBool(startResult,equalToBool(YES));
    assertThatBool(self.client.progress,equalToBool(YES));
    
    MKTArgumentCaptor *requestSerializer = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) setRequestSerializer:[requestSerializer capture]];
    [self assertRequestSerializer:(AFHTTPRequestSerializer*)[requestSerializer value]];
    
    MKTArgumentCaptor *responseSerializer = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) setResponseSerializer:[responseSerializer capture]];
    [self assertResponseSerializer:(AFHTTPResponseSerializer*)[responseSerializer value]];
    
    [verify(cookieManager) secureTokenForServer:server];
    [verify(self.operationManager) GET:[self urlGetRegistersToken] parameters:nil success:anything() failure:anything()];
    
}

- (void)testShouldNotStartListFilesIfInProgress
{
    self.client.progress = YES;
    BOOL startResult = [self.client listFilesWithSuccess:nil failure:nil];
    
    assertThatBool(startResult,equalToBool(NO));
    [verifyCount(self.operationManager,never()) setRequestSerializer:anything()];
    [verifyCount(self.operationManager,never()) setResponseSerializer:anything()];
    [verifyCount(self.operationManager, never()) GET:anything() parameters:nil success:anything() failure:anything()];
}

-(void)testListFilesShouldUnableToLoginErrorWhenUnauthorized
{
    NSURL *server = [NSURL URLWithString:TEST_SERVER];
    [given([self.operationManager baseURL]) willReturn:server];
    [given([cookieManager secureTokenForServer:server]) willReturn:TEST_TOKEN];
    NotAuthorizedResponse *response = [[NotAuthorizedResponse alloc] init];
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    __block NSError *receivedError = nil;
    
    [self.client listFilesWithSuccess:^(NSArray *files) {
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

-(void)testListFilesShouldUnableToLoginErrorWhenReceivedEmptyArray
{
    NSArray *response = [NSArray array];
    NSURL *server = [NSURL URLWithString:TEST_SERVER];
    [given([self.operationManager baseURL]) willReturn:server];
    [given([cookieManager secureTokenForServer:server]) willReturn:TEST_TOKEN];
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    __block NSError *receivedError = nil;
    
    [self.client listFilesWithSuccess:^(NSArray *files) {
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


-(void)testListFilesShouldFailureWhenOtherError
{
    NSURL *server = [NSURL URLWithString:TEST_SERVER];
    [given([self.operationManager baseURL]) willReturn:server];
    [given([cookieManager secureTokenForServer:server]) willReturn:TEST_TOKEN];
    NSError *error = [NSError errorWithDomain:@"TEST" code:1 userInfo:nil];
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    __block NSError *receivedError = nil;

    [self.client listFilesWithSuccess:^(NSArray *files) {
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

-(void)testListFilesShouldSuccessWhenReceivedRegisters
{
    NSArray *response = [NSArray arrayWithObject:@"register1"];
    __block BOOL successBlockCalled = NO;
    __block BOOL failureBlockCalled = NO;
    __block NSArray *receivedArray = nil;
    
    [self.client listFilesWithSuccess:^(NSArray *files) {
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

-(void)assertRequestSerializer:(AFHTTPRequestSerializer*)serializer {
    NSDictionary* headers = serializer.HTTPRequestHeaders;
    assertThat([headers valueForKey:@"Accept-Encoding"],equalTo(@"gzip, deflate"));
    assertThat([headers valueForKey:@"Accept"],equalTo(@"*/*"));
    assertThat([headers valueForKey:@"Accept-Language"],equalTo(@"en-us"));
    assertThat([headers valueForKey:@"Connection"],equalTo(@"keep-alive"));
    assertThat([headers valueForKey:@"Ajxp-Force-Login"],equalTo(@"true"));
    assertThat([headers valueForKey:@"User-Agent"],equalTo(@"ajaxplorer-ios-client/1.0"));
}

-(void)assertResponseSerializer:(AFHTTPResponseSerializer*)serializer {
    assertThat(serializer,instanceOf([AFCompoundResponseSerializer class]));
    AFCompoundResponseSerializer* compoundSerializer = (AFCompoundResponseSerializer*)serializer;
    assertThatUnsignedInteger(compoundSerializer.responseSerializers.count,equalToUnsignedInteger(2));
    assertThat([compoundSerializer.responseSerializers objectAtIndex:0],instanceOf([XMLResponseSerializer class]));
    assertThat([compoundSerializer.responseSerializers objectAtIndex:1],instanceOf([XMLResponseSerializer class]));
    assertThat([self xmlResponseSerializerFrom:compoundSerializer AtIndex:0],instanceOf([NotAuthorizedResponseSerializerDelegate class]));
    assertThat([self xmlResponseSerializerFrom:compoundSerializer AtIndex:1],instanceOf([WorkspacesResponseSerializerDelegate class]));
}

-(id<XMLResponseSerializerDelegate>)xmlResponseSerializerFrom:(AFCompoundResponseSerializer*)compound AtIndex:(NSUInteger)index {
    return ((XMLResponseSerializer*)[compound.responseSerializers objectAtIndex:index]).serializerDelegate;
}

@end
