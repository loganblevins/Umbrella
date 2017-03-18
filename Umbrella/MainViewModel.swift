//
//  MainViewModel.swift
//  Umbrella
//
//  Created by Logan Blevins on 11/16/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import Foundation
import UIKit

protocol MainViewModelDelegate: class
{
	func onGeneralFailure()
}

final class MainViewModel: WeatherModelDelegate
{
	// MARK: Public API
	//
	init()
	{
		weatherModel.delegate = self
		buildGroupedCaches()
	}
	
	weak var delegate: MainViewModelDelegate?
	
	var englishMode: Bool
	{
		return StandardDefaults.sharedInstance.englishMode
	}
	
	func fetchWeatherAsync( forZipCode zipCode: String?, completion: @escaping(_ result: Result<Any> ) -> Void )
	{
		self.weatherAPI.fetchWeather( forZipCode: zipCode )
		{
			[weak self] result in
			guard let strongSelf = self else { return }
			
			strongSelf.weatherModel.maybeUpdate( result )
			completion( result )
		}
	}
	
	func hourlyModels() -> HourlyData
	{
		return weatherModel.hourlyModels
	}
	
	func numberOfSections() -> Int
	{
		guard weatherModel.hasData else { return 0 }
		let lastIndex = hourlyModels().endIndex
		let actualLastIndex = lastIndex - 1
		
		// WeatherUnderground gives us the hourly forecast in ascending order, based on date.
		//
		// Maybe later it would be better to not rely on this? Rather, to get the min, max of Unix timestamps instead.
		//
		guard let beginEpoch = weatherModel.hourlyUnixTimestamp( forHour: 0, from: hourlyModels() ) else { return 0 }
		guard let endEpoch = weatherModel.hourlyUnixTimestamp( forHour: actualLastIndex, from: hourlyModels() ) else { return 0 }
		
		guard let beginEpochNum = Double( beginEpoch ) else
		{
			delegate?.onGeneralFailure()
			return 0
		}
		guard let endEpochNum = Double( endEpoch ) else
		{
			delegate?.onGeneralFailure()
			return 0
		}
		
		let beginDate = Date( timeIntervalSince1970: beginEpochNum )
		let endDate = Date( timeIntervalSince1970: endEpochNum )
		print( "Number of sections: \( endDate.uniqueDays( from: beginDate ) )" )
		return endDate.uniqueDays( from: beginDate )
	}
	
	func numberOfItemsInSection( forSection section: Int ) -> Int
	{
		guard weatherModel.hasData else { return 0 }
		
		guard let sectionArray = groupedHourlyWeatherByDayCache[section] else
		{
			delegate?.onGeneralFailure()
			return 0
		}
		let count = sectionArray.count
		print( "Number of items in section: \( section ): \( count )" )
		return sectionArray.count
	}
	
	func timeViewable( forIndexPath indexPath: IndexPath ) -> ( text: String, tint: UIColor? )
	{
		guard weatherModel.hasData else { return ( "2:00 PM", nil ) }
		let section = indexPath.section
		let itemNumber = indexPath.item
		
		guard let cachedSectionArray = groupedHourlyWeatherByDayCache[section] else
		{
			delegate?.onGeneralFailure()
			return ( "2:00 PM", nil )
		}
		let time = weatherModel.hourlyPrettyTimestamp( forHour: itemNumber, from: cachedSectionArray )
		
		var tint: UIColor?
		if let tintColor = self.tintCache.object( forKey: indexPath as AnyObject ) as? UIColor
		{
			tint = tintColor
		}
		else if self.imageCache.object( forKey: indexPath as AnyObject ) == nil
		{
			tint = self.tint( fromIndexPath: indexPath )
		}
		
		guard let strongTime = time else
		{
			delegate?.onGeneralFailure()
			return ( "2.00 PM", nil )
		}
		return ( strongTime, tint )
	}
	
