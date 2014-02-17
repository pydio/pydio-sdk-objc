//
//  ListFilesResponseSerializerDelegateTests.m
//  PydioSDK
//
//  Created by ME on 17/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "XMLResponseSerializerDelegate.h"
#import "ListFilesResponseParserDelegate.h"

#pragma mark - Access to private data of tested class

@interface ListFilesResponseSerializerDelegate ()
@property (readwrite, nonatomic,strong) ListFilesResponseParserDelegate* parserDelegate;
@end

#pragma mark - Tests

@interface ListFilesResponseSerializerDelegateTests : XCTestCase
@property (nonatomic,strong) ListFilesResponseSerializerDelegate* serializerDelegate;
@end

@implementation ListFilesResponseSerializerDelegateTests

- (void)setUp
{
    [super setUp];
    self.serializerDelegate = [[ListFilesResponseSerializerDelegate alloc] init];
}

- (void)tearDown
{
    self.serializerDelegate = nil;
    [super tearDown];
}

- (void)test_ShouldReturnProperXMLParserDelegate
{
    assertThat([self.serializerDelegate xmlParserDelegate],instanceOf([ListFilesResponseParserDelegate class]));
}

-(void)test_ShouldReturnArrayWithParsedResults_WhenParsedArrayWithFiles
{
    NSArray *array = [NSArray arrayWithObjects:@"item1",@"item2", nil];
    ListFilesResponseParserDelegate *parserDelegate = mock([ListFilesResponseParserDelegate class]);
    [given(parserDelegate.files) willReturn:array];
    self.serializerDelegate.parserDelegate = parserDelegate;
    
    assertThat([self.serializerDelegate parseResult],equalTo(array));
}

-(void)test_ShouldReturnNotNilErrorUserInfo
{
    NSObject *object = [[NSObject alloc] init];
    assertThat([self.serializerDelegate errorUserInfo:object],notNilValue());
}

@end
