//
//  WeatherModel.swift
//  Umbrella
//
//  Created by Logan Blevins on 11/17/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import Foundation
import UIKit

protocol WeatherModelDelegate: class
{
	func onModelUpdated()
}

class WeatherModel
{
	// MARK: Singleton implementation
	//
	private init() {}
	static let sharedInstance = WeatherModel()
	
	// MARK: Public API
	//
	weak var delegate: WeatherModelDelegate?
	
	@discardableResult
	func maybeUpdate(_ result: Result<Any> ) -> Bool
	{
		switch result
		{
		case .success( let weather as Weather ):
			self.currentWeather = weather.current
			self.hourlyWeather = weather.hourly
			delegate?.onModelUpdated()
			return true
			
		case .failure( _ ):
			return false
			
		default:
			return false
		}
	}
	
	var hourlyModels: HourlyData
	{
		return hourlyWeather
	}
	
	var hasData: Bool
	{
		return !currentWeather.isEmpty && !hourlyWeather.isEmpty
	}
	
	// MARK: Current weather
	//
	var currentCity: String?
	{
		return currentWeather[key( from: CurrentWeather.currentCity )] ?? nil
	}
	
	var currentTempF: String?
	{
		return currentWeather[key( from: CurrentWeather.currentTempF )] ?? nil
	}
	
	var currentTempC: String?
	{
		return currentWeather[key( from: CurrentWeather.currentTempC )] ?? nil
	}
	
	var currentCondition: String?
	{
		return currentWeather[key( from: CurrentWeather.currentCondition )] ?? nil
	}
	
	// MARK: Hourly weather
	//
	func hourlyPrettyTimestamp( forHour hour: Int, from weather: HourlyData ) -> String?
	{
		return weather[hour][key( from: HourlyWeather.hourlyPrettyTimestamp )] ?? nil
	}
	
	func hourlyUnixTimestamp( forHour hour: Int, from weather: HourlyData ) -> String?
	{
		return weather[hour][key( from: HourlyWeather.hourlyUnixTimestamp )] ?? nil
	}
	
	func hourlyIconURL( forHour hour: Int, highlighted: Bool, from weather: HourlyData ) -> URL?
	{
		let iconString = weather[hour][key( from: HourlyWeather.hourlyIcon )] ?? nil
		let url = iconString?.weatherIconURL( highlighted: highlighted )
		return url
	}
	
	func hourlyTempF( forHour hour: Int, from weather: HourlyData ) -> String?
	{
		return weather[hour][key( from: HourlyWeather.hourlyTempF )] ?? nil
	}
	
	func hourlyTempC( forHour hour: Int, from weather: HourlyData ) -> String?
	{
		return weather[hour][key( from: HourlyWeather.hourlyTempC )] ?? nil
	}
	
	// MARK: Implementation Details
	//
	fileprivate func key( from enumCase: WeatherKeyable ) -> String
	{
		return String( describing: enumCase )
	}
	
	fileprivate var currentWeather = CurrentData()
	fileprivate var hourlyWeather = HourlyData()
}
