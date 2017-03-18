//
//  Utility.swift
//  Umbrella
//
//  Created by Logan Blevins on 11/17/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import Foundation

func switchKey<T, U>(_ myDict: inout [T:U], fromKey: T, toKey: T )
{
	if let entry = myDict.removeValue( forKey: fromKey )
	{
		myDict[toKey] = entry
	}
}
