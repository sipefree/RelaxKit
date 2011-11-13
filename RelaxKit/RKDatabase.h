//
//  RKDatabase.h
//  RelaxKit
//
//  Created by Simon Free on 12/11/2011.
//  Copyright (c) 2011 N/A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RelaxKit.h"
#import "RKTypes.h"

@class RKConnection;
@class RKRequest;

@interface RKDatabase : NSObject {
    NSString* _name;
    RKConnection* _connection;
    NSCache* _cache;
}
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) RKConnection* connection;
@property (nonatomic, retain) NSCache* cache;
- (id)initWithName:(NSString*)name connection:(RKConnection*)connection cache:(NSCache*)cache;
+ (id)databaseWithName:(NSString*)name connection:(RKConnection*)connection cache:(NSCache*)cache;

- (RKRequest*)query:(NSString*)method path:(NSString*)path :(RKCallback)callback;
- (RKRequest*)query:(NSString*)method path:(NSString*)path options:(NSDictionary*)options data:(id)data headers:(NSDictionary*)headers :(RKCallback)callback;
- (RKRequest*)exists:(void(^)(id err, id exists))callback;
- (RKRequest*)get:(NSString*)_id :(RKCallback)callback;
- (RKRequest*)get:(NSString*)_id rev:(NSString*)rev :(RKCallback)callback;
- (RKRequest*)getBulk:(NSArray*)ids :(RKCallback)callback;
- (RKRequest*)save:(NSString*)_id rev:(NSString*)rev doc:(id)doc :(RKCallback)callback;
- (RKRequest*)save:(NSString*)_id doc:(id)doc :(RKCallback)callback;
- (RKRequest*)save:(id)doc :(RKCallback)callback;
- (RKRequest*)saveBulk:(id)docs :(RKCallback)callback;
- (RKRequest*)replicateTo:(NSString*)target options:(id)options :(RKCallback)callback;
- (RKRequest*)replicateTo:(NSString*)target :(RKCallback)callback;
- (RKRequest*)destroy:(RKCallback)callback;
- (RKRequest*)remove:(NSString*)_id :(RKCallback)callback;
- (RKRequest*)remove:(NSString *)_id rev:(NSString*)rev :(RKCallback)callback;
- (RKRequest*)create:(RKCallback)callback;
- (RKRequest*)info:(RKCallback)callback;
- (RKRequest*)allWithOptions:(id)options :(RKCallback)callback;
- (RKRequest*)all:(RKCallback)callback;
- (RKRequest*)compact:(RKCallback)callback;
- (RKRequest*)compactDesign:(NSString*)design :(RKCallback)callback;
- (RKRequest*)viewCleanup:(RKCallback)callback;
- (RKRequest*)allBySeqWithOptions:(id)options :(RKCallback)callback;
- (RKRequest*)allBySeq:(RKCallback)callback;
- (RKRequest*)view:(NSString*)path options:(id)options :(RKCallback)callback;
- (RKRequest*)view:(NSString*)path :(RKCallback)callback;
- (RKRequest*)view:(NSString*)path keys:(NSArray*)keys reduce:(BOOL)reduce :(RKCallback)callback;
- (RKRequest*)view:(NSString*)path key:(id)key reduce:(BOOL)reduce :(RKCallback)callback;
- (RKRequest*)view:(NSString*)path startKey:(id)startKey endKey:(id)endKey reduce:(BOOL)reduce :(RKCallback)callback;
- (RKRequest*)list:(NSString*)path options:(id)options :(RKCallback)callback;
- (RKRequest*)list:(NSString*)path :(RKCallback)callback;
- (RKRequest*)list:(NSString*)path keys:(NSArray*)keys reduce:(BOOL)reduce :(RKCallback)callback;
- (RKRequest*)list:(NSString*)path key:(id)key reduce:(BOOL)reduce :(RKCallback)callback;
- (RKRequest*)list:(NSString*)path startKey:(id)startKey endKey:(id)endKey reduce:(BOOL)reduce :(RKCallback)callback;

- (RKRequest*)update:(NSString*)path ID:(NSString*)_id options:(id)options :(RKCallback)callback;
- (RKRequest*)update:(NSString*)path :(RKCallback)callback;
- (RKRequest*)changes:(RKCallback)callback;
- (RKRequest*)changes:(id)options :(RKCallback)callback;

- (RKRequest*)temporaryView:(id)doc :(RKCallback)callback;
@end
