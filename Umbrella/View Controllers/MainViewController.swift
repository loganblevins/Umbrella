//
//  MainViewController.swift
//  Umbrella
//
//  Created by Logan Blevins on 3/18/17.
//  Copyright © 2017 Logan Blevins. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, MainViewModelDelegate, SettingsViewControllerDelegate
{
	// MARK: Public API
	//
    @IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var cityStateLabel: UILabel!
	@IBOutlet weak var tempLabel: UILabel!
	@IBOutlet weak var conditionsLabel: UILabel!
	
	@IBOutlet weak var currentWeatherView: UIView!
	
	@IBAction func settingsButtonPressed()
	{
		showSettingsViewController()
	}

	override func viewDidLoad()
	{
		self.mainViewModel.delegate = self
	}
	
	func applicationdidBecomeActive()
	{
		guard let zipCode = StandardDefaults.sharedInstance.zipCode else
		{
			showSettingsViewController()
			return
		}
		
		fetchWeather( forZipCode: zipCode )
	}
	
	// MARK: MainViewModelDelegate
	//
	func onGeneralFailure()
	{
		showErrorAlert()
	}
	
	// MARK: SettingsViewControllerDelegate methods
	//
	func onGetWeatherButtonPressed( withZipCode zipCode: String? )
	{
		fetchWeather( forZipCode: zipCode )
	}
	
	func onEnglishModeValueChanged( englishMode: Bool )
	{
		StandardDefaults.sharedInstance.englishMode = englishMode
		mainViewModel.updateStore()
		collectionView.reloadData()
		updateCurrentWeather()
	}
	
	// MARK: Implementation details
	//
	fileprivate func showErrorAlert()
	{
		let alert = Alert( parent: self )
		alert.displayError()
		{
			[weak self] tryAgain in
			guard let strongSelf = self else { return }
			
			if tryAgain
			{
				strongSelf.showSettingsViewController()
			}
		}
	}
	
	fileprivate func showBadZipCodeAlert()
	{
		let alert = Alert( parent: self )
		alert.displayBadZipCode()
		{
			[weak self] in
			guard let strongSelf = self else { return }
			
			strongSelf.showSettingsViewController()
		}
	}
	
	fileprivate func fetchWeather( forZipCode zipCode: String? )
	{
		showNetworkActivity( show: true )
		mainViewModel.fetchWeatherAsync( forZipCode: zipCode )
		{
			[weak self] result in
			guard let strongSelf = self else { return }
			
			defer
			{
				DispatchQueue.main.async
				{
					showNetworkActivity( show: false )
				}
			}
			
			switch result
			{
			case .success( _ ):
				DispatchQueue.main.async
				{
					strongSelf.onFetchSuccess( forZipCode: zipCode )
				}
				
			case .failure( let error ):
				DispatchQueue.main.async
				{
					strongSelf.onFetchFailure( error )
				}
			}
		}
	}
	
	fileprivate func showSettingsViewController()
	{
		if presentedViewController == nil
		{
			guard let settingsViewController = SettingsViewController.storyboardInstance() else { return }
			settingsViewController.delegate = self
			present( settingsViewController, animated: true, completion: nil )
		}
	}
	
	fileprivate func onFetchSuccess( forZipCode zipCode: String? )
	{
		StandardDefaults.sharedInstance.zipCode = zipCode
		collectionView.reloadData()
		updateCurrentWeather()
	}
	
	fileprivate func onFetchFailure(_ error: Error? )
	{
		switch error
		{
		case is WeatherURLFacilityError:
			showBadZipCodeAlert()
			
		default:
			showErrorAlert()
		}
	}
	
	fileprivate func updateCurrentWeather()
	{
		currentWeatherView.backgroundColor = mainViewModel.currentViewBackgroundColor()
		cityStateLabel.text = mainViewModel.currentCityStateViewable()
		tempLabel.text = mainViewModel.currentTempViewable()
		conditionsLabel.text = mainViewModel.currentConditionViewable()
	}
	
	fileprivate func onZipCodeInput( zipCode: String? )
	{
		fetchWeather( forZipCode: zipCode )
	}
	
	let mainViewModel = MainViewModel()
}

// MARK: UICollectionViewDataSource methods
//
extension MainViewController: UICollectionViewDataSource
{
    func numberOfSections( in collectionView: UICollectionView ) -> Int
	{
		return mainViewModel.numberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int ) -> Int
	{
		let count = mainViewModel.numberOfItemsInSection( forSection: section )
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath ) -> UICollectionViewCell
	{
        let cell = collectionView.dequeueReusableCell( withReuseIdentifier: "cell", for: indexPath ) as! CellView
		
		let time = mainViewModel.timeViewable( forIndexPath: indexPath )
		let temp = mainViewModel.tempViewable( forIndexPath: indexPath )
		mainViewModel.iconViewable( forIndexPath: indexPath )
		{
			image, tint in
			
			cell.configureImage( withImage: image, tint: tint )
		}
		
		cell.configureTempLabel( withText: temp.text, color: temp.tint )
		cell.configureTimeLabel( withText: time.text, color: time.tint )
		return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath ) -> UICollectionReusableView
	{
		assert( kind == UICollectionElementKindSectionHeader )
        let header = collectionView.dequeueReusableSupplementaryView( ofKind: kind, withReuseIdentifier: "header", for: indexPath ) as! HeaderView
		let title = mainViewModel.headerTitleViewable( forIndexPath: indexPath )
		header.configureDayLabel( withText: title )
		return header
    }
}
