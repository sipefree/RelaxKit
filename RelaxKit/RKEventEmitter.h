//
//  RKEventEmitter.h
//  RelaxKit
//
//  Created by Simon Free on 12/11/2011.
//  Copyright (c) 2011 N/A. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RKEventEmitterEvent)(id arg);

@interface RKEventEmitter : NSObject {
    NSMutableDictionary* onEvents;
    NSMutableDictionary* onceEvents;
}
- (void)addListenerForEvent:(NSString*)event withCallback:(void (^)(id arg))block;
- (void)addOneTimeListenerForEvent:(NSString*)event withCallback:(void (^)(id arg1))block;
- (void)on:(NSString*)event :(void (^)(id arg1))block;
- (void)once:(NSString*)event :(void (^)(id arg1))block;
- (void)removeCallback:(void (^)(id arg1))block forEvent:(NSString*)event;
- (void)removeAllListenersForEvent:(NSString*)event;
- (NSArray*)listenersForEvent:(NSString*)event;
- (void)emit:(NSString*)event :(id)arg;
@end
