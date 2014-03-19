//
//  WorkspacesResponseSerializerDelegate.m
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

#import "XMLResponseSerializerDelegate.h"
#import "RepositoriesParserDelegate.h"
#import "WorkspaceResponse.h"


#pragma mark - 

@interface WorkspacesResponseSerializerDelegate ()
@property (nonatomic,strong) RepositoriesParserDelegate *parserDelegate;
@end

#pragma mark - Tests

@interface WorkspacesResponseSerializerDelegateTests : XCTestCase
@property (nonatomic,strong) WorkspacesResponseSerializerDelegate* serializerDelegate;
@end

@implementation WorkspacesResponseSerializerDelegateTests

- (void)setUp
{
    [super setUp];
    self.serializerDelegate = [[WorkspacesResponseSerializerDelegate alloc] init];
}

- (void)tearDown
{
    self.serializerDelegate = nil;
    [super tearDown];
}

- (void)testShouldReturnProperXMLParserDelegate
{
    assertThat([self.serializerDelegate xmlParserDelegate],instanceOf([RepositoriesParserDelegate class]));
}

-(void)testShouldReturnArrayOfRepositoriesWhenRepositoriesArrayInResponseIsPresent
{
    RepositoriesParserDelegate *parserDelegate = mock([RepositoriesParserDelegate class]);
    WorkspaceResponse *repository = [[WorkspaceResponse alloc] initWithId:@"1" AndLabel:@"label" AndDescription:@"description"];
    NSArray *responseArray = @[repository];
    [given(parserDelegate.repositories) willReturn:responseArray];
    self.serializerDelegate.parserDelegate = parserDelegate;
    
    assertThat([self.serializerDelegate parseResult],equalTo(responseArray));
}

-(void)testShouldReturnNilWhenNoArrayWithRepositories
{
    NSArray *result = [self.serializerDelegate parseResult];
    
    assertThatInt(result.count,equalToInt(0));
}

-(void)testErrorUserInfoSholdBeNil
{
    NSObject *object = [[NSObject alloc] init];
    assertThat([self.serializerDelegate errorUserInfo:object],notNilValue());
}

@end
