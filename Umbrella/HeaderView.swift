//
//  HeaderView.swift
//  Umbrella
//
//  Created by Logan Blevins on 11/16/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import Foundation
import UIKit

class HeaderView: UICollectionReusableView
{
	@IBOutlet weak var dayLabel: UILabel!
	
	func configureDayLabel( withText text: String? )
	{
		dayLabel.text = text
	}
}
