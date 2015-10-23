//
//  ViewController.swift
//  CoreDataThreading
//
//  Created by Andrea Bizzotto on 19/10/2015.
//  Copyright © 2015 musevisions. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    var fetchedResultsController: NSFetchedResultsController!
    
    lazy var coreDataStack: CoreDataStack = {
        return CoreDataStack(storeType: NSSQLiteStoreType, modelName: "MVCoreDataStack")
    }()
    
    lazy var dataWriter: DataWriter = {
        return DataWriter(coreDataStack: self.coreDataStack)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setup()
        fetch()
    }
    
    @IBAction func refresh() {
        dataWriter.write() { error in
            self.fetch()
        }
    }
    
    @IBAction func clear() {
        dataWriter.deleteAll() { error in
            self.fetch()
        }
    }

    func setup() {
        let fetchRequest = NSFetchRequest(entityName: "Note")
        
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "uid", ascending: true)]
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.mainManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        //self.fetchedResultsController.delegate = self
    }
    
    func fetch() {
        
        do {
            try fetchedResultsController.performFetch()
        }
        catch {
            let nserror = error as NSError
            print("Unable to perform fetch: \(nserror)")
        }
        
        self.tableView.reloadData()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?.first?.numberOfObjects ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!

        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        
        if let note = fetchedResultsController.objectAtIndexPath(indexPath) as? Note {
            
            if let uid = note.uid,
                let title = note.title {
                    
                    cell.textLabel?.text = "\(uid) - \(title)"
            }
        }
    }
}


extension ViewController: NSFetchedResultsControllerDelegate {
 
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        guard let indexPath = indexPath else {
            return;
        }
        switch (type) {
        case .Insert:
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            break

        case .Delete:
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            break
        
        case .Update:
            if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
                self.configureCell(cell, indexPath: indexPath)
            }
            break
            
        case .Move:
            if let newIndexPath = newIndexPath {
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                self.tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
            }
            break
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo,  atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {

        print("NSFetchedResultsController controllerWillChangeContent")
//        self.tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
  
        print("NSFetchedResultsController controllerDidChangeContent")
//        self.tableView.endUpdates()
    }
}