	func tempViewable( forIndexPath indexPath: IndexPath ) -> ( text: String, tint: UIColor? )
	{
		guard weatherModel.hasData else { return ( "50°", nil ) }
		let section = indexPath.section
		let itemNumber = indexPath.item
		let tempFunc = englishMode ? weatherModel.hourlyTempF : weatherModel.hourlyTempC

		guard let cachedSectionArray = groupedHourlyWeatherByDayCache[section] else
		{
			delegate?.onGeneralFailure()
			return ( "50°", nil )
		}
		let temp = tempFunc( itemNumber, cachedSectionArray )

		guard let formattedTemp = temp?.appending( "°" ) else
		{
			delegate?.onGeneralFailure()
			return ( "50°", nil )
		}
		
		var tint: UIColor?
		if let tintColor = self.tintCache.object( forKey: indexPath as AnyObject ) as? UIColor
		{
			tint = tintColor
		}
		else if self.imageCache.object( forKey: indexPath as AnyObject ) == nil
		{
			tint = self.tint( fromIndexPath: indexPath )
		}
		
		return ( formattedTemp, tint )
	}
	
	func iconViewable( forIndexPath indexPath: IndexPath, completion: @escaping(_ image: UIImage?, _ imageTint: UIColor? ) -> Void )
	{
		guard weatherModel.hasData else
		{
			completion( nil, nil )
			return
		}
		let section = indexPath.section
		let itemNumber = indexPath.item
		
		guard let sectionArray = groupedHourlyWeatherByDayCache[section] else
		{
			delegate?.onGeneralFailure()
			completion( nil, nil )
			return
		}
		
		if let image = self.imageCache.object( forKey: indexPath as AnyObject ) as? UIImage
		{
			var tint: UIColor?
			if let tintColor = self.tintCache.object( forKey: indexPath as AnyObject ) as? UIColor
			{
				tint = tintColor
			}
			
			completion( image, tint )
			return
		}
		
		let tint = self.tint( fromIndexPath: indexPath )
		if let strongTint = tint
		{
			self.tintCache.setObject( strongTint, forKey: indexPath as AnyObject )
		}
	
		guard let imageUrl = weatherModel.hourlyIconURL( forHour: itemNumber, highlighted: tint == nil ? false : true, from: sectionArray ) else
		{
			delegate?.onGeneralFailure()
			completion( nil, nil )
			return
		}
		fetchImageAsync( forUrl: imageUrl )
		{
			result in
			
			switch result
			{
			case .success( let image as UIImage ):
				DispatchQueue.main.async
				{
					self.cache( withImage: image, withTintColor: tint, forIndexPath: indexPath )
					completion( image, tint )
				}
				
			case .failure( _ ):
				DispatchQueue.main.async
				{
					self.delegate?.onGeneralFailure()
					completion( nil, nil )
				}
				
			default:
				assertionFailure( "What are you doing????? Case should not exist!" )
			}
		}
	}
	
	func headerTitleViewable( forIndexPath indexPath: IndexPath ) -> String
	{
		guard weatherModel.hasData else { return "Today" }
		let section = indexPath.section
		let itemNumber = indexPath.item
		
		switch section
		{
		case 0:
			return "Today"
			
		case 1:
			return "Tomorrow"
		
		default:
			guard let cachedSectionArray = groupedHourlyWeatherByDayCache[section] else
			{
				delegate?.onGeneralFailure()
				return "Next Day"
			}
			
			guard let day = weatherModel.hourlyUnixTimestamp( forHour: itemNumber, from: cachedSectionArray ) else
			{
				delegate?.onGeneralFailure()
				return "Next Day"
			}
		
			guard let doubleDay = Double( day ) else
			{
				delegate?.onGeneralFailure()
				return "Next Day"
			}
			return String( doubleDay.prettyWeekdayFromEpoch() )
		}
	}
	
	func currentCityStateViewable() -> String?
	{
		guard weatherModel.hasData else { return "   " }
		return weatherModel.currentCity
	}
	
	func currentTempViewable() -> String?
	{
		guard weatherModel.hasData else { return "- -" }
		guard let temp = englishMode ? weatherModel.currentTempF : weatherModel.currentTempC else
		{
			delegate?.onGeneralFailure()
			return nil
		}
		let numericTemp = Double( temp )
		guard let roundedTemp = numericTemp?.rounded() else
		{
			delegate?.onGeneralFailure()
			return nil
		}
		let roundedStringTemp = String( format: "%.0f", roundedTemp )
		let formattedTemp = roundedStringTemp.appending( "°" )
		return formattedTemp
	}
	
