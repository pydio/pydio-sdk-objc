//
//  XMLResponseBuilder.m
//  PydioSDK
//
//  Created by ME on 04/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "NotAuthorizedXMLResponseParser.h"

@interface NotAuthorizedXMLResponseParser ()
@property (nonatomic,assign) SEL startElementAction;

-(void)firstElementStart:(NSString *)elementName;
-(void)requireAuthElementStart:(NSString *)elementName;
@end


@implementation NotAuthorizedXMLResponseParser

-(instancetype)init {
    self = [super init];
    if (self) {
        self.startElementAction = @selector(firstElementStart:);
        _notLogged = NO;
    }
    
    return self;
}

#pragma mark -

-(void)firstElementStart:(NSString *)elementName {
    if ([elementName compare:@"tree"] == NSOrderedSame) {
        self.startElementAction = @selector(requireAuthElementStart:);
    } else if ([elementName compare:@"ajxp_registry_part"] == NSOrderedSame) {
        _notLogged = YES;
        self.startElementAction = nil;
    }
}

-(void)requireAuthElementStart:(NSString *)elementName {
    if ([elementName compare:@"require_auth"] == NSOrderedSame) {
        _notLogged = YES;
        self.startElementAction = nil;
    }
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (self.startElementAction) {
        [self performSelector:self.startElementAction withObject:elementName];
    }
#pragma clang diagnostic pop
}

@end
