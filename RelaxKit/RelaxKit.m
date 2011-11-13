//
//  RelaxKit.m
//  RelaxKit
//
//  Created by Simon Free on 10/11/2011.
//  Copyright (c) 2011 N/A. All rights reserved.
//

#import "RelaxKit.h"


static RelaxKit* _sharedInstance = nil;

@implementation RelaxKit

@synthesize defaultOptions;

+ (RelaxKit*)defaults {
    if(!_sharedInstance) {
        _sharedInstance = [[RelaxKit alloc] init];
    }
    return _sharedInstance;
}

- (id)init {
    self = [super init];
    if(self) {
        self.defaultOptions = nil;
    }
    return self;
}

+ (NSString*)escape:(NSString*)_id {
    NSArray* special = [NSArray arrayWithObjects:@"_design", @"_changes", @"_temp_view", nil];
    NSString* firstPart = [[_id componentsSeparatedByString:@"/"] objectAtIndex:0];
    for (NSString* spec in special) {
        if([firstPart isEqualToString:spec]) {
            return _id;
        }
    }
    return [_id stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
}

@end
