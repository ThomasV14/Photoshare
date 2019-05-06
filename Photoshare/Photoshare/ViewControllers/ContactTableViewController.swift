//
//  ContactTableViewController.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/26/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit
import ProgressHUD

class ContactTableViewController: UITableViewController {
    
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var blockButton: UIButton!
    
    
    var user: User?
    override func viewDidLoad() {
        super.viewDidLoad()
        setContact()
        tableView.tableFooterView = UIView()
    }

    
    // MARK: IBActions
    @IBAction func messageButtonPressed(_ sender: Any) {
        if !checkBlockedStatus(withUser: user!){
            let messageVC = MessageViewController()
            messageVC.titleName = user!.firstname
            messageVC.membersToPush = [User.userId(),user!.objectId]
            messageVC.memberIds = [User.userId(),user!.objectId]
            messageVC.chatRoomId = startPrivateChat(userOne: User.username()!, userTwo: user!)
            messageVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(messageVC, animated: true)
        } else {
            ProgressHUD.showError("You cannot message this person")
        }
    }
    
    @IBAction func blockButtonPressed(_ sender: Any) {
        
        var currentUserBlockedUsers = User.username()!.blockedUsers
        if currentUserBlockedUsers.contains(user!.objectId) {
            let index = currentUserBlockedUsers.firstIndex(of: user!.objectId)!
            currentUserBlockedUsers.remove(at: index)
        } else {
            currentUserBlockedUsers.append(user!.objectId)
        }
        
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID:currentUserBlockedUsers]) { (error) in
            if error != nil {
                ProgressHUD.showError()
            } else {
                self.updateBlockStatus()
            }
        }
        blockUser(userToBlock: user!)
        
    }
    // MARK: - TableView Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        } else {
            return 10
        }
    }

    
    // MARK: Helper functions
    
    func setContact(){
        if user != nil {
            self.title = "Contact Card"
            nameLabel.text = user!.fullname
            imageFromData(pictureData: user!.avatar) { (avatarImage) in
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
            updateBlockStatus()
        }
    }
    
    func updateButtons(hidden:Bool){
        blockButton.isHidden = hidden
        messageButton.isHidden = hidden
        
    }
    
    func updateBlockStatus(){
        if user!.objectId == User.userId() {
            updateButtons(hidden: true)
        } else {
            updateButtons(hidden: false)
        }
        
        if User.username()!.blockedUsers.contains(user!.objectId) {
            blockButton.setTitle("Unblock User", for: .normal)
        } else {
            blockButton.setTitle("Block User", for: .normal)
        }
        
    }
}
