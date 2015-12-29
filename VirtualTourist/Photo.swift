//
//  Photo.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/27/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//
//  Class that encapsulates a Flickr photo
//  imagePath is a String that saves the URL for the photo image and is also used as a path to save the photo in the Cache
//  pin is a Pin object that "owns" the photo

import UIKit
import CoreData

class Photo : NSManagedObject {
	
	@NSManaged var imagePath: String!
	@NSManaged var pin: Pin?
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init(imagePath: String, context: NSManagedObjectContext) {
		let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
		super.init(entity: entity,insertIntoManagedObjectContext: context)

		self.imagePath = imagePath
	}
	
	override func prepareForDeletion() {
		Flickr.Caches.imageCache.deleteImage(imagePath)
	}
	
	var image: UIImage? {
		
		get {
			return Flickr.Caches.imageCache.imageWithIdentifier(imagePath)
		}
		
		set {
			Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath)
		}
	}
	
}
