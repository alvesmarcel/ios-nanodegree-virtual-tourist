//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/27/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//
// http://bjmiller.me/post/58431532849/nsfetchedresultscontroller-with-mkmapview
//
// little bug with map region - the region changes slightly when reloaded
// verify the behavior of tapping a pin

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController : UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var editBarButton: UIBarButtonItem!
	@IBOutlet weak var editViewLabel: UILabel!
	
	var editMode: Bool = false
	var pinDraggedAndDropped: Bool = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		
		let methodArguments = [
			Flickr.JSONBodyKeys.Method: Flickr.Methods.PhotosSearch,
			Flickr.JSONBodyKeys.ApiKey: Flickr.Constants.ApiKey,
			Flickr.JSONBodyKeys.SafeSearch: Flickr.SearchParameters.SafeSearch,
			Flickr.JSONBodyKeys.Extras: Flickr.SearchParameters.Extras,
			Flickr.JSONBodyKeys.DataFormat: Flickr.SearchParameters.DataFormat,
			Flickr.JSONBodyKeys.NoJSONCallback: "1",
			Flickr.JSONBodyKeys.Latitude: "-10.949262",
			Flickr.JSONBodyKeys.Longitude: "-37.070812",
			Flickr.JSONBodyKeys.PerPage: "9",
			Flickr.JSONBodyKeys.Page: "1000"
		]
		
		Flickr.sharedInstance().searchFlickrPhotosWithParameters(methodArguments) { results, error in
			print(results["photos"]!!["photo"]!!.count)
		}
		
		navigationItem.backBarButtonItem = UIBarButtonItem(title:"OK", style:.Plain, target:nil, action:nil)
		
		let lpgr = UILongPressGestureRecognizer(target: self, action: "addPinToMap:")
		self.mapView.addGestureRecognizer(lpgr)
		
		do {
			try fetchedResultsController.performFetch()
		} catch {}
		
		fetchedResultsController.delegate = self
		
		mapView.addAnnotations(fetchedResultsController.fetchedObjects as! [Pin])
		
		if let savedRegion = MapRegion.loadMapRegion() {
			mapView.setRegion(savedRegion, animated: true)
		}
	}
	
	@IBAction func editButtonTapped(sender: UIBarButtonItem) {
		
		if editBarButton.title == "Edit" {
			editMode = true
			editBarButton.title = "Done"
			UIView.animateWithDuration(0.5) { animations in
				self.mapView.frame.origin.y -=  60.0
			}
		} else {
			editMode = false
			editBarButton.title = "Edit"
			UIView.animateWithDuration(0.5) { animations in
				self.mapView.frame.origin.y =  0
			}
		}
	}
	
	func addPinToMap(sender: UILongPressGestureRecognizer) {
		
		if (sender.state == UIGestureRecognizerState.Began && !editMode) {
			let point = sender.locationInView(self.mapView)
			let coordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
			let pin = Pin(coordinate: coordinate, context: sharedContext)
			sharedContext.insertObject(pin)
			CoreDataStackManager.sharedInstance().saveContext()
		}
	}
	
	// MARK: - MKMapViewDelegate methods
	
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		let reuseId = "pin"
		
		var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
		
		if pinView == nil {
			pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
			pinView?.draggable = true
		} else {
			pinView!.annotation = annotation
		}
		
		pinView?.setSelected(true, animated: false)
		pinView?.animatesDrop = true
		
		// Sets drop animation to false when the pin is just being dragged and dropped
		if (pinDraggedAndDropped) {
			pinView?.animatesDrop = false
			pinDraggedAndDropped = false
		}
		
		return pinView
	}
	
	func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
		
		if editMode {
			// deletes
			let pin = view.annotation as! Pin
			sharedContext.deleteObject(pin)
			CoreDataStackManager.sharedInstance().saveContext()
		} else {
			let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
			
			let latitude = view.annotation!.coordinate.latitude
			let longitude = view.annotation!.coordinate.longitude
			controller.mapCenter = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
			
			self.navigationController!.pushViewController(controller, animated: true)
		}
	}
	
	func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
		
		dispatch_async(dispatch_get_main_queue()) {
			self.pinDraggedAndDropped = true
		}
		
		if newState == MKAnnotationViewDragState.Ending {
			let pin = view.annotation as! Pin
			sharedContext.deleteObject(pin)
			sharedContext.insertObject(Pin(coordinate: view.annotation!.coordinate, context: sharedContext))
			CoreDataStackManager.sharedInstance().saveContext()
		}
	}
	
	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		MapRegion.saveMapRegion(mapView.region.center.latitude, longitude: mapView.region.center.longitude, latitudeDelta: mapView.region.span.latitudeDelta, longitudeDelta: mapView.region.span.longitudeDelta)
	}
	
	var sharedContext: NSManagedObjectContext {
		return CoreDataStackManager.sharedInstance().managedObjectContext
	}
	
	lazy var fetchedResultsController: NSFetchedResultsController = {
		
		let fetchRequest = NSFetchRequest(entityName: "Pin")
		
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
		
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
			managedObjectContext: self.sharedContext,
			sectionNameKeyPath: nil,
			cacheName: nil)
		
		return fetchedResultsController
		
	}()
	
	// MARK: delegate
	
	func controller(controller: NSFetchedResultsController,
					didChangeObject anObject: AnyObject,
					atIndexPath indexPath: NSIndexPath?,
					forChangeType type: NSFetchedResultsChangeType,
					newIndexPath: NSIndexPath?) {
			
		switch type {
			case .Insert:
				mapView.addAnnotation(anObject as! Pin)
				
			case .Delete:
				mapView.removeAnnotation(anObject as! Pin)
				
			default:
				return
		}
	}
}
