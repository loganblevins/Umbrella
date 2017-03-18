//
//  AppDelegate.swift
//  Umbrella
//
//  Created by Logan Blevins on 3/18/17.
//  Copyright © 2017 Logan Blevins. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
	
    func applicationDidBecomeActive(_ application: UIApplication )
	{
		MainViewController().applicationdidBecomeActive()
    }
	
	fileprivate func MainViewController() -> MainViewController
	{
		return ( window?.rootViewController as! MainViewController )
	}
}
