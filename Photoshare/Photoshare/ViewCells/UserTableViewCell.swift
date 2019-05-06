//
//  UserTableViewCell.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/25/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit

protocol UserTableViewCellDelegate {
    func didTapAvatarImage(indexPath: IndexPath)
}

class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    var indexPath: IndexPath!
    let tapGestureRecognizer = UITapGestureRecognizer()
    var delegate: UserTableViewCellDelegate?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tapGestureRecognizer.addTarget(self, action: #selector(avatarTap))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // TODO: Check if the if statement always evaluates to true
    func generateCellWith(user: User, indexPath: IndexPath){
        self.indexPath = indexPath
        self.nameLabel.text = user.fullname
        if user.avatar != ""{
            imageFromData(pictureData: user.avatar) { (avatarImage) in
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
    }
    
    @objc func avatarTap(){
        delegate!.didTapAvatarImage(indexPath: indexPath)
    }

}
