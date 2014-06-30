//
//  ViewController.swift
//  AwaitDemo
//
//  Created by Yasuhiro Inami on 2014/06/30.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import UIKit
import PromiseKit

class ViewController: UITableViewController {
    
    let request = NSURLRequest(URL: NSURL(string:"https://github.com"))
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1_000_000_000), dispatch_get_main_queue()) {
            self._startTest()
        }
    }
    
    func _startTest()
    {
        SVProgressHUD.showWithStatus("loading...")
        
        NSLog("await start")
        
//        let data = self._performAwait()
//        let data = self._performAwaitWithTimeout()
        let data = self._performAwaitWithPromiseKit()
        
        NSLog("await end")
        
        if let data_ = data {
            let html = NSString(data: data, encoding: NSUTF8StringEncoding)
            println(html)
            
            SVProgressHUD.showSuccessWithStatus("Success!")
        }
        else {
            let message = "Failed: either execution failed or timed out"
            println(message)
            
            SVProgressHUD.showErrorWithStatus(message)
        }
    }
    
    func _performAwait() -> NSData?
    {
        return await { NSURLConnection.sendSynchronousRequest(self.request, returningResponse:nil, error: nil) }
    }
    
    func _performAwaitWithTimeout() -> NSData?
    {
        let timeout = 1.0
        
        return await({
            sleep(CUnsignedInt(timeout)+1)  // sleep well to demonstrate timeout error
            return NSData()
        }, timeout: timeout)
    }
    
    func _performAwaitWithPromiseKit() -> NSData?
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
        
//        return await({ promise.value }, until: { !promise.pending } )
        return await(promise)
    }
    
    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!)
    {
        let vc = self.storyboard!.instantiateViewControllerWithIdentifier("ViewController") as? UIViewController
        self.navigationController.pushViewController(vc, animated: true)
    }
}

