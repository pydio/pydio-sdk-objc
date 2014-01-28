//
//  RepositoriesResponseParser.m
//  PydioSDK
//
//  Created by ME on 19/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "RepositoriesParserDelegate.h"
#import "RepositoriesParserDelegate_Private.h"
#import "RepositoriesParserStates.h"


@implementation RepositoriesParserDelegate

-(instancetype)init {
    self = [super init];
    if (self) {
        self.parserState = [[StartParserState alloc] initWithParser:self];
        _repositories = [NSArray array];
    }
    
    return self;
}

-(void)appendRepository:(Workspace*)repo {
    _repositories = [_repositories arrayByAddingObject:repo];
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    [self.parserState didStartElement:elementName attributes:attributeDict];
}

-(void)parser:(NSXMLParser*)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    [self.parserState didEndElement:elementName];
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [self.parserState foundCharacters:string];
}
@end

