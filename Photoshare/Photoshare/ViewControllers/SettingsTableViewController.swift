//
//  SettingsTableViewController.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/25/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit

// TODO: Add option to view and update blocked list

class SettingsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.tableFooterView = UIView()
        
    }
    
    // MARK: TableView Delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // MARK: IBActions
    
    
    @IBAction func logOutButtonPressed(_ sender: Any) {
        User.logOutCurrentUser { (success) in
            if success {
                self.showWelcomeView()
            }
        }
    }
    
    // MARK: Helper functions
    
    func showWelcomeView() {
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "welcome")
        self.present(mainView, animated: true, completion: nil)
    }
}
