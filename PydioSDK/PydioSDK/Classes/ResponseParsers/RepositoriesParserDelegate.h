//
//  RepositoriesResponseParser.h
//  PydioSDK
//
//  Created by ME on 19/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RepositoriesParserDelegate : NSObject<NSXMLParserDelegate>
@property (readonly,nonatomic,strong) NSArray* repositories;
@end
