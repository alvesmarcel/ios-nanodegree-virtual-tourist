//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/27/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
	
	// MARK: - Outlets
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var newCollectionButton: UIButton!
	
	// MARK: - Class variables
	
	var pin: Pin!
	var photosToBeRemoved = [NSIndexPath : Photo]()
	
	// MARK: - Shared Context
	
	var sharedContext: NSManagedObjectContext {
		return CoreDataStackManager.sharedInstance().managedObjectContext
	}
	
	// MARK: - Lifecycle
	
	override func viewDidLoad() {
		configureMapView()
		collectionView.backgroundColor = UIColor.whiteColor()
	}
	
	override func viewWillAppear(animated: Bool) {
		collectionView.reloadData()
	}
	
	// MARK: - Overridden UIViewController method
	
	// Organizes the UICollectionView
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		// Lay out the collection view so that cells take up 1/3 of the width,
		// with no space in between.
		let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
		layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		layout.minimumLineSpacing = 0.0
		layout.minimumInteritemSpacing = 0.0
		
		let width = floor(self.collectionView.frame.size.width/3)
		layout.itemSize = CGSize(width: width, height: width)
		collectionView.collectionViewLayout = layout
	}
	
	// MARK: - Actions
	
	@IBAction func newCollectionDeleteButtonTouch(sender: UIButton) {
		if sender.titleLabel?.text == "New Collection" {
			getNewPhotosFromFlickr()
		} else {
			deleteSelectedPhotos()
		}
	}
	
	// MARK: - UICollectionViewDataSource methods
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return pin.photos.count
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionCell", forIndexPath: indexPath) as! PhotoAlbumViewCell
		let photo = pin.photos[indexPath.row]
		configureCell(cell, photo: photo)
		return cell
	}
	
	// MARK: - UICollectionViewDelegate methods
	
	// Performs different actions depending on the collectionViewIsEditing
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoAlbumViewCell
		selectCell(cell, forIndexPath: indexPath)
		updateBottomButton()
	}
	
	// MARK: - Helper methods
	
	// Configures mapView (region and annotation)
	func configureMapView() {
		
		mapView.zoomEnabled = false
		mapView.scrollEnabled = false
		
		let mapCenter = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
		let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
		let region = MKCoordinateRegion(center: mapCenter, span: span)
		mapView.setRegion(region, animated: false)
		
		let annotation = MKPointAnnotation()
		annotation.coordinate = mapCenter
		mapView.addAnnotation(annotation)
	}
	
	// Configures collectionView cells choosing a proper image
	func configureCell(cell: PhotoAlbumViewCell, photo: Photo) {
		
		// No image: background gray and activityIndicator on
		cell.backgroundColor = UIColor.grayColor()
		cell.activityIndicator.startAnimating()
		
		var cellImage = UIImage()
		
		// The photo has an image in the file system: no need to download from Flickr
		if photo.image != nil {
			cellImage = photo.image!
			cell.activityIndicator.stopAnimating()
		}
		// The photo has no image in the file system: download the image from Flickr
		else {
			
			let task = Flickr.sharedInstance().fetchImageFromFlickr(photo.imagePath!) { data, error in
				
				if let error = error {
					print("Image download error: \(error.localizedDescription)")
				}
				
				if let data = data {

					let image = UIImage(data: data)
					
					photo.image = image
					
					dispatch_async(dispatch_get_main_queue()) {
						cell.image.image = image
						cell.activityIndicator.stopAnimating()
					}
				}
			}
			
			cell.taskToCancelifCellIsReused = task
		}
		
		cell.image.image = cellImage
	}
	
	// Selects or deselects cell for an indexPath
	func selectCell(cell: PhotoAlbumViewCell, forIndexPath indexPath: NSIndexPath) {
		if cell.alpha < 1.0 {
			cell.alpha = 1.0
			photosToBeRemoved.removeValueForKey(indexPath)
		} else {
			cell.alpha = 0.3
			photosToBeRemoved[indexPath] = pin.photos[indexPath.row]
		}
	}
	
	// Deletes selected photos
	func deleteSelectedPhotos() {
		collectionView.performBatchUpdates({
			
			// Deletes photo from CoreData and cell from collectionView
			for photo in self.photosToBeRemoved {
				self.photosToBeRemoved.removeValueForKey(photo.0)
				self.sharedContext.deleteObject(photo.1)
				self.collectionView.deleteItemsAtIndexPaths([photo.0])
				CoreDataStackManager.sharedInstance().saveContext()
			}
		}, completion: nil)
		
		updateBottomButton()
	}
	
	// Deletes all photos from current pin
	func deleteAllPhotos() {
		for photo in pin.photos {
			sharedContext.deleteObject(photo)
		}
	}
	
	// Fetch new photos from Flickr
	func getNewPhotosFromFlickr() {
		
		// Increment flickrPage so different photos will be fetched
		pin.flickrPage += 1
		
		// Delete all photos before fetching new ones
		deleteAllPhotos()
		
		// Cleans collectionView
		dispatch_async(dispatch_get_main_queue()) {
			self.collectionView.reloadData()
		}
		
		// Fetch new photos from Flickr
		Flickr.sharedInstance().fetchPhotosFromFlickr(pin.latitude, longitude: pin.longitude, perPage: Flickr.Constants.PageSize, page: pin.flickrPage) { results, error in
			
			if let photos = results as? [[String : AnyObject]] {
				for photo in photos {
					let imagePath = photo["url_m"] as! String
					Photo(imagePath: imagePath, context: self.sharedContext).pin = self.pin
				}
				CoreDataStackManager.sharedInstance().saveContext()
				
				// Updating the collectionView with the new photos
				dispatch_async(dispatch_get_main_queue()) {
					self.collectionView.reloadData()
				}
			}
		}
	}
	
	// Changes bottomButton title
	func updateBottomButton() {
		if photosToBeRemoved.isEmpty {
			newCollectionButton.setTitle("New Collection", forState: .Normal)
		} else {
			newCollectionButton.setTitle("Remove Selected Pictures", forState: .Normal)
		}
	}
}
