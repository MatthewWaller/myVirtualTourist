//
//  PhotoAlbumViewController.swift
//  myVirtualTourist
//
//  Created by Matthew Waller on 3/15/16.
//  Copyright © 2016 Matthew Waller. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate  {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    
    
    var selectedPin: MKTouristAnnotation?
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.selectedPin!.pin!)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    //MARK: lifecycle
    override func viewDidLoad() {
        
        do {
            try fetchedResultsController.performFetch()
        } catch _ as NSError {

        }
        
        updateBottomButton()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        

        let space: CGFloat = 8.0
        let spacingDimension = (view.frame.size.width - (4 * space)) / 3.0
        
        layout.minimumInteritemSpacing = space
        layout.minimumLineSpacing = space
        
        layout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
        
        layout.itemSize = CGSize(width: spacingDimension, height: spacingDimension)
        collectionView.collectionViewLayout = layout
    }
    
    //MARK: CollectionView setup
    
    func configureCell(cell: FlickrCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        
        cell.imageView.backgroundColor = UIColor.blueColor()
        cell.activityIndicator.startAnimating()
        cell.imageView.image = nil
        
        if let image = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo {
            
            let filename = image.imagePath
        
            let documentsDirectory = FlickrClient.sharedInstance().databaseURL()
        
            let fileURL = documentsDirectory?.URLByAppendingPathComponent(filename!)
        
            if let retrievedImageData = NSData(contentsOfFile: (fileURL?.path)!) {
        
                let retrievedImage = UIImage(data: retrievedImageData)
        
                cell.imageView.image = retrievedImage
        
                cell.activityIndicator.stopAnimating()
        
            }
            
        }
        
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.alpha = 0.5
        } else {
            cell.alpha = 1.0
        }
    
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects

    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCell", forIndexPath: indexPath) as! FlickrCollectionViewCell
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FlickrCollectionViewCell
        
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
    
        configureCell(cell, atIndexPath: indexPath)
        
        updateBottomButton()
    }

    // MARK: - Fetched Results Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
       
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
    }
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type{
            
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            
            break
        case .Move:
            
            break
        
        }
        
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
                
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    // MARK: - Actions and Helpers
    
    @IBAction func buttonButtonClicked() {
        
        if selectedIndexes.isEmpty {
            deleteAllPics()
        } else {
            deleteSelectedPics()
        }
    }
    
    func deleteAllPics() {
        
        
        for pic in fetchedResultsController.fetchedObjects as! [Photo] {
            doDelete(pic)
        }
        
        replacePhotos()
        
        updateBottomButton()
    }
    
    func deleteSelectedPics() {
        var picsToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            picsToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for pic in picsToDelete {
            doDelete(pic)
        }
        
        selectedIndexes = [NSIndexPath]()
        
        updateBottomButton()
    }
    
    func replacePhotos(){
        
        FlickrClient.sharedInstance().getImagesForAnnotation(selectedPin!)
        
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Pictures"
        } else {
            bottomButton.title = "Replace all pictures"
        }
    }
    
    func doDelete(pic: Photo){
        
        pic.deleteImage()
        
        sharedContext.deleteObject(pic)
        
        CoreDataStackManager.sharedInstance().saveContext()
    }

}