//
//  InviteView.swift
//  Missito
//
//  Created by Mihail Triohin on 3/3/18.
//  Copyright © 2018 Missito GmbH. All rights reserved.
//

import UIKit

class InviteView: UIView {
    @IBOutlet weak var inviteTextLabel: UILabel!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet var contentView: UIView!
    var inviteClosure: (()->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commontInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commontInit()
    }
    
    private func commontInit() {
        Bundle.main.loadNibNamed("InviteView", owner: self, options: nil)
        guard let content = contentView else { return }
        content.frame = self.bounds
        content.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(content)
    }
    
    @IBAction func onInvite(_ sender: Any) {
        inviteClosure?()
        self.removeFromSuperview()
    }
    
    @IBAction func onDismiss(_ sender: Any) {
        self.removeFromSuperview()
    }
}
