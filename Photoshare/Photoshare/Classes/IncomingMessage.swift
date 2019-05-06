//
//  IncomingMessage.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/29/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class IncomingMessage {
    
    var collectionView: JSQMessagesCollectionView
    
    init(collectionView:JSQMessagesCollectionView) {
        self.collectionView = collectionView
    }
    
    func createMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage?{
        var message: JSQMessage?
        let type = messageDictionary[kTYPE] as! String
        if type == kTEXT{
            message = createTextMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        } else if type == kPICTURE {
            message = createPictureMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        } else{
            print("Unknown Message Type")
        }
        
        if message != nil {
            return message
        } else {
            return nil
        }
    }
    
    func createTextMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as? String
        let senderId = messageDictionary[kSENDERID] as? String
        let text = messageDictionary[kMESSAGE] as! String
        var date: Date!
        if let created = messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        return JSQMessage(senderId: senderId, senderDisplayName: name, date: date, text: text)
    }
    
    func createPictureMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage {
        
        let name = messageDictionary[kSENDERNAME] as? String
        let senderId = messageDictionary[kSENDERID] as? String
        
        var date: Date!
        if let created = messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        
        let mediaItem = PhotoMediaItem(image:nil)
        mediaItem?.appliesMediaViewMaskAsOutgoing = (senderId == User.userId())
        downloadImage(imageUrl: messageDictionary[kPICTURE] as! String) { (image) in
            if image != nil {
                mediaItem?.image = image
                self.collectionView.reloadData()
            }
        }
        return JSQMessage(senderId: senderId, senderDisplayName: name, date: date, media: mediaItem)
    }
}
