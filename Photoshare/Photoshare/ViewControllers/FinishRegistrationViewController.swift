//
//  FinishRegistrationViewController.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/25/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit
import ImagePicker
import ProgressHUD

class FinishRegistrationViewController: UIViewController, ImagePickerDelegate {

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    
    
    var email: String!
    var password: String!
    var avatarImage: UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avatarImageView.isUserInteractionEnabled = true
        
    }
    
    
    
    // MARK: IBActions
    
    @IBAction func avatarImageViewTap(_ sender: Any) {
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.imageLimit = 1
        present(imagePickerController, animated: true, completion: nil)
        dismissKeyboard()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        dismissKeyboard()
        ProgressHUD.show("Registering...")
        
        let valid: Bool = ((firstNameTextField.text != "") && (lastNameTextField.text != "") && (cityTextField.text != ""))
        if valid {
            User.registerUserWith(email: email!, password: password!, firstName: firstNameTextField.text!, lastName: lastNameTextField.text!) { (error) in
                if error != nil {
                    ProgressHUD.dismiss()
                    ProgressHUD.showError(error!.localizedDescription)
                    return
                } else {
                    self.registerUser()
                }
            }
        } else {
            ProgressHUD.showError("Invalid Registration")
        }
    }
    @IBAction func cancelButtonPressed(_ sender: Any) {
        cleanTextFields()
        dismissKeyboard()
        performSegue(withIdentifier: "startOver", sender: self)
    }
    
    
    // MARK: Helpers
    
    func cleanTextFields(){
        firstNameTextField.text = ""
        lastNameTextField.text = ""
        cityTextField.text = ""
        
    }
    
    func dismissKeyboard(){
        self.view.endEditing(false)
    }
    
    func registerUser(){
        let fullName = firstNameTextField.text! + " " + lastNameTextField.text!
        var tempDictionary: Dictionary = [kFIRSTNAME: firstNameTextField.text!,kLASTNAME: lastNameTextField.text!,
                                          kFULLNAME: fullName,kCITY: cityTextField.text!] as [String:Any]
        
        if self.avatarImage == nil {
            imageFromInitials(firstName: firstNameTextField.text!, lastName: lastNameTextField.text!) { (avatarFromInitials) in
                let avatarImage = UIImageJPEGRepresentation(avatarFromInitials, 0.5)
                let avatarString = avatarImage?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                tempDictionary[kAVATAR] = avatarString
                self.finalizeRegistration(values: tempDictionary)
            }
        } else {
            let avatarImage = UIImageJPEGRepresentation(self.avatarImage!, 0.3)
            let avatarString = avatarImage?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            tempDictionary[kAVATAR] = avatarString
            self.finalizeRegistration(values: tempDictionary)
        }
        
    }
    
    func finalizeRegistration(values : [String:Any]){
        updateCurrentUserInFirestore(withValues: values) { (error) in
            if error != nil {
                DispatchQueue.main.async {
                    ProgressHUD.showError(error!.localizedDescription)
                }
                return
            }
            ProgressHUD.dismiss()
            self.goToApplication()
        }
    }
    
    func goToApplication(){
        cleanTextFields()
        dismissKeyboard()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID:User.userId()])
        
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        self.present(mainView, animated: true, completion: nil)
    }
    
    // MARK: ImagePicker Delegate
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        if images.count > 0 {
            self.avatarImage = images.first!
            self.avatarImageView.image = self.avatarImage?.circleMasked
        }
        
        self.dismiss(animated: true, completion: nil)

    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        self.dismiss(animated: true, completion: nil)

    }
    
    
}
