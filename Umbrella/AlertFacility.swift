//
//  AlertFacility.swift
//  Umbrella
//
//  Created by Logan Blevins on 11/21/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import UIKit

protocol AlertFacility
{
	func displayError( completion: @escaping(_ response: Bool ) -> Void )
	func displayBadZipCode( completion: @escaping() -> Void )
}

struct Alert: AlertFacility
{
	init( parent: UIViewController )
	{
		self.parent = parent
	}
	
	func displayError( completion: @escaping(_ response: Bool ) -> Void )
	{
		let alert = UIAlertController( title: "Something went wrong...",
		                               message: "Try to get the weather again?",
		                               preferredStyle: .alert )
		alert.addAction( .init( title: "No", style: .default )
		{
			_ in
			completion( false )
		} )
		
		alert.addAction( .init( title: "Yes", style: .default )
		{
			_ in
			completion( true )
		} )
		
		parent.present( alert, animated: true, completion: nil )
	}
	
	func displayBadZipCode( completion: @escaping() -> Void )
	{
		let alert = UIAlertController( title: "Oops, invalid zip code.",
		message: nil,
		preferredStyle: .alert )
		alert.addAction( .init( title: "Ok", style: .default )
		{
			_ in
			completion()
		} )
		parent.present( alert, animated: true, completion: nil )
	}

	fileprivate let parent: UIViewController
}
