//
//  RegisterViewController.swift
//  iFly
//
//  Created by Mike Buzzard on 2/22/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

import UIKit

// NOTE: registration currently disabled because web server not set up
// registration can be tested by enabling the individual text fields and
// submission buttons and testing on personal laptop with server running
class RegisterViewController: UIViewController {

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailAddressTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var verifyPasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // registerButtonTapped() - processes user input when they tap register
    //     Note - Needs server side code set up to function properly
    @IBAction func registerButtonTapped(_ sender: Any) {
        print("Register button tapped")
        
        // Validate required fields aren't empty
        if (firstNameTextField.text?.isEmpty)! ||
            (lastNameTextField.text?.isEmpty)! ||
            (emailAddressTextField.text?.isEmpty)! ||
            (passwordTextField.text?.isEmpty)!
        {
            // Display error and return
            displayMessage(userMessage: "Please fill in all required fields")
            return
        }
        
        // Validate that passwords match
        if
            ((passwordTextField.text?.elementsEqual(verifyPasswordTextField.text!))! != true)
        {
            // Display error and return
            displayMessage(userMessage: "Please make sure your passwords match")
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
        
        // Prepare http request for server
        // Set request URL, content type, and method
        let url = URL(string: "https://afternoon-thicket-42652.herokuapp.com/")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        // Set post parameters
        let parameters: [String: Any] = [
            "firstName": firstNameTextField.text!,
            "lastName": lastNameTextField.text!,
            "userName": emailAddressTextField.text!,
            "userPassword": passwordTextField.text!,
            "mode": "register"
        ]
        
        request.httpBody = parameters.percentEscaped().data(using: .utf8) // Set parameters as http body
        
        // create the http request task to be performed
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {                                     // networking error check
                    print("Error", error ?? "Could not connect to network")
                    return
            }
            
            guard (200 ... 299) ~= response.statusCode else {           // http error check
                print("Received error code \(response.statusCode)")
                return
            }
            
            // Store response in string
            let responseString = String(data: data, encoding: .utf8)
            
            // Create delay to test activity indicator
            // Performed asynchronously to avoid locking UI
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
                self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                self.displayMessage(userMessage: responseString!);
            })
        }
        
        task.resume()
        
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
    
    // Generic function to display a message inside an alert controller
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
    
    // Dissmisses keyboard if user presses outside of text entry
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true);
    }
    
}

// Extensions for http requests
extension Dictionary {
    func percentEscaped() -> String {
        return map { (key, value) in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
            }
            .joined(separator: "&")
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
