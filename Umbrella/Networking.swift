//
//  Networking.swift
//  Umbrella
//
//  Created by Logan Blevins on 11/16/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import Foundation
import Alamofire

// Let's be Swifty!
//
enum Result<T>
{
	case success( T )
	case failure( Error? )
}

enum NetworkError: Error, CustomStringConvertible
{
	case invalid( String? )
	case cannotParse( String? )
	
	var description: String
	{
		switch self
		{
		case .invalid( let reason ):
			return "Unable to make request: \( reason ?? "Unknown" )"
			
		case .cannotParse( let reason ):
			return "Unable to parse response: \( reason ?? "Unknown" )"
		}
	}
}

func showNetworkActivity( show: Bool )
{
	UIApplication.shared.isNetworkActivityIndicatorVisible = show
}

// Generic requestor interface useful to make unit testing easier down the road.
//
protocol Requestor
{
	func request( url: URL, completion: @escaping(_ result: Result<Any> ) -> Void )
	func requestJSON( url: URL, completion: @escaping(_ result: Result<Any> ) -> Void )
}

// Specific implementation using Alamofire 🔥.
//
struct AlamofireRequestor: Requestor
{
	func requestJSON( url: URL, completion: @escaping(_ result: Result<Any> ) -> Void )
	{
		Alamofire.request( url, method: .get ).validate().responseJSON()
		{
			response in
			
			if let data = response.data, response.result.isSuccess
			{
				print( response.debugDescription )
				completion( .success( data ) )
			}
			else
			{
				completion( .failure( NetworkError.invalid( response.result.error?.localizedDescription ) ) )
			}
		}
	}
	
	func request( url: URL, completion: @escaping(_ result: Result<Any> ) -> Void )
	{
		Alamofire.request( url, method: .get ).validate().response()
		{
			response in
			
			if let data = response.data
			{
				print( response.response.debugDescription )
				completion( .success( data ) )
			}
			else
			{
				completion( .failure( NetworkError.invalid( response.error.debugDescription ) ) )
			}
		}
	}
}
