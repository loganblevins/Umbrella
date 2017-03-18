//
//  WeatherAPI.swift
//  Umbrella
//
//  Created by Logan Blevins on 11/16/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import Foundation
import Freddy

typealias City = String
typealias Temp = String
typealias Condition = String
typealias Icon = String
typealias Timestamp = String

typealias CurrentData = [String: String?]
typealias HourlyData = [[String: String?]]
typealias Weather = ( current: CurrentData, hourly: HourlyData )

protocol WeatherKeyable
{
	static var allValues: Array<WeatherKeyable> { get }
}

enum CurrentWeather: WeatherKeyable
{
	case currentCity
	case currentTempF
	case currentTempC
	case currentCondition
	
	// Order of elements matter!
	//
	static var allValues: Array<WeatherKeyable> = [ currentCity,
													currentTempF,
													currentTempC,
													currentCondition ]
}

enum HourlyWeather: WeatherKeyable
{
	case hourlyPrettyTimestamp
	case hourlyUnixTimestamp
	case hourlyIcon
	case hourlyTempF
	case hourlyTempC
	
	// Order of elements matter!
	//
	static var allValues: Array<WeatherKeyable> = [ hourlyPrettyTimestamp,
													 hourlyUnixTimestamp,
													 hourlyIcon,
													 hourlyTempF,
													 hourlyTempC ]
}

class WeatherAPI
{
	init( requestor: Requestor )
	{
		self.requestor = requestor
	}
	
	func fetchWeather( forZipCode zipCode: String?, completion: @escaping(_ result: Result<Any> ) -> Void )
	{
		guard let facility = WeatherURLFacility( zipCode: zipCode ) else
		{
			completion( .failure( WeatherURLFacilityError.BadZipCode ) )
			return
		}
		guard let url = facility.url else
		{
			completion( .failure( WeatherURLFacilityError.BadURL ) )
			return
		}
		
		requestor.requestJSON( url: url )
		{
			[weak self] result in
			guard let strongSelf = self else { return }
			
			do
			{
				let weather = try strongSelf.parseAll( result )
				completion( .success( weather ) )
			}
			catch
			{
				let e = error as! NetworkError
				print( e.description )
				completion( .failure( e ) )
			}
		}
	}
	
	func fetchImage( forUrl url: URL, completion: @escaping(_ result: Result<Any> ) -> Void )
	{
		requestor.request( url: url )
		{
			result in
			
			switch result
			{
			case .success( let data ):
				guard let data = data as? Data else
				{
					completion( .failure( NetworkError.invalid( "Bad data." ) ) )
					return
				}
				guard let image = UIImage( data: data ) else
				{
					completion( .failure( NetworkError.invalid( "Bad data." ) ) )
					return
				}
				completion( .success( image ) )
				
			case .failure( let error ):
				let e = error as! NetworkError
				print( e.description )
				completion( .failure( e ) )
			}
		}
	}
	
	fileprivate func parseAll(_ result: Result<Any> ) throws -> Weather
	{
		switch result
		{
		case .success( let data ):
			guard let data = data as? Data else { throw NetworkError.cannotParse( "Bad data." ) }
			do
			{
				let currentWeather: CurrentData = try parseCurrent( data )
				let hourlyWeather: HourlyData = try parseHourly( data )
				let weather = ( currentWeather, hourlyWeather )
				return weather
			}
			catch
			{
				throw error
			}
			
		case .failure( let error ):
			throw error ?? NetworkError.invalid( "Bad data." )
		}
	}
	
	fileprivate func parseCurrent(_ data: Data ) throws -> CurrentData
	{
		// Order of elements matter!
		//
		let funcArray = [ parsedCurrentCity,
		                  parsedCurrentTempF,
		                  parsedCurrentTempC,
		                  parsedCurrentCondition ]
		
		var weatherData = [String: String?]()
		for ( index, parser ) in funcArray.enumerated()
		{
			let endpoint = CurrentWeather.allValues[index]
			let endpointString = String( describing: endpoint )
			let parsed = try parser( data )
			weatherData[endpointString] = parsed
		}
		return weatherData
	}
	
