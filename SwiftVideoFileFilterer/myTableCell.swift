//
//  myTableCell.swift
//  SwiftVideoFileFilterer
//
//  Created by Scott Yannitell on 10/22/15.
//  Copyright © 2015 Scott Yannitell. All rights reserved.
//

import UIKit

class myTableCell: UITableViewCell {

    
    //@IBOutlet var label1: UILabel!
    
    //@IBOutlet var label2: UILabel!
    
    
    
    @IBOutlet var filterField: UITextField!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
