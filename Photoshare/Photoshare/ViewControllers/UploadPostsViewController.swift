//
//  UploadPostsViewController.swift
//  Photoshare
//
//  Created by Thomas Varghese on 5/1/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit
import ImagePicker
import ProgressHUD


class UploadPostsViewController: UIViewController, ImagePickerDelegate{
    

    @IBOutlet weak var imageToUploadView: UIImageView!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var uploadButton: UIButton!
    
    var user: User!
    var post: UIImage?
    var caption: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageToUploadView.isUserInteractionEnabled = true
    
    }
    
    @IBAction func imageViewTapped(_ sender: Any) {
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.imageLimit = 1
        present(imagePickerController, animated: true, completion: nil)
        dismissKeyboard()
    }
    // MARK: IBActions

    @IBAction func uploadButtonPressed(_ sender: Any) {
        ProgressHUD.show("Uploading Image...")
        self.caption = captionTextField.text
        self.uploadPost(image: self.post!, view: self.view!) { (postUrl) in
            guard let postUrl = postUrl else {
                return
            }
            reference(.Post).document(User.userId()).setData([kPOSTURL:postUrl,kCAPTION:self.caption!])
            ProgressHUD.dismiss()
            self.goBackToTimeline()
        }
    }
    
    
    

    // MARK: ImagePicker Delegate
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        if images.count > 0 {
            self.post = images.first!
            self.imageToUploadView.image = self.post!
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Helper Functions
    func cleanTextFields(){
        captionTextField.text = ""
    }
    
    func dismissKeyboard(){
        self.view.endEditing(false)
    }
    
    func goBackToTimeline(){
        cleanTextFields()
        dismissKeyboard()
        
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        self.present(mainView, animated: true, completion: nil)
    }


func uploadPost(image: UIImage, view: UIView,completion: @escaping (_ imageLink: String?) -> Void) {
    
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    progressHUD.mode = .determinateHorizontalBar
    let date = dateFormatter().string(from: Date())
    let postFileName = "Posts/" + User.userId() + "/" + date + ".jpg"
    let storageRef = Storage.storage().reference(forURL: kFILEREFERENCE).child(postFileName)
    let imageData = UIImageJPEGRepresentation(image, 0.5)
    
    var task : StorageUploadTask!
    task = storageRef.putData(imageData!, metadata: nil, completion: { (metadata, error) in
        
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        
        if error != nil {
            print("Error Uploading Post \(error!.localizedDescription)")
            return
        }
        storageRef.downloadURL(completion: { (url, error) in
            guard let downloadUrl = url else {
                completion(nil)
                return
            }
            completion(downloadUrl.absoluteString)
        })
    })
    
    task.observe(StorageTaskStatus.progress) { (snapshot) in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }
}
}


