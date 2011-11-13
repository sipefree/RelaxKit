//
//  RKDatabase.m
//  RelaxKit
//
//  Created by Simon Free on 12/11/2011.
//  Copyright (c) 2011 N/A. All rights reserved.
//

#import "RKDatabase.h"

@implementation RKDatabase
@synthesize name=_name;
@synthesize connection=_connection;
@synthesize cache=_cache;

- (id)initWithName:(NSString*)name connection:(RKConnection*)connection cache:(NSCache*)cache {
    self = [super init];
    if(self) {
        self.name = name;
        self.connection = connection;
        self.cache = cache;
    }
    return self;
}
+ (id)databaseWithName:(NSString*)name connection:(RKConnection*)connection cache:(NSCache*)cache {
    return [[[RKDatabase alloc] initWithName:name connection:connection cache:cache] autorelease];
}

- (RKRequest*)query:(NSString*)method path:(NSString*)path :(RKCallback)callback {
    return  [self query:method path:path options:nil data:nil headers:nil :callback];
}
- (RKRequest*)query:(NSString*)method
               path:(NSString*)path
            options:(NSDictionary*)options
               data:(id)data
            headers:(NSDictionary*)headers
                   :(RKCallback)callback
{
    NSString* realPath = [NSString stringWithFormat:@"%@/%@",self.name,path];
    return [self.connection request:method path:realPath options:options data:data headers:headers :callback];
}
- (RKRequest*)exists:(void(^)(id err, id exists))callback {
    return [self query:@"GET" path:@"" :^(id err, id nul) {
        if(nul) {
            callback(nil, [NSNumber numberWithBool:YES]);
            return;
        }
        if(err && ![[err objectForKey:@"error"] isEqualToString:@"not_found"]) {
            callback(err, nil);
        } else {
            int status = [[[err objectForKey:@"headers"] objectForKey:@"status-code"] intValue];
            if(status == 404) {
                callback(nil, [NSNumber numberWithBool:NO]);
            } else {
                callback(nil, [NSNumber numberWithBool:YES]);
            }
        }
    }];
}
- (RKRequest*)get:(NSString*)_id :(RKCallback)callback {
    return [self get:_id rev:nil :callback];
}
- (RKRequest*)get:(NSString*)_id rev:(NSString*)rev :(RKCallback)callback {
    NSDictionary* options = nil;
    if (rev) {
        options = [NSDictionary dictionaryWithObject:rev forKey:@"rev"];
    }
    return [self query:@"GET" path:[RelaxKit escape:_id] options:options data:nil headers:nil :^(id err, id json) {
        if (!err) [self.cache setObject:json forKey:[json objectForKey:@"_id"]];
        callback(err, json);
    }];
}
- (RKRequest*)getBulk:(NSArray*)ids :(RKCallback)callback {
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             ids, @"keys",
                             @"true", @"include_docs", nil];
    return [self query:@"POST" path:@"/_all_docs" options:options data:nil headers:nil :callback];
}

- (RKRequest*)_put:(NSString*)_id document:(id)document :(RKCallback)callback {
    return [self query:@"PUT" path:[RelaxKit escape:_id] options:nil data:document headers:nil :^(id err, id json) {
        if(!err) {
            NSMutableDictionary* saved = [NSMutableDictionary dictionaryWithDictionary:document];
            [saved setObject:[json objectForKey:@"id"] forKey:@"_id"];
            [saved setObject:[json objectForKey:@"rev"] forKey:@"_rev"];
            [self.cache setObject:saved forKey:_id];
        }
        callback(err, json);
    }];
}
- (RKRequest*)_post:(id)document :(RKCallback)callback {
    return [self query:@"POST" path:@"/" options:nil data:document headers:nil :^(id err, id json) {
        if(!err) {
            NSMutableDictionary* saved = [NSMutableDictionary dictionaryWithDictionary:document];
            [saved setObject:[json objectForKey:@"id"] forKey:@"_id"];
            [saved setObject:[json objectForKey:@"rev"] forKey:@"_rev"];
            [self.cache setObject:saved forKey:[json objectForKey:@"id"]];
        }
        callback(err, json);
    }];
}
- (RKRequest*)_head:(NSString*)_id :(RKCallback)callback {
    return [self query:@"HEAD" path:[RelaxKit escape:_id] :callback];
}

