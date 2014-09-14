//
//  Await.swift
//  Await
//
//  Created by Yasuhiro Inami on 2014/06/30.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import Foundation

struct Await
{
    static func awaitForClosure<T>(
        closure: () -> T?,
        until: () -> Bool = { true },
        queue: dispatch_queue_t? = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        timeout: NSTimeInterval = 0.0
        ) -> T?
    {
        if dispatch_queue_get_label(queue) == dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) {
            return closure()
        }
        
        var result: T?
        var finished = false
        
        dispatch_async(queue) {
            result = closure()
            finished = true
        }
        
        let firstUntil = until()
        let startDate = NSDate()
        
        while (!finished || !until()) &&
            (timeout <= 0.0 || NSDate().timeIntervalSinceDate(startDate) < timeout)
        {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1 , Boolean(0))
        }
        
        //
        // Closure may not contain result right after our first dispatch_async
        // (for example, when closure is wrapping other asyncs e.g. promise, which is still executing),
        // so retrieve the result once more.
        //
        if !firstUntil && result == nil {
            result = closure()
        }
        
        return result
    }
    
    static func awaitForFinishableClosure<T>(
        finishableClosure: (finish: T? -> Void) -> Void,
        queue: dispatch_queue_t? = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        timeout: NSTimeInterval = 0.0
        ) -> T?
    {
        var result: T?
        
        if dispatch_queue_get_label(queue) == dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) {
            finishableClosure({ delayedResult in
                result = delayedResult
            })
            return result
        }
        
        var finished = false
        
        dispatch_async(queue) {
            finishableClosure { delayedResult in
                result = delayedResult
                finished = true
            }
        }
        
        let startDate = NSDate()
        
        while (!finished) &&
            (timeout <= 0.0 || NSDate().timeIntervalSinceDate(startDate) < timeout)
        {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1 , Boolean(0))
        }
        
        return result
    }
    
    static func awaitForFinishableClosure(
        finishableClosure: (finish: () -> Void) -> Void,
        queue: dispatch_queue_t? = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        timeout: NSTimeInterval = 0.0
        )
    {
        self.awaitForFinishableClosure({ (finish: ()? -> Void) in
            finishableClosure { finish(nil) }
        }, queue: queue, timeout: timeout)
    }
    
    // for application use
    static func asyncClosure(closure: () -> Void)
    {
        CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopCommonModes, closure)
    }
}

/// await + until (as closure)
public func await<T>(
    until: () -> Bool = { true },
    queue: dispatch_queue_t? = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    timeout: NSTimeInterval = 0,
    closure: () -> T?
    ) -> T?
{
    return Await.awaitForClosure(closure, until: until, queue: queue, timeout: timeout)
}

/// await + until (as Bool)
public func await<T>(
    #until: @autoclosure () -> Bool,
    queue: dispatch_queue_t? = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    timeout: NSTimeInterval = 0,
    closure: () -> T?
    ) -> T?
{
    return await(until: until as () -> Bool, queue: queue, timeout: timeout, closure)
}

/// await + finishableClosure (call finish(someObj) manually)
public func await<T>(
    queue: dispatch_queue_t? = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    timeout: NSTimeInterval = 0,
    finishableClosure: (finish: T? -> Void) -> Void
    ) -> T?
{
    return Await.awaitForFinishableClosure(finishableClosure, queue: queue, timeout: timeout)
}

/// await + finishableClosure (call finish() manually)
public func await(
    queue: dispatch_queue_t? = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    timeout: NSTimeInterval = 0,
    finishableClosure: (finish: () -> Void) -> Void
    )
{
    Await.awaitForFinishableClosure(finishableClosure, queue: queue, timeout: timeout)
}

//
// NOTE:
// For applicaiton use, you MUST wrap `await` calls with `async`.
// This is to ensure that `await` will not block `dispatch_get_main_queue()`
// which often causes UIKit not responding to touches.
//
// LIMITATION:
// `await(_:timeout:)` may not work properly inside `async` due to nested RunLoop running.
//
public func async(closure: () -> Void)
{
    Await.asyncClosure(closure)
}