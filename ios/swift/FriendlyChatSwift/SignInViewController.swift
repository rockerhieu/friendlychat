//
//  Copyright (c) 2015 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

import Firebase
import MBProgressHUD

@objc(SignInViewController)
class SignInViewController: UIViewController {

  @IBOutlet weak var emailField: UITextField!
  @IBOutlet weak var passwordField: UITextField!

  override func viewDidAppear(_ animated: Bool) {
    if let user = FIRAuth.auth()?.currentUser {
      self.signedIn(user)
    }
  }

  @IBAction func didTapSignIn(_ sender: AnyObject) {
    // Sign In with credentials.
    guard let email = emailField.text, let password = passwordField.text else { return }
    MBProgressHUD.showAdded(to: self.view, animated: true)
    FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
      MBProgressHUD.hide(for: self.view, animated: true)
      if let error = error {
        self.showAlert(withTitle: "Error", message: error.localizedDescription)
        return
      }
      self.signedIn(user!)
    }
  }
  @IBAction func didTapSignUp(_ sender: AnyObject) {
    guard let email = emailField.text, let password = passwordField.text else { return }
    MBProgressHUD.showAdded(to: self.view, animated: true)
    FIRAuth.auth()?.createUser(withEmail: email, password: password) { (user, error) in
      if let error = error {
        MBProgressHUD.hide(for: self.view, animated: true)
        self.showAlert(withTitle: "Error", message: error.localizedDescription)
        return
      }
      self.setDisplayName(user!)
    }
  }

  func setDisplayName(_ user: FIRUser) {
    let changeRequest = user.profileChangeRequest()
    changeRequest.displayName = user.email!.components(separatedBy: "@")[0]
    changeRequest.commitChanges(){ (error) in
      MBProgressHUD.hide(for: self.view, animated: true)
      if let error = error {
        self.showAlert(withTitle: "Error", message: error.localizedDescription)
        return
      }
      self.signedIn(FIRAuth.auth()?.currentUser)
    }
  }

  @IBAction func didRequestPasswordReset(_ sender: AnyObject) {
    let prompt = UIAlertController.init(title: nil, message: "Email:", preferredStyle: .alert)
    let okAction = UIAlertAction.init(title: "OK", style: .default) { (action) in
      let userInput = prompt.textFields![0].text
      if (userInput!.isEmpty) {
        return
      }
      MBProgressHUD.showAdded(to: self.view, animated: true)
      FIRAuth.auth()?.sendPasswordReset(withEmail: userInput!) { (error) in
        MBProgressHUD.hide(for: self.view, animated: true)
        if let error = error {
          self.showAlert(withTitle: "Error", message: error.localizedDescription)
          return
        }
        self.showAlert(withTitle: "Reset password email sent", message: "Please check your mail box!")
      }
    }
    prompt.addTextField(configurationHandler: nil)
    prompt.addAction(okAction)
    present(prompt, animated: true, completion: nil);
  }

  func signedIn(_ user: FIRUser?) {
    MeasurementHelper.sendLoginEvent()

    let gravatar = "https://www.gravatar.com/avatar/\(MD5(string: (user?.email)!)!)"
    AppState.sharedInstance.displayName = user?.displayName ?? user?.email
    AppState.sharedInstance.photoURL = user?.photoURL ?? URL(string: gravatar)
    AppState.sharedInstance.signedIn = true
    let notificationName = Notification.Name(rawValue: Constants.NotificationKeys.SignedIn)
    NotificationCenter.default.post(name: notificationName, object: nil, userInfo: nil)
    performSegue(withIdentifier: Constants.Segues.SignInToFp, sender: nil)
  }

  func MD5(string: String) -> String? {
    guard let messageData = string.data(using:String.Encoding.utf8) else { return nil }
    var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
    
    _ = digestData.withUnsafeMutableBytes {digestBytes in
      messageData.withUnsafeBytes {messageBytes in
        CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
      }
    }
    
    return digestData.map { String(format: "%02hhx", $0) }.joined()
  }
  
  func showAlert(withTitle title:String, message:String) {
    DispatchQueue.main.async {
      let alert = UIAlertController(title: title,
                                    message: message, preferredStyle: .alert)
      let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
      alert.addAction(dismissAction)
      self.present(alert, animated: true, completion: nil)
    }
  }
}
