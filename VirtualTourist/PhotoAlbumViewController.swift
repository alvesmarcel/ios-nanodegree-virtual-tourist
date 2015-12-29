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
	
	var pin: Pin!
	
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
		
		cell.image.backgroundColor = UIColor.grayColor()
		cell.activityIndicator.startAnimating()
		
		return cell
	}
	
	// MARK: UICollectionViewDelegate methods
	
	// Performs different actions depending on the collectionViewIsEditing
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		
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
}
