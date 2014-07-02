//
//  AwaitDemoTests.swift
//  AwaitDemoTests
//
//  Created by Yasuhiro Inami on 2014/06/30.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import XCTest
import PromiseKit

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
    
    func testAwaitWithUntil()
    {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        var shouldStop = false
        
        self.response = await({
            dispatch_async(queue) {
                sleep(1)
                shouldStop = true
            }
            return NSData() // dummy
        }, until: { shouldStop })
        
        XCTAssertNotNil(self.response, "Should await for data.")
    }

    func testAwaitWithTimeout()
    {
        let timeout = 1.0
        
        self.response = await({
            sleep(CUnsignedInt(timeout)+1)  // sleep well to demonstrate timeout error
            return NSData() // dummy
        }, timeout: timeout)
        
        XCTAssertNil(self.response, "Should time out and return nil.")
        
        self.response = await({
            // no sleep
            return NSURLConnection.sendSynchronousRequest(self.request, returningResponse: nil, error: nil)
        }, timeout: timeout)
        
        XCTAssertNotNil(self.response, "Should GET html data within \(timeout) seconds.")
    }
    
    func testAwaitWithPromiseKit()
    {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
//        let queue = dispatch_get_main_queue()
        
        let promise = Promise<NSData> { [weak self] (fulfiller, rejecter) in
            dispatch_async(queue) {
                let data = NSURLConnection.sendSynchronousRequest(self!.request, returningResponse:nil, error: nil)
                fulfiller(data)
            }
        }.then(onQueue: queue) { (data: NSData) -> NSData in
            return data
        }
        
//        self.response = await({ promise.value }, until: { !promise.pending })
        self.response = await(promise)
        
        XCTAssertNotNil(self.response, "Should GET html data.")
    }
    
    func testAwaitWithNSOperation()
    {
        let operation = NSBlockOperation(block: { sleep(1); return })
        operation.completionBlock = { println("operation finished.") }
        
        self.response = await({
            operation.start()
            return NSData() // dummy
        }, until: {
            return operation.finished == true
        })
        
        XCTAssertNotNil(self.response, "Should await for data.")
    }
    
    func testAwaitWithNSOperationQueue()
    {
        let operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        for i in 0..3 {
            let operation = NSBlockOperation(block: { sleep(1); return })
            operation.completionBlock = { println("operation[\(i)] finished.") }
            operationQueue.addOperation(operation)
        }
        
        self.response = await({
            return NSData() // dummy
        }, until: {
            return operationQueue.operationCount == 0
        })
        
        XCTAssertNotNil(self.response, "Should await for data.")
    }
    
    func testAwaitFinishable()
    {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        self.response = await { finish in
            dispatch_async(queue) {
                sleep(1)
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
                sleep(1)
                self.response = NSData()  // dummy
                finish()
            }
        }
        
        XCTAssertNotNil(self.response, "Should await for data.")
    }
}
