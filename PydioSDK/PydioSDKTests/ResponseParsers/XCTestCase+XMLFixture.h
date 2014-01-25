//
//  XCTestCase+XMLFixture.h
//  PydioSDK
//
//  Created by ME on 25/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface XCTestCase (XMLFixture)
-(NSXMLParser*)parserWithFixture:(NSString*)file delegate:(NSObject<NSXMLParserDelegate>*)delegate;
-(NSData*)loadFixture:(NSString*)name;
@end
