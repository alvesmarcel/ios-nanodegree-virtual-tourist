//
//  FlickrUser.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/30/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//

import CoreData
import MapKit

class FlickrUser : NSManagedObject {
	
	@NSManaged var username: String
	@NSManaged var photos: [Photo]
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init(username: String, context: NSManagedObjectContext) {
		let entity =  NSEntityDescription.entityForName("FlickrUser", inManagedObjectContext: context)!
		super.init(entity: entity,insertIntoManagedObjectContext: context)
		
		self.username = username
	}
}