//
//  RKTests.m
//  RelaxKit
//
//  Created by Simon Free on 12/11/2011.
//  Copyright (c) 2011 N/A. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h> 
#import "RelaxKit.h"

#define kWait [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0]
#define kSuccess [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd]
#define kFailure [self notify:kGHUnitWaitStatusFailure forSelector:_cmd]

@interface RKTests : GHAsyncTestCase {
    RKConnection* connection;
    RKDatabase* testDatabase;
}
@end

@implementation RKTests

- (BOOL)shouldRunOnMainThread {
    // By default NO, but if you have a UI test or test dependent on running on the main thread return YES.
    // Also an async test that calls back on the main thread, you'll probably want to return YES.
    return YES;
}

- (void)setUpClass {
    // Run at start of all tests in the class
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"http://127.0.0.1", @"host",
                             [NSNumber numberWithInt:5984], @"port",
                             [NSNumber numberWithBool:YES], @"cache", nil];
    connection = [[RKConnection alloc] initWithOptions:options];
    testDatabase = [[connection database:@"rk_test"] retain];
    
    

}

- (void)tearDownClass {
    // Run at end of all tests in the class
    [connection release];
    [testDatabase release];
}

- (void)setUp {
    // Run before each test method
}

- (void)tearDown {
    // Run after each test method
}  
- (void)test00ServerInfo
{
    [self prepare];
    
    [connection info:^(id err, id json) {
        if (err) {
            GHTestLog(@"info error: %@", err);
            kFailure;
        }
        GHTestLog(@"info: %@", json);
        if (![json objectForKey:@"couchdb"]) {
            GHTestLog(@"This doesn't appear to be a CouchDB instance.");
            kFailure;
        } else {
            kSuccess;
        }
    }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}
- (void)test01ServerConfig
{
    [self prepare];
    
    [connection config:^(id err, id json) {
        if (err) {
            GHTestLog(@"config error: %@", err);
            kFailure;
        }
        GHTestLog(@"config: %@", json);
        kSuccess;
    }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}
- (void)test02ServerStats
{
    [self prepare];
    
    [connection stats:^(id err, id json) {
        if (err) {
            GHTestLog(@"stats error: %@", err);
            kFailure;
        }
        GHTestLog(@"stats: %@", json);
        kSuccess;
    }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}
- (void)test03ServerActiveTasks
{
    [self prepare];
    
    [connection activeTasks:^(id err, id json) {
        if (err) {
            GHTestLog(@"activeTasks error: %@", err);
            kFailure;
        }
        GHTestLog(@"activeTasks: %@", json);
        kSuccess;
    }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}
- (void)test04ServerUUIDs
{
    [self prepare];
    
    [connection uuids:0 :^(id err, id json) {
        if(err) {
            GHTestLog(@"uuids error: %@", err);
            kFailure;
        }
        GHTestLog(@"uuids 0: %@", json);
        kSuccess;
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
     
    [self prepare];
    
    [connection uuids:1 :^(id err, id json) {
        if(err) {
            GHTestLog(@"uuids error: %@", err);
            kFailure;
        }
        GHTestLog(@"uuids 1: %@", json);
        kSuccess;
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
    
    [self prepare];
      
    [connection uuids:10 :^(id err, id json) {
         if(err) {
             GHTestLog(@"uuids error: %@", err);
             kFailure;
         }
         GHTestLog(@"uuids 10: %@", json);
         kSuccess;
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}

- (void)test05DatabaseExistsNo {
    [self prepare];
    [testDatabase exists:^(id err, id exists) {
        if([exists boolValue] == YES) {
            GHTestLog(@"database already exists!");
            kFailure;
        } else {
            GHTestLog(@"   -> %@", exists);
            kSuccess;
        }
        
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}

- (void)test06DatabaseCreate {
    [self prepare];
    [testDatabase create:^(id err, id res) {
        if(err) {
            GHTestLog(@"create database error: %@", err);
            kFailure;
        }
        GHTestLog(@"   -> %@", res);
        kSuccess;
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}
- (void)test07DatabaseExistsYes {
    [self prepare];
    [testDatabase exists:^(id err, id exists) {
        if([exists boolValue] == NO) {
            GHTestLog(@"database doesn't exist!");
            kFailure;
        } else {
            GHTestLog(@"   -> %@", exists);
            kSuccess;
        }
        
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}

- (void)test08DocSave {
    NSDictionary* bobDoc = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES], @"ears",
                            nil];
    
    [self prepare];
    GHTestLog(@"save()");
    [testDatabase save:@"bob" doc:bobDoc :^(id err, id json) {
        GHTestLog(@"  -> %@", json);
        kSuccess;
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}
- (void)test09DocIsInCache {
    GHAssertTrue(([testDatabase.cache objectForKey:@"bob"] != nil), @"should write through the cache");
}
-(void)test10DocUpdate {
    NSDictionary* bobDoc = [NSDictionary dictionaryWithObjectsAndKeys:
              [NSNumber numberWithInt:12], @"size",
              nil];
    
    [self prepare];
    GHTestLog(@"save()");
    [testDatabase save:@"bob" doc:bobDoc :^(id err, id json) {
        
    }];
    kWait;
}

- (void)testZDatabaseDestroy {
    [self prepare];
    [testDatabase destroy:^(id err, id res) {
        if(err) {
            GHTestLog(@"destroy database error: %@", err);
            kFailure;
        }
        GHTestLog(@"   -> %@", res);
        kSuccess;
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}
@end
