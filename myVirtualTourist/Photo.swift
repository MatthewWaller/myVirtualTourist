//
//  Photo.swift
//  myVirtualTourist
//
//  Created by Matthew Waller on 3/15/16.
//  Copyright © 2016 Matthew Waller. All rights reserved.
//

import Foundation
import CoreData

class Photo: NSManagedObject {
    
    @NSManaged var imagePath: String?
    @NSManaged var location: Pin?
    @NSManaged var downloaded: NSNumber?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(path: String, context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        imagePath = path
        
    }
    
    func deleteImage(){
        
        let documentsDirectory = FlickrClient.sharedInstance().databaseURL()
        
        let fileURL = documentsDirectory?.URLByAppendingPathComponent(imagePath!)
        
        do {
            try NSFileManager.defaultManager().removeItemAtURL(fileURL!)
        } catch {
            
        }
    }
    
}