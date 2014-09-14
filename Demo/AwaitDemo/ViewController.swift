//
//  ViewController.swift
//  AwaitDemo
//
//  Created by Yasuhiro Inami on 2014/06/30.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import UIKit
//import PromiseKit

class ViewController: UITableViewController
{
    struct DebugOptions
    {
        static let shouldStartAwaitOnViewDidAppear = true
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
        //
        // NOTE:
        // For applicaiton use, you MUST wrap `await` calls with `async`.
        // This is to ensure that `await` will not block `dispatch_get_main_queue()`
        // which often causes UIKit not responding to touches.
        //
        // LIMITATION:
        // `await(_:timeout:)` may not work properly inside `async` due to nested RunLoop running.
        //
        async {
            SVProgressHUD.showWithStatus("Loading...")
            
            NSLog("await start")
            
            let result = self._performAwait()
//            let result = self._performAwaitWithTimeout()
//            let result = self._performAwaitWithPromiseKit()
            
            NSLog("await end")
            
            if let result_ = result {
//                NSLog("result = \(result_)")
                SVProgressHUD.showSuccessWithStatus("Success!")
            }
            else {
                let message = "Failed: either execution failed or timed out"
                NSLog(message)
                
                SVProgressHUD.showErrorWithStatus(message)
            }
        }
    }
    
    func _performAwait() -> Any?
    {
        return await { sleep(3) }
    }
    
    func _performAwaitWithTimeout() -> Any?
    {
        return await({ sleep(2) }, timeout: 1)
    }
    
//    func _performAwaitWithPromiseKit() -> Any?
//    {
//        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
////        let queue = dispatch_get_main_queue()
//        
//        let promise = Promise<NSData> { (fulfiller, rejecter) in
//            dispatch_async(queue) {
//                let request = NSURLRequest(URL: NSURL(string:"https://github.com"))
//                let data = NSURLConnection.sendSynchronousRequest(request, returningResponse:nil, error: nil)
//                fulfiller(data)
//            }
//        }.then(onQueue: queue) { (data: NSData) -> NSString in
//            return NSString(data: data, encoding: NSUTF8StringEncoding)
//        }
//        
////        return await({ promise.value }, until: { !promise.pending } )
//        return await(promise)
//    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let vc = self.storyboard!.instantiateViewControllerWithIdentifier("ViewController") as? UIViewController
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}

