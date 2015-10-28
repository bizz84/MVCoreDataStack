//
//  DataDownloader.swift
//  MVCoreDataStack
//
//  Created by Andrea Bizzotto on 19/10/2015.
//  Copyright © 2015 musevisions. All rights reserved.
//

import CoreData
import MVCoreDataStack

extension Double {
    func format() -> String {
        return NSString(format: "%.4f", self) as String
    }
}


func completeOnMainQueue(error: NSError?, completion: (error: NSError?) -> ()) {
    
    dispatch_async(dispatch_get_main_queue()) {
        completion(error: error)
    }
}


class DataWriter: NSObject {

    let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack) {
     
        self.coreDataStack = coreDataStack
    }

    // MARK: Public methods
    func write(writeCount: Int, completion: (error: NSError?) -> ()) {
        
        let moc = getMOC()
        moc.performBlock() {

            let start = NSDate()
            
            self.insert(writeCount, moc: moc)

            self.coreDataStack.saveContext(moc) { error in
                
                print("Inserted \(writeCount) items in \(NSDate().timeIntervalSinceDate(start).format()) sec")

                completeOnMainQueue(error, completion: completion)
            }
        }
    }
    
    func deleteAll(completion: (error: NSError?) -> ()) {
    
        if #available(iOS 9.0, *) {
            let batchDelete = coreDataStack.storeType == NSSQLiteStoreType
            if (batchDelete) {
                deleteAllBatch(completion)
            }
            else {
                deleteAllLoop(completion)
            }
        }
        else {
            deleteAllLoop(completion)
        }
    }
    
    // MARK: Private methods
    private func getMOC() -> NSManagedObjectContext {
        //return coreDataStack.newManagedObjectContext(.PrivateQueueConcurrencyType)
        return coreDataStack.privateManagedObjectContext
    }

    private func insert(count: Int, moc: NSManagedObjectContext) {
        
        for i in 0..<count {
            
            let note = NSEntityDescription.insertNewObjectForEntityForName("Note", inManagedObjectContext: moc) as! Note
            
            note.uid = i
            note.title = "Lorem ipsum dolor sit amet..."
        }
    }

    
    @available(iOS 9.0, *)
    private func deleteAllBatch(completion: (error: NSError?) -> ()) {
        
        let moc = getMOC()
        moc.performBlock() {
            
            let fetchRequest = NSFetchRequest(entityName: "Note")
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                let start = NSDate()
                
                try moc.executeRequest(deleteRequest)
                self.coreDataStack.saveContext(moc) { error in
                    
                    print("Deleted all records in \(NSDate().timeIntervalSinceDate(start).format()) sec")

                    completeOnMainQueue(error, completion: completion)
                }
            }
            catch {
                completeOnMainQueue(error as NSError, completion: completion)
            }
        }
    }
    
    private func deleteAllLoop(completion: (error: NSError?) -> ()) {
        
        let moc = getMOC()
        moc.performBlock() {

            let fetchRequest = NSFetchRequest(entityName: "Note")

            do {
                let start = NSDate()

                let notes = try moc.executeFetchRequest(fetchRequest) as! [Note]

                for note in notes {
                    moc.deleteObject(note)
                }
                
                self.coreDataStack.saveContext(moc) { error in

                    print("Deleted all records in \(NSDate().timeIntervalSinceDate(start).format()) sec")

                    completeOnMainQueue(error, completion: completion)
                }
            }
            catch {
                let nserror = error as NSError
                completeOnMainQueue(nserror, completion: completion)
                return
            }
        }
    }
}
