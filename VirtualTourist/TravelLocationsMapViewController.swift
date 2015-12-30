//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/27/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//
//  This class controls the TravelLocationView
//  The mapView is used in conjuction with NSFetchedResultsControllerDelegate. This idea was based on:
//  http://bjmiller.me/post/58431532849/nsfetchedresultscontroller-with-mkmapview
//  The pins are persisted using CoreData
//  
//  There is a known bug: the region is slightly changed when the app exits and is opened again

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController : UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
	
	// MARK: - Outlets
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var editBarButton: UIBarButtonItem!
	@IBOutlet weak var editViewLabel: UILabel!
	
	// MARK: Class variables
	
	var editMode: Bool = false
	var pinDraggedAndDropped: Bool = false
	
	// MARK: - Shared Context
	
	var sharedContext: NSManagedObjectContext {
		return CoreDataStackManager.sharedInstance().managedObjectContext
	}
	
	// MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.backBarButtonItem = UIBarButtonItem(title:"OK", style:.Plain, target:nil, action:nil)
		
		// Used to add a pin when the user makes a "long press"
		let lpgr = UILongPressGestureRecognizer(target: self, action: "addPinToMap:")
		self.mapView.addGestureRecognizer(lpgr)
		
		// Fetch pins and put them in the map
		do {
			try fetchedResultsController.performFetch()
		} catch {}
		mapView.addAnnotations(fetchedResultsController.fetchedObjects as! [Pin])
		
		fetchedResultsController.delegate = self
		
		// Load MapRegion if it was saved
		if let savedRegion = MapRegion.loadMapRegion() {
			mapView.setRegion(savedRegion, animated: true)
		}
	}
	
	// MARK: - Actions
	
	@IBAction func editButtonTapped(sender: UIBarButtonItem) {
		setEditModeTo(editBarButton.title! == "Edit")
	}
	
	// Adds pin to the location tapped by the user
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
			pinView?.draggable = true // configurates every pin to be draggable
		} else {
			pinView!.annotation = annotation
		}
		
		// Avoids the need to select the pin before dragging
		pinView?.setSelected(true, animated: false)
		
		// Drop should be animated by default
		pinView?.animatesDrop = true
		
		// Sets drop animation to false when the pin is just being dragged and dropped
		if (pinDraggedAndDropped) {
			pinView?.animatesDrop = false
			pinDraggedAndDropped = false
		}

		return pinView
	}
	
	func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
		
		let pin = view.annotation as! Pin
		
		// editMode? Deletes the pin when selected
		if editMode {
			sharedContext.deleteObject(pin)
			CoreDataStackManager.sharedInstance().saveContext()
		}
		// not editMode? Performs segue to PhotoAlbumViewController
		else {
			let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
			controller.pin = pin
			self.navigationController!.pushViewController(controller, animated: true)
		}
	}
	
	// Deals with dragging and dropping a pin
	func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
		
		// Used to inform that it is performing an "update" of the pin position (it is being dragged and dropped)
		dispatch_async(dispatch_get_main_queue()) {
			self.pinDraggedAndDropped = true
		}
		
		// Deletes old pin and saves new pin after the dragging and dropping has ended
		if newState == MKAnnotationViewDragState.Ending {
			let pin = view.annotation as! Pin
			sharedContext.deleteObject(pin)
			sharedContext.insertObject(Pin(coordinate: view.annotation!.coordinate, context: sharedContext))
			CoreDataStackManager.sharedInstance().saveContext()
		}
	}
	
	// Saves map region when the region changes
	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		MapRegion.saveMapRegion(mapView.region.center.latitude, longitude: mapView.region.center.longitude, latitudeDelta: mapView.region.span.latitudeDelta, longitudeDelta: mapView.region.span.longitudeDelta)
	}
	
	// MARK: - FetchedResultsController
	
	lazy var fetchedResultsController: NSFetchedResultsController = {
		
		let fetchRequest = NSFetchRequest(entityName: "Pin")
		
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
		
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
			managedObjectContext: self.sharedContext,
			sectionNameKeyPath: nil,
			cacheName: nil)
		
		return fetchedResultsController
		
	}()
	
	// MARK: - NSFetchedResultsControllerDelegate
	
	func controller(controller: NSFetchedResultsController,
					didChangeObject anObject: AnyObject,
					atIndexPath indexPath: NSIndexPath?,
					forChangeType type: NSFetchedResultsChangeType,
					newIndexPath: NSIndexPath?)
	{
		let pin = anObject as! Pin
			
		switch type {
			case .Insert:
				// Fetches photos as soon as the pin drops; also works for dragging and dropping pin
				preFetchPhotosForPin(pin)
				mapView.addAnnotation(pin)
				
			case .Delete:
				mapView.removeAnnotation(pin)
				
			default:
				return
		}
	}
	
	// MARK: - Helper methods
	
	// Sets the configuration for editing
	func setEditModeTo(flag: Bool) {
		if flag {
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
	
	// Pre-fetches photos from Flickr with pin information
	// These photos are saved in the pin
	func preFetchPhotosForPin(pin: Pin) {
		Flickr.sharedInstance().fetchPhotosFromFlickr(pin.latitude, longitude: pin.longitude, perPage: 21, page: 1) { results, error in
			
			if let photos = results as? [[String : AnyObject]] {
				for photo in photos {
					let imagePath = photo["url_m"] as! String
					dispatch_async(dispatch_get_main_queue()) {
						Photo(imageURLString: imagePath, context: self.sharedContext).pin = pin
						CoreDataStackManager.sharedInstance().saveContext()
					}
				}
			}
		}
	}
}
