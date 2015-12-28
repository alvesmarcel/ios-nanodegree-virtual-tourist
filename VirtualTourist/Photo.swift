//
//  Photo.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/27/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//

import UIKit
import CoreData

class Photo : NSManagedObject {
	
	@NSManaged var imagePath: String?
	@NSManaged var pin: Pin?
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init(imagePath: String, context: NSManagedObjectContext) {
		let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
		super.init(entity: entity,insertIntoManagedObjectContext: context)

		self.imagePath = imagePath
	}
	
	var image: UIImage? {
		
		get {
			return Flickr.Caches.imageCache.imageWithIdentifier(imagePath)
		}
		
		set {
			Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath!)
		}
	}
	
}
