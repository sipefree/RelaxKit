//
//  RKConnection.m
//  RelaxKit
//
//  Created by Simon Free on 10/11/2011.
//  Copyright (c) 2011 N/A. All rights reserved.
//

#import "RKConnection.h"
#import "NSData+Base64.h"
#import "JSONKit.h"

@implementation RKRequest
@end

@implementation RKConnection
@synthesize options=_options;
@synthesize operationQueue=_operationQueue;
@synthesize streamEventMap=_streamEventMap;

- (id)initWithDefaults {
    return [self initWithOptions:[RelaxKit defaults].defaultOptions];
}
- (id)initWithOptions:(NSDictionary *)options {
    self = [super init];
    if (self) {
        _options = options;
        _operationQueue = [[NSOperationQueue alloc] init];
        _streamEventMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSString*)queryStringFromDict:(NSDictionary*)dict {
    NSMutableString* queryString = [NSMutableString string];
    for (NSString* key in [dict allKeys]) {
        NSString* value = [dict objectForKey:key];
        [queryString appendFormat:@"%@=%@&",key,[value stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    }
    return queryString;
}

- (NSMutableURLRequest*)_urlRequest:(NSString*)method path:(NSString*)path options:(NSDictionary*)options data:(NSData*)data headers:(NSDictionary*)headers {
    NSMutableDictionary* realHeaders = [NSMutableDictionary dictionaryWithDictionary:headers];
    
    if(!options) {
        options = [NSDictionary dictionary];
    }
    
    if ([self.options objectForKey:@"auth"]) {
        NSDictionary* auth = [self.options objectForKey:@"auth"];
        NSString* authString = [NSString stringWithFormat:@"%@:%@",
                                [auth objectForKey:@"username"],
                                [auth objectForKey:@"password"]];
        NSData* authData = [authString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString* authBase64 = [authData base64EncodedString];
        
        NSString* header = [NSString stringWithFormat:@"Basic %@",authBase64];
        
        [realHeaders setObject:header forKey:@"Authorization"];
    }
    
    NSDictionary* defaultHeaders = [self.options objectForKey:@"headers"];
    
    for (NSString* key in [defaultHeaders allKeys]) {
        [realHeaders setObject:[defaultHeaders objectForKey:key] forKey:key];
    }
    
    if(data) {
        //[realHeaders setObject:@"chunked" forKey:@"Transfer-Encoding"];
        [realHeaders setObject:[NSString stringWithFormat:@"%i",[data length]] forKey:@"Content-Length"];
    }
    
    if([path characterAtIndex:0] != '/') {
        path = [NSString stringWithFormat:@"/%@",path];
    }
    
    NSString* host = [self.options objectForKey:@"host"];
    int port = [[self.options objectForKey:@"port"] integerValue];
    
    path = [NSString stringWithFormat:@"%@?%@",path,[self queryStringFromDict:options]];
    
    NSString* urlString = [NSString stringWithFormat:@"%@:%i%@",host,port,path];
    
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setAllHTTPHeaderFields:realHeaders];
    [request setHTTPBody:data];
    [request setHTTPMethod:method];
    
    NSLog(@"%@ %@", method, urlString);
    NSLog(@"%@", realHeaders);
    NSLog(@"body: length=%i, %@", [data length], data);

    return request;
}


- (RKRequest*)rawRequest:(NSString*)method path:(NSString*)path options:(NSDictionary*)options data:(NSData*)data headers:(NSDictionary*)headers {
    RKRequest* emitter = [[RKRequest alloc] init];
    
    if (!headers) {
        headers = [NSDictionary dictionary];
    }
    
    NSMutableURLRequest* request = [self _urlRequest:method path:path options:options data:data headers:headers];
    
    __block AFHTTPRequestOperation* operation = [AFHTTPRequestOperation HTTPRequestOperationWithRequest:request
        success:^(id response) {
            [emitter emit:@"response" :operation.response];
            [emitter emit:@"data" :operation.responseData];
            [emitter emit:@"end" :nil];
            if(operation.error) {
                [emitter emit:@"error" :operation.error];
            }
            [operation release];
        }
        failure:^(NSHTTPURLResponse* response, NSError* error) {
            [emitter emit:@"response" :operation.response];
            [emitter emit:@"error" :operation.error];
            [operation release];
        }];
    [operation setAcceptableStatusCodes:nil];
    [operation retain];
    [self.operationQueue addOperation:operation];
    
    return emitter;
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    RKRequest* emitter = [self.streamEventMap objectForKey:aStream];
    if(!emitter) return;
    
    if(eventCode == NSStreamEventHasBytesAvailable) {
        
    }
}

- (RKRequest*)rawStreamingRequest:(NSString*)method path:(NSString*)path options:(NSDictionary*)options data:(NSData*)data headers:(NSDictionary*)headers {
    RKRequest* emitter = [[RKRequest alloc] init];
    
    if (!headers) {
        headers = [NSDictionary dictionary];
    }
    
    NSMutableURLRequest* request = [self _urlRequest:method
                                                path:path
                                             options:options
                                                data:nil
                                             headers:headers];
    
    AFHTTPRequestOperation* operation = [AFHTTPRequestOperation HTTPRequestOperationWithRequest:request
        success:^(id response) {
            [emitter emit:@"response" :response];
            if(operation.error) {
                [emitter emit:@"error" :operation.error];
            }
        }
        failure:^(NSHTTPURLResponse* response, NSError* error) {
            [emitter emit:@"response" :operation.response];
            [emitter emit:@"error" :operation.error];
        }];
    
    NSOutputStream* outputStream = [NSOutputStream outputStreamToMemory];
    [outputStream setDelegate:self];
    
    [self.operationQueue addOperation:operation];
    
    return emitter;
}

- (void)close {
    [self.operationQueue cancelAllOperations];
}

- (RKRequest*)request:(NSString*)method path:(NSString*)path options:(NSDictionary*)options data:(id)data headers:(NSDictionary*)headers :(RKCallback)callback {
    
    [callback retain];
    
    NSMutableDictionary* realHeaders = [NSMutableDictionary dictionaryWithDictionary:headers];
    
    if (data) {
        NSString* type = @"";
        if(![data isKindOfClass:[NSData class]]) {
            data = [data JSONData];
            type = @"application/json";
        } else {
            type = [data MIMEType];
        }
            
        
        NSString* length = [NSString stringWithFormat:@"%i",[data length]];
        [realHeaders setObject:length forKey:@"Content-Length"];
        [realHeaders setObject:type forKey:@"Content-Type"];
    } else {
        [realHeaders setObject:@"0" forKey:@"Content-Length"];
    }
    
    RKRequest* request = [self rawRequest:method path:path options:options data:data headers:realHeaders];
    __block NSMutableData* responseData;
    __block NSMutableDictionary* respHeaders;
    __block int statusCode;
    __block NSHTTPURLResponse* resp;
    [request on:@"response" :^(id response) {
        resp = response;
        respHeaders = [[NSMutableDictionary alloc] initWithDictionary:[resp allHeaderFields]];
        statusCode = [response statusCode];
        [respHeaders setObject:[NSNumber numberWithInt:statusCode] forKey:@"status-code"];
        int length = [[respHeaders objectForKey:@"Content-Length"] intValue];
        responseData = [[NSMutableData alloc] initWithCapacity:length];
    }];
    [request on:@"data" :^(id _data) {
        NSData* data = _data;
        [responseData appendData:data];
    }];
    [request on:@"end" :^ (id nul) {
        if ([method isEqualToString:@"HEAD"]) {
            callback(nil, respHeaders);
        } else {
            id json = [responseData mutableObjectFromJSONData];

            if([json respondsToSelector:@selector(objectForKey:)] && [json objectForKey:@"error"]) {
                [json setObject:respHeaders forKey:@"headers"];
                callback(json, nil);
            } else {
                callback(nil, json);
                
            }
        }
        [respHeaders autorelease];
        [responseData release];
        [callback release];
    }];
    
    return request;
}

- (RKRequest*)request:(NSString *)method path:(NSString *)path :(RKCallback)callback {
    return [self request:method path:path options:nil data:nil headers:nil :callback];
}

- (RKDatabase*)database:(NSString *)name {
    NSString* goodName = [name stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    return [RKDatabase databaseWithName:goodName connection:self cache:[[[NSCache alloc] init] autorelease]];
}

- (RKRequest*)databases:(RKCallback)callback {
    return [self request:@"GET" path:@"/_all_dbs" :callback];
}
- (RKRequest*)config:(RKCallback)callback {
    return [self request:@"GET" path:@"/_config" :callback];
}
- (RKRequest*)info:(RKCallback)callback {
    return [self request:@"GET" path:@"/" :callback];
}
- (RKRequest*)stats:(RKCallback)callback {
    return [self request:@"GET" path:@"/_stats" :callback];
}
- (RKRequest*)activeTasks:(RKCallback)callback {
    return [self request:@"GET" path:@"/_active_tasks" :callback];
}
- (RKRequest*)uuids:(int)count :(RKCallback)callback {
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSString stringWithFormat:@"%i",count],@"count",
                              nil];
    return [self request:@"GET" path:@"/_uuids" options:options data:nil headers:nil :callback];
}
- (RKRequest*)replicate:(id)options :(RKCallback)callback {
    return [self request:@"POST" path:@"/_replicate" options:nil data:options headers:nil :callback];
}


- (void)dealloc {
    [self.options release];
    [self.operationQueue release];
    [self.streamEventMap release];
    [super dealloc];
}
@end
