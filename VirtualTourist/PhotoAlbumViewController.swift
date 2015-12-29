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
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var newCollectionButton: UIButton!
	
	var pin: Pin!
	
	var photosToBeRemoved = [NSIndexPath : Photo]()
	
	override func viewDidLoad() {
		configureMapView()
		collectionView.backgroundColor = UIColor.whiteColor()
	}
	
	override func viewWillAppear(animated: Bool) {
		collectionView.reloadData()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		// Lay out the collection view so that cells take up 1/3 of the width,
		// with no space in between.
		let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
		layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		layout.minimumLineSpacing = 1.0
		layout.minimumInteritemSpacing = 1.0
		
		let width = floor(self.collectionView.frame.size.width/3)
		layout.itemSize = CGSize(width: width, height: width)
		collectionView.collectionViewLayout = layout
	}
	
	@IBAction func newCollectionDeleteButtonTouch(sender: UIButton) {
		if sender.titleLabel?.text == "New Collection" {
			
		} else {
			print(pin.photos.count)
			updateBottomButton()
			collectionView.performBatchUpdates({
				for photo in self.photosToBeRemoved {
					self.photosToBeRemoved.removeValueForKey(photo.0)
					self.sharedContext.deleteObject(photo.1)
					CoreDataStackManager.sharedInstance().saveContext()
					self.collectionView.deleteItemsAtIndexPaths([photo.0])
				}
			}, completion: nil)
		}
	}
	
	// MARK: UICollectionViewDataSource methods
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return pin.photos.count
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionCell", forIndexPath: indexPath) as! PhotoAlbumViewCell
		
		let photo = pin.photos[indexPath.row]
		
		configureCell(cell, photo: photo)
		
		return cell
	}
	
	// MARK: UICollectionViewDelegate methods
	
	// Performs different actions depending on the collectionViewIsEditing
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoAlbumViewCell
		
		if cell.alpha < 1.0 {
			cell.alpha = 1.0
			photosToBeRemoved.removeValueForKey(indexPath)
		} else {
			cell.alpha = 0.3
			photosToBeRemoved[indexPath] = pin.photos[indexPath.row]
		}
		
		updateBottomButton()
	}
	
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
	
	// MARK: Configure Cell
	
	func configureCell(cell: PhotoAlbumViewCell, photo: Photo) {
		
		cell.backgroundColor = UIColor.grayColor()
		cell.activityIndicator.startAnimating()
		
		var cellImage = UIImage()
		
		if photo.image != nil {
			cellImage = photo.image!
			cell.activityIndicator.stopAnimating()
		} else {
			
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
	
	var sharedContext: NSManagedObjectContext {
		return CoreDataStackManager.sharedInstance().managedObjectContext
	}
	
	func updateBottomButton() {
		if photosToBeRemoved.count == 0 {
			newCollectionButton.setTitle("New Collection", forState: .Normal)
		} else {
			newCollectionButton.setTitle("Remove Selected Pictures", forState: .Normal)
		}
	}
}
