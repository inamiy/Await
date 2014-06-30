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
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow:0.01))
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
}

func await<T>(
    closure: () -> T?,
    until: () -> Bool = { true },
    queue: dispatch_queue_t? = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    timeout: NSTimeInterval = 0
    ) -> T?
{
    return Await.awaitForClosure(closure, until: until, queue: queue, timeout: timeout)
}