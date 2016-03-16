//
//  Region.swift
//  myVirtualTourist
//
//  Created by Matthew Waller on 3/14/16.
//  Copyright © 2016 Matthew Waller. All rights reserved.
//

import Foundation
import CoreData

class Region: NSManagedObject {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var longitudeDelta: Double
    @NSManaged var latitudeDelta: Double
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(lat: Double, long: Double, latDelta: Double, longDelta: Double, context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Region", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        latitude = lat
        longitude = long
        longitudeDelta = longDelta
        latitudeDelta = latDelta
    }
}