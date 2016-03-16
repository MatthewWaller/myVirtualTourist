//
//  MKTouristAnnotation.swift
//  myVirtualTourist
//
//  Created by Matthew Waller on 3/15/16.
//  Copyright © 2016 Matthew Waller. All rights reserved.
//

import Foundation
import MapKit

class MKTouristAnnotation : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var pin: Pin?
    var title: String?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        
    }
}