//
//  Pin.swift
//  myVirtualTourist
//
//  Created by Matthew Waller on 3/14/16.
//  Copyright © 2016 Matthew Waller. All rights reserved.
//

import Foundation
import CoreData

class Pin: NSManagedObject {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var region: Region
    @NSManaged var pictures: [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(lat: Double, long: Double, context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        latitude = lat
        longitude = long
    }
    
}