	func currentViewBackgroundColor() -> UIColor
	{
		guard weatherModel.hasData else { return Constants.Colors.warmColor }
		guard let temp = englishMode ? weatherModel.currentTempF : weatherModel.currentTempC else
		{
			delegate?.onGeneralFailure()
			return Constants.Colors.warmColor
		}
		let numericTemp = Double( temp )
		guard let roundedTemp = numericTemp?.rounded() else
		{
			delegate?.onGeneralFailure()
			return Constants.Colors.warmColor
		}
		return roundedTemp >= 60 ? Constants.Colors.warmColor : Constants.Colors.coolColor
	}
	
	func currentConditionViewable() -> String?
	{
		guard weatherModel.hasData else { return "   " }
		return weatherModel.currentCondition
	}
	
	// MARK: WeatherModelDelegate methods
	//
	func onModelUpdated()
	{
		updateStore()
	}
	
	func updateStore()
	{
		emptyAllCaches()
		buildGroupedCaches()
	}
	
	// MARK: Implementation details
	//
	fileprivate func tint( fromIndexPath indexPath: IndexPath ) -> UIColor?
	{
		let section = indexPath.section
		let itemNumber = indexPath.item
		
		var tint: UIColor?
		
		let minTempIndex = groupedMinTempByDayCache[section]
		let maxTempIndex = groupedMaxTempByDayCache[section]
		
		if minTempIndex == maxTempIndex
		{
			return nil
		}
		else if minTempIndex == itemNumber
		{
			tint = Constants.Colors.coolColor
		}
		else if maxTempIndex == itemNumber
		{
			tint = Constants.Colors.warmColor
		}
		
		return tint
	}
	
	fileprivate func cache( withImage image: UIImage, withTintColor tintColor: UIColor?, forIndexPath indexPath: IndexPath )
	{
		self.imageCache.setObject( image, forKey: indexPath as AnyObject )
		if let strongTintColor = tintColor
		{
			self.tintCache.setObject( strongTintColor, forKey: indexPath as AnyObject  )
		}
	}
	
	fileprivate func emptyAllCaches()
	{
		imageCache.removeAllObjects()
		tintCache.removeAllObjects()
		groupedHourlyWeatherByDayCache.removeAll()
		groupedMinTempByDayCache.removeAll()
		groupedMaxTempByDayCache.removeAll()
	}
	
	fileprivate func buildGroupedCaches()
	{
		groupedHourlyWeatherByDayCache = groupedHourlyWeatherByDay()
		groupedMinTempByDayCache = groupedMinTempItemByDayCache()
		groupedMaxTempByDayCache = groupedMaxTempItemByDayCache()
	}
	
	fileprivate func fetchImageAsync( forUrl url: URL, completion: @escaping(_ result: Result<Any> ) -> Void )
	{
		self.weatherAPI.fetchImage( forUrl: url )
		{
			result in
			completion( result )
		}
	}
 
	fileprivate func minTemp( forSection section: Int ) -> Int
	{
		let tempFunc = englishMode ? weatherModel.hourlyTempF : weatherModel.hourlyTempC
		guard let sectionArray = groupedHourlyWeatherByDayCache[section] else
		{
			delegate?.onGeneralFailure()
			return 0
		}
		
		var tempArray = [Int]()
		for i in 0..<sectionArray.count
		{
			guard let temp = tempFunc( i, sectionArray ) else
			{
				delegate?.onGeneralFailure()
				return 0
			}
			let numericTemp = Int( temp ) ?? 0
			tempArray.append( numericTemp )
		}
		
		guard let min = tempArray.min() else
		{
			delegate?.onGeneralFailure()
			return 0
		}
		return min
	}
	
	fileprivate func itemOfFirstMin( forSection section: Int ) -> Int
	{
		guard weatherModel.hasData else { return 0 }
		let temp = minTemp( forSection: section )
		
		guard let sectionArray = groupedHourlyWeatherByDayCache[section] else
		{
			delegate?.onGeneralFailure()
			return 0
		}
		let tempFunc = self.englishMode ? weatherModel.hourlyTempF : weatherModel.hourlyTempC
		var index = 0
		for hour in 0..<sectionArray.count
		{
			guard let hourTemp = tempFunc( hour, sectionArray ) else
			{
				delegate?.onGeneralFailure()
				return 0
			}
			let numericHourTemp = Int( hourTemp ) ?? 0
			if numericHourTemp == temp
			{
				index = hour
				break
			}
		}
		
		return index
	}
	
