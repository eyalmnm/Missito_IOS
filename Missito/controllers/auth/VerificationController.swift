//
//  VerificationController.swift
//  Missito
//
//  Created by George Poenaru on 26/05/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit
import JWT
import MBProgressHUD
import MessageUI

class VerificationController: UIViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate, UITextViewDelegate {
    
    var otpToken: String?
    var phone: String?
    private var progress: MBProgressHUD?
    
    @IBOutlet weak var topTextView: UITextView!
    @IBOutlet weak var codeInputView: MissitoVerificationCodeView!
    @IBOutlet weak var resendCodeLabel: UILabel!
    @IBOutlet weak var didntGetCodeLabel: UILabel!
    @IBOutlet weak var codeTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var codeBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLabels()
        setupConstraints()
        codeInputView.completion = { [weak self] (code: String) in
            self?.login(code)
        }
        
        //Hide Keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(RegisterController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        DefaultsHelper.saveLastCodeSendTime(Utils.getCurrentTimeInMillis())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { 
            self.codeInputView.focus()
        }
    }
    
    func setupConstraints() {
        let size = UIScreen.main.bounds
        if size.height == 568.0 {
            // Adjust constraints for iPhone 5s
            codeTopConstraint.constant = 15
            codeBottomConstraint.constant = 26
        }
    }
    
    func setupLabels() {
        topTextView.delegate = self
        
        updateResendCodeLabel()

        var colorAttrs = [String: Any]()
        var fontAttrs = [String: Any]()
        colorAttrs[NSForegroundColorAttributeName] = UIColor.missitoLightBlue
        colorAttrs[NSFontAttributeName] = UIFont.SFUIDisplayLight(size: 15.0)
        fontAttrs[NSFontAttributeName] = UIFont.SFUIDisplayLight(size: 15.0)
        fontAttrs[NSForegroundColorAttributeName] = UIColor.missitoDarkGray
        
        var topTextAttrs = colorAttrs
        topTextAttrs[NSLinkAttributeName] = "goback"
        let termsStr = NSMutableAttributedString(string: "Enter the verification code\nwe have sent to ", attributes: fontAttrs)
        
        termsStr.append(NSAttributedString(string: Utils.format(phone: phone!), attributes: topTextAttrs))

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        termsStr.addAttributes([NSParagraphStyleAttributeName: paragraph], range: NSRange(location: 0, length: termsStr.length))

        topTextView.attributedText = termsStr
        
        
        resendCodeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onResendTapped(recognizer:))))
        
        let didnGetCodeStr = NSMutableAttributedString(string: "Didn't get the code?", attributes: colorAttrs)
        didntGetCodeLabel.attributedText = didnGetCodeStr
        
        didntGetCodeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onDidntReceiveTapped(recognizer:))))
    }
    
    func updateResendCodeLabel() {
        var colorAttrs = [String: Any]()
        colorAttrs[NSFontAttributeName] = UIFont.SFUIDisplayLight(size: 15.0)

        var color: UIColor?
        var text: String?
        let remainingTime = Constants.SMS_RESEND_DELAY - (Utils.getCurrentTimeInMillis() - DefaultsHelper.getLastCodeSendTime())
        
        if remainingTime > 0 {
            color = UIColor.missitoLightGray
            resendCodeLabel.isUserInteractionEnabled = false
            let sec = Int((Double(remainingTime) / 1000.0 + 0.5).rounded())
            text = "Request the code again in \(sec) seconds"
        } else {
            color = UIColor.missitoLightBlue
            resendCodeLabel.isUserInteractionEnabled = true
            text = "Resend code"
        }
        
        colorAttrs[NSForegroundColorAttributeName] = color

        let resendCodeStr = NSMutableAttributedString(string: text!, attributes: colorAttrs)
        resendCodeLabel.attributedText = resendCodeStr
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateResendCodeLabel()
        }

    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        // go back on phone number click
        navigationController?.popViewController(animated: true)
        return false
    }

    func hideKeyboard() {
        view.endEditing(true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onResendTapped(recognizer: UITapGestureRecognizer) {
        DefaultsHelper.saveLastCodeSendTime(Utils.getCurrentTimeInMillis())
        
        resendCodeLabel.isEnabled = false
        APIRequests.requestOTP(phone: (phone ?? "")) { (response, error) in
            self.resendCodeLabel.isEnabled = true
            if let response = response {
                self.otpToken = response.token
            } else {
                if let error = error {
                    print("requestOTP error: " + error.localizedDescription)
                } else {
                    print("Error: requestOTP returned empty response")
                }
                Utils.alert(viewController: self, title: "An error occured", message: (error?.localizedDescription ?? "Please try again later"))
            }
        }
    }
    
    func onDidntReceiveTapped(recognizer: UITapGestureRecognizer) {
        if MFMailComposeViewController.canSendMail() {
            sendEmail()
        } else {
            let message = "Subject: SMS Code not received, Text: \(getSysInfoString())"
            UIPasteboard.general.string = "Hello world"
            let alert = UIAlertController(title: "Please send a message to verify@missito.im", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
                UIPasteboard.general.string = message
            })
            present(alert, animated: true, completion: nil)
        }
    }
    
    func getSysInfoString() -> String {
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "no-version"
        let systemVersion = "iOS " + UIDevice.current.systemVersion
        let platform = Utils.platformName()
        
        return "Number=\(phone ?? "no-phone") Missito \(appVersion); \(systemVersion); \(platform)"
    }
    
    func sendEmail() {
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        composeVC.setToRecipients(["verify@missito.im"])
        composeVC.setSubject("SMS Code not received")
        composeVC.setMessageBody(getSysInfoString(), isHTML: false)
        present(composeVC, animated: true, completion: nil)
    }
    
    // MARK: - MFMailComposeViewController delegate methods
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    func login(_ code: String) {
        progress = Utils.showProgress(message: "", view: view)
        view.endEditing(true)
        
        guard let authService = CoreServices.authService else {
            progress?.hide(animated: true)
            let alert = UIAlertController(title: "An error occured", message: "Cannot authenticate. Try again later.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
            self.present(alert, animated: true)
            return
        }
        
        authService.verify(phone: phone!, token: otpToken!, code: code) { (error) in
            self.progress?.hide(animated: true)
            if let error = error {
                let alert: UIAlertController?
                switch error {
                case .httpStatusError(status: 500):
                    alert = UIAlertController(title: "Oops!", message: "Invalid code.", preferredStyle: .alert)
                default:
                    alert = UIAlertController(title: "An error occured", message: "Cannot authenticate. Try again later.", preferredStyle: .alert)
                }
                alert?.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.codeInputView.reset()
                })
                self.present(alert!, animated: true){}
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                var viewController: UIViewController?
                if DefaultsHelper.getUserName() == nil {
                    viewController = storyboard.instantiateViewController(withIdentifier: "nameInput")
                } else {
                    viewController = storyboard.instantiateInitialViewController()
                }
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.window?.rootViewController = viewController
            }
        }
    }
    
    @IBAction func notReceived(_ sender: AnyObject) {
        
        _ = self.navigationController?.popViewController(animated: true)
        
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
    }

    
    

}
