//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/27/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//
// http://bjmiller.me/post/58431532849/nsfetchedresultscontroller-with-mkmapview

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
		
		let lpgr = UILongPressGestureRecognizer(target: self, action: "addPinToMap:")
		self.mapView.addGestureRecognizer(lpgr)
		
		do {
			try fetchedResultsController.performFetch()
		} catch {}
		
		fetchedResultsController.delegate = self
		
		mapView.addAnnotations(fetchedResultsController.fetchedObjects as! [Pin])
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
			print("Transition")
			// view transition
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
				print("Insert")
				mapView.addAnnotation(anObject as! Pin)
				
			case .Delete:
				print("Delete")
				mapView.removeAnnotation(anObject as! Pin)
				
			default:
				return
		}
	}
}
