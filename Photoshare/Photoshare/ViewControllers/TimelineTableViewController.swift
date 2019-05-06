//
//  TimelineTableViewController.swift
//  Photoshare
//
//  Created by Thomas Varghese on 5/1/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit
import ProgressHUD
import IDMPhotoBrowser

class TimelineTableViewController: UITableViewController {

    var Posts: [NSDictionary] = []
    var images: [UIImage] = []
    var captions: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        loadPosts()
    }

    @IBAction func uploadPostButtonTapped(_ sender: Any) {
        let uploadVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "uploadPostView") as! UploadPostsViewController
        uploadVC.user = User.username()
        self.navigationController?.pushViewController(uploadVC, animated: true)
        tableView.tableFooterView = UIView()
    }
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Posts.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postTableViewCell", for: indexPath) as! PostTableViewCell
        if images.count <= indexPath.section {
            return cell
        }
        let scaledImage: UIImage = images[indexPath.section]
        cell.generateCell(image: scaledImage, caption: captions[indexPath.section])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(325.0)
    }
    // MARK: Helper Functions
    
    
    func loadPosts(){
        ProgressHUD.show("Loading Posts...")
        reference(.Post).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else {
                ProgressHUD.dismiss()
                self.tableView.reloadData()
                return
            }
            if !snapshot.isEmpty{
                for document in snapshot.documents {
                    let currentPost = document.data()
                    self.Posts.append(currentPost as NSDictionary)
                }
            }
            
            self.downloadImages()
        }
    }
    
    func downloadImages(){
        for index in 0..<Posts.count {
            let currentPost = Posts[index]
            let currentImageUrl = currentPost.object(forKey: kPOSTURL)
            let currentCaption = currentPost.object(forKey: kCAPTION)
            downloadImage(imageUrl: currentImageUrl as! String) { (image) in
                if image != nil {
                    self.images.append(image!)
                    self.captions.append(currentCaption as! String)
                    self.tableView.reloadData()
                }
            }
            ProgressHUD.dismiss()
        }
    }

}
