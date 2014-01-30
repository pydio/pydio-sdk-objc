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
#import "FileNode.h"


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
    FileNode *expectedTree = [self expectedFilesTree];
    NSXMLParser *parser = [self parserWithFixture:@"ls_response2.xml" delegate:self.parserDelegate];
    
    BOOL result = [parser parse];
    
    assertThatBool(result,equalToBool(YES));
    assertThatUnsignedInteger(self.parserDelegate.files.count,equalToUnsignedInteger(1));
    assertThatBool([((FileNode*)[self.parserDelegate.files objectAtIndex:0]) isTreeEqual:expectedTree],equalToBool(YES));
}

#pragma mark - Helpers

-(FileNode*)expectedFilesTree {
    FileNode *node = [[FileNode alloc] init];
    
    node.name = @"";
    node.isFile = NO;
    node.path = @"";
    node.size = 0;
    node.modificationTime = [NSDate dateWithTimeIntervalSince1970:1389931615];
    node.children = @[
                      [self child1:node],
                      [self child2:node]
                     ];
    
    return node;
}

-(FileNode*)child1:(FileNode*)parent {
    FileNode *node = [[FileNode alloc] init];

    node.parent = parent;
    node.name = @"curl_dump";
    node.isFile = YES;
    node.path = @"/curl_dump";
    node.size = 53066;
    node.modificationTime = [NSDate dateWithTimeIntervalSince1970:1389931615];

    return node;
}

-(FileNode*)child2:(FileNode*)parent {
    FileNode *node = [[FileNode alloc] init];
    
    node.parent = parent;
    node.name = @"Recycle Bin";
    node.isFile = NO;
    node.path = @"/recycle_bin";
    node.size = 0;
    node.modificationTime = [NSDate dateWithTimeIntervalSince1970:1386778972];
    
    return node;
}

@end
