//
//  ListFilesResponseParserDelegateTests.m
//  PydioSDK
//
//  Created by ME on 01/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "ListFilesResponseParserDelegate.h"
#import "XCTestCase+XMLFixture.h"
#import "Node.h"


@interface ListFilesResponseParserDelegateTests : XCTestCase
@property (nonatomic,strong) ListFilesResponseParserDelegate *parserDelegate;
@end

@implementation ListFilesResponseParserDelegateTests

- (void)setUp
{
    [super setUp];
    self.parserDelegate = [[ListFilesResponseParserDelegate alloc] init];
}

- (void)tearDown
{
    self.parserDelegate = nil;
    [super tearDown];
}

- (void)testShouldParseCorrectFilesResponse
{
    Node *expectedTree = [self expectedFilesTree];
    NSXMLParser *parser = [self parserWithFixture:@"ls_response2.xml" delegate:self.parserDelegate];
    
    BOOL result = [parser parse];
    
    assertThatBool(result,equalToBool(YES));
    assertThatUnsignedInteger(self.parserDelegate.files.count,equalToUnsignedInteger(2));
    assertThatBool([((Node*)[self.parserDelegate.files objectAtIndex:0]) isTreeEqual:[expectedTree.children objectAtIndex:0]],equalToBool(YES));
    assertThatBool([((Node*)[self.parserDelegate.files objectAtIndex:1]) isTreeEqual:[expectedTree.children objectAtIndex:1]],equalToBool(YES));
}

#pragma mark - Helpers

-(Node*)root {
    Node *node = [[Node alloc] init];
    
    node.name = @"";
    node.isLeaf = NO;
    node.path = @"";
    node.size = 0;
    node.mTime = [NSDate dateWithTimeIntervalSince1970:1389931615];

    return node;
}

-(Node*)expectedFilesTree {
    Node* node = [self root];
    
    node.children = @[
                      [self child1:node],
                      [self child2:node]
                     ];
    
    return node;
}

-(Node*)child1:(Node*)parent {
    Node *node = [[Node alloc] init];

    node.parent = parent;
    node.name = @"curl_dump";
    node.isLeaf = YES;
    node.path = @"/curl_dump";
    node.size = 53066;
    node.mTime = [NSDate dateWithTimeIntervalSince1970:1389931615];

    return node;
}

-(Node*)child2:(Node*)parent {
    Node *node = [[Node alloc] init];
    
    node.parent = parent;
    node.name = @"Recycle Bin";
    node.isLeaf = NO;
    node.path = @"/recycle_bin";
    node.size = 0;
    node.mTime = [NSDate dateWithTimeIntervalSince1970:1386778972];
    
    return node;
}

@end
