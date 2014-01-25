//
//  LoginResponseSerializerTests.m
//  PydioSDK
//
//  Created by ME on 25/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "LoginResponseSerializer.h"
#import "LoginResponseParserDelegate.h"
#import "LoginResponse.h"
#import "PydioErrors.h"
#import <objc/runtime.h>


#pragma mark - methods returning response from AFXMLParserResponseSerializer

static NSXMLParser *xmlParser = nil;

static id responseWithNil(id self, SEL _cmd, NSURLResponse * response, NSData *data, NSError *__autoreleasing *error) {
    return nil;
}

static id responseWithXMLParser(id self, SEL _cmd, NSURLResponse * response, NSData *data, NSError *__autoreleasing *error) {
    return xmlParser;
}

#pragma mark - 

static LoginResponseParserDelegate* parserDelegate = nil;

static LoginResponseParserDelegate* createResponseParserDelegate(id self, SEL _cmd) {
    return parserDelegate;
}

#pragma mark - Private methods of LoginResponseSerializer
@interface LoginResponseSerializer ()
-(LoginResponseParserDelegate*)createResponseParserDelegate;
@end

#pragma mark - Tests

@interface LoginResponseSerializerTests : XCTestCase {
    Method _createDelegateMethod;
    IMP _originalCreateDelegateIMP;
    Method _afResponseMethod;
    IMP _originalAFResponseIMP;
}
@property (nonatomic,strong) LoginResponseSerializer* responseSerializer;
@end

@implementation LoginResponseSerializerTests

- (void)setUp
{
    [super setUp];
    xmlParser = mock([NSXMLParser class]);
    parserDelegate = mock([LoginResponseParserDelegate class]);
    _createDelegateMethod = class_getInstanceMethod([LoginResponseSerializer class], @selector(createResponseParserDelegate));
    _originalCreateDelegateIMP = method_setImplementation(_createDelegateMethod, (IMP)createResponseParserDelegate);
    self.responseSerializer = [[LoginResponseSerializer alloc] init];
    _afResponseMethod = class_getInstanceMethod([AFXMLParserResponseSerializer class], @selector(responseObjectForResponse:data:error:));
}

- (void)tearDown
{
    method_setImplementation(_afResponseMethod, _originalCreateDelegateIMP);
    _afResponseMethod = nil;
    self.responseSerializer = nil;
    method_setImplementation(_createDelegateMethod, _originalCreateDelegateIMP);
    parserDelegate = nil;
    xmlParser = nil;
    [super tearDown];
}

- (void)testShouldReturnNilWhenNilFromAFNetworking
{
    _originalCreateDelegateIMP = method_setImplementation(_afResponseMethod, (IMP)responseWithNil);
    
    id response = [self.responseSerializer responseObjectForResponse:nil data:nil error:nil];
    
    assertThat(response,nilValue());
}

-(void)testShouldReturnLoginResultWhenParserParsedCorrectly
{
    _originalCreateDelegateIMP = method_setImplementation(_afResponseMethod, (IMP)responseWithXMLParser);
    [given(parserDelegate.resultValue) willReturn:@"1"];
    [given(parserDelegate.secureToken) willReturn:@"secure_token"];
    LoginResponse *expectedResponse = [[LoginResponse alloc] initWithValue:@"1" AndToken:@"secure_token"];
    NSError *receivedError = nil;
    
    id response = [self.responseSerializer responseObjectForResponse:nil data:nil error:&receivedError];
    
    [verify(xmlParser) setDelegate:parserDelegate];
    [verify(xmlParser) parse];
    assertThat(response,equalTo(expectedResponse));
    assertThat(receivedError,nilValue());
}

-(void)testShouldErrorWhenParsedResultIsNil
{
    _originalCreateDelegateIMP = method_setImplementation(_afResponseMethod, (IMP)responseWithXMLParser);
    [given(parserDelegate.resultValue) willReturn:nil];
    NSError *receivedError = nil;
    
    id response = [self.responseSerializer responseObjectForResponse:nil data:nil error:&receivedError];
    
    [verify(xmlParser) setDelegate:parserDelegate];
    [verify(xmlParser) parse];
    assertThat(response,nilValue());
    assertThat(receivedError.domain,equalTo(PydioErrorDomain));
    assertThatInteger(receivedError.code,equalToInteger(PydioErrorUnableToParseAnswer));
}

@end
