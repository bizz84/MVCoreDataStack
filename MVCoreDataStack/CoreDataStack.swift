//
//  CoreDataStack.swift
//  MVCoreDataStack
//
//  Created by Andrea Bizzotto on 19/10/2015.
//  Copyright © 2015 musevisions. All rights reserved.
//

import CoreData

public class CoreDataStack {

    // MARK: Public
    public let storeType: String
    public let modelName: String
    
    public init(storeType: String, modelName: String) {
        self.storeType = storeType
        self.modelName = modelName
    }
    
    // MARK: Managed object contexts
    lazy public var mainManagedObjectContext: NSManagedObjectContext = {
        
        var moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.persistentStoreCoordinator
        return moc
    }()
    
    lazy public var privateManagedObjectContext: NSManagedObjectContext = {
        
        var moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        // Must use mainManagedObjectContext as parentContext for performance reasons
        moc.parentContext = self.mainManagedObjectContext
        return moc
    }()
    
    public func newManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        
        let moc = NSManagedObjectContext(concurrencyType: concurrencyType)
        moc.parentContext = self.mainManagedObjectContext
        return moc
    }

    // MARK: - Core Data Saving support
    public func saveContext (managedObjectContext: NSManagedObjectContext,
        completion: (error: NSError?) -> () ) {
            
        if !managedObjectContext.hasChanges {
            completion(error: nil)
            return
        }
            
        do {
            try managedObjectContext.save()
        }
        catch(let error) {
            let nserror = error as NSError
            print("Unresolved error \(nserror), \(nserror.userInfo)")
            completion(error: nserror)
            return
        }
        
        // When using SQLite store and the managed object context's parent is the main MOC,
        // save the parent object context to persist to the persistence store coordinator
        var willSaveParent = false
        if self.storeType == NSSQLiteStoreType {
            if let parent = managedObjectContext.parentContext
                where parent == self.mainManagedObjectContext && parent.hasChanges {

                willSaveParent = true
                parent.performBlock() {
                    do {
                        try parent.save()
                    }
                    catch(let error) {
                        completion(error: error as NSError)
                        return
                    }
                    completion(error: nil)
                }
            }
        }
        if willSaveParent == false {
            completion(error: nil)
        }
    }

    // MARK: - Private Core Data Stack methods
    lazy private var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.musevisions.iOS.CoreDataThreading" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy private var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource(self.modelName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy private var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let sqliteFileLocation = "\(self.modelName).sqlite"
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(sqliteFileLocation)
        do {
            try coordinator.addPersistentStoreWithType(self.storeType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data."

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "com.musevisions.CoreDataStack", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
}
