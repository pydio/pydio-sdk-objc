//
//  DownloadNodesResponseSerializerTests.m
//  PydioSDK
//
//  Created by Michal Kloczko on 11/05/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>
#import "DownloadNodesResponseSerializer.h"
#import "PydioErrors.h"

#pragma mark - method Swizzling

static BOOL validationResult = NO;

static BOOL validateResponse(id self, SEL _cmd, NSURLResponse * response, NSData *data, NSError *__autoreleasing *error) {
    return validationResult;
}

#pragma mark - TestCase

@interface DownloadNodesResponseSerializerTests : XCTestCase {
    Method _method;
    IMP _originalIMP;
}
@property (nonatomic,strong) DownloadNodesResponseSerializer *responseSerializer;
@end

@implementation DownloadNodesResponseSerializerTests

- (void)setUp
{
    [super setUp];
    _method = class_getInstanceMethod([AFHTTPResponseSerializer class], @selector(validateResponse:data:error:));
    _originalIMP = method_setImplementation(_method, (IMP)validateResponse);
    self.responseSerializer = [[DownloadNodesResponseSerializer alloc] init];
}

- (void)tearDown
{
    self.responseSerializer = nil;
    validationResult = NO;
    method_setImplementation(_method, _originalIMP);
    [super tearDown];
}

- (void)test_shouldAcceptServerDownloadResponse
{
    //given
    validationResult = YES;
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                              statusCode:200
                                                             HTTPVersion:nil
                                                            headerFields:@{
                                                                           @"Content-Type" : @"application/force-download; name=\"File\"",
                                                                           @"Content-Transfer-Encoding" : @"binary"
                                                                           }
                                   ];
    NSError *error = nil;
    //when
    BOOL result = [self.responseSerializer validateResponse:response data:nil error:&error];
    //then
    assertThatBool(result,equalToBool(YES));
    assertThat(error,nilValue());
}

- (void)test_shouldNotAcceptServerDownloadResponse_whenNoContentTransferEncoding
{
    //given
    validationResult = YES;
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:@{ @"Content-Type" : @"application/force-download; name=\"File\""}];
    NSError *error = nil;
    NSError *expectedError = [[NSError alloc] initWithDomain:PydioErrorDomain code:PydioErrorNotAZipFileResponse userInfo:nil];
    //when
    BOOL result = [self.responseSerializer validateResponse:response data:nil error:&error];
    //then
    assertThatBool(result,equalToBool(NO));
    assertThat(error,equalTo(expectedError));
}

- (void)test_shouldNotAcceptServerDownloadResponse_whenNoContentType
{
    //given
    validationResult = YES;
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200
                                                             HTTPVersion:nil headerFields:@{ @"Content-Transfer-Encoding" : @"binary"}];
    NSError *error = nil;
    NSError *expectedError = [[NSError alloc] initWithDomain:PydioErrorDomain code:PydioErrorNotAZipFileResponse userInfo:nil];
    //when
    BOOL result = [self.responseSerializer validateResponse:response data:nil error:&error];
    //then
    assertThatBool(result,equalToBool(NO));
    assertThat(error,equalTo(expectedError));
}

- (void)test_shouldNotAcceptServerDownloadResponse_whenAFNetworkingDidNotValidateResponse
{
    //given
    validationResult = NO;
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:@{ @"Content-Type" : @"application/force-download; name=\"Files.zip\""}];
    NSError *error = nil;
    //when
    BOOL result = [self.responseSerializer validateResponse:response data:nil error:&error];
    //then
    assertThatBool(result,equalToBool(NO));
    assertThat(error,nilValue());
}

@end
