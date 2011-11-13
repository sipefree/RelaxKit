//
//  RKConnection.h
//  RelaxKit
//
//  Created by Simon Free on 10/11/2011.
//  Copyright (c) 2011 N/A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RelaxKit.h"
#import "RKEventEmitter.h"
#import "RKTypes.h"

@class RKDatabase;

@interface RKRequest : RKEventEmitter
@end

@interface RKConnection : NSObject <NSStreamDelegate> {
    NSDictionary* _options;
    NSOperationQueue* _operationQueue;
    NSMutableDictionary* _streamEventMap;
}
@property (nonatomic, retain) NSDictionary* options;
@property (nonatomic, retain) NSOperationQueue* operationQueue;
@property (nonatomic, retain) NSMutableDictionary* streamEventMap;
- (id)initWithDefaults;
- (id)initWithOptions:(NSDictionary*)options;
- (RKRequest*)rawRequest:(NSString*)method path:(NSString*)path options:(NSDictionary*)options data:(NSData*)data headers:(NSDictionary*)headers;
- (RKRequest*)rawStreamingRequest:(NSString*)method path:(NSString*)path options:(NSDictionary*)options data:(NSData*)data headers:(NSDictionary*)headers;

- (void)close;

- (RKRequest*)request:(NSString*)method path:(NSString*)path options:(NSDictionary*)options data:(id)data headers:(NSDictionary*)headers :(RKCallback)callback;

- (RKRequest*)request:(NSString *)method path:(NSString *)path :(RKCallback)callback;

- (RKDatabase*)database:(NSString*)name;
- (RKRequest*)config:(RKCallback)callback;
- (RKRequest*)info:(RKCallback)callback;
- (RKRequest*)stats:(RKCallback)callback;
- (RKRequest*)activeTasks:(RKCallback)callback;
- (RKRequest*)uuids:(int)count :(RKCallback)callback;
- (RKRequest*)replicate:(id)options :(RKCallback)callback;
@end
