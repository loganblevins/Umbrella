//
//  SettingsViewController.swift
//  Umbrella
//
//  Created by Logan Blevins on 3/18/17.
//  Copyright © 2017 Logan Blevins. All rights reserved.
//

import UIKit

protocol SettingsViewControllerDelegate: class
{
	func onGetWeatherButtonPressed( withZipCode zipCode: String? )
	func onEnglishModeValueChanged( englishMode: Bool )
}

final class SettingsViewController: UIViewController, UITextFieldDelegate
{
	// MARK: Public API
	//
	override func viewDidLoad()
	{
		if let zipCode = StandardDefaults.sharedInstance.zipCode
		{
			zipCodeTextField.text = zipCode
		}
		
		let englishMode = StandardDefaults.sharedInstance.englishMode
		let segmentIndex = englishMode ? 0 : 1
		segmentedControl.selectedSegmentIndex = segmentIndex
	}
	
	@IBOutlet weak var zipCodeTextField: UITextField!
	@IBOutlet weak var segmentedControl: UISegmentedControl!
	
	weak var delegate: SettingsViewControllerDelegate?
	
	static func storyboardInstance() -> SettingsViewController?
	{
		let storyboard = UIStoryboard( name: String( describing: self ) , bundle: nil )
		return storyboard.instantiateInitialViewController() as? SettingsViewController
	}
	
	@IBAction func segmentedControlChanged(_ sender: UISegmentedControl )
	{
		assert( sender == segmentedControl )
		let pressedSegment = sender.selectedSegmentIndex
		let englishMode = pressedSegment == 0 ? true : false
		delegate?.onEnglishModeValueChanged( englishMode: englishMode )
	}

	@IBAction func blurViewTapped(_ sender: UIGestureRecognizer )
	{
		dismiss( animated: true, completion: nil )
	}
	
	@IBAction func getTheWeatherButtonPressed()
	{
		guard let zipCode = zipCodeTextField.text?.trimmed() else { return }
		if !zipCode.isEmpty
		{
			delegate?.onGetWeatherButtonPressed( withZipCode: zipCode )
			dismiss( animated: true, completion: nil )
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField ) -> Bool
	{
		assert( textField == zipCodeTextField )
		textField.resignFirstResponder()
		return true
	}
}
