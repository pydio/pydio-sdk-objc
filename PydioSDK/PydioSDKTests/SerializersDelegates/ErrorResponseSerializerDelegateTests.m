//
//  ErrorResponseSerializerDelegateTests.m
//  PydioSDK
//
//  Created by ME on 13/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "XMLResponseSerializerDelegate.h"
#import "ErrorResponseParserDelegate.h"
#import "PydioErrorResponse.h"


#pragma mark - Access to private data of tested class
@interface ErrorResponseSerializerDelegate ()
@property (readwrite, nonatomic,strong) ErrorResponseParserDelegate* parserDelegate;
@end


#pragma mark - Tests

@interface ErrorResponseSerializerDelegateTests : XCTestCase
@property (nonatomic,strong) ErrorResponseSerializerDelegate *serializerDelegate;
@end

@implementation ErrorResponseSerializerDelegateTests

- (void)setUp
{
    [super setUp];
    self.serializerDelegate = [[ErrorResponseSerializerDelegate alloc] init];
}

- (void)tearDown
{
    self.serializerDelegate = nil;
    [super tearDown];
}

- (void)test_ShouldReturnProperXMLParserDelegate
{
    assertThat([self.serializerDelegate xmlParserDelegate],instanceOf([ErrorResponseParserDelegate class]));
}

-(void)test_ShouldReturnErrorMessage_WhenParsedErrorMessage
{
    PydioErrorResponse *expectedResponse = [PydioErrorResponse errorResponseWithString:@"Example error"];
    ErrorResponseParserDelegate *parserDelegate = mock([ErrorResponseParserDelegate class]);
    [given(parserDelegate.errorMessage) willReturn:@"Example error"];
    self.serializerDelegate.parserDelegate = parserDelegate;
    
    assertThat([self.serializerDelegate parseResult],equalTo(expectedResponse));
}

-(void)test_ShouldReturnNilErrorMessage_WhenNotParsedErrorMessage
{
    ErrorResponseParserDelegate *parserDelegate = mock([ErrorResponseParserDelegate class]);
    [given(parserDelegate.errorMessage) willReturn:nil];
    self.serializerDelegate.parserDelegate = parserDelegate;
    
    assertThat([self.serializerDelegate parseResult],nilValue());
}

-(void)test_ShouldReturnNilErrorUserInfo
{
    NSObject *object = [[NSObject alloc] init];
    assertThat([self.serializerDelegate errorUserInfo:object],nilValue());
}

@end
