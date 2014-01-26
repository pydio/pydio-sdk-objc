//
//  XMLResponseSerializerDelegate.h
//  PydioSDK
//
//  Created by ME on 26/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSXMLParserDelegate;

@protocol XMLResponseSerializerDelegate <NSObject>
@required
-(id <NSXMLParserDelegate>)xmlParserDelegate;
-(id)parseResult;
-(NSDictionary*)userInfoForError;
@end
