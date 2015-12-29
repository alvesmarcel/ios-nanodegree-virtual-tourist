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
	
	var mapCenter: CLLocationCoordinate2D!
	
	var pin: Pin!
	
	override func viewDidLoad() {
		configureMapView()
		collectionView.backgroundColor = UIColor.whiteColor()
		
		
	}
	
	// MARK: UICollectionViewDataSource methods
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 12
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionCell", forIndexPath: indexPath)
		
		// FAZER O DOWNLOAD DAS IMAGENS
		
		return cell
	}
	
	// MARK: UICollectionViewDelegate methods
	
	// Performs different actions depending on the collectionViewIsEditing
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		
	}
	
	func configureMapView() {
		
		mapView.zoomEnabled = false
		mapView.scrollEnabled = false
		
		let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
		let region = MKCoordinateRegion(center: mapCenter, span: span)
		mapView.setRegion(region, animated: false)
		
		let annotation = MKPointAnnotation()
		annotation.coordinate = mapCenter
		mapView.addAnnotation(annotation)
	}
}