- (int)respCode:(id)json {
    return [[[json objectForKey:@"headers"] objectForKey:@"status-code"] intValue];
}
- (int)respCodeH:(id)json {
    return [[json objectForKey:@"status-code"] intValue];
}

- (RKRequest*)save:(NSString*)_id rev:(NSString*)rev doc:(id)doc :(RKCallback)callback {
    NSMutableDictionary* document = [NSMutableDictionary dictionary];
    
    // PUT a single document
    if (_id) {
        if (_id.length > 10 && [[_id substringToIndex:10] isEqualToString:@"_design/"]) {
            // Design document
            [document setObject:@"javascript" forKey:@"language"];
            [document setObject:doc forKey:@"views"];
        } else {
            document = doc;
        }
        
        if(rev) {
            [document setObject:rev forKey:@"_rev"];
        }
        
        if ([document objectForKey:@"_rev"]) {
            return [self _put:_id document:document :callback];
        } else if([self.cache objectForKey:_id]) {
            [document setObject:[[self.cache objectForKey:_id] objectForKey:@"_rev"] forKey:@"_rev"];
            return [self _put:_id document:document :callback];
        } else {
            // Attempt to create a new document. If it fails,
            // because an existing document with that _id exists (409),
            // perform a HEAD, to get the _rev and try to re-save
            [self _put:_id document:document :^(id err, id json) {
                if (err && [err objectForKey:@"headers"] && [self respCode:err] == 409) {
                    [self _head:_id :^(id err, id headers) {
                        if ([self respCodeH:headers] == 404 || ![headers objectForKey:@"etag"]) {
                            callback([NSDictionary dictionaryWithObject:@"not_found" forKey:@"reason"], nil);
                            return;
                        }
                        
                        NSString* etag = [headers objectForKey:@"etag"];
                        etag = [etag substringWithRange:NSMakeRange(1, [etag length]-2)];
                        [document setObject:etag forKey:@"_rev"];
                        [self _put:_id document:document :callback];
                    }];
                } else {
                    callback(nil, json);
                }
            }];
            return nil;
        }
    } else {
        return [self _post:doc :callback];
    }
}
- (RKRequest*)save:(id)doc :(RKCallback)callback {
    return [self save:nil rev:nil doc:doc :callback];
}
- (RKRequest*)save:(NSString*)_id doc:(id)doc :(RKCallback)callback {
    return [self save:_id rev:nil doc:doc :callback];
}
- (RKRequest*)saveBulk:(id)docs :(RKCallback)callback {
    NSDictionary* options = self.connection.options;
    NSMutableDictionary* document = [NSMutableDictionary dictionaryWithObject:docs forKey:@"docs"];
    if ([options objectForKey:@"allOrNothing"]) {
        [document setObject:[NSNumber numberWithBool:YES] forKey:@"all_or_nothing"];
    }
    return [self query:@"POST" path:@"/_bulk_docs" options:nil data:document headers:nil :callback];
}
- (RKRequest*)replicateTo:(NSString*)target options:(id)options :(RKCallback)callback {
    NSMutableDictionary* opts = [NSMutableDictionary dictionaryWithDictionary:options];
    [opts setObject:self.name forKey:@"source"];
    [opts setObject:target forKey:@"target"];
    return [self.connection replicate:opts :callback];
}
- (RKRequest*)replicateTo:(NSString*)target :(RKCallback)callback {
    return [self replicateTo:target options:nil :callback];
}
- (RKRequest*)destroy:(RKCallback)callback {
    return [self query:@"DELETE" path:@"/" :callback];
}

