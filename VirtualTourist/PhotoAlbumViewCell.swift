//
//  PhotoAlbumViewCell.swift
//  VirtualTourist
//
//  Created by Marcel Oliveira Alves on 12/28/15.
//  Copyright © 2015 Marcel Oliveira Alves. All rights reserved.
//
//  Custom UICollectionViewCell

import UIKit

class PhotoAlbumViewCell: UICollectionViewCell {
	
	@IBOutlet weak var image: UIImageView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var usernameLabel: UILabel!
	
	var isLoading = true
	
	// This idea was borowed from FavoriteActors
	// The property is observed: when it is set, the previous NSURLSessionTask is cancelled
	var taskToCancelifCellIsReused: NSURLSessionTask? {
		
		didSet {
			if let taskToCancel = oldValue {
				taskToCancel.cancel()
			}
		}
	}
}