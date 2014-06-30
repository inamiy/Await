//
//  Await+PromiseKit.swift
//  Await
//
//  Created by Yasuhiro Inami on 2014/06/30.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import Foundation
import PromiseKit

extension Await
{
    static func awaitForPromise<T>(
        promise: Promise<T>,
        queue: dispatch_queue_t? = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        timeout: NSTimeInterval = 0.0
        ) -> T?
    {
        return self.awaitForClosure({ promise.value }, until: { !promise.pending }, queue: queue, timeout: timeout)
    }
}

func await<T>(
    promise: Promise<T>,
    queue: dispatch_queue_t? = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    timeout: NSTimeInterval = 0
    ) -> T?
{
    return Await.awaitForPromise(promise, queue: queue, timeout: timeout)
}