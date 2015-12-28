//
//  MapRegion.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/28/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//

import MapKit

struct MapRegion {
	
	static let LatitudeDictKey = "latitude"
	static let LongitudeDictKey = "longitude"
	static let LatitudeDeltaDictKey = "latitudeDelta"
	static let LongitudeDeltaDictKey = "longitudeDelta"
	
	static let MapRegionArchive = "mapRegionArchive"
	
	private static var filePath : String {
		let manager = NSFileManager.defaultManager()
		let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
		return url.URLByAppendingPathComponent(MapRegionArchive).path!
	}
	
	static func saveMapRegion(latitude: CLLocationDegrees,
							  longitude: CLLocationDegrees,
							  latitudeDelta: CLLocationDegrees,
							  longitudeDelta: CLLocationDegrees)
	{
		let dictionary = [
			LatitudeDictKey : latitude,
			LongitudeDictKey : longitude,
			LatitudeDeltaDictKey : latitudeDelta,
			LongitudeDeltaDictKey : longitudeDelta
		]
		
		NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
	}
	
	static func loadMapRegion() -> MKCoordinateRegion? {
		
		if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
			
			let latitude = regionDictionary[LatitudeDictKey] as! CLLocationDegrees
			let longitude = regionDictionary[LongitudeDictKey] as! CLLocationDegrees
			let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
			
			let latitudeDelta = regionDictionary[LatitudeDeltaDictKey] as! CLLocationDegrees
			let longitudeDelta = regionDictionary[LongitudeDeltaDictKey] as! CLLocationDegrees
			let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
		
			return MKCoordinateRegion(center: center, span: span)
		}
		
		return nil
	}
}
