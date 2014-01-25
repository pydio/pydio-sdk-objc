//
//  XCTestCase+XMLFixture.m
//  PydioSDK
//
//  Created by ME on 25/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "XCTestCase+XMLFixture.h"

@implementation XCTestCase (XMLFixture)

-(NSXMLParser*)parserWithFixture:(NSString *)file delegate:(NSObject<NSXMLParserDelegate>*)delegate {
    NSData * xmlData = [self loadFixture:file];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xmlData];
    parser.delegate = delegate;
    
    return parser;
}

-(NSData*)loadFixture:(NSString*)name {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:name ofType:nil];
    
    return [[NSData alloc] initWithContentsOfFile:path];    
}

@end
