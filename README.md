## What is it?

RelaxKit is a library for connecting to CouchDB databases in
Objective-C. It uses AFNetworking for nice asynchronous requests and
uses JSONKit for really fast coding/decoding of JSON.

It follows the philosophy of Node.JS-style asynchronous libraries, with
each function taking a callback at the end. The callback argument is
un-named ( @selector(:) ) for brevity. The API is heavily based on https://github.com/cloudhead/cradle.

It also includes a small Objective-C version of EventEmitter. I know
that Foundation has similar functionality all over it, but this one
leads to much more consise code.

## How to use

First clone the repo.

        git clone git://github.com/sipefree/RelaxKit.git
        cd RelaxKit
        git submodule init
        git submodule update

Then open the Xcode project and compile the .a by building the RelaxKit
project. Some work needs to be done on this.

If you want to run the tests, run the RKTest target.

Copy the .a and the header files to your own project.

## API Examples

### Create a connection

```objc
NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"http://127.0.0.1", @"host",
                           [NSNumber numberWithInt:5984], @"port",
                           [NSNumber numberWithBool:YES], @"cache",
                        nil];
RKConnection* connection = [[RKConnection alloc] initWithOptions:options];
```

### Use a database

```objc
RKDatabase* myDB = [[connection database:@"my_db"] retain];
```

### Get server info

```objc
[connection info: ^(id err, id json) {
    if(err) {
        // handle the error
    } else {
        NSLog(@"json NSDictionary object: %@", json);
    }
}];
```

err and json are of type id because they might be a JKArray or a
JKDictionary.

### Get UUIDs

```objc
[connection uuids:20 :^(id err, id json) {
    if(err) {
        // handle error
    } else {
        for(NSString* uuid in [json objectForKey:@"uuids"]) {
            NSLog(@"Have a UUID: %@", uuid);
        }
    }
}];
```

### Check if a database exists and create it

```objc
[myDB exists:^(id err, id exists) {
    if([exists boolValue])
        NSlog(@"myDB exists!");
    else
        NSLog(@"better create it!");
        [myDB create:^(id err, id res) {
            if(err)
                NSLog(@"well that didn't work");
            else
                NSLog(@"hurray!");
        }];
}];
```

### Save a document

```objc
NSDictionary* bobDoc = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithBool:YES], @"ears",
                        nil];
[myDB save:@"bob" doc:bobDoc :^(id err, id json) {
    // do stuff
}];
```

### Get a document

```objc
[myDB get:@"jonny" :^(id err, id json) {
    NSLog(@"%@", [json valueForKey:@"_rev"]);
}];
```

### Misc

All methods in the API return an RKRequest (subclass of RKEventEmitter) object.

You can use that to hook lower-level events:

```objc
RKRequest* req = [myDB get:@"bob" :^(id err, id json) {
    NSLog(@"whatever");
}];
[req on:@"response" :^(id response) {
    // do something with the NSHTTPURLResponse
}];
```


## What's not working?

### Probably a lot of things!

I haven't finished writing all the tests, and it's guaranteed that many
of the methods simply don't work at all.

Views have certainly not been tested.

Attachments are not currently supported at all.

_changes feed is not supported.
