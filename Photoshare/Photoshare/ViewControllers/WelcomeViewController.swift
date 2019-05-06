//
//  WelcomeViewController.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/24/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit
import ProgressHUD

class WelcomeViewController: UIViewController {

    
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextfield: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var initialButtonLogin: UIButton!
    @IBOutlet weak var initialButtonRegister: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showInitialButtons()
    }
    
    // MARK: IBActions
    
    @IBAction func initiateLogin(_ sender: Any) {
        hideInitialButtons()
        self.emailTextField.isHidden = false
        self.passwordTextField.isHidden = false
        self.loginButton.isHidden = false
    }
    
    @IBAction func initiateRegistration(_ sender: Any) {
        hideInitialButtons()
        self.emailTextField.isHidden = false
        self.passwordTextField.isHidden = false
        self.confirmPasswordTextfield.isHidden = false
        self.registerButton.isHidden = false
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        dismissKeyboard()
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            loginUser()
        } else {
            ProgressHUD.showError("Email or Password is invalid")
        }
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        dismissKeyboard()
        if emailTextField.text != "" && passwordTextField.text != ""  && confirmPasswordTextfield.text != "" {
            if passwordTextField.text == confirmPasswordTextfield.text {
                registerUser()
            } else {
                ProgressHUD.showError("Passwords don't match! ")
            }
        } else {
            ProgressHUD.showError("Invalid Resgistration")
        }    }
    
    @IBAction func backgroundTap(_ sender: Any) {
        dismissKeyboard()
    }
    
    
    // MARK: Helper Functions
    func showInitialButtons(){
        emailTextField.isHidden = true
        passwordTextField.isHidden = true
        confirmPasswordTextfield.isHidden = true
        loginButton.isHidden = true
        registerButton.isHidden = true
        initialButtonLogin.isHidden = false
        initialButtonRegister.isHidden = false
        
    }
    func hideInitialButtons(){
        initialButtonLogin.isHidden = true
        initialButtonRegister.isHidden = true
        
    }
    
    func loginUser(){
        ProgressHUD.show("Logging in...")
        User.loginUserWith(email:emailTextField.text!, password: passwordTextField.text!) { (error) in
            
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            } else{
                self.presentApp()
            }
        }
    }
    
    func registerUser(){
        dismissKeyboard()
        performSegue(withIdentifier: "finishRegistration", sender: self)
        cleanTextFields()
        
    }
    
    func dismissKeyboard(){
        self.view.endEditing(false)
    }
    
    func cleanTextFields(){
        emailTextField.text = ""
        passwordTextField.text = ""
        confirmPasswordTextfield.text = ""
    }
    
    
    
    func presentApp(){
        ProgressHUD.dismiss()
        cleanTextFields()
        dismissKeyboard()
        
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID:User.userId()])
        
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        self.present(mainView, animated: true, completion: nil)
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "finishRegistration" {
            let vc = segue.destination as! FinishRegistrationViewController
            vc.email = emailTextField.text!
            vc.password = passwordTextField.text!
        }
    }
}
