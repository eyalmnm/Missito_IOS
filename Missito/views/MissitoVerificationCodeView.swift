//
//  MissitoVerificationCodeView.swift
//  Missito
//
//  Created by Jenea Vranceanu on 8/4/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit

class MissitoVerificationCodeView: UIView, UITextFieldDelegate {
    
    private var darkDigitStyle = [String: AnyObject]()
    private var blueDigitStyle = [String: AnyObject]()
    
    @IBOutlet weak var digit1: UITextField!
    @IBOutlet weak var digit2: UITextField!
    @IBOutlet weak var digit3: UITextField!
    @IBOutlet weak var digit4: UITextField!
    @IBOutlet weak var digit5: UITextField!
    
    private var lastResponder: UITextField?
    
    var completion: ((String)->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        lastResponder = digit1
        digit1.delegate = self
        digit2.delegate = self
        digit3.delegate = self
        digit4.delegate = self
        digit5.delegate = self
        
        darkDigitStyle[NSForegroundColorAttributeName] = UIColor.missitoDarkGray
        darkDigitStyle[NSUnderlineStyleAttributeName] = 1 as AnyObject
        darkDigitStyle[NSFontAttributeName] = UIFont.SFUIDisplayLight(size: 35)
        
        blueDigitStyle[NSForegroundColorAttributeName] = UIColor.missitoLightBlue
        blueDigitStyle[NSUnderlineStyleAttributeName] = 1 as AnyObject
        blueDigitStyle[NSFontAttributeName] = UIFont.SFUIDisplayLight(size: 35)

        var placehoderStyle = [String:AnyObject]()
        placehoderStyle[NSForegroundColorAttributeName] = UIColor.missitoDarkGray
        placehoderStyle[NSFontAttributeName] = UIFont.SFUIDisplayLight(size: 35)
        
        let attributedPlaceholder = NSMutableAttributedString()
        attributedPlaceholder.append(NSAttributedString(string: "_", attributes: placehoderStyle))
        digit1.attributedPlaceholder = attributedPlaceholder
        digit2.attributedPlaceholder = attributedPlaceholder
        digit3.attributedPlaceholder = attributedPlaceholder
        digit4.attributedPlaceholder = attributedPlaceholder
        digit5.attributedPlaceholder = attributedPlaceholder
    }
    
    func focus() {
        lastResponder?.becomeFirstResponder()
    }
    
    func reset() {
        digit1.text = nil
        digit2.text = nil
        digit3.text = nil
        digit4.text = nil
        digit5.text = nil
        lastResponder?.resignFirstResponder()
        lastResponder = digit1
        digit1.becomeFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if ((textField.text?.characters.count ?? 0) <= 1 || string.isEmpty) {
            changeResponder((textField.text ?? ""), string)
        }
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField != lastResponder {
            textField.resignFirstResponder()
            // allow some time for resignFirstResponder to complete
            // see https://stackoverflow.com/questions/27098097/becomefirstresponder-not-working-in-ios-8
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { 
                self.lastResponder?.becomeFirstResponder()
            })
        }
    }
    
    private func changeResponder(_ prevText: String, _ nextText: String) {
        let move = !prevText.isEmpty
        let isDelete = nextText.isEmpty
        var grayTextField: UITextField?
        var blueTextField: UITextField?
        var sendCode = false
        switch lastResponder?.tag ?? 0 {
        case 0:
            if !isDelete {
                lastResponder = move ? digit2 : digit1
                if move {
                    digit1.resignFirstResponder()
                    digit2.becomeFirstResponder()
                    grayTextField = digit1
                    blueTextField = digit2
                } else {
                    blueTextField = digit1
                }
            } else {
                grayTextField = digit1
            }
        case 1:
            grayTextField = (isDelete || move ? digit2 : digit1)
            blueTextField = isDelete ? digit1 : (move ? digit3 : digit2)
            moveFocus(from: digit2, to: blueTextField!)
        case 2:
            grayTextField = (isDelete || move ? digit3 : digit2)
            blueTextField = isDelete ? digit2 : (move ? digit4 : digit3)
            moveFocus(from: digit3, to: blueTextField!)
        case 3:
            grayTextField = (isDelete || move ? digit4 : digit3)
            blueTextField = isDelete ? digit3 : (move && !isDelete ? digit5 : digit4)
            sendCode = (blueTextField == digit5)
            moveFocus(from: digit4, to: blueTextField!)
        case 4:
            if isDelete {
                grayTextField = digit5
                blueTextField = digit4
                lastResponder = digit4
                digit5.resignFirstResponder()
                digit4.becomeFirstResponder()
            } else {
                grayTextField = digit4
                blueTextField = digit5
            }
        default: break
        }
        
        if let grayTextField = grayTextField {
            updateStyle(grayTextField, (isDelete ? "" : prevText), darkDigitStyle)
        }
        if let blueTextField = blueTextField {
            updateStyle(blueTextField, (isDelete ? nil : nextText), blueDigitStyle)
        }
        if sendCode {
            completion?(getCode())
        }
    }
    
    private func getCode() -> String {
        return digit1.text! + digit2.text! + digit3.text! + digit4.text! + digit5.text!
    }
    
    private func updateStyle(_ textField: UITextField, _ string: String?, _ style: [String: AnyObject]) {
        let attributedString = NSMutableAttributedString()
        if let string = string {
            attributedString.append(NSAttributedString(string: string, attributes: style))
        } else {
            attributedString.append(NSAttributedString(string: textField.text!, attributes: style))
        }
        textField.attributedText = attributedString
    }
    
    private func moveFocus(from: UITextField, to: UITextField) {
        lastResponder = to
        from.resignFirstResponder()
        to.becomeFirstResponder()
    }
}
