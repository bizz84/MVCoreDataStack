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

The ```CoreDataStack``` class must be used in conjunction with the ```performBlock``` and ```performBlockAndWait``` methods when performing CoreData operations in the private MOC.

The code snipped below illustrates how to delete all objects for a given entity:

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

### Test Setup

We have run some write and delete tests in various configurations. 

* All tests are based on a CoreData model with one single entity with two attributes:

 Key name | Type
 -------- | ------
 uid      | Int32
 title    | String

* We use the newly introduced NSBatchDeleteRequest on iOS 9 when the core data stack is configured to use SQLite, and fallback to the old fetch + delete loop with in-memory stores or when running iOS 8. The table below summarises this configuration:

            | SQLite               | In Memory
----------- | -------------------- | --------------------
iOS 9.1     | NSBatchDeleteRequest | Fetch + Delete Loop
iOS 8.4.1   | Fetch + Delete Loop  | Fetch + Delete Loop

The two tables below illustrate the timings we have observed when inserting or deleting different numbers of records. Performance has been measured by taking the average of 5 samples for each measurement.

### Results 

**SQLite Performance**

Device                   | Write 500 | Delete 500 | Write 5000 | Delete 5000  | Write 50000 | Delete 50000 
------------------------ | --------- | ---------- | ---------- | ------------ | ----------- | ------------ 
iPhone 6 (iOS 9.1)       | 0.057 sec | 0.017 sec  | 0.350 sec  | 0.009 sec    | 3.086 sec   | 0.034 sec


**In Memory Store Performance**

Device                   | Write 500 | Delete 500 | Write 5000 | Delete 5000  | Write 50000 | Delete 50000 
------------------------ | --------- | ---------- | ---------- | ------------ | ----------- | ------------ 
iPhone 6 (iOS 9.1)       | 0.019 sec | 0.040 sec  | 0.140 sec  | 0.392 sec    | 1.318 sec   | 3.585 sec
iPod Touch 5 (iOS 8.4.1) | 

### Insights 

From the comparisons between the iPhone 6 results we can observe that writes are approximately 3x faster when using an in-memory store compared to a SQLite store, but deletes are approximately **1000x slower**.

This shows that CoreData is very inefficient in deleting data when using in-memory stores, and very fast when deleting from SQLite stores with the new NSBatchDeleteRequest. Hopefully Apple will make NSBatchDeleteRequest available for in-memory stores as well.

## References

* [Apple Core Data Performance](https://developer.apple.com/library/prerelease/watchos/documentation/Cocoa/Conceptual/CoreData/Performance.html)
* [Apple Core Data Concurrency](https://developer.apple.com/library/prerelease/watchos/documentation/Cocoa/Conceptual/CoreData/Concurrency.html#//apple_ref/doc/uid/TP40001075-CH24-SW1)
* [Experimenting with the parent-child concurrency pattern to optimize CoreData apps](http://developmentnow.com/2015/04/28/experimenting-with-the-parent-child-concurrency-pattern-to-optimize-coredata-apps/)
* [NSManagedObjectContext’s parentContext](http://benedictcohen.co.uk/blog/archives/308)
* [Getting Sexy with Core Data](http://blog.chadwilken.com/core-data-concurrency/)



