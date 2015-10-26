//
//  BrightnessCell.swift
//  SwiftVideoFileFilterer
//
//  Created by Scott Yannitell on 10/24/15.
//  Copyright © 2015 Scott Yannitell. All rights reserved.
//

import UIKit

class SingleSliderCell: UITableViewCell {

    @IBOutlet var filterField: UITextField!
    
    @IBOutlet var slider: UISlider!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
