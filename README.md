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

        git clone git://github.com/sipefree/RelaxKit.git
        cd RelaxKit
        git submodule init
        git submodule update


