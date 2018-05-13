//
//  CountryCell.swift
//  Missito
//
//  Created by George Poenaru on 25/05/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit

class CountryCell: UITableViewCell {

    @IBOutlet weak var dialCodeLabel: UILabel!
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var countryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dialCodeLabel.textColor = UIColor.missitoLightGray
        countryLabel.textColor = UIColor.missitoDarkGray
        checkImage.tintColor = UIColor.missitoBlue
        countryLabel.font = UIFont.SFUIDisplayLight(size: 19.0)
        dialCodeLabel.font = UIFont.SFUIDisplayLight(size: 16.0)
    }
    
    func prepare(_ country: Country, _ isSelected: Bool) {
        countryLabel.text = country.countryName
        dialCodeLabel.text = "+" + country.dialCode
        if isSelected {
            checkImage.isHidden = false
            backgroundColor = UIColor.missitoLightGrayWithAlpha0x26
        } else {
            checkImage.isHidden = true
            backgroundColor = UIColor.white
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
