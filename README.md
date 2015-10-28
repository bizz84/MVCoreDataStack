#Core Data Parent-Child Stack

This sample project illustrates how to set up a CoreData stack to use the parent-child model with two managed object contexts (MOCs) as described [here](
http://developmentnow.com/2015/04/28/experimenting-with-the-parent-child-concurrency-pattern-to-optimize-coredata-apps/).

A simple producer-consumer demo application is included:

* Consumer: [```ViewController```](https://github.com/bizz84/MVCoreDataStack/blob/master/MVCoreDataStackDemo/Classes/ViewController.swift) class showing a table view linked to the main MOC via ```NSFetchedResultsController```
* Producer: [```DataWriter```](https://github.com/bizz84/MVCoreDataStack/blob/master/MVCoreDataStackDemo/Classes/DataWriter.swift) class used to write and delete records with a private MOC.

Access to the main and private MOCs happens via the [```CoreDataStack```](https://github.com/bizz84/MVCoreDataStack/blob/master/MVCoreDataStack/CoreDataStack.swift) class, which can be configured to use either an in memory or a SQLite backing store.

The core data stack is built so that the main MOC runs on the main queue and writes directly to the persistence store coordinator.
The private MOC runs on a private queue and has the main MOC as its parent, so that when changes are saved to the private MOC, the main MOC is automatically updated.

This guarantees optimal performance and prevents the main thread from locking provided that write/delete/save operations are performed on the private MOC.

When the SQLite store is used, saves to the private MOC are always followed by corresponding saves in the main MOC to ensure that the changes are persisted.
This is not necessary when using an in memory store.

## Usage

The ```CoreDataStack``` class must be used in conjunction with the ```performBlock``` and ```performBlockAndWait``` when performing CoreData operations in the private MOC.

TODO: UPDATE

```swift
// Initialisation
let coreDataStack = return CoreDataStack(storeType: NSSQLiteStoreType, modelName: "MyXcdataModel")

func deleteAllItems(coreDataStack: CoreDataStack, completion: (error: NSError?) -> ()) {
	let privateMOC = coreDataStack.privateManagedObjectContext
	privateMOC.performBlock() {
		let fetchRequest = NSFetchRequest(entityName: "Item")
		let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
		                
		do {
			try moc.executeRequest(deleteRequest)
			try coreDataStack.saveContext(privateMOC)
		}
		catch {
			let nserror = error as NSError
			completeOnMainQueue(nserror, completion: completion)
			return
		}
		completeOnMainQueue(nil, completion: completion)
	}
}

func completeOnMainQueue(error: NSError?, completion: (error: NSError?) -> ()) {
    dispatch_async(dispatch_get_main_queue()) {
        completion(error: error)
    }
}

```

## Installation

You can use CocoaPods to import MVCoreDataStack in your podfile:

```
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '8.0'
inhibit_all_warnings!
use_frameworks!

pod 'MVCoreDataStack'
```
Alternatively, simply drag-and-drop the [```CoreDataStack.swift```](https://github.com/bizz84/MVCoreDataStack/blob/master/MVCoreDataStack/CoreDataStack.swift) file in your project file and use it directly.

## Performance

Performance has been measured by taking the average of 5 samples for each measurement. Delete commands on SQLite use the new NSBatchDeleteRequest class introduced in iOS 9, and the old fetch-loop-deleteObject method for in memory stores and iOS 8.

**SQLite Performance**

Device                   | Write 500 | Write 5000 | Write 50000 | Delete 50000
------------------------ | --------- | ---------- | ----------- | ----------
iPhone 6 (iOS 9.1)       | 0.066 sec | 0.289 sec  | 3.044 sec   | 0.037 sec
iPod Touch 5 (iOS 8.4.1) |

**In Memory Store Performance**

Device                   | Write 500 | Write 5000 | Write 50000 | Delete
------------------------ | --------- | ---------- | ----------- | ----------
iPhone 6 (iOS 9.1)       | 
iPod Touch 5 (iOS 8.4.1) |

## References

* [Apple Core Data Performance](https://developer.apple.com/library/prerelease/watchos/documentation/Cocoa/Conceptual/CoreData/Performance.html)
* [Apple Core Data Concurrency](https://developer.apple.com/library/prerelease/watchos/documentation/Cocoa/Conceptual/CoreData/Concurrency.html#//apple_ref/doc/uid/TP40001075-CH24-SW1)
* [Experimenting with the parent-child concurrency pattern to optimize CoreData apps](http://developmentnow.com/2015/04/28/experimenting-with-the-parent-child-concurrency-pattern-to-optimize-coredata-apps/)
* [NSManagedObjectContext’s parentContext](http://benedictcohen.co.uk/blog/archives/308)
* [Getting Sexy with Core Data](http://blog.chadwilken.com/core-data-concurrency/)



