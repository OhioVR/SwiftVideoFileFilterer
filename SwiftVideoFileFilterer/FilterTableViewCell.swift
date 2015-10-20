//
//  FilterTableViewCell.swift
//  SwiftVideoFileFilterer
//
//  Created by Scott Yannitell on 10/20/15.
//  Copyright © 2015 Scott Yannitell. All rights reserved.
//

import UIKit

class FilterTableViewCell: UITableViewCell {

    @IBOutlet var name: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
