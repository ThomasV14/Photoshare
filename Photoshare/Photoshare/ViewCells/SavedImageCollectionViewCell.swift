//
//  SavedImageCollectionViewCell.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/30/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit

class SavedImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func generateCell(image: UIImage) {
        self.imageView.image = image
    }
}
