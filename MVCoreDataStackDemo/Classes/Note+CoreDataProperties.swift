//
//  Note+CoreDataProperties.swift
//  MVCoreDataStack
//
//  Created by Andrea Bizzotto on 19/10/2015.
//  Copyright © 2015 musevisions. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Note {

    @NSManaged var uid: NSNumber?
    @NSManaged var title: String?

}
