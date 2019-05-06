//
//  UsersTableViewController.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/25/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD

class UsersTableViewController: UITableViewController, UISearchResultsUpdating, UserTableViewCellDelegate {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var locationSegmentedController: UISegmentedControl!
    
    var users: [User] = []
    var filteredUsers: [User] = []
    var allUsersGroupped = NSDictionary() as! [String: [User]] // Group by alpha
    var sectionTitleList: [String] = []
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Users"
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()

        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        
        loadUsers(filter: kCITY)
    }
    
    // MARK: IBActions
    
    
    @IBAction func filterSegmentValueChanged(_ sender: Any) {
        
        let index = (sender as! UISegmentedControl).selectedSegmentIndex
        switch index {
        case 0:
            loadUsers(filter: kCITY)
        case 1:
            loadUsers(filter: "")
        default:
            return
        }
    }
    // MARK: Search controller functions
    
    func filterContentForSearchText(searchText: String, scope: String = "All"){
        filteredUsers = users.filter({ (user) -> Bool in
            return user.fullname.uppercased().contains(searchText.uppercased())
        })
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    
    // MARK: TableView Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        } else {
            return allUsersGroupped.count
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredUsers.count
        } else {
            let sectionTitle = self.sectionTitleList[section]
            let users = self.allUsersGroupped[sectionTitle]
            return users!.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserTableViewCell
        var user: User
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGroupped[sectionTitle]
            user = users![indexPath.row]
        }
        cell.generateCellWith(user: user, indexPath: indexPath)
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        } else {
            return sectionTitleList[section]
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return nil
        } else {
            return self.sectionTitleList
        }
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var user: User
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGroupped[sectionTitle]
            user = users![indexPath.row]
        }
        if !checkBlockedStatus(withUser: user){
            let messageVC = MessageViewController()
            messageVC.titleName = user.firstname
            messageVC.membersToPush = [User.userId(),user.objectId] 
            messageVC.memberIds = [User.userId(),user.objectId]
            messageVC.chatRoomId = startPrivateChat(userOne: User.username()!, userTwo: user)
            messageVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(messageVC, animated: true)
        } else {
            ProgressHUD.showError("You cannot message this person")
        }
        
}
    
    // MARK: UserTableViewCell Delegate
    
    func didTapAvatarImage(indexPath: IndexPath) {
        let contactVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "contactView") as! ContactTableViewController
        
        var user: User
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGroupped[sectionTitle]
            user = users![indexPath.row]
        }
        
        contactVC.user = user
        self.navigationController?.pushViewController(contactVC, animated: true)
    }
    
    // MARK: Helper functions
    
    
    // TODO: Add Maps and Order by Proximity
    func loadUsers(filter: String){
        ProgressHUD.show()
        
        var query: Query!
        switch filter {
        case kCITY:
            query = reference(.User).whereField(kCITY, isEqualTo: User.username()!.city).order(by: kFIRSTNAME, descending: false)
        default:
            query = reference(.User).order(by: kFIRSTNAME, descending: false)
        }
        
        query.getDocuments { (snapshot, error) in
            self.emptyArrays()
            if error != nil {
                ProgressHUD.showError()
            } else {
                
                guard let snapshot = snapshot else {
                    ProgressHUD.dismiss()
                    return
                }
                
                if !snapshot.isEmpty {
                    for userDictionary in snapshot.documents {
                        let userDictionaryDecoded = userDictionary.data() as NSDictionary
                        let fUser = User(_dictionary: userDictionaryDecoded)
                        if fUser.objectId != User.userId() {
                            self.users.append(fUser)
                        }
                    }
                    
                    self.splitData()
                }
            }
            self.tableView.reloadData()
            ProgressHUD.dismiss()
            
        }
    }
    
    func emptyArrays(){
        self.users = []
        self.filteredUsers = []
        self.sectionTitleList = []
        self.allUsersGroupped = [:]
    }
    
    
    fileprivate func splitData(){
        for i in 0..<self.users.count {
            let currentUser = self.users[i]
            let firstLetter = currentUser.firstname.first!
            let sectionTitle = "\(firstLetter)"
            if self.allUsersGroupped[sectionTitle] != nil {
                self.allUsersGroupped[sectionTitle]!.append(currentUser)
            } else {
                self.allUsersGroupped[sectionTitle] = []
                self.allUsersGroupped[sectionTitle]!.append(currentUser)
                self.sectionTitleList.append(sectionTitle) // Query is returned in alphabetical order
                
            }
        }
    }
}
