//
//  NSDate+TimeMeasuring.swift
//  CoreDataThreading
//
//  Created by Andrea Bizzotto on 23/10/2015.
//  Copyright © 2015 musevisions. All rights reserved.
//

import Foundation

extension NSDate {

    class func measureTime(task: () throws -> ()) throws -> NSTimeInterval {
        
        let start = NSDate()
        
        try task()
        
        return NSDate().timeIntervalSinceDate(start)
    }
    
    class func measureTime(task: () -> ()) -> NSTimeInterval {
        
        let start = NSDate()
        
        task()
        
        return NSDate().timeIntervalSinceDate(start)
    }
}
