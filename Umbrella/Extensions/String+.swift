//
//  String+.swift
//  Umbrella
//
//  Created by Logan Blevins on 3/18/17.
//  Copyright © 2017 Logan Blevins. All rights reserved.
//

import Foundation

extension String
{
    func weatherIconURL( highlighted: Bool ) -> URL?
	{
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "YOUR_URL_GOES_HERE"
        
        if highlighted
		{
            urlComponents.path = "/\( self )-selected.png"
        }
		else
		{
            urlComponents.path = "/\( self ).png"
        }
        
        return urlComponents.url
    }
	
	func trimmed() -> String
	{
		return self.trimmingCharacters( in: .whitespaces )
	}
	
	var count: Int
	{
		return self.utf16.count
	}
}
