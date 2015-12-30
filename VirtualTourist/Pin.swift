//
//  Pin.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/27/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//
//  Class that encapsulates a pin on the map and its information
//  This class conforms MKAnnotation protocol, making possible the use of this class with MapKit and NSFetchedResultsControllerDelegate
//  - coordinate is a mandatory property because of MKAnnotation protocol
//  latitude and longitude are used to save the pin's location and also to create the coordinate property
//  flickrPage is used to fetch new pages of photos from Flickr when a call tofetchPhotosFromFlickr is necessary
//  photos represents an array of the pin's photos

import CoreData
import MapKit

class Pin : NSManagedObject, MKAnnotation {
	
	@NSManaged var latitude: Double
	@NSManaged var longitude: Double
	@NSManaged var flickrPage: Int
	@NSManaged var photos: [Photo]
	
	lazy var coordinate : CLLocationCoordinate2D  = {
		return CLLocationCoordinate2DMake(self.latitude, self.longitude)
	}()
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
		let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
		super.init(entity: entity,insertIntoManagedObjectContext: context)

		self.latitude = latitude
		self.longitude = longitude
		self.flickrPage = 1
	}
	
	convenience init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
		self.init(latitude: coordinate.latitude, longitude: coordinate.longitude, context: context)
	}
}