//
//  DownloadNodesRequestParams.h
//  PydioSDK
//
//  Created by Michal Kloczko on 06/05/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadNodesRequestParams : NSObject
@property (nonatomic,strong) NSString* workspaceId;
@property (nonatomic,strong) NSArray* nodes;
@property (nonatomic,strong) NSDictionary* additional;

-(NSDictionary *)dictionaryRepresentation;
@end
