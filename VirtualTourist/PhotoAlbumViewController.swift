//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/27/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//

import UIKit
import MapKit

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
		
		if photosToBeRemoved.count == 0 {
			newCollectionButton.setTitle("New Collection", forState: .Normal)
		} else {
			newCollectionButton.setTitle("Remove Selected Pictures", forState: .Normal)
		}
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
}
