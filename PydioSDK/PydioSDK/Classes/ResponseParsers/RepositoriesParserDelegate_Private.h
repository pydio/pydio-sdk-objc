//
//  RepositoriesXMLResponseParserDelegate_Private.h
//  PydioSDK
//
//  Created by ME on 20/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "RepositoriesParserDelegate.h"

@class BaseParserState;
@class Repository;

@interface RepositoriesParserDelegate ()
@property (nonatomic,strong) BaseParserState *parserState;

-(void)appendRepository:(Repository*)repo;
@end
