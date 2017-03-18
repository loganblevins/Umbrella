//
//  Date+.swift
//  Umbrella
//
//  Created by Logan Blevins on 11/17/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import Foundation

extension Date
{
	// This extension is quite different than a typical "Let's find the difference between two dates..."
	// scenario. We can't use a typical method of solving this, because we would get the number of 
	// whole days, rather than including all unique days. 
	//
	// First, we strip the time components from the date, preventing whole-day comparisons to be made.
	// Then, we take the difference and add 1, to compensate for the lost start day. 
	// But, by still including year, month, and day, we're able to accurately make comparisons even if we're 
	// comparing days: 31st and 2nd for example. No important context is lost.
	//
	func uniqueDays( from date: Date ) -> Int
	{
		let endDate = Calendar.current.dateComponents( [.year, .month, .day], from: self )
		let beginDate = Calendar.current.dateComponents( [.year, .month, .day], from: date )
		let dayDifference = Calendar.current.dateComponents( [.day], from: beginDate, to: endDate ).day ?? 0
		let inclusiveDifference = dayDifference + 1
		
		return inclusiveDifference
	}
}
