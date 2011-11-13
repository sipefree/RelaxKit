//
//  RKEventEmitter.m
//  RelaxKit
//
//  Created by Simon Free on 12/11/2011.
//  Copyright (c) 2011 N/A. All rights reserved.
//

#import "RKEventEmitter.h"

@implementation RKEventEmitter
- (id)init {
    self = [super init];
    if(self) {
        onEvents = [[NSMutableDictionary alloc] init];
        onceEvents = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addListenerForEvent:(NSString*)event withCallback:(void (^)(id arg))block {
    [self on:event :block];
}
- (void)addOneTimeListenerForEvent:(NSString*)event withCallback:(void (^)(id arg1))block {
    [self once:event :block];
}
- (void)on:(NSString*)event :(void (^)(id arg1))block {
    NSMutableArray* arr = [onEvents objectForKey:event];
    if (!arr) {
        arr = [NSMutableArray arrayWithCapacity:10];
        [onEvents setObject:arr forKey:event];
    }
    if (![arr containsObject:block]) {
        [arr addObject:Block_copy(block)];
    }
}
- (void)once:(NSString*)event :(void (^)(id arg1))block {
    NSMutableArray* arr = [onceEvents objectForKey:event];
    if (!arr) {
        arr = [NSMutableArray arrayWithCapacity:10];
        [onceEvents setObject:arr forKey:event];
    }
    if (![arr containsObject:block]) {
        [arr addObject:block];
    }
}
- (void)removeCallback:(void (^)(id arg1))block forEvent:(NSString*)event {
    NSMutableArray* onArr = [onEvents objectForKey:event];
    NSMutableArray* onceArr = [onceEvents objectForKey:event];
    
    if(onArr && [onArr containsObject:block]) {
        [onArr removeObject:block];
        Block_release(block);
    }
    if(onceArr && [onceArr containsObject:block]) {
        [onceArr removeObject:block];
        Block_release(block);
    }
}
- (void)removeAllListenersForEvent:(NSString*)event {
    for (RKEventEmitterEvent block in [onEvents objectForKey:event]) {
        [self removeCallback:block forEvent:event];
    }
    for (RKEventEmitterEvent block in [onceEvents objectForKey:event]) {
        [self removeCallback:block forEvent:event];
    }
    [onEvents removeObjectForKey:event];
    [onceEvents removeObjectForKey:event];
}
- (NSArray*)listenersForEvent:(NSString*)event {
    NSMutableArray* onArr = [onEvents objectForKey:event];
    NSMutableArray* onceArr = [onceEvents objectForKey:event];
    NSMutableArray* listeners = [NSMutableArray arrayWithCapacity:[onArr count]+[onceArr count]];
    [listeners addObjectsFromArray:onArr];
    [listeners addObjectsFromArray:onceArr];
    
    return listeners;
}
- (void)emit:(NSString*)event :(id)arg {
    NSMutableArray* onArr = [onEvents objectForKey:event];
    NSMutableArray* onceArr = [onceEvents objectForKey:event];
    for (RKEventEmitterEvent block in onArr) {
        block(arg);
    }
    for (RKEventEmitterEvent block in onceArr) {
        block(arg);
        [self removeCallback:block forEvent:event];
    }
}

- (void)dealloc {
    for (NSString* event in [onEvents allKeys]) {
        [self removeAllListenersForEvent:event];
    }
    for (NSString* event in [onceEvents allKeys]) {
        [self removeAllListenersForEvent:event];
    }
    [onEvents release];
    [onceEvents release];
    [super dealloc];
}
@end
