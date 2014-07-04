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
    
    struct DebugOptions
    {
        // To test how RunLoop works with/without queueing.
        // NOTE: Many UI e.g. button-highlighting won't update when set to `false`.
        static let shouldStartAwaitAfterDelay = false
        
        //
        // NOTE:
        // Setting `true` requires `shouldStartAwaitAfterDelay=true` as well for better UI response, 
        // since viewDidAppear is called via _dispatch_main_queue_callback_4CF.
        //
        static let shouldStartAwaitOnViewDidAppear = false
    }
    
    override func viewDidLoad()
    {
        NSLog("viewDidLoad")
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        NSLog("viewWillAppear")
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool)
    {
        NSLog("viewDidAppear")
        super.viewDidAppear(animated)
        
        if DebugOptions.shouldStartAwaitOnViewDidAppear {
            self.startAwait()
        }
    }
    
    @IBAction func startAwait()
    {
        if DebugOptions.shouldStartAwaitAfterDelay {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1_000_000_000), dispatch_get_main_queue()) {
                self._startAwait()
            }
        }
        else {
            self._startAwait()
        }
    }
    
    func _startAwait()
    {
        SVProgressHUD.showWithStatus("loading...")
        
        NSLog("await start")
        
        let data = self._performAwait()
//        let data = self._performAwaitWithTimeout()
//        let data = self._performAwaitWithPromiseKit()
        
        NSLog("await end")
        
        if let data_ = data {
            let html = NSString(data: data, encoding: NSUTF8StringEncoding)
//            println(html)
            
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
        return await { sleep(3); return NSData() /* dummy */ }
//        return await { NSURLConnection.sendSynchronousRequest(self.request, returningResponse:nil, error: nil) }
    }
    
    func _performAwaitWithTimeout() -> NSData?
    {
        let timeout = 1.0
        
        return await({
            sleep(CUnsignedInt(timeout)+1)  // sleep well to demonstrate timeout error
            return NSData() // dummy
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

