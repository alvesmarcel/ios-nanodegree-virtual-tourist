//
//  Flickr.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/28/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//

import Foundation

class Flickr : NSObject {
	
	typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
	
	var session: NSURLSession
	
	override init() {
		session = NSURLSession.sharedSession()
		super.init()
	}
	
	func searchFlickrPhotosWithParameters(parameters: [String : AnyObject], completionHandler: CompletionHander) -> NSURLSessionDataTask {
		
		var mutableParameters = parameters
		
		// Add in the API Key
		mutableParameters[JSONBodyKeys.ApiKey] = Constants.ApiKey
		
		let urlString = Constants.BaseURL + Flickr.escapedParameters(mutableParameters)
		let url = NSURL(string: urlString)!
		let request = NSURLRequest(URL: url)
		
		let task = session.dataTaskWithRequest(request) { data, response, downloadError in
			
			if let error = downloadError {
				let newError = Flickr.errorForData(data, response: response, error: error)
				completionHandler(result: nil, error: newError)
			} else {
				Flickr.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
			}
		}
		
		task.resume()
		
		return task
	}
	
	func fetchPhotosFromFlickr(latitude: Double, longitude: Double, perPage: Int, page: Int, completionHandler: CompletionHander) {
		let methodArguments = [
			Flickr.JSONBodyKeys.Method: Flickr.Methods.PhotosSearch,
			Flickr.JSONBodyKeys.ApiKey: Flickr.Constants.ApiKey,
			Flickr.JSONBodyKeys.SafeSearch: Flickr.SearchParameters.SafeSearch,
			Flickr.JSONBodyKeys.Extras: Flickr.SearchParameters.Extras,
			Flickr.JSONBodyKeys.DataFormat: Flickr.SearchParameters.DataFormat,
			Flickr.JSONBodyKeys.NoJSONCallback: Flickr.SearchParameters.NoJSONCallback,
			Flickr.JSONBodyKeys.Latitude: "\(latitude)",
			Flickr.JSONBodyKeys.Longitude: "\(longitude)",
			Flickr.JSONBodyKeys.PerPage: "\(perPage)",
			Flickr.JSONBodyKeys.Page: "\(page)"
		]
		
		Flickr.sharedInstance().searchFlickrPhotosWithParameters(methodArguments) { JSONResult, error in
			if let error = error {
				completionHandler(result: nil, error: error)
			} else {
				if let results = JSONResult.valueForKey(JSONResponseKeys.Photos)?.valueForKey(JSONResponseKeys.Photo) as? [[String : AnyObject]] {
					completionHandler(result: results, error: nil)
				} else {
					completionHandler(result: nil, error: NSError(domain: "fetchPhotosFromFlickr", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find JSONResponseKey"]))
				}
			}
		}
	}
	
	func fetchImageFromFlickr(imageURLString: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
		let url = NSURL(string: imageURLString)!
		
		let request = NSURLRequest(URL: url)
		
		let task = session.dataTaskWithRequest(request) {data, response, downloadError in
			
			if let error = downloadError {
				let newError = Flickr.errorForData(data, response: response, error: error)
				completionHandler(imageData: nil, error: newError)
			} else {
				completionHandler(imageData: data, error: nil)
			}
		}
		
		task.resume()
		
		return task
	}
	
	// MARK: - Shared Instance
	
	class func sharedInstance() -> Flickr {
		
		struct Singleton {
			static var sharedInstance = Flickr()
		}
		
		return Singleton.sharedInstance
	}
	
	// HELPER
	
	class func escapedParameters(parameters: [String : AnyObject]) -> String {
		
		var urlVars = [String]()
		
		for (key, value) in parameters {
			
			// make sure that it is a string value
			let stringValue = "\(value)"
			
			// Escape it
			let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
			
			// Append it
			
			if let unwrappedEscapedValue = escapedValue {
				urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
			} else {
				print("Warning: trouble excaping string \"\(stringValue)\"")
			}
		}
		
		return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
	}
	
	class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
		
		if data == nil {
			return error
		}
		
		do {
			let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
			
			if let parsedResult = parsedResult as? [String : AnyObject], errorMessage = parsedResult[Flickr.JSONResponseKeys.ErrorMessage] as? String {
				let userInfo = [NSLocalizedDescriptionKey : errorMessage]
				return NSError(domain: "Flickr Error", code: 1, userInfo: userInfo)
			}
			
		} catch _ {}
		
		return error
	}
	
	// Parsing the JSON
	
	class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHander) {
		var parsingError: NSError? = nil
		
		let parsedResult: AnyObject?
		do {
			parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
		} catch let error as NSError {
			parsingError = error
			parsedResult = nil
		}
		
		if let error = parsingError {
			completionHandler(result: nil, error: error)
		} else {
			completionHandler(result: parsedResult, error: nil)
		}
	}
	
	struct Caches {
		static let imageCache = ImageCache()
	}
}