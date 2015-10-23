//
//  DataDownloader.swift
//  CoreDataThreading
//
//  Created by Andrea Bizzotto on 19/10/2015.
//  Copyright © 2015 musevisions. All rights reserved.
//

import CoreData

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

    private let writeCount = 50000
    let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack) {
     
        self.coreDataStack = coreDataStack
    }

    // MARK: Public methods
    func write(completion: (error: NSError?) -> ()) {
        
        print("Write...")

        let moc = getMOC()
        moc.performBlock() {

            print("Write (block)...")

            let elapsed = NSDate.measureTime() {
                
                self.insert(self.writeCount, moc: moc)

                self.coreDataStack.saveContext(moc) { error in
                    completeOnMainQueue(error, completion: completion)
                    return
                }
            }
            
            print("Inserted \(self.writeCount) items in \(elapsed.format()) sec")
        }
    }
    
    func deleteAll(completion: (error: NSError?) -> ()) {
    
        let batchDelete = coreDataStack.storeType == NSSQLiteStoreType
        if (batchDelete) {
            deleteAllBatch(completion)
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

    
    private func deleteAllBatch(completion: (error: NSError?) -> ()) {
        
        let moc = getMOC()
        moc.performBlock() {
            
            let fetchRequest = NSFetchRequest(entityName: "Note")
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                let elapsed = try NSDate.measureTime() {
                
                    try moc.executeRequest(deleteRequest)
                    self.coreDataStack.saveContext(moc) { error in
                        completeOnMainQueue(error, completion: completion)
                        return
                    }
                }
                print("Deleted all records in \(elapsed.format()) sec")
            }
            catch {
                let nserror = error as NSError
                completeOnMainQueue(nserror, completion: completion)
                return
            }
        }
    }
    
    private func deleteAllLoop(completion: (error: NSError?) -> ()) {
        
        print("Delete all...")

        let moc = getMOC()
        moc.performBlock() {

            print("Delete all (block)...")
            let fetchRequest = NSFetchRequest(entityName: "Note")

            do {
                let elapsed = try NSDate.measureTime() {

                    let notes = try moc.executeFetchRequest(fetchRequest) as! [Note]

                    for note in notes {
                        moc.deleteObject(note)
                    }
                    
                    self.coreDataStack.saveContext(moc) { error in
                        completeOnMainQueue(error, completion: completion)
                        return
                    }
                }
                
                print("Deleted all items in \(elapsed.format()) sec.")
            }
            catch {
                let nserror = error as NSError
                completeOnMainQueue(nserror, completion: completion)
                return
            }
        }
    }
}
