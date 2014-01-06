//
//  BootConfResponseSerializerTests.m
//  PydioSDK
//
//  Created by ME on 06/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "BootConfResponseSerializer.h"

#pragma mark - responses

id responseWithNil(id self, SEL _cmd, NSURLResponse *response,NSData *data,NSError *__autoreleasing *error) {
    return nil;
}

id responseWithArray(id self, SEL _cmd, NSURLResponse *response,NSData *data,NSError *__autoreleasing *error) {
    return [[NSArray alloc] init];
}

id responseWithEmptyDictionary(id self, SEL _cmd, NSURLResponse *response,NSData *data,NSError *__autoreleasing *error) {
    return [[NSDictionary alloc] init];
}

id responseWithDictionaryWithToken(id self, SEL _cmd, NSURLResponse *response,NSData *data,NSError *__autoreleasing *error) {
    return @{@"SECURE_TOKEN": @"123456"};
}

#pragma mark - Tests

@interface BootConfResponseSerializerTests : XCTestCase {
    Method _exchangedMethod;
    IMP _originalIMP;
}
@property (nonatomic,strong) BootConfResponseSerializer* serializer;
@end

@implementation BootConfResponseSerializerTests

- (void)setUp
{
    [super setUp];
    self.serializer = [[BootConfResponseSerializer alloc] init];
    _exchangedMethod = class_getInstanceMethod([AFJSONResponseSerializer class], @selector(responseObjectForResponse:data:error:));
}

- (void)tearDown
{
    method_setImplementation(_exchangedMethod, _originalIMP);
    [super tearDown];
}

- (void)testShouldReturnNilWhenSuperReturnedNil
{
    //given
    _originalIMP = method_setImplementation(_exchangedMethod, (IMP)responseWithNil);
    
    //when
    id response = [self.serializer responseObjectForResponse:nil data:nil error:nil];
    
    //then
    assertThat(response, nilValue());
}

- (void)testShouldReturnNilAndErrorWhenSuperNotReturnedDictionary
{
    //given
    _originalIMP = method_setImplementation(_exchangedMethod, (IMP)responseWithArray);
    NSError *error = nil;
    
    //when
    id response = [self.serializer responseObjectForResponse:nil data:nil error:&error];
    
    //then
    assertThat(response, nilValue());
    assertThat([error domain],equalTo(PydioErrorDomain));
    assertThatLong([error code],equalToLong(NSURLErrorCannotDecodeContentData));
    
    NSDictionary *userInfo = [error userInfo];
    assertThat(userInfo,notNilValue());
    assertThat([userInfo valueForKey:NSLocalizedDescriptionKey],equalTo(@"Error extracting SECURE_TOKEN"));
    assertThat([userInfo valueForKey:NSLocalizedFailureReasonErrorKey],startsWith(@"Could not extract SECURE_TOKEN:"));
}

- (void)testShouldReturnNilAndErrorWhenSuperReturnedDictionaryWithoutToken
{
    //given
    _originalIMP = method_setImplementation(_exchangedMethod, (IMP)responseWithEmptyDictionary);
    NSError *error = nil;
    
    //when
    id response = [self.serializer responseObjectForResponse:nil data:nil error:&error];
    
    //then
    assertThat(response, nilValue());
    assertThat([error domain],equalTo(PydioErrorDomain));
    assertThatLong([error code],equalToLong(NSURLErrorCannotDecodeContentData));
    
    NSDictionary *userInfo = [error userInfo];
    assertThat(userInfo,notNilValue());
    assertThat([userInfo valueForKey:NSLocalizedDescriptionKey],equalTo(@"Error extracting SECURE_TOKEN"));
    assertThat([userInfo valueForKey:NSLocalizedFailureReasonErrorKey],startsWith(@"Could not extract SECURE_TOKEN:"));
    
}

- (void)testShouldReturnSecureToken
{
    //given
    _originalIMP = method_setImplementation(_exchangedMethod, (IMP)responseWithDictionaryWithToken);
    NSError *error = nil;
    
    //when
    id response = [self.serializer responseObjectForResponse:nil data:nil error:&error];
    
    //then
    assertThat(response, equalTo(@"123456"));
    assertThat([error domain],nilValue());
    
}

@end
