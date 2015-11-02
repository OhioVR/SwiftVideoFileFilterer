//
//  SixSliderCell.swift
//  SwiftVideoFileFilterer
//
//  Created by Scott Yannitell on 10/31/15.
//  Copyright © 2015 Scott Yannitell. All rights reserved.
//

import UIKit

class SixSliderCell: UITableViewCell {

    @IBOutlet var filterField: UITextField!
    
    @IBOutlet var slider1: UISlider!
    
    @IBOutlet var slider2: UISlider!
    
    @IBOutlet var slider3: UISlider!
    
    @IBOutlet var slider4: UISlider!
    
    @IBOutlet var slider5: UISlider!
    
    @IBOutlet var slider6: UISlider!
    
    @IBOutlet var label1: UILabel!
    
    @IBOutlet var label2: UILabel!
    
    @IBOutlet var label3: UILabel!
    
    @IBOutlet var label4: UILabel!
    
    @IBOutlet var label5: UILabel!
    
    @IBOutlet var label6: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
