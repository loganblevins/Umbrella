//
//  CellView.swift
//  Umbrella
//
//  Created by Logan Blevins on 11/16/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import Foundation
import UIKit

class CellView: UICollectionViewCell
{
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var iconImage: UIImageView!
	@IBOutlet weak var tempLabel: UILabel!
	
	func configureImage( withImage image: UIImage?, tint: UIColor? )
	{
		let renderedImage = image?.withRenderingMode( .alwaysTemplate )
		iconImage.contentMode = .scaleAspectFit
		iconImage.image = renderedImage
		
		if let highOrLowTint = tint
		{
			iconImage.tintColor = highOrLowTint
		}
		else
		{
			iconImage.tintColor = UIColor.black
		}
	}
	
	func configureTimeLabel( withText text: String?, color: UIColor? )
	{
		timeLabel.text = text
		timeLabel.textColor = color
	}
	
	func configureTempLabel( withText text: String?, color: UIColor? )
	{
		tempLabel.text = text
		tempLabel.textColor = color
	}
}
