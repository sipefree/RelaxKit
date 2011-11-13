//
//  RelaxKit.h
//  RelaxKit
//
//  Created by Simon Free on 10/11/2011.
//  Copyright (c) 2011 N/A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKConnection.h"
#import "RKDatabase.h"
#import "RKEventEmitter.h"

@interface RelaxKit : NSObject
+ (RelaxKit*)defaults;
@property (nonatomic, retain) NSDictionary* defaultOptions;

+ (NSString*)escape:(NSString*)_id;
@end