// Delete a document.
// If the rev wasn't supplied, we attempt to retrieve it from the
// cache. If the deletion was successful, we purge the cache.
- (RKRequest*)remove:(NSString*)_id :(RKCallback)callback {
    NSString* rev = [[self.cache objectForKey:_id] objectForKey:@"_rev"];
    if(!rev) {
        callback([NSDictionary dictionaryWithObject:@"rev needs to be supplied" forKey:@"reason"], nil);
        return nil;
    }
    return [self remove:_id rev:rev :callback];
}
- (RKRequest*)remove:(NSString *)_id rev:(NSString*)rev :(RKCallback)callback {
    NSDictionary* opts = [NSDictionary dictionaryWithObject:rev forKey:@"_rev"];
    return [self query:@"DELETE" path:[RelaxKit escape:_id] options:opts data:nil headers:nil :callback];
}
- (RKRequest*)create:(RKCallback)callback {
    return [self query:@"PUT" path:@"/" :callback];
}
- (RKRequest*)info:(RKCallback)callback {
    return [self query:@"GET" path:@"/" :callback];
}
- (RKRequest*)allWithOptions:(id)options :(RKCallback)callback {
    return [self query:@"GET" path:@"/_all_docs" options:options data:nil headers:nil :callback];
}
- (RKRequest*)all:(RKCallback)callback {
    return [self allWithOptions:nil :callback];
}
- (RKRequest*)compact:(RKCallback)callback {
    NSDictionary* headers = [NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    return [self query:@"POST" path:@"/_compact" options:nil data:[NSDictionary dictionary] headers:headers :callback];
}
- (RKRequest*)compactDesign:(NSString*)design :(RKCallback)callback {
    NSDictionary* headers = [NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    NSString* path = [NSString stringWithFormat:@"/_compact/%@",[RelaxKit escape:design]];
    return [self query:@"POST" path:path options:nil data:[NSDictionary dictionary] headers:headers :callback];
}
- (RKRequest*)viewCleanup:(RKCallback)callback {
    NSDictionary* headers = [NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    return [self query:@"POST" path:@"/_view_cleanup" options:nil data:[NSDictionary dictionary] headers:headers :callback];
}
- (RKRequest*)allBySeqWithOptions:(id)options :(RKCallback)callback {
    return [self query:@"GET" path:@"/_all_docs_by_seq" options:options data:nil headers:nil :callback];
}
- (RKRequest*)allBySeq:(RKCallback)callback {
    return [self allBySeqWithOptions:nil :callback];
}
- (RKRequest*)_design:(NSString*)path options:(id)options type:(NSString*)type :(RKCallback)callback {
    NSArray* pathParts = [path componentsSeparatedByString:@"/"];
    NSString* realPath = [NSString stringWithFormat:@"_design/%@/_@%/%@",
                          [RelaxKit escape:[pathParts objectAtIndex:0]],
                          type,
                          [RelaxKit escape:[pathParts objectAtIndex:1]]];
    NSMutableDictionary* realOptions = [NSMutableDictionary dictionaryWithDictionary:options];
    if(options) {
        for (NSString* key in [NSArray arrayWithObjects:@"key", @"startkey", @"endkey", nil]) {
            if ([options objectForKey:key]) {
                [realOptions setObject:[[options objectForKey:key] JSONString] forKey:key];
            }
        }
    }
    
    if (options && [options objectForKey:@"keys"]) {
        return [self query:@"POST" path:realPath options:realOptions data:nil headers:nil :callback];
    } else {
        return [self query:@"GET" path:realPath options:realOptions data:nil headers:nil :callback];
    }
}
- (RKRequest*)view:(NSString*)path options:(id)options :(RKCallback)callback {
    return [self _design:path options:options type:@"view" :callback];
}
- (RKRequest*)view:(NSString*)path :(RKCallback)callback {
    return [self view:path options:nil :callback];
}


- (RKRequest*)_design:(NSString*)path keys:(NSArray*)keys reduce:(BOOL)reduce type:(NSString*)type :(RKCallback)callback {
    NSMutableArray* realKeys = [NSMutableArray arrayWithCapacity:[keys count]];
    for (id key in keys) {
        if([key isKindOfClass:[NSString class]]) {
            [realKeys addObject:key];
        } else {
            [realKeys addObject:[key JSONString]];
        }
    }
    NSDictionary* opts = [NSDictionary dictionaryWithObjectsAndKeys:
                          realKeys,@"keys",
                          [NSNumber numberWithBool:reduce], @"reduce",
                          nil];
    return [self view:path options:opts :callback];
}
- (RKRequest*)_design:(NSString*)path key:(id)key reduce:(BOOL)reduce type:(NSString*)type :(RKCallback)callback {
    NSString* realKey;
    if([key isKindOfClass:[NSString class]])
        realKey = key;
    else
        realKey = [key JSONString];
    
    NSDictionary* opts = [NSDictionary dictionaryWithObjectsAndKeys:
                          realKey,@"key",
                          [NSNumber numberWithBool:reduce], @"reduce",
                          nil];
    return [self view:path options:opts :callback];
}
- (RKRequest*)_design:(NSString*)path startKey:(id)startKey endKey:(id)endKey reduce:(BOOL)reduce type:(NSString*)type :(RKCallback)callback {
    NSString* realStartKey, *realEndKey;
    if([startKey isKindOfClass:[NSString class]])
        realStartKey = startKey;
    else
        realStartKey = [startKey JSONString];
    
    if([endKey isKindOfClass:[NSString class]])
        realEndKey = endKey;
    else
        realEndKey = [endKey JSONString];
    
    NSDictionary* opts = [NSDictionary dictionaryWithObjectsAndKeys:
                          realStartKey,@"startkey",
                          realEndKey,@"endkey",
                          [NSNumber numberWithBool:reduce], @"reduce",
                          nil];
    return [self view:path options:opts :callback];
}

- (RKRequest*)view:(NSString*)path keys:(NSArray*)keys reduce:(BOOL)reduce :(RKCallback)callback {
    return [self _design:path keys:keys reduce:reduce type:@"view" :callback];
}

- (RKRequest*)view:(NSString*)path key:(id)key reduce:(BOOL)reduce :(RKCallback)callback {
    return [self _design:path key:key reduce:reduce type:@"view" :callback];
}
- (RKRequest*)view:(NSString*)path startKey:(id)startKey endKey:(id)endKey reduce:(BOOL)reduce :(RKCallback)callback {
    return [self _design:path startKey:startKey endKey:endKey reduce:reduce type:@"view" :callback];
}

- (RKRequest*)list:(NSString*)path options:(id)options :(RKCallback)callback {
    return [self _design:path options:options type:@"list" :callback];
}
- (RKRequest*)list:(NSString*)path :(RKCallback)callback {
    return [self _design:path options:nil type:@"list" :callback];
}
- (RKRequest*)list:(NSString*)path keys:(NSArray*)keys reduce:(BOOL)reduce :(RKCallback)callback {
    return [self _design:path keys:keys reduce:reduce type:@"list" :callback];
}
- (RKRequest*)list:(NSString*)path key:(id)key reduce:(BOOL)reduce :(RKCallback)callback {
    return [self _design:path key:key reduce:reduce type:@"list" :callback];
}
- (RKRequest*)list:(NSString*)path startKey:(id)startKey endKey:(id)endKey reduce:(BOOL)reduce :(RKCallback)callback {
    return [self _design:path startKey:startKey endKey:endKey reduce:reduce type:@"list" :callback];
}
- (RKRequest*)update:(NSString*)path ID:(NSString*)_id options:(id)options :(RKCallback)callback {
    NSMutableArray* pathParts = [NSMutableArray array];
    for (NSString* part in [path componentsSeparatedByString:@"/"]) {
        [pathParts addObject:[RelaxKit escape:part]];
    }
    
    NSString* realPath;
    
    if(_id) {
        realPath = [NSString stringWithFormat:@"_design/%@/_update/%@/%@",
                          [pathParts objectAtIndex:0],
                          [pathParts objectAtIndex:1],
                          _id];
        return [self query:@"PUT" path:realPath options:options data:nil headers:nil :callback];
    } else {
        realPath = [NSString stringWithFormat:@"_design/%@/_update/%@",
                [pathParts objectAtIndex:0],
                [pathParts objectAtIndex:1]];
        return [self query:@"POST" path:realPath options:options data:nil headers:nil :callback];
    }
}
- (RKRequest*)update:(NSString*)path :(RKCallback)callback {
    return [self update:path ID:nil options:nil :callback];
}
- (RKRequest*)changes:(RKCallback)callback {
    return nil;
}
- (RKRequest*)changes:(id)options :(RKCallback)callback {
    return nil;
}

- (RKRequest*)temporaryView:(id)doc :(RKCallback)callback {
    return [self query:@"PORT" path:@"_temp_view" options:nil data:doc headers:nil :callback];
}


@end
