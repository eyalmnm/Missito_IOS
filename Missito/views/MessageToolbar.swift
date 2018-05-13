//
//  MessageToolbar.swift
//  Missito
//
//  Created by George Poenaru on 23/08/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit

class MessageToolbar: UIToolbar {
    
    private static let itemWidth = CGFloat(30)

    @IBOutlet var attachmentButton: UIBarButtonItem!
    @IBOutlet var cameraButton: UIBarButtonItem!
    @IBOutlet var galleryButton: UIBarButtonItem!
    
    @IBOutlet weak var textItem: UIBarButtonItem!
    @IBOutlet weak var messagesTextField: MessageTextField!
    private let shrinkTextFieldBarButton = UIBarButtonItem()
    
    private var initTextItemWidth: CGFloat = 0
    private var focusedTextItemWidth: CGFloat = 0
    private var hasFocus = false
    
    private var toolbarButtonsIdle, toolbarButtonsFocused: [UIBarButtonItem]?
    let micButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    let sendMessageButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    
    override func awakeFromNib() {
        toolbarButtonsIdle = self.items!
        toolbarButtonsFocused = self.items!
        
        shrinkTextFieldBarButton.title = nil
        shrinkTextFieldBarButton.image = UIImage(named: "arrow_right")
        shrinkTextFieldBarButton.tintColor = UIColor.missitoBlue
        shrinkTextFieldBarButton.action = #selector (MessageToolbar.focusLost)
        
        toolbarButtonsFocused?.removeSubrange(ClosedRange<Int>(uncheckedBounds: (lower: 0, upper: 5)))
        toolbarButtonsFocused?.insert(shrinkTextFieldBarButton, at: 0)
        
        setupRightViewButton(micButton, UIImage(named: "mic_message"))
        setupRightViewButton(sendMessageButton, UIImage(named: "send_message"))

        let attributes = [NSFontAttributeName: UIFont.fontAwesome(ofSize: 24)] as Dictionary!
        attachmentButton.setTitleTextAttributes(attributes, for: .normal)
        attachmentButton.title = String.fontAwesomeIcon(name: .paperclip)
        attachmentButton.image = nil
        attachmentButton.width = 30
        attachmentButton.tintColor = UIColor.lightGray
        
        cameraButton.tintColor = UIColor.lightGray
        galleryButton.tintColor = UIColor.lightGray
        
        let itemsSpacing = CGFloat(14)
        
        focusedTextItemWidth = UIScreen.main.bounds.width - itemsSpacing * 3 - cameraButton.width
        initTextItemWidth = UIScreen.main.bounds.width - itemsSpacing * 5 - cameraButton.width * 3
    }
    
    func setCorrectSize() {
        messagesTextField.setWidth(initTextItemWidth)
        messagesTextField.setCustomRightView(micButton)
    }
    
    private func setupRightViewButton(_ button: UIButton, _ image: UIImage?) {
        button.tintColor = UIColor.missitoBlue
        button.layer.cornerRadius = button.bounds.size.height * 0.5
        button.layer.masksToBounds = true
        button.setBackgroundImage(image, for: .normal)
    }
    
    func focusReceived() {
        if focusedTextItemWidth > 0 && !hasFocus {
            setItems(toolbarButtonsFocused, animated: true)
            hasFocus = true
            messagesTextField.setWidth(focusedTextItemWidth)
            messagesTextField.setCustomRightView(sendMessageButton)
        }
    }
    
    func focusLost() {
        if initTextItemWidth > 0 && hasFocus {
            setItems(toolbarButtonsIdle, animated: true)
            hasFocus = false
            messagesTextField.setWidth(initTextItemWidth)
            if let text = messagesTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                messagesTextField.setCustomRightView(sendMessageButton)
            } else {
                messagesTextField.setCustomRightView(micButton)
            }
        }
    }
}
