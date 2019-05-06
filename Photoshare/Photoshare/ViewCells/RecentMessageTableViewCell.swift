//
//  RecentMessageTableViewCell.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/26/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit

// TODO: Fix layout constraints on cell

protocol RecentMessageTableViewCellDelegate {
    func didTapAvatarImage(indexPath: IndexPath)
}
class RecentMessageTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var unreadMessageCounterLabel: UILabel!
    @IBOutlet weak var unreadMessageCounterBackgroundView: UIView!
    
    var indexPath: IndexPath!
    let tapGesture = UITapGestureRecognizer()
    var delegate: RecentMessageTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        unreadMessageCounterBackgroundView.layer.cornerRadius = unreadMessageCounterBackgroundView.frame.width / 2
        tapGesture.addTarget(self, action: #selector(self.avatarTap))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGesture)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    func generateCell(recentChat: NSDictionary, indexPath: IndexPath){
        self.indexPath = indexPath
        
        self.nameLabel.text = recentChat[kWITHUSERFULLNAME] as? String
        self.lastMessageLabel.text = recentChat[kLASTMESSAGE] as? String
        self.unreadMessageCounterLabel.text = recentChat[kCOUNTER] as? String
        
        if let avatarString = recentChat[kAVATAR] {
            imageFromData(pictureData: avatarString as! String) { (avatarImage) in
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
        
        if recentChat[kCOUNTER] as! Int != 0{
                self.unreadMessageCounterLabel.text = "\(recentChat[kCOUNTER] as! Int)"
                self.unreadMessageCounterBackgroundView.isHidden = false
                self.unreadMessageCounterLabel.isHidden = false
        } else {
            self.unreadMessageCounterBackgroundView.isHidden = true
            self.unreadMessageCounterLabel.isHidden = true
            
        }
        var date: Date!
        if let created = recentChat[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)!
            }
        } else {
            date = Date()
        }
        
        self.dateLabel.text = timeElapsed(date: date) + " ago"
    }

    
    @objc func avatarTap(){
        delegate?.didTapAvatarImage(indexPath: indexPath)
    }
}
