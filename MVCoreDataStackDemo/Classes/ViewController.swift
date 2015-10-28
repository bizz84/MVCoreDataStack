//
//  ViewController.swift
//  MVCoreDataStack
//
//  Created by Andrea Bizzotto on 19/10/2015.
//  Copyright © 2015 musevisions. All rights reserved.
//

import UIKit
import CoreData
import MVCoreDataStack

class ViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    var fetchedResultsController: NSFetchedResultsController!
    
    lazy var coreDataStack: CoreDataStack = {
        return CoreDataStack(storeType: NSSQLiteStoreType, modelName: "MVCoreDataStack")
    }()
    
    lazy var dataWriter: DataWriter = {
        return DataWriter(coreDataStack: self.coreDataStack)
    }()
    
    var itemsToInsert: Int {
        
        switch segmentedControl.selectedSegmentIndex {
            case 0: return 500
            case 1: return 5000
            case 2: return 50000
            default: return 0
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    
        setup()
        fetch()
    }
    
    @IBAction func write() {
        dataWriter.write(self.itemsToInsert) { error in
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
