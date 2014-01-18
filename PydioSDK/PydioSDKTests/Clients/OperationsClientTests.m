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

static const NSString * const REGISTERS_URL_PART = @"index.php?get_action=get_xml_registry";
static const NSString * const SECURE_TOKEN_PART = @"&secure_token=";
static const NSString * const XPATH_PART = @"&xPath=user/repositories";
static const NSString * const TEST_TOKEN = @"j9tJRcVJYjKyfphibjRX47YgyVN1eoIv";
static NSString * const TEST_SERVER = @"http://www.testserver.com";

static CookieManager *cookieManager = nil;

id mockedCookieManager(id self, SEL _cmd) {
    return cookieManager;
}

@interface OperationsClient ()
@property (readwrite,nonatomic,assign) BOOL progress;

-(NSString*)urlStringForGetRegisters;
@end


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
    //should set request serializers
    //should set response serializers
    [verify(cookieManager) secureTokenForServer:server];
    [verify(self.operationManager) GET:[self urlGetRegistersToken] parameters:nil success:anything() failure:anything()];
    
}

- (void)testShouldNotStartListFilesIfInProgress
{
    self.client.progress = YES;
    BOOL startResult = [self.client listFilesWithSuccess:nil failure:nil];
    
    assertThatBool(startResult,equalToBool(NO));
    //should not set request serializers
    //should not set response serializers
    [verifyCount(self.operationManager, never()) GET:anything() parameters:nil success:anything() failure:anything()];
}

-(void)testListFilesShouldFailureWhenUnauthorized
{
    
}

#pragma mark -
-(NSString *)urlGetRegistersNoToken {
    return [NSString stringWithFormat:@"%@%@",REGISTERS_URL_PART,XPATH_PART];
}

-(NSString *)urlGetRegistersToken {
    return [NSString stringWithFormat:@"%@%@%@%@",REGISTERS_URL_PART,SECURE_TOKEN_PART,TEST_TOKEN,XPATH_PART];
}

@end
