//
//  StoreTableViewCell.swift
//  DAWG
//
//  Created by Eddie Craig on 21/10/2018.
//  Copyright © 2018 Simon Hogg. All rights reserved.
//

import UIKit

class StoreTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBOutlet weak var storeImageView: UIImageView!
    
    
    @IBOutlet weak var storeLabel: UILabel!
    @IBOutlet weak var storeDetail: UILabel!
}
