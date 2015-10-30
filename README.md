#Core Data Parent-Child Stack for iOS 8 and 9

This sample project shows how to set up a CoreData stack to use two managed object contexts (MOCs) in a parent-child configuration. This is a setup that can be used to perform long-running CoreData operations on a background queue, while reading the data on the main queue and keeping the UI responsive. 

## Overview

A simple producer-consumer demo application is included:

* Consumer: [```ViewController```](https://github.com/bizz84/MVCoreDataStack/blob/master/MVCoreDataStackDemo/Classes/ViewController.swift) class showing a table view linked to the main MOC via ```NSFetchedResultsController```
* Producer: [```DataWriter```](https://github.com/bizz84/MVCoreDataStack/blob/master/MVCoreDataStackDemo/Classes/DataWriter.swift) class used to write and delete records with a private MOC.

Access to the main and private MOCs happens via the [```CoreDataStack```](https://github.com/bizz84/MVCoreDataStack/blob/master/MVCoreDataStack/CoreDataStack.swift) class, which can be configured to use either an in memory or a SQLite backing store.

The core data stack is built so that the main MOC runs on the main queue and writes directly to the persistence store coordinator.
The private MOC runs on a private queue and has the main MOC as its parent, so that when changes are saved to the private MOC, the main MOC is automatically updated.

By performing write/delete/save operations on the private MOC, we get optimal performance and keep the UI responsive as most of the CoreData work is performed on the private queue.

When the SQLite store is used, saves to the private MOC are also performed on the main MOC to ensure that the changes are persisted. This is not necessary when using an in memory store.

*For more information about different CoreData concurrency patterns and when they should be used, [read this](
http://developmentnow.com/2015/04/28/experimenting-with-the-parent-child-concurrency-pattern-to-optimize-coredata-apps/) or check the [References section](#references) below.*

## Installation

To integrate MVCoreDataStack in your own project, you can include it in your podfile:

```
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '8.0'
use_frameworks!

pod 'MVCoreDataStack'
```

Alternatively, simply drag-and-drop the [```CoreDataStack.swift```](https://github.com/bizz84/MVCoreDataStack/blob/master/MVCoreDataStack/CoreDataStack.swift) file in Xcode and use it directly.

## Usage

The ```CoreDataStack``` class must be used in conjunction with the ```performBlock``` and ```performBlockAndWait``` methods when performing CoreData operations in the private MOC.

The code snipped below illustrates how to delete all objects for a given entity by using the new NSBatchDeleteRequest API introduced in iOS 9. See the [Performance section](#performance) below for when NSBatchDeleteRequest can be used.

```swift
// Initialisation
let coreDataStack = return CoreDataStack(storeType: NSSQLiteStoreType, modelName: "MyXcdataModel")

@available(iOS 9.0, *)
func deleteAllItems(coreDataStack: CoreDataStack, completion: (error: NSError?) -> ()) {
	let privateMOC = coreDataStack.privateManagedObjectContext
	privateMOC.performBlock() {
		let fetchRequest = NSFetchRequest(entityName: "Item")
		let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
		                
		do {
			try moc.executeRequest(deleteRequest)
			// Note the saveContext method is asynchronous as it runs on the main queue
			// to push the changes to the persistent store when we use SQLite
			coreDataStack.saveContext(moc) { error in
				completeOnMainQueue(error, completion: completion)
			}
		}
		catch {
			completeOnMainQueue(error as NSError, completion: completion)
		}
	}
}

func completeOnMainQueue(error: NSError?, completion: (error: NSError?) -> ()) {
    dispatch_async(dispatch_get_main_queue()) {
        completion(error: error)
    }
}
```

For more example code on how to write CoreData operations using ```CoreDataStack```, see the [```DataWriter```](https://github.com/bizz84/MVCoreDataStack/blob/master/MVCoreDataStackDemo/Classes/DataWriter.swift) file.

<a name="performance"></a>
## Performance

#### Test Setup

We have run some write and delete tests to benchmark the performance of CoreData in various configurations. 

* All tests are based on a CoreData model with one single entity with two attributes:

 Attribute | Type
 --------- | ------
 uid       | Int32
 title     | String

* We use the newly introduced NSBatchDeleteRequest on iOS 9 when the core data stack is configured to use SQLite, and fallback to the old fetch + delete loop with in-memory stores or when running iOS 8. The table below summarises this configuration:

            | SQLite               | In Memory
----------- | -------------------- | --------------------
iOS 9.1     | NSBatchDeleteRequest | Fetch + Delete Loop
iOS 8.4.1   | Fetch + Delete Loop  | Fetch + Delete Loop

The two tables below illustrate the timings we have observed when inserting or deleting different numbers of records. Performance has been measured by taking the average of 5 samples for each measurement.

#### Results 

**SQLite Performance**

Device                   | Write 500 | Delete 500 | Write 5000 | Delete 5000  | Write 50000 | Delete 50000 
------------------------ | --------- | ---------- | ---------- | ------------ | ----------- | ------------ 
iPhone 6 (iOS 9.1)       | 0.057 sec | 0.017 sec  | 0.350 sec  | 0.009 sec    | 3.086 sec   | 0.034 sec
iPod Touch 5 (iOS 8.4.1) | 0.151 sec | 0.224 sec  | 1.439 sec  | 2.080 sec    | 16.160 sec  | 25.816 sec


**In Memory Store Performance**

Device                   | Write 500 | Delete 500 | Write 5000 | Delete 5000  | Write 50000 | Delete 50000 
------------------------ | --------- | ---------- | ---------- | ------------ | ----------- | ------------ 
iPhone 6 (iOS 9.1)       | 0.019 sec | 0.040 sec  | 0.140 sec  | 0.392 sec    | 1.318 sec   | 3.585 sec
iPod Touch 5 (iOS 8.4.1) | 0.071 sec | 0.121 sec  | 0.691 sec  | 1.169 sec    | 6.808 sec   | 25.272 sec

#### Insights 

From the benchmarks above we can draw some important insights on performance:

* Write operatons are typically 2x to 3x faster when using an in-memory store compared to a SQLite store
* Delete operations using the NSBatchDeleteRequest are approximately **1000x faster** than the Fetch + Delete loop approach. 

To sum up, CoreData is very inefficient in deleting data when using in-memory stores, and very fast when deleting from SQLite stores with the new NSBatchDeleteRequest. Hopefully Apple will make NSBatchDeleteRequest available for in-memory stores as well.

As for the difference in benchmarks between different devices, the iPhone 6 is approximately 3x faster than the iPod Touch 5 on all tests, meaning that it's possible to estimate performance on a slow device from a baseline measured on a fast device.

<a name="references"></a>
## References

* [Apple Core Data Performance](https://developer.apple.com/library/prerelease/watchos/documentation/Cocoa/Conceptual/CoreData/Performance.html)
* [Apple Core Data Concurrency](https://developer.apple.com/library/prerelease/watchos/documentation/Cocoa/Conceptual/CoreData/Concurrency.html#//apple_ref/doc/uid/TP40001075-CH24-SW1)
* [Experimenting with the parent-child concurrency pattern to optimize CoreData apps](http://developmentnow.com/2015/04/28/experimenting-with-the-parent-child-concurrency-pattern-to-optimize-coredata-apps/)
* [Marcus Zarra: My Core Data Stack](http://martiancraft.com/blog/2015/03/core-data-stack/)
* [NSManagedObjectContext’s parentContext](http://benedictcohen.co.uk/blog/archives/308)
* [Getting Sexy with Core Data](http://blog.chadwilken.com/core-data-concurrency/)



