//
//  StandardDefaults.swift
//  Umbrella
//
//  Created by Logan Blevins on 11/16/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import Foundation

class StandardDefaults
{
	var zipCode: String?
	{
		get
		{
			return getValue( key: zipCodeKey ) ?? nil
		}
		set
		{
			standardDefaults.set( newValue, forKey: zipCodeKey )
		}
	}
	
	var englishMode: Bool
	{
		get
		{
			return getValue( key: englishModeKey ) ?? true
		}
		set
		{
			standardDefaults.set( newValue, forKey: englishModeKey )
		}
	}
	
	static let sharedInstance = StandardDefaults()
	private init() {}
	
	fileprivate let standardDefaults = UserDefaults.standard
	fileprivate let zipCodeKey = "zipCodeKey"
	fileprivate let englishModeKey = "englishModeKey"
	
	fileprivate func getValue<T>( key: String ) -> T?
	{
		guard let objectValue = standardDefaults.object( forKey: key ) else
		{
			return nil
		}
		
		return objectValue as? T
	}
}
