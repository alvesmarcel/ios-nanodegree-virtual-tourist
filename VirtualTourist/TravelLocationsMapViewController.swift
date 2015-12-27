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
	
	func addPinToMap(sender: UILongPressGestureRecognizer) {
		
		if (sender.state == UIGestureRecognizerState.Began) {
			let point = sender.locationInView(self.mapView)
			let coordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
			let annotation = Pin(coordinate: coordinate, context: sharedContext)
			annotation.coordinate = coordinate
			self.mapView.addAnnotation(annotation)
			CoreDataStackManager.sharedInstance().saveContext()
		}
	}
	
	// MARK: - MKMapViewDelegate methods
	
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		let reuseId = "pin"
		
		var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
		
		if pinView == nil {
			pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
			pinView?.animatesDrop = true
		}
		else {
			pinView!.annotation = annotation
		}
		
		return pinView
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
