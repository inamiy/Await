//
//  AwaitDemoTests.swift
//  AwaitDemoTests
//
//  Created by Yasuhiro Inami on 2014/06/30.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import XCTest
//import PromiseKit

class AwaitDemoTests: XCTestCase {
    
    let request = NSURLRequest(URL: NSURL(string:"https://github.com"))
    var response: NSData?
    
    override func setUp()
    {
        super.setUp()
        println("\n\n\n\n\n")
    }
    
    override func tearDown()
    {
        println("\n\n\n\n\n")
        super.tearDown()
    }
    
    func testAwait()
    {
        self.response = await { NSURLConnection.sendSynchronousRequest(self.request, returningResponse:nil, error: nil) }
        
        XCTAssertNotNil(self.response, "Should GET html data.")
    }
    
    func testAwaitTuple()
    {
        let result: (value: Int?, error: NSError?)? = await {
            usleep(100_000);
            return (nil, NSError(domain: "AwaitDemoTest", code: -1, userInfo: nil))
        }
        
        XCTAssertNil(result!.value, "Should not return value.")
        XCTAssertNotNil(result!.error, "Should return error.")
    }
    
    func testAwaitWithUntil()
    {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        var shouldStop = false
        
        self.response = await(until: shouldStop) {
            dispatch_async(queue) {
                usleep(100_000)
                shouldStop = true
            }
            return NSData() // dummy
        }
        
        XCTAssertNotNil(self.response, "Should await for data.")
    }

    func testAwaitWithTimeout()
    {
        let timeout = 0.2   // 200ms
        
        self.response = await(timeout: timeout) {
            usleep(300_000) // 300ms, sleep well to demonstrate timeout error
            return NSData() // dummy
        }
        
        XCTAssertNil(self.response, "Should time out and return nil.")
        
        self.response = await(timeout: timeout) {
            usleep(100_000) // 100ms
            return NSData()
        }
        
        XCTAssertNotNil(self.response, "Should GET html data within \(timeout) seconds.")
    }
    
//    func testAwaitWithPromiseKit()
//    {
//        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
////        let queue = dispatch_get_main_queue()
//        
//        let promise = Promise<NSData> { [weak self] (fulfiller, rejecter) in
//            dispatch_async(queue) {
//                let data = NSURLConnection.sendSynchronousRequest(self!.request, returningResponse:nil, error: nil)
//                fulfiller(data)
//            }
//        }.then(onQueue: queue) { (data: NSData) -> NSData in
//            return data
//        }
//        
////        self.response = await({ promise.value }, until: { !promise.pending })
//        self.response = await(promise)
//        
//        XCTAssertNotNil(self.response, "Should GET html data.")
//    }
    
    func testAwaitWithNSOperation()
    {
        let operation = NSBlockOperation(block: { usleep(100_000); return })
        operation.completionBlock = { println("operation finished.") }
        
        self.response = await(until: operation.finished) {
            operation.start()
            return NSData() // dummy
        }
        
        XCTAssertNotNil(self.response, "Should await for data.")
    }
    
    func testAwaitWithNSOperationQueue()
    {
        let operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        for i in 0 ..< 3 {
            let operation = NSBlockOperation(block: { usleep(100_000); return })
            operation.completionBlock = { println("operation[\(i)] finished.") }
            operationQueue.addOperation(operation)
        }
        
        self.response = await(until: operationQueue.operationCount == 0) {
            return NSData() // dummy
        }
        
        XCTAssertNotNil(self.response, "Should await for data.")
    }
    
    func testAwaitFinishable()
    {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        self.response = await { finish in
            dispatch_async(queue) {
                usleep(100_000)
                finish(NSData())  // dummy
            }
        }
        
        XCTAssertNotNil(self.response, "Should await for data.")
    }
    
    func testAwaitFinishableNoReturn()
    {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        await { finish in
            dispatch_async(queue) {
                usleep(100_000)
                self.response = NSData()  // dummy
                finish()
            }
        }
        
        XCTAssertNotNil(self.response, "Should await for data.")
    }
}
