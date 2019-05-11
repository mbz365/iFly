//
//  SignInViewController.swift
//  iFly
//
//  Created by Mike Buzzard on 2/22/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

import UIKit

// Structure for holding user information

struct LOGIN: Codable {
    let success: Int
    let message: String
    let firstName: String
    let lastName: String
    let userId: String
    let email: String
}

class SignInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var mapViewBtn: UIButton!
    @IBOutlet weak var cameraViewBtn: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var signInLabel: UILabel!
    
    let currentUser = User()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)

        // Set delegates for dismissing keyboard
        self.userName.delegate = self;
        self.userPassword.delegate = self;
    }
    
    // signInButtonPressed() - Process action when user taps sign in button
    @IBAction func signInButtonPressed(_ sender: Any) {
        print("Sign in button tapped")
        self.view.endEditing(true)
        let username = userName.text
        let password = userPassword.text
        
        // Check if username or password field is empty
        if (username?.isEmpty)! || (password?.isEmpty)!
        {
            // Display error message and return
            displayMessage(userMessage: "Please fill out all required fields")
            
            return
        }
        
        // Create activity indicator
        let myActivityIndicator =
            UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        
        // Position activity indicator in the center of the main view
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = false
        
        // Start Activity Indicator
        myActivityIndicator.startAnimating()
        
        // Add activity indicator to view
        view.addSubview(myActivityIndicator)
        
        // Send HTTP request to perform sign in
        // Processing php request
        let url = URL(string: "https://afternoon-thicket-42652.herokuapp.com/")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let parameters: [String: Any] = [
            "firstName": "",
            "lastName": "",
            "userName": userName.text!,
            "userPassword": userPassword.text!,
            "mode": "login"
        ]
        
        request.httpBody = parameters.percentEscaped().data(using: .utf8)
        
        // Check if network connection is not working
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {
                    print("error", error ?? "Unknown error")
                    return
            }
            
            // Check for http errors
            guard (200 ... 299) ~= response.statusCode else {
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            // Convert php response into string
            let responseString = String(data: data, encoding: .utf8)
            let jsonData = responseString?.data(using: .utf8)!
            
            // Create a JSON Decoder object
            let decoder = JSONDecoder()
            
            // Parse JSON and store it in LOGIN struct
            let login = try! decoder.decode(LOGIN.self, from: jsonData!)

            // Set current user
            self.currentUser.isLoggedIn = Int32(login.success)
            self.currentUser.firstName = login.firstName
            self.currentUser.lastName = login.lastName
            self.currentUser.userId = Int32(login.userId) ?? 0
            self.currentUser.username = login.email
            
            self.removeActivityIndicator(activityIndicator: myActivityIndicator)

            // Display success or failure message
            
            if (self.currentUser.isLoggedIn == 1) {
                self.performSegue(withIdentifier: "loginSegue", sender: self)
            }
            else {
                self.displayMessage(userMessage: login.message)
            }
        }
        
        task.resume()

    }
    
    // registerButtonPressed() - Process action when user taps register button
    @IBAction func registerButtonPressed(_ sender: Any) {
        print("Register button tapped")
        
        let registerViewController = self.storyboard?.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
        
        self.present(registerViewController, animated: true)
    }
    
    func displayMessage(userMessage:String) -> Void {
        DispatchQueue.main.async
            {
                let alertController = UIAlertController(title: "Alert", message: userMessage, preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default)
                { (action:UIAlertAction!) in
                    print("Ok button tapped")
                    DispatchQueue.main.async
                        {
                            self.dismiss(animated: true, completion: nil)
                    }
                }
                
                alertController.addAction(OKAction)
                self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // removeActivityIndicator() - removes activity indicator from view
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView)
    {
        DispatchQueue.main.async
            {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
        }
    }
    
    // Dissmisses keyboard if user presses outside of text entry
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true);
    }
    
    @IBAction func mapViewBtnAction(_ sender: Any) {
        // Comment to require login
        self.performSegue(withIdentifier: "mapViewSegue", sender: mapViewBtn)
        
        // Uncomment to reenable login
        /*
        if (self.currentUser.isLoggedIn == 1) {
            self.performSegue(withIdentifier: "mapViewSegue", sender: mapViewBtn)
        }
        else {
            displayMessage(userMessage: "Please log in first.")
        }
        */
    }
    
    @IBAction func cameraViewBtnAction(_ sender: Any) {
        
        // Comment to require login
        self.performSegue(withIdentifier: "cameraViewSegue", sender: cameraViewBtn)
        
        // Uncomment to reenable login
        /*
        if (self.currentUser.isLoggedIn == 1) {
            self.performSegue(withIdentifier: "cameraViewSegue", sender: cameraViewBtn)
        }
        else {
            displayMessage(userMessage: "Please log in first.")
        }
        */
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*
        if (segue.identifier == "cameraViewSegue") {
            if let viewController = segue.destination as? DJICameraViewController {
                viewController.currentUser = self.currentUser
            }
        }
        else if (segue.identifier == "mapViewSegue") {
            if let viewController = segue.destination as? MapViewController {
                viewController.currentUser = self.currentUser
            }
        }
        */
        if (segue.identifier == "loginSegue") {
            if let viewController = segue.destination as? LoggedInViewController {
                viewController.currentUser = self.currentUser
            }
        }
        
        
    }
    
    // Dissmiss keyboard when return key is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

