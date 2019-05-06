//
//  PostTableViewCell.swift
//  Photoshare
//
//  Created by Thomas Varghese on 5/1/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func generateCell(image: UIImage,caption: String) {
        self.postImageView.image = image
        self.captionLabel.text = caption
    }
    
    
    
}
