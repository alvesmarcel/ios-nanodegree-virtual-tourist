//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/28/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//

extension Flickr {

	struct Constants {
		static let ApiKey = "9bd65c1700be1d09780a9fa35e819124"
		static let BaseURL = "https://api.flickr.com/services/rest/"
	}
	
	struct Methods {
		static let PhotosSearch = "flickr.photos.search"
	}
	
	struct SearchParameters {
		static let Extras = "url_m"
		static let SafeSearch = "1"
		static let DataFormat = "json"
		static let NoJSONCallback = "1"
	}
	
	struct JSONBodyKeys {
		static let ApiKey = "api_key"
		static let Method = "method"
		static let Extras = "extras"
		static let SafeSearch = "safe_search"
		static let DataFormat = "format"
		static let NoJSONCallback = "nojsoncallback"
		static let Latitude = "lat"
		static let Longitude = "lon"
		static let Radius = "radius"
		static let MinTakenDate = "min_taken_date"
		static let MaxTakenDate = "max_taken_date"
		static let PerPage = "per_page"
		static let Page = "page"
	}
	
	struct JSONResponseKeys {
		static let ErrorMessage = "message"
		static let Photos = "photos"
		static let Photo = "photo"
	}
}