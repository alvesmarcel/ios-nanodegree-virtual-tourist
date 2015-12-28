//
//  Pin.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/27/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//

import CoreData
import MapKit

class Pin : NSManagedObject, MKAnnotation {
	
	@NSManaged var latitude: Double
	@NSManaged var longitude: Double
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
	}
	
	init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
		let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
		super.init(entity: entity,insertIntoManagedObjectContext: context)
		
		self.latitude = coordinate.latitude
		self.longitude = coordinate.longitude
	}
}