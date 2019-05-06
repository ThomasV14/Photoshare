//
//  MessagesViewController.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/25/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit
import FirebaseFirestore

class MessagesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecentMessageTableViewCellDelegate, UISearchResultsUpdating {
    

    @IBOutlet weak var tableView: UITableView!
    
    var recentChats: [NSDictionary] = []
    var filteredChats: [NSDictionary] = []
    var recentListener: ListenerRegistration!
    let searchController = UISearchController(searchResultsController: nil)
    
    
    // MARK: View Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadRecentChats()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        recentListener.remove()
    }
    

    @IBAction func createNewChatButtonPressed(_ sender: Any) {
        let userVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "usersTableView") as! UsersTableViewController
        self.navigationController?.pushViewController(userVC, animated: true)
    }

    
    
    
    // MARK: TableView Delegate and Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredChats.count
            
        } else {
            return recentChats.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! RecentMessageTableViewCell
        cell.delegate = self
        let recent = getCorrrectChat(indexPath: indexPath)
        cell.generateCell(recentChat: recent, indexPath: indexPath)
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let current = getCorrrectChat(indexPath: indexPath)
        var title = "Unmute"
        var mute = false
        if (current[kMEMBERSTOPUSH] as! [String]).contains(User.userId()) {
            title = "Mute"
            mute = true
        }
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) in
            self.recentChats.remove(at: indexPath.row)
            deleteRecentChatForCurrentUser(recent: current)
            self.tableView.reloadData()
        }
        let muteAction = UITableViewRowAction(style: .default, title: title) { (action, indexPath) in
            self.updateMutedChats(recent: current, mute: mute)
        }
        muteAction.backgroundColor = #colorLiteral(red: 0.1687666337, green: 0.3412866232, blue: 0.5414507772, alpha: 1)
        deleteAction.backgroundColor = #colorLiteral(red: 0.3860103627, green: 0.1123391405, blue: 0.1170053725, alpha: 1)
        return [deleteAction,muteAction]
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let current = getCorrrectChat(indexPath: indexPath)
        restartRecentChatForCurrentUser(recent: current)
        let messageVC = MessageViewController()
        messageVC.hidesBottomBarWhenPushed = true
        messageVC.titleName = (current[kWITHUSERFULLNAME] as? String)!
        messageVC.chatRoomId = (current[kCHATROOMID] as? String)!
        messageVC.memberIds = (current[kMEMBERS] as? [String])!
        messageVC.membersToPush = (current[kMEMBERSTOPUSH] as? [String])!
        navigationController?.pushViewController(messageVC, animated: true)
    }
    
    // MARK: Helper functions
    
    func loadRecentChats(){
        recentListener = reference(.Recent).whereField(kUSERID, isEqualTo: User.userId()).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else {
                return
            }
            
            self.recentChats = []
            if !snapshot.isEmpty {
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as! [NSDictionary]
                for recent in sorted {
                    if recent[kLASTMESSAGE] as! String != "" && recent[kCHATROOMID] != nil && recent[kRECENTID] != nil {
                        self.recentChats.append(recent)
                    }
                }
                self.tableView.reloadData()
                self.tableView.tableFooterView = UIView()
            }
        })
    }
    
    func updateMutedChats(recent: NSDictionary, mute: Bool){
        var membersToPush = recent[kMEMBERSTOPUSH] as! [String]
        if mute {
            let index = membersToPush.firstIndex(of: User.userId())!
            membersToPush.remove(at: index)
        } else {
            membersToPush.append(User.userId())
        }
        
        updateRecentChatMuteOptionsFromMessage(chatRoomId: recent[kCHATROOMID] as! String, members: recent[kMEMBERS] as! [String], withValues: [kMEMBERSTOPUSH:membersToPush])
    }
    
    
    // MARK:RecentMessageTableViewCell Delegate
    
    func didTapAvatarImage(indexPath: IndexPath) {
        let recentChat = getCorrrectChat(indexPath: indexPath)
        if recentChat[kTYPE] as! String == kPRIVATE {
            
            reference(.User).document(recentChat[kWITHUSERUSERID] as! String).getDocument { (snapshot, error) in
                guard let snapshot = snapshot else { return }
                if snapshot.exists {
                    let userDictionary = snapshot.data() as! NSDictionary
                    let tempUser = User(_dictionary: userDictionary)
                    self.showRecentChatProfile(user: tempUser)
                    
                }
            }
            
        }
    }
    // MARK: Helper Functions
    
    func showRecentChatProfile(user: User){
        let contactVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "contactView") as! ContactTableViewController
        contactVC.user = user
        self.navigationController?.pushViewController(contactVC, animated: true)
    }
    
    // MARK: Search Controller Functions
    
    func filterContentForSearchText(searchText: String, scope: String = "All"){
        filteredChats = recentChats.filter({ (recentChat) -> Bool in
            return (recentChat[kWITHUSERFULLNAME] as! String).lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }

    
    func getCorrrectChat(indexPath: IndexPath) -> NSDictionary{
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredChats[indexPath.row]
            
        } else {
            return recentChats[indexPath.row]
            
        }
    }
    
    
}
