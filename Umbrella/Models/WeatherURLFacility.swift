//
//  WeatherURLFacility.swift
//  Umbrella
//
//  Created by Logan Blevins on 3/18/17.
//  Copyright © 2017 Logan Blevins. All rights reserved.
//

import Foundation

enum WeatherURLFacilityError: Error, CustomStringConvertible
{
	case BadZipCode
	case BadURL
	
	var description: String
	{
		switch self
		{
		case .BadZipCode:
			return "Invalid zip code format."

		case .BadURL:
			return "Bad URL."
		}
	}
}

struct WeatherURLFacility
{
	/**
	Initializer
	
	- parameter zipCode: The zip code for desired location
	
	- returns: The initialized object or nil
	*/
	init?( zipCode: String? )
	{
		self.zipCode = zipCode
		
		if !validZipCode()
		{
			return nil
		}
	}
	
    var url: Foundation.URL?
	{
        get
		{
            var urlComponents = URLComponents()
            urlComponents.scheme = "https"
            urlComponents.host = "api.wunderground.com"
            urlComponents.path = "/api/\( Constants.APIStrings.WeatherAPIKey )/conditions/hourly/q/\( zipCode! ).json"
            
            return urlComponents.url
        }
    }
	
	/**
	Checks for valid zip code format

	- returns: Determination for valid zip code
	*/

	// Zip codes can either be only 5 numerics, or
	// separated with a `-`, with the last component 4 numerics.
	//
	fileprivate func validZipCode() -> Bool
	{
		let separated = zipCode.components( separatedBy: "-" )
		let invalidCharacters = CharacterSet.decimalDigits.inverted
		
		let componentOne = separated.first
		guard componentOne?.count == 5 else { return false }
		
		switch separated.count
		{
		case 1:
			return componentOne?.rangeOfCharacter( from: invalidCharacters ) == nil
			
		case 2:
			let componentTwo = separated[1]
			guard componentTwo.count == 4 else { return false }
			return componentTwo.rangeOfCharacter( from: invalidCharacters ) == nil
			
		default:
			return false
		}
	}
	
	fileprivate let zipCode: String!
}
