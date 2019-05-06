//
//  OutgoingMessages.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/28/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import Foundation


class OutgoingMessage {
    
    let messageDictionary: NSMutableDictionary
    
    init(message: String, senderId: String, senderName: String, date: Date,status: String, type: String ) {
        let dateString = dateFormatter().string(from: date)
        messageDictionary = NSMutableDictionary(objects: [message,senderId,senderName,dateString,status,type],
                                                forKeys: [kMESSAGE as NSCopying,kSENDERID as NSCopying, kSENDERNAME as NSCopying,
                                                          kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    init(message: String, imageLink: String, senderId: String, senderName: String, date: Date,status: String, type: String ) {
        let dateString = dateFormatter().string(from: date)
        messageDictionary = NSMutableDictionary(objects: [message,imageLink,senderId,senderName,dateString,status,type],
                                                forKeys: [kMESSAGE as NSCopying,kPICTURE as NSCopying,kSENDERID as NSCopying, kSENDERNAME as NSCopying,
                                                          kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }

    
    func sendMessage(chatRoomId: String, messageDictionary: NSMutableDictionary, memberIds: [String],membersToPush: [String]){
        let messageID = UUID().uuidString
        messageDictionary[kMESSAGEID] = messageID

        for memberId in memberIds {
            reference(.Message).document(memberId).collection(chatRoomId).document(messageID).setData(messageDictionary as! [String:Any])
        }
        
        updateRecentChatFromMessage(chatRoomId: chatRoomId, lastMessage: messageDictionary[kMESSAGE] as! String)
        
    }
    
    class func deleteMessage(messageId: String, chatRoomId: String){
        reference(.Message).document(User.userId()).collection(chatRoomId).document(messageId).delete()
    }
    
    class func updateMessage(messageId: String, chatRoomId: String, memberIds: [String]){
        let readDate = dateFormatter().string(from: Date())
        let values = [kSTATUS: kREAD, kREADDATE:readDate]
        for userId in memberIds {
            reference(.Message).document(userId).collection(chatRoomId).document(messageId).getDocument { (snapshot, error) in
                
                guard let snapshot = snapshot else {
                    return
                }
                if snapshot.exists {
                    reference(.Message).document(userId).collection(chatRoomId).document(messageId).updateData(values)
                }
            }
        }
        
    }
}
