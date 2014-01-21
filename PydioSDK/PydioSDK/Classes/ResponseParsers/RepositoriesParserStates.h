//
//  RepositoriesParserStates.h
//  PydioSDK
//
//  Created by ME on 20/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RepositoriesParserDelegate;

@interface BaseParserState : NSObject
@property (nonatomic,weak) RepositoriesParserDelegate *parser;
@property (nonatomic,strong) NSString* buffer;

-(instancetype)initWithParser:(RepositoriesParserDelegate*)parser;
-(void)didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict;
-(void)didEndElement:(NSString *)elementName;
-(void)foundCharacters:(NSString *)string;
@end

@interface StartParserState : BaseParserState
@end

@interface ExpectStartRepoState : BaseParserState
@end

@interface ExpectEndRepoState : BaseParserState
@property (nonatomic,strong) NSString *repoId;
@property (nonatomic,strong) NSString *label;
@property (nonatomic,strong) NSString *description;
@end
