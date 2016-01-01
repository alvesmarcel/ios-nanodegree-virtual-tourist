//
//  Flickr.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/28/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//
//  Class responsible for fetching Flickr data (photos' dictionaries and images)

import Foundation

class Flickr : NSObject {
	
	typealias CompletionHandler = (result: AnyObject!, error: NSError?) -> Void
	
	// Shared Instance
	static let sharedInstance = Flickr()
	
	var session: NSURLSession
	
	override init() {
		session = NSURLSession.sharedSession()
		super.init()
	}
	
	// MARK: - Flickr API functions
	
	// General method for requesting a Flickr resource
	private func taskForFlickrResource(parameters: [String : AnyObject], completionHandler: CompletionHandler) -> NSURLSessionDataTask {
		
		var mutableParameters = parameters
		
		// Add in the API Key
		mutableParameters[JSONBodyKeys.ApiKey] = Constants.ApiKey
		mutableParameters[JSONBodyKeys.DataFormat] = Flickr.SearchParameters.DataFormat
		mutableParameters[JSONBodyKeys.NoJSONCallback] = Flickr.SearchParameters.NoJSONCallback
		
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
	
	// Creates the dictionary with latitude and longitude information to fetch Flickr photos based on location
	// This method is the one called by the ViewControllers
	func fetchPhotosFromFlickr(latitude: Double, longitude: Double, perPage: Int, page: Int, completionHandler: CompletionHandler) {
		let methodArguments = [
			JSONBodyKeys.Method: Methods.PhotosSearch,
			JSONBodyKeys.SafeSearch: SearchParameters.SafeSearch,
			JSONBodyKeys.Extras: SearchParameters.Extras,
			JSONBodyKeys.Latitude: "\(latitude)",
			JSONBodyKeys.Longitude: "\(longitude)",
			JSONBodyKeys.PerPage: "\(perPage)",
			JSONBodyKeys.Page: "\(page)"
		]
		
		Flickr.sharedInstance.taskForFlickrResource(methodArguments) { JSONResult, error in
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
	
	// Fetches images from Flickr, after the photos were already fetched
	// The imageURLString is in the photo dictionary information with the key "url_m"
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
	
	// Gets user informations for a specific photo
	func getFlickrUsernameForPhoto(userID: String, completionHandler: CompletionHandler) {
		let methodArguments = [
			Flickr.JSONBodyKeys.Method: Flickr.Methods.FlickrUserInfo,
			Flickr.JSONBodyKeys.ApiKey: Flickr.Constants.ApiKey,
			Flickr.JSONBodyKeys.UserID: userID
		]
		
		Flickr.sharedInstance.taskForFlickrResource(methodArguments) { JSONResult, error in
			if let error = error {
				completionHandler(result: nil, error: error)
			} else {
				if let results = JSONResult.valueForKey(JSONResponseKeys.Person)?.valueForKey(JSONResponseKeys.Username) as? [String : String] {
					completionHandler(result: results, error: nil)
				} else {
					completionHandler(result: nil, error: NSError(domain: "getFlickrUserInformationForPhoto", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find JSONResponseKey"]))
				}
			}
		}
	}
	
	// MARK: - Helper
	
	// Returns a string that will compose the URL for fetching Flickr data
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
	
	// Deal with error from Flickr data
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
	
	// JSON Parser
	class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHandler) {
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
	
	// Caches the image (saves image using NSFileManager)
	struct Caches {
		static let imageCache = ImageCache()
	}
}