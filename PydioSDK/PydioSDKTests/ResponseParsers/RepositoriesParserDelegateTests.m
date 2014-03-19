//
//  RepositoriesParserDelegateTests.m
//  PydioSDK
//
//  Created by ME on 20/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "RepositoriesParserDelegate.h"
#import "WorkspaceResponse.h"
#import "XCTestCase+XMLFixture.h"


@interface RepositoriesParserDelegateTests : XCTestCase
@property (nonatomic,strong) RepositoriesParserDelegate *parserDelegate;
@end

@implementation RepositoriesParserDelegateTests

- (void)setUp
{
    [super setUp];
    self.parserDelegate = [[RepositoriesParserDelegate alloc] init];
}

- (void)tearDown
{
    self.parserDelegate = nil;
    [super tearDown];
}

- (void)testShouldParseCorrectRepositoriesXML
{
    NSXMLParser *parser = [self parserWithFixture:@"get_registers_response.xml" delegate:self.parserDelegate];
    
    BOOL result = [parser parse];
    
    assertThatBool(result,equalToBool(YES));
    assertThat(self.parserDelegate.repositories,notNilValue());
    assertThatUnsignedInteger(self.parserDelegate.repositories.count,equalToUnsignedInteger(3));
    [self assertRepo:[self.parserDelegate.repositories objectAtIndex:0] WithId:@"0" Label:@"Common Files" Description:@"No description available"];
    [self assertRepo:[self.parserDelegate.repositories objectAtIndex:1] WithId:@"1" Label:@"My Files" Description:@"No description available"];
    [self assertRepo:[self.parserDelegate.repositories objectAtIndex:2] WithId:@"b03285d816de6a3c67349ab87d27ac20" Label:@"Synchro" Description:@"Created by charles on 2013/10/14"];
}

#pragma mark -

-(void)assertRepo:(WorkspaceResponse*)repo WithId:(NSString *)repoId Label:(NSString *)label Description:(NSString*)description {
    assertThat(repo.workspaceId,equalTo(repoId));
    assertThat(repo.label,equalTo(label));
    assertThat(repo.description,equalTo(description));
}

@end
