//
//  RegisterController.swift
//  Missito
//
//  Created by George Poenaru on 25/05/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit
import JWT
import CoreTelephony
import FontAwesome_swift
import libPhoneNumber_iOS
import MBProgressHUD

struct Country {
    let countryCode: String
    let countryName: String
    let dialCode: String
    let flagReference: String?
}

extension Country: Equatable {}

func ==(lhs: Country, rhs: Country) -> Bool {
    return lhs.countryCode == rhs.countryCode
}


class RegisterController: UIViewController, Customizable, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    var country: Country?
    let phoneUtil = NBPhoneNumberUtil()
    var phoneNumber: String?
    var progress: MBProgressHUD?
    
    private var otpToken: String?
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var countryFlagImage: UIImageView!
    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var dialCodeTextField: UITextField!
    @IBOutlet weak var chevronIcon: UIImageView!
    @IBOutlet weak var termsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTermsLabel()
        
        chevronIcon.image = UIImage.fontAwesomeIcon(name: .chevronRight, textColor: UIColor.missitoLightGray,
            size: CGSize(width: 26, height: 26)
        )
        
        continueButton.setBackgroundImage(UIImage.imageWithColor(color: UIColor.missitoBlue), for: .normal)
        continueButton.setBackgroundImage(UIImage.imageWithColor(color: UIColor.missitoLightBlue), for: .highlighted)
        continueButton.setBackgroundImage(UIImage.imageWithColor(color: UIColor.lightGray), for: .disabled)
        

        let tapper = UITapGestureRecognizer(target: self, action:#selector(hideKeyboard))
        tapper.cancelsTouchesInView = false
        tapper.delegate = self
        view.addGestureRecognizer(tapper)
        staticMissitoNavigationBar()
        
        //Initial country set by locale
        let code = Utils.currentCountryCode ?? "us"
        country = Utils.countryForCountryCode(code) ?? Utils.countryForCountryCode("us")
        setUiForCountry(country)
        dialCodeTextField.text = "+" + country!.dialCode
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text, textField == dialCodeTextField else { return true }
        
        let finalString = (text as NSString).replacingCharacters(in: range, with: string)
        
        // Return false if finalString is more than 4 characters (dial code max 3 numbers and '+')
        if !finalString.starts(with: "+") || finalString.components(separatedBy: "+").count != 2 || finalString.count > 4 {
            return false
        }
        
        let code = finalString.replacingOccurrences(of: "+", with: "")
        setUiForCountry(finalString.count >= 2 ? Utils.countryForDialCode(code) : nil)
        
        return finalString.count <= 4
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !((touch.view?.isKind(of: UIControl.self)) ?? false)
    }
    
    func setupTermsLabel() {
        var colorAttrs = [String: AnyObject]()
        var fontAttrs = [String: AnyObject]()
        colorAttrs[NSForegroundColorAttributeName] = UIColor.missitoLightBlue
        colorAttrs[NSFontAttributeName] = UIFont.SFUIDisplayLight(size: 14.0)
        fontAttrs[NSFontAttributeName] = UIFont.SFUIDisplayLight(size: 14.0)
        
        let termsStr = NSMutableAttributedString()
        termsStr.append(NSAttributedString(string: "By signing up, you agree\nto our ", attributes: fontAttrs))
        termsStr.append(NSAttributedString(string: "Terms of Service", attributes: colorAttrs))
        termsStr.append(NSAttributedString(string:" and ", attributes: fontAttrs))
        termsStr.append(NSAttributedString(string: "Privacy policy", attributes: colorAttrs))
        
        termsLabel.attributedText = termsStr
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.topItem?.title = "Account setup"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
        super.viewWillDisappear(true)
    }
    
    
    func hideKeyboard() {
        view.endEditing(true)
    }
    
    func setUiForCountry(_ country: Country?) {
        guard let country = country else {
            countryFlagImage.image = UIImage(named: "no_flag")
            countryNameLabel.text = "Bad dialing code"
            countryNameLabel.textColor = UIColor.badDialCodeOrange
            dialCodeTextField.textColor = UIColor.badDialCodeOrange
            continueButton.isEnabled = false
            self.country = nil
            return
        }
        
        // In case country was changed by editing dial code in TextField
        // So when user opens country list correct country is selected
        self.country = country
        self.continueButton.isEnabled = !phoneTextField.text!.isEmpty
        
        countryNameLabel.textColor = UIColor.missitoDarkGray
        dialCodeTextField.textColor = UIColor.missitoDarkGray
        countryNameLabel.text = country.countryName
        if let flag = UIImage(named: (country.flagReference ?? "")) {
            countryFlagImage.image = flag
        } else {
            countryFlagImage.image = UIImage.fontAwesomeIcon(name: .flagO, textColor: UIColor.fountainBlue, size: countryFlagImage.frame.size)
        }
    }
    
    func checkPhoneText() {
        
        func warnTooShort() {
            Utils.alert(viewController: self, title: "Wrong phone number!", message: "The phone number you entered is too short for \(country!.countryName).")
        }
        
        func warnTooLong() {
            Utils.alert(viewController: self, title: "Wrong phone number!", message: "The phone number you entered is too long for \(country!.countryName).")
        }
        
        func warnBadFormat() {
            
        }

        guard country != nil else {
            // Should never enter here
            return
        }

        var phoneNumber: NBPhoneNumber!
        do {
            phoneNumber = try phoneUtil.parse(phoneTextField.text!, defaultRegion: country?.countryCode)
        } catch {
            switch (error as NSError).domain {
                // When number is less than 1-3 (varies by country)
            case "NOT_A_NUMBER":
                warnTooShort()
                // When number is too long
            case "TOO_LONG":
                warnTooLong()
            default:
                break
            }
            return
        }
        
        let validationResult = phoneUtil.isPossibleNumber(withReason: phoneNumber, error: nil)
        switch validationResult {
        case .TOO_SHORT:
            // When number is > 3 but still shorter than possible
            warnTooShort()
        case .IS_POSSIBLE:
            self.phoneNumber = try? phoneUtil.format(phoneNumber, numberFormat: .E164)
            verify()
            return
        case .TOO_LONG:
            // Is triggered when number is too long, typpicaly 5~ digits above possible, numbers longer than this are handled by parse method at the beggining of function
            warnTooLong()
        default:
            break
        }
    }
    
    @IBAction func onPhoneTextChange(_ sender: Any) {
        // Filter characters to match only from 0 to 9
        phoneTextField.text = String(phoneTextField.text!.filter({"0123456789".contains($0)}))
        
        if phoneTextField.text!.isEmpty {
            continueButton.isEnabled = false
        } else if country != nil {
            continueButton.isEnabled = true
        }
    }

    @IBAction func onContinueTap(_ sender: Any) {
        phoneTextField.resignFirstResponder()
        checkPhoneText()
    }
    
    @IBAction func onCountryTap(_ sender: Any) {
        performSegue(withIdentifier: "countries", sender: nil)
    }
    
    // MARK: - Navigation
    
    func verify() {
        guard let phoneNumber = self.phoneNumber,
            let _ = self.country?.dialCode else {
                return
        }
        let remainingTime = Constants.SMS_RESEND_DELAY - (Utils.getCurrentTimeInMillis() - DefaultsHelper.getLastCodeSendTime())
        guard remainingTime <= 0 else {
            let sec = Int((Double(remainingTime) / 1000.0 + 0.5).rounded())
            Utils.alert(viewController: self, title: "Please wait", message: "Try again in \(sec) seconds")
            return
        }
        
        continueButton.isEnabled = false
        progress = Utils.showProgress(message: "", view: view)
        
        print("Phone: " + phoneNumber)
        
        APIRequests.requestOTP(phone: phoneNumber) { (response, error) in
            if let response = response {
                self.otpToken = response.token
                self.performSegue(withIdentifier: "verify", sender: self.next)
            } else {
                if let error = error {
                    print("requestOTP error: " + error.localizedDescription)
                } else {
                    print("Error: requestOTP returned empty response")
                }
                Utils.alert(viewController: self, title: "An error occured", message: (error?.localizedDescription ?? "Please try again later"))
            }
            self.continueButton.isEnabled = true
            self.progress?.hide(animated: true)
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "countries" {
            let controller = segue.destination as! CountryPickerController
            controller.selectedCountry = self.country
            controller.completion = {
                country in
                self.country = country
                self.setUiForCountry(country)
                let dialCode = country?.dialCode != nil ? "+" + country!.dialCode : nil
                self.dialCodeTextField.text = dialCode
            }
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        } else if segue.identifier == "verify" {
            guard let phoneNumber = self.phoneNumber else {
                    let alert = UIAlertController(title: "Oops!", message:"Failed to retrieve phone number or country code", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
                    self.present(alert, animated: true){}
                    return
            }
            
            let controller = segue.destination as! VerificationController
            controller.otpToken = otpToken
            controller.phone = phoneNumber
        }
    }
}
