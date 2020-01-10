//
//  ColorViewCell.swift
//  ColorPicker
//
//  Created by rutinfc on 2020/01/10.
//  Copyright © 2020 rutinfc. All rights reserved.
//

import UIKit

class ColorViewCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var hexString: UILabel!
    
    var color : UIColor? {
        didSet {
            self.hexString.text = self.color?.rgb.color.hexString()
            
            if self.color?.blackOrWhite == UIColor.white {
                self.title.textColor = UIColor.gray.withAlphaComponent(0.7)
            } else {
                self.title.textColor = UIColor.white.withAlphaComponent(0.7)
            }
            self.hexString.textColor = self.title.textColor
            self.contentView.backgroundColor = self.color
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
//        self.layer.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
//        self.layer.borderWidth = 1
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
