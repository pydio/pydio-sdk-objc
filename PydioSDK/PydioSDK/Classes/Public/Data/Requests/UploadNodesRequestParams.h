//
//  UploadNodesRequestParams.h
//  PydioSDK
//
//  Created by Michal Kloczko on 11/05/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UploadNodesRequestParams : NSObject
@property (nonatomic,strong) NSString* workspaceId;
@property (nonatomic,strong) NSString* dir;
@property (nonatomic,strong) NSString* fileName;
@property (nonatomic,strong) NSData* data;
@property (nonatomic,strong) NSDictionary* additional;

-(NSDictionary *)dictionaryRepresentation;

@end
