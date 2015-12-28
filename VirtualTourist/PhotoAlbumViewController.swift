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
	
	override func viewDidLoad() {
		
		mapView.zoomEnabled = false
		mapView.scrollEnabled = false
	}
	
}