	fileprivate func parseHourly(_ data: Data ) throws -> HourlyData
	{
		// Order of elements matter!
		//
		let funcArray = [ parsedHourlyPrettyTimestamp,
						  parsedHourlyUnixTimestamp,
						  parsedHourlyIcon,
						  parsedHourlyTempF,
						  parsedHourlyTempC ]
		
		var weatherData = [String: String?]()
		var weatherArray = HourlyData()
		
		let json = try JSON( data: data )
		let hoursArray = try json.getArray( at: "hourly_forecast" )
		for hour in hoursArray
		{
			for ( index, parser ) in funcArray.enumerated()
			{
				let endpoint = HourlyWeather.allValues[index]
				let endpointString = String( describing: endpoint )
				let parsed = try parser( hour )
				weatherData[endpointString] = parsed
			}
			weatherArray.append( weatherData )
		}
		return weatherArray
	}
	
	// MARK: Current
	//
	fileprivate func parsedCurrentCity(_ data: Data ) throws -> City
	{
		do
		{
			let json = try JSON( data: data )
			let city = try json.getString( at: "current_observation", "display_location", "full" )
			return city
		}
		catch
		{
			throw NetworkError.cannotParse( #function )
		}
	}
	
	fileprivate func parsedCurrentTempF(_ data: Data ) throws -> Temp
	{
		do
		{
			let json = try JSON( data: data )
			let tempF = try json.getString( at: "current_observation", "temp_f" )
			return tempF
		}
		catch
		{
			throw NetworkError.cannotParse( #function )
		}
	}
	
	fileprivate func parsedCurrentTempC(_ data: Data ) throws -> Temp
	{
		do
		{
			let json = try JSON( data: data )
			let tempC = try json.getString( at: "current_observation", "temp_c" )
			return tempC
		}
		catch
		{
			throw NetworkError.cannotParse( #function )
		}
	}
	
	fileprivate func parsedCurrentCondition(_ data: Data ) throws -> Condition
	{
		do
		{
			let json = try JSON( data: data )
			let condition = try json.getString( at: "current_observation", "weather" )
			return condition
		}
		catch
		{
			throw NetworkError.cannotParse( #function )
		}
	}
	
	// MARK: Hourly
	//
	fileprivate func parsedHourlyPrettyTimestamp(_ json: JSON ) throws -> Timestamp
	{
		do
		{
			let timestamp = try json.getString( at: "FCTTIME", "civil" )
			return timestamp
		}
		catch
		{
			throw NetworkError.cannotParse( #function )
		}
	}
	
	fileprivate func parsedHourlyUnixTimestamp(_ json: JSON ) throws -> Timestamp
	{
		do
		{
			let timestamp = try json.getString( at: "FCTTIME", "epoch" )
			return timestamp
		}
		catch
		{
			throw NetworkError.cannotParse( #function )
		}
	}
	
	fileprivate func parsedHourlyIcon(_ json: JSON ) throws -> Icon
	{
		do
		{
			let icon = try json.getString( at: "icon" )
			return icon
		}
		catch
		{
			throw NetworkError.cannotParse( #function )
		}
	}
	
	fileprivate func parsedHourlyTempF(_ json: JSON ) throws -> Temp
	{
		do
		{
			let tempF = try json.getString( at: "temp", "english" )
			return tempF
		}
		catch
		{
			throw NetworkError.cannotParse( #function )
		}
	}
	
	fileprivate func parsedHourlyTempC(_ json: JSON ) throws -> Temp
	{
		do
		{
			let tempC = try json.getString( at: "temp", "metric" )
			return tempC
		}
		catch
		{
			throw NetworkError.cannotParse( #function )
		}
	}
	
	fileprivate let requestor: Requestor!
}
