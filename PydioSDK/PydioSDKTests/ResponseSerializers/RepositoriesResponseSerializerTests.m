//
//  RepositoriesResponseSerializerTests.m
//  PydioSDK
//
//  Created by ME on 20/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "RepositoriesResponseSerializer.h"
#import "RepositoriesParserDelegate.h"
#import "PydioErrors.h"
#import "Repository.h"

#pragma mark - methods returning response from AFXMLParserResponseSerializer

static NSXMLParser *xmlParser = nil;

static id responseWithNil(id self, SEL _cmd, NSURLResponse * response, NSData *data, NSError *__autoreleasing *error) {
    return nil;
}

static id responseWithXMLParser(id self, SEL _cmd, NSURLResponse * response, NSData *data, NSError *__autoreleasing *error) {
    return xmlParser;
}

#pragma mark - RepositoriesParserDelegate mock

static RepositoriesParserDelegate *repositoriesParserDelegate = nil;

RepositoriesParserDelegate* getParserDelegate(id self, SEL _cmd, NSString* server) {
    return repositoriesParserDelegate;
}

#pragma mark - RepositoriesResponseSerializer addon

@interface RepositoriesResponseSerializer ()
-(RepositoriesParserDelegate *)createRepositoriesParserDelegate;
@end

#pragma mark - Tests

@interface RepositoriesResponseSerializerTests : XCTestCase
@property (nonatomic,strong) RepositoriesResponseSerializer* serializer;
@end

@implementation RepositoriesResponseSerializerTests {
    Method _createDelegateMethod;
    IMP _originalCreateDelegateIMP;
    Method _responseMethod;
    IMP _originalResponseIMP;
}

- (void)setUp
{
    [super setUp];
    xmlParser = mock([NSXMLParser class]);
    repositoriesParserDelegate = mock([RepositoriesParserDelegate class]);
    _createDelegateMethod = class_getInstanceMethod([RepositoriesResponseSerializer class], @selector(createRepositoriesParserDelegate));
    _originalCreateDelegateIMP = method_setImplementation(_createDelegateMethod, (IMP)getParserDelegate);
    _responseMethod = class_getInstanceMethod([AFXMLParserResponseSerializer class], @selector(responseObjectForResponse:data:error:));

    self.serializer = [[RepositoriesResponseSerializer alloc] init];
}

- (void)tearDown
{
    self.serializer = nil;
    method_setImplementation(_responseMethod, _originalResponseIMP);
    method_setImplementation(_createDelegateMethod, _originalCreateDelegateIMP);
    repositoriesParserDelegate = nil;
    xmlParser = nil;
    [super tearDown];
}

- (void)testShouldReturnNilWhenSuperReturnedNil {
    _originalResponseIMP = method_setImplementation(_responseMethod, (IMP)responseWithNil);
    
    id response = [self.serializer responseObjectForResponse:nil data:nil error:nil];
    
    assertThat(response,nilValue());
}

-(void)testShouldReturnNilAndErrorWhenNoRepositories {
    _originalResponseIMP = method_setImplementation(_responseMethod, (IMP)responseWithXMLParser);
    NSError *error = nil;
    
    id response = [self.serializer responseObjectForResponse:nil data:nil error:&error];
    
    [verify(xmlParser) setDelegate:equalTo(repositoriesParserDelegate)];
    assertThat(response,nilValue());
    assertThat(error,notNilValue());
    assertThat(error.domain,equalTo(PydioErrorDomain));
    assertThatInteger(error.code,equalToInteger(PydioErrorUnableToParseAnswer));
}

-(void)testShouldReturnArrayOfRepositories {
    _originalResponseIMP = method_setImplementation(_responseMethod, (IMP)responseWithXMLParser);
    Repository *repo = [[Repository alloc] initWithId:@"testId" AndLabel:@"label" AndDescription:@"description"];
    NSArray *reposArray = [NSArray arrayWithObject:repo];
    [given([repositoriesParserDelegate repositories]) willReturn:reposArray];
    NSError *error = nil;
    
    id response = [self.serializer responseObjectForResponse:nil data:nil error:&error];
    
    [verify(xmlParser) setDelegate:equalTo(repositoriesParserDelegate)];
    assertThat(error,nilValue());
    assertThat(response,instanceOf([NSArray class]));
    NSArray *responseArray = response;
    assertThatUnsignedInteger(responseArray.count,equalToUnsignedInteger(reposArray.count));
    assertThat([responseArray objectAtIndex:0],sameInstance(repo));
}

@end