	fileprivate func itemOfFirstMax( forSection section: Int ) -> Int
	{
		guard weatherModel.hasData else { return 0 }
		let temp = maxTemp( forSection: section )
		
		print( "Max temp for section: \( section ) = \( temp )" )
		
		guard let sectionArray = groupedHourlyWeatherByDayCache[section] else
		{
			delegate?.onGeneralFailure()
			return 0
		}
		let tempFunc = self.englishMode ? weatherModel.hourlyTempF : weatherModel.hourlyTempC
		var index = 0
		for hour in 0..<sectionArray.count
		{
			guard let hourTemp = tempFunc( hour, sectionArray ) else
			{
				delegate?.onGeneralFailure()
				return 0
			}
			let numericHourTemp = Int( hourTemp ) ?? 0
			if numericHourTemp == temp
			{
				index = hour
				break
			}
		}
		
		return index
	}
	
	fileprivate func maxTemp( forSection section: Int ) -> Int
	{
		let tempFunc = englishMode ? weatherModel.hourlyTempF : weatherModel.hourlyTempC
		guard let sectionArray = groupedHourlyWeatherByDayCache[section] else
		{
			delegate?.onGeneralFailure()
			return 0
		}
		
		var tempArray = [Int]()
		for i in 0..<sectionArray.count
		{
			guard let temp = tempFunc( i, sectionArray ) else
			{
				delegate?.onGeneralFailure()
				return 0
			}
			let numericTemp = Int( temp ) ?? 0
			tempArray.append( numericTemp )
		}
		
		guard let max = tempArray.max() else
		{
			delegate?.onGeneralFailure()
			return 0
		}
		return max
	}
	
	fileprivate func groupedHourlyWeatherByDay() -> [Int: HourlyData]
	{
		var grouped = [Int: HourlyData]()
		let hourlyModels = self.hourlyModels()
		for ( index, hour ) in hourlyModels.enumerated()
		{
			guard let epoch = weatherModel.hourlyUnixTimestamp( forHour: index, from: hourlyModels ) else
			{
				delegate?.onGeneralFailure()
				return [0: [["": nil]]]
			}
			guard let epochNum = Double( epoch ) else
			{
				delegate?.onGeneralFailure()
				return [0: [["": nil]]]
			}
			let day = epochNum.dayFromEpoch()
			
			if !grouped.keys.contains( day )
			{
				grouped[day] = [hour]
			}
			else
			{
				grouped[day]!.append( hour )
			}
		}
		
		var ctr = 0
		for key in grouped.keys.sorted()
		{
			switchKey( &grouped, fromKey: key, toKey: ctr )
			ctr = ctr + 1
		}
		
		return grouped
	}
	
	fileprivate func groupedMinTempItemByDayCache() -> [Int: Int]
	{
		var grouped = [Int: Int]()
		let dayCount = numberOfSections()
		for i in 0..<dayCount
		{
			let minTempItem = itemOfFirstMin( forSection: i )
			grouped[i] = minTempItem
		}
		
		return grouped
	}
	
	fileprivate func groupedMaxTempItemByDayCache() -> [Int: Int]
	{
		var grouped = [Int: Int]()
		let dayCount = numberOfSections()
		for i in 0..<dayCount
		{
			let minTempItem = itemOfFirstMax( forSection: i )
			grouped[i] = minTempItem
		}
		
		return grouped
	}
	
	fileprivate var imageCache = NSCache<AnyObject, AnyObject>()
	fileprivate var tintCache = NSCache<AnyObject, AnyObject>()
	fileprivate var groupedHourlyWeatherByDayCache = [Int: HourlyData]()
	fileprivate var groupedMinTempByDayCache = [Int: Int]()
	fileprivate var groupedMaxTempByDayCache = [Int: Int]()
	
	fileprivate let weatherModel = WeatherModel.sharedInstance
	fileprivate let weatherAPI = WeatherAPI( requestor: AlamofireRequestor() )
}
