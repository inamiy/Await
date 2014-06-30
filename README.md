Await
=====

Swift port of C# Await using Cocoa's Run Loop mechanism.


### Without `Await`

```
showProgressHUD("Start!")     // displays AFTER download finished (you know why)
let image = downloadLargeImageFromWeb()  // OMG downloading from main-thread!!!
showProgressHUD("Finished!")  // displays after download finished
```

```
showProgressHUD("Start!")  // main-thread

// OK let's use dispatch_async then...
dispatch_async(globalQueue) {
    image = downloadLargeImageFromWeb()  // background-thread
    
    dispatch_async(dispatch_get_main_queue()) {
        showProgressHUD("Finished!")  // main-thread
        
        // want more nested blocks here?
    }
}
```


### With `Await`

```
showProgressHUD("Start!")

let image = await { downloadLargeImageFromWeb() }

// because of await's running Run Loop, "Start!" will be displayed immediately here

showProgressHUD("Finished!")  // displays after download finished
```


How to use
----------

### await

```
let image = await { downloadLargeImageFromWeb() }
```

`await` calls dispatch_async for given closure & runs Run Loop until finished.

### await + until

```
var shouldStop = false
var container: SomeContainer

let result = await({
    container.data = nil
    
    dispatch_async(globalQueue) {
        container.data = downloadData()
        shouldStop = true
    }
    
    return container.data
}, until: { shouldStop })
```

Use `until: () -> Bool` to manually adjust the Run Loop running time.
This is especially useful in combination with async-programming monads like [Promise](http://promises-aplus.github.io/promises-spec/).

Take a look at [PromiseKit](https://github.com/mxcl/PromiseKit) example:

```
import PromiseKit
var promise = Promise<NSData> { (fulfiller, rejecter) in ... }
...

let result = await({ promise.value }, until: { !promise.pending })
// or, let result = await(promise)
```

### await + timeout

```
await({ downloadLargeImageFromWeb() }, timeout: 3)  // returns nil if 3 sec has passed
```
