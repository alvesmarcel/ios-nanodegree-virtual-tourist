//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/27/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController : UIViewController {
	
	@IBOutlet weak var mapView: MKMapView!
	
	var mapCenter: CLLocationCoordinate2D!
	
	override func viewDidLoad() {
		configureMapView()
		
	}
	
	func travelLocationsMap(travelLocationsMap: TravelLocationsMapViewController, didDropPin pin: Pin?) {
		
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
