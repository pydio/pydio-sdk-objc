//
//  RepositoriesParserStates.m
//  PydioSDK
//
//  Created by ME on 20/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "RepositoriesParserStates.h"
#import "RepositoriesParserDelegate_Private.h"
#import "Workspace.h"


@implementation BaseParserState

-(instancetype)initWithParser:(RepositoriesParserDelegate*)parser {
    self = [super init];
    if (self) {
        self.parser = parser;
        self.buffer = @"";
    }
    
    return self;
}

-(void)didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict {
    
}

-(void)didEndElement:(NSString *)elementName {
    
}

-(void)foundCharacters:(NSString *)string {
    self.buffer = [self.buffer stringByAppendingString:string];
}

@end

#pragma mark - Derived Parsers States

@implementation StartParserState

-(void)didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"repositories"]) {
        self.parser.parserState = [[ExpectStartRepoState alloc] initWithParser:self.parser];
    }
}

@end


@implementation ExpectStartRepoState

-(void)didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"repo"] && [attributeDict valueForKey:@"id"]) {
        ExpectEndRepoState *endRepoState = [[ExpectEndRepoState alloc] initWithParser:self.parser];
        endRepoState.repoId = [attributeDict valueForKey:@"id"];
        self.parser.parserState = endRepoState;
    }
}

@end


@implementation ExpectEndRepoState
-(void)didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict {
    self.buffer = @"";
}

-(void)didEndElement:(NSString *)elementName {
    if (!self.label && [elementName isEqualToString:@"label"]) {
        self.label = self.buffer;
    } else if (!self.description && [elementName isEqualToString:@"description"]) {
        self.description = self.buffer;
    } else if ([elementName isEqualToString:@"repo"]) {
        Workspace *repo = [[Workspace alloc] initWithId:self.repoId AndLabel:self.label AndDescription:self.description];
        [self.parser appendRepository:repo];
        self.parser.parserState = [[ExpectStartRepoState alloc] initWithParser:self.parser];
    }
}

@end
