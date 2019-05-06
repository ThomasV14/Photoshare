//
//  SavedImagesCollectionViewController.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/30/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit
import IDMPhotoBrowser

class SavedImagesCollectionViewController: UICollectionViewController {
    
    var images: [UIImage] = []
    var imageLinks: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Shared Photos"
        if imageLinks.count > 0 {
            downloadImages()
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "savedImageCell", for: indexPath) as! SavedImageCollectionViewCell
        cell.generateCell(image: images[indexPath.row])
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photos = IDMPhoto.photos(withImages: images)
        let browser = IDMPhotoBrowser(photos: photos)
        browser?.displayActionButton = false
        browser?.setInitialPageIndex(UInt(indexPath.row))
        self.present(browser!, animated: true, completion: nil)
    }
    
    // MARK: Helper Functions
    
    func downloadImages(){
        for imageLink in imageLinks {
            downloadImage(imageUrl: imageLink) { (image) in
                if image != nil {
                    self.images.append(image!)
                    self.collectionView?.reloadData()
                }
            }
        }
    }

}
