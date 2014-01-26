//
//  XMLResponseSerializerTests.m
//  PydioSDK
//
//  Created by ME on 26/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "XMLResponseSerializer.h"
#import "XMLResponseSerializerDelegate.h"
#import <objc/runtime.h>
#import "PydioErrors.h"


#pragma mark - AFNetworking

static NSXMLParser *parser = nil;

static id response(id self, SEL _cmd, NSURLResponse *response, NSData *data, NSError *__autoreleasing *error) {
    return parser;
}

#pragma mark - Tests

@interface XMLResponseSerializerTests : XCTestCase {
    Method _responseMethod;
    IMP _responseIMP;
}
@property (nonatomic,strong) NSObject<NSXMLParserDelegate> *xmlParserDelegate;
@property (nonatomic,strong) NSObject<XMLResponseSerializerDelegate> *serializerDelegate;
@property (nonatomic,strong) XMLResponseSerializer* responseSerializer;
@end

@implementation XMLResponseSerializerTests

- (void)setUp
{
    [super setUp];
    _responseMethod = class_getInstanceMethod([AFXMLParserResponseSerializer class], @selector(responseObjectForResponse:data:error:));
    _responseIMP = method_setImplementation(_responseMethod, (IMP)response);
    self.xmlParserDelegate = mockProtocol(@protocol(NSXMLParserDelegate));
    self.serializerDelegate = mockProtocol(@protocol(XMLResponseSerializerDelegate));
    [given([self.serializerDelegate xmlParserDelegate]) willReturn:self.xmlParserDelegate];
    self.responseSerializer = [XMLResponseSerializer serializerWithDelegate:self.serializerDelegate];
}

- (void)tearDown
{
    parser = nil;
    self.responseSerializer = nil;
    self.serializerDelegate = nil;
    method_setImplementation(_responseMethod, _responseIMP);
    [super tearDown];
}

-(void)testshouldReturnNilWhenAFNetworkingReturnedNil
{
    id response = [self.responseSerializer responseObjectForResponse:nil data:nil error:nil];
    
    assertThat(response,nilValue());
}

-(void)testshouldReturnParsedAnswerWhenAFNetworkingReturnedAnswer
{
    NSObject *parserResult = [[NSObject alloc] init];
    [given([self.serializerDelegate parseResult]) willReturn:parserResult];
    parser = mock([NSXMLParser class]);
    
    id response = [self.responseSerializer responseObjectForResponse:nil data:nil error:nil];
    
    [verify(self.serializerDelegate) xmlParserDelegate];
    [verify(self.serializerDelegate) parseResult];
    [verify(parser) setDelegate:self.xmlParserDelegate];
    [verify(parser) parse];
    assertThat(response,sameInstance(parserResult));
    [verifyCount(self.serializerDelegate, never()) errorUserInfo:anything()];
}

-(void)testshouldReturnNilAndErrorWhenParserReturnsNilAndUserINfoIsNotNil
{
    NSDictionary *userInfo = @{};
    [given([self.serializerDelegate errorUserInfo:anything()]) willReturn:userInfo];
    parser = mock([NSXMLParser class]);
    NSError *receivedError = nil;
    
    id response = [self.responseSerializer responseObjectForResponse:nil data:nil error:&receivedError];
    
    [verify(self.serializerDelegate) xmlParserDelegate];
    [verify(self.serializerDelegate) parseResult];
    [verify(parser) setDelegate:self.xmlParserDelegate];
    [verify(parser) parse];
    assertThat(response,nilValue());
    [verify(self.serializerDelegate) errorUserInfo:anything()];
    assertThatInteger(receivedError.code,equalToInteger(PydioErrorUnableToParseAnswer));
    assertThat(receivedError.domain,equalTo(PydioErrorDomain));
}

-(void)testshouldReturnNilAndNilErrorWhenParserReturnsNilAndUserINfoIsNil
{
    parser = mock([NSXMLParser class]);
    NSError *receivedError = nil;
    
    id response = [self.responseSerializer responseObjectForResponse:nil data:nil error:&receivedError];
    
    [verify(self.serializerDelegate) xmlParserDelegate];
    [verify(self.serializerDelegate) parseResult];
    [verify(parser) setDelegate:self.xmlParserDelegate];
    [verify(parser) parse];
    assertThat(response,nilValue());
    [verify(self.serializerDelegate) errorUserInfo:anything()];
    assertThat(receivedError,nilValue());
}

@end
