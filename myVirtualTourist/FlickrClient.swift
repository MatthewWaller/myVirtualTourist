//
//  FlickrClient.swift
//  myVirtualTourist
//
//  Created by Matthew Waller on 3/14/16.
//  Copyright © 2016 Matthew Waller. All rights reserved.
//

import Foundation
import UIKit
import CoreData

// MARK: - Globals

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "664e62f887b3158078f89cc915b90078"
let EXTRAS = "url_m"
let PER_PAGE = "18"
let SAFE_SEARCH = "1"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"
let BOUNDING_BOX_HALF_WIDTH = 1.0
let BOUNDING_BOX_HALF_HEIGHT = 1.0
let LAT_MIN = -90.0
let LAT_MAX = 90.0
let LON_MIN = -180.0
let LON_MAX = 180.0


class FlickrClient : NSObject {
    
    func generalFlickrTask(methodArguments: [String : AnyObject], completionHandler: (result: AnyObject!, errorString: String?) -> Void) -> NSURLSessionDataTask {
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            guard (error == nil) else {
                
                completionHandler(result: nil, errorString: "There was an error with your request: \(error)")
                
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    completionHandler(result: nil, errorString: "Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    completionHandler(result: nil, errorString: "Your request returned an invalid response! Response: \(response)!")
                } else {
                    completionHandler(result: nil, errorString: "Your request returned an invalid response!")
                }
                return
            }
            
            guard let data = data else {
                completionHandler(result: nil, errorString: "No data was returned by the request!")
                return
            }
            
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                completionHandler(result: nil, errorString: "Could not parse the data as JSON: '\(data)'")
                return
            }
        
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                completionHandler(result: nil, errorString: "Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                completionHandler(result: nil, errorString: "Cannot find key 'photos' in \(parsedResult)")
                return
            }
            
            completionHandler(result: photosDictionary, errorString: nil)
            
        }
        
        task.resume()
        
        return task
    }
    
    func getImagesForAnnotation(annotation: MKTouristAnnotation){
        
        if annotation.pin == nil {
    
        let thePin = Pin(lat: annotation.coordinate.latitude, long: annotation.coordinate.longitude, context: sharedContext)
    
        annotation.pin = thePin
            
        getImagesForPin(thePin)
            
        } else {
            
            getImagesForPin(annotation.pin!)
            
        }
        
            }
    
    func getImagesForPin(thePin: Pin){
        
        let bbox = createBoundingBoxString(thePin.latitude, long: thePin.longitude)
        
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox": bbox,
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "per_page": PER_PAGE,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        getImageFromFlickrBySearch(methodArguments) { (result, errorString) -> Void in
            
            if errorString != nil {
                
                
            } else {
                
                self.persistImages(result as! [[String : AnyObject]], thePin: thePin) { (result, errorString) -> Void in
                    
                    if errorString != nil {
                        
                    } else {
                        
                        print("Success persisting!")
                        
                    }
                }
            }
            
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
        

        
    }
    
    func getImageFromFlickrBySearch(methodArguments: [String : AnyObject], completionHandler: (result: AnyObject!, errorString: String?)->Void) {
   
        generalFlickrTask(methodArguments) { (result, errorString) -> Void in
            
            guard let totalPages = result["pages"] as? Int else {
                completionHandler(result: nil, errorString: "Cannot find key 'pages' in \(result)")
                return
            }
            
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage, completionHandler: { (result, errorString) -> Void in
                if errorString != nil {
                    completionHandler(result: nil, errorString: errorString)
                } else {
                    completionHandler(result: result, errorString: nil)
                }
                
            
            })

        }
    
    }
    
    
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: (result: AnyObject!, errorString: String?)->Void) {
        
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        generalFlickrTask(withPageDictionary) { (result, errorString) -> Void in
            
            guard let totalPhotosVal = (result["total"] as? NSString)?.integerValue else {
                
                completionHandler(result: nil, errorString: "Cannot find key 'total' in \(result)")
                
                return
            }
            
            if totalPhotosVal > 0 {
                
                guard let photosArray = result["photo"] as? [[String: AnyObject]] else {
                    
                    completionHandler(result: nil, errorString: "Cannot find key 'photo' in \(result)")
                    
                    return
                }
                
                completionHandler(result: photosArray, errorString: nil)
   
                
            } else {
                
                completionHandler(result: nil, errorString: "No Photos Found. Search Again.")
                
            }
        }

    }
    
    func persistImages(photosArray: [[String: AnyObject]], thePin: Pin, completionHandler: (result: AnyObject!, errorString: String?)->Void) {
        
        var newArray = [[String: AnyObject]]()
        
        for photoDictionary in photosArray {
            
            guard let imageUrlString = photoDictionary["url_m"] as? String else {
                return
            }
            
            guard let imageID = photoDictionary["id"] as? String else {
                return
            }
            
            guard let imageOwner = photoDictionary["owner"] as? String else {
                return
            }
            
            let fileName = "\(imageID)\(imageOwner)"
            
            let photoToSave = Photo(path: fileName, context: sharedContext)
            
            photoToSave.location = thePin
            
            let newPhotoDictionary = ["fileName":fileName, "urlString": imageUrlString, "photo": photoToSave]
            
            newArray.append(newPhotoDictionary)
            
            CoreDataStackManager.sharedInstance().saveContext()
            
            }
        
        completionHandler(result: "Finished making CoreData photos", errorString: nil)
        
        writeImagesToDocumentDirectory(newArray)
            
    }
    
    func writeImagesToDocumentDirectory(photosArray: [[String: AnyObject]]){
        
        for photoDictionary in photosArray {
            
            guard let imageUrlString = photoDictionary["urlString"] as? String else {
                return
            }
            
            guard let fileName = photoDictionary["fileName"] as? String else {
                return
            }
            
            guard let coreDataPhoto = photoDictionary["photo"] as? Photo else {
                return
            }
            
            let imageURL = NSURL(string: imageUrlString)
            
            if let imageData = NSData(contentsOfURL: imageURL!) {
                
                let documentsDirectoryURL = databaseURL()
                
                let fileURL = documentsDirectoryURL?.URLByAppendingPathComponent(fileName)
                
                coreDataPhoto.downloaded = imageData.writeToURL(fileURL!, atomically: true).hashValue
                
                CoreDataStackManager.sharedInstance().saveContext()
                
            }
        }
        
    }

    func createBoundingBoxString(lat: Double, long: Double) -> String {
        
        let bottom_left_lon = max(long - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(lat - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(long + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(lat + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    func databaseURL() -> NSURL? {
        
        let fileManager = NSFileManager.defaultManager()
        
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        
        if let documentDirectory: NSURL = urls.first {
            return documentDirectory
        }
        
        
        return nil
    }
    
    
    // MARK: Escape HTML Parameters
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
    
}