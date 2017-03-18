//
//  Double+.swift
//  Umbrella
//
//  Created by Logan Blevins on 11/17/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import Foundation

extension Double
{
	func dayFromEpoch() -> Int
	{
		let date = Date( timeIntervalSince1970: self )
		return Calendar.current.component( .day, from: date )
	}
	
	func prettyWeekdayFromEpoch() -> String
	{
		let date = Date( timeIntervalSince1970: self )
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "EEEE"
		return dateFormatter.string( from: date ).capitalized
	}
}
