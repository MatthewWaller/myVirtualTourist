//
//  ViewController.swift
//  myVirtualTourist
//
//  Created by Matthew Waller on 3/14/16.
//  Copyright © 2016 Matthew Waller. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var map: MKMapView!
    var selectedPin: Pin?
    var selectedAnnotation: MKTouristAnnotation?
    
    var fetchRequest: NSFetchRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "makeNewPin:")
        
        longPressRecogniser.minimumPressDuration = 1.0
        map.addGestureRecognizer(longPressRecogniser)
        map.delegate = self
        
        fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            try fetchedPinResultsController.performFetch()
        } catch {}
        
        fetchedPinResultsController.delegate = self
        
        addSavedPins()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        getRegion()
    }
    
    func addSavedPins(){
        
        let pins = fetchedPinResultsController.fetchedObjects as! [Pin]
        
        var annotations = [MKTouristAnnotation]()
        
        for pin in pins {
            
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
            
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let annotation = MKTouristAnnotation(coordinate: coordinate)
            annotation.pin = pin
            
            
            annotations.append(annotation)
            
        }

            map.addAnnotations(annotations)
        
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedPinResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "longitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    



    func makeNewPin(getstureRecognizer : UIGestureRecognizer){
        
        //Code adapted from here: http://stackoverflow.com/questions/3959994/how-to-add-a-push-pin-to-a-mkmapviewios-when-touching
        
        if getstureRecognizer.state != .Began { return }
        
        let touchPoint = getstureRecognizer.locationInView(map)
        let touchMapCoordinate = map.convertPoint(touchPoint, toCoordinateFromView: map)
        
        let annotation = MKTouristAnnotation(coordinate: touchMapCoordinate)
        
        FlickrClient.sharedInstance().getImagesForAnnotation(annotation)
        
        map.addAnnotation(annotation)
        
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        let customAnnotation = annotation as! MKTouristAnnotation
        
        customAnnotation.title = "See images from here!"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: customAnnotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.pinTintColor = UIColor.blueColor()
            pinView!.draggable = true
            pinView!.canShowCallout = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) { // found with help from here: http://stackoverflow.com/questions/29776853/ios-swift-mapkit-making-an-annotation-draggable-by-the-user
        
        switch (newState) {
            
        case .Ending, .Canceling:
            
            let theAnnotation = view.annotation as? MKTouristAnnotation

            //Get rid of the old annotation pin and pictures here
            
            let photos = theAnnotation?.pin?.pictures
            
            for photo in photos! {
                
                photo.deleteImage()
                sharedContext.deleteObject(photo)
                
            }
            
            sharedContext.deleteObject((theAnnotation?.pin)!)
                
            theAnnotation?.pin = nil
                
            //Then get new pics!
        
            FlickrClient.sharedInstance().getImagesForAnnotation(theAnnotation!)
            
        default: break
        }
    }
    
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let touristPin = view.annotation as! MKTouristAnnotation
        selectedAnnotation = touristPin
        selectedPin = touristPin.pin!
        
        performSegueWithIdentifier("showAlbum", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let albumController = segue.destinationViewController as! PhotoAlbumViewController
        
        albumController.selectedPin = selectedAnnotation
        
        
        
    }
    
    lazy var fetchedRegionResultsController: NSFetchedResultsController = {
    
        let fetchRequest = NSFetchRequest(entityName: "Region")
    
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
    
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
    
        return fetchedResultsController
            
        }()
    
    //MARK: Saving region for user here
    //With help from forums https://discussions.udacity.com/t/my-maps-span-isnt-being-persisted-correctly/27895/12
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        saveRegion()
        
    }
    
    func getRegion(){
    
    
            do {
                try fetchedRegionResultsController.performFetch()
            } catch {
            
            }
    
    
            let regionResults = fetchedRegionResultsController.fetchedObjects as? [Region]
    
            if (regionResults?.isEmpty == false) { //Region exists
    
                let region = regionResults![0]
    
                let span = MKCoordinateSpan(latitudeDelta: region.latitudeDelta, longitudeDelta: region.longitudeDelta)
    
                let coordinate = CLLocationCoordinate2D(latitude: region.latitude, longitude: region.longitude)
    
                let theRegion = MKCoordinateRegion(center: coordinate, span: span)
    
                map.region = theRegion
                map.setCenterCoordinate(
                    theRegion.center,
                    animated: true
                )
    
            } else  { //region doesn't exist yet
                
                let theLat = map.region.center.latitude as Double
                let theLong = map.region.center.longitude as Double
                let theLatDelta = map.region.span.latitudeDelta as Double
                let theLongDelta = map.region.span.longitudeDelta as Double
    
                _ = Region(lat: theLat, long: theLong, latDelta: theLatDelta, longDelta: theLongDelta, context: sharedContext)
    
                CoreDataStackManager.sharedInstance().saveContext()
                
                do {
                    try fetchedRegionResultsController.performFetch()
                } catch {
                    
                }
            }
        }
    
        func saveRegion(){
    
            let regionResults = fetchedRegionResultsController.fetchedObjects as! [Region]
    
            let region = regionResults[0]
    
            region.latitude = map.region.center.latitude as Double
            
            region.longitude = map.region.center.longitude as Double
            
            region.latitudeDelta = map.region.span.latitudeDelta as Double
            
            region.longitudeDelta = map.region.span.longitudeDelta as Double
            
            CoreDataStackManager.sharedInstance().saveContext()
            
        }
}
