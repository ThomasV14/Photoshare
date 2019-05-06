//
//  Recent.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/26/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

// TODO: Remove Repeated Code
import Foundation



func startPrivateChat(userOne:User, userTwo:User) -> String {
    let chatRoomId = createChatID(userOne: userOne,userTwo: userTwo)
    createRecentChat(members: [userOne.objectId,userTwo.objectId], chatRoomId: chatRoomId, withUserName: "", type: kPRIVATE, users: [userOne,userTwo], chatAvatar:nil)
    return chatRoomId
}

func createChatID(userOne:User,userTwo:User) -> String{
    let userOneId = userOne.objectId
    let userTwoId = userTwo.objectId
    
    if userOneId.compare(userTwoId).rawValue < 0 {
        return userOneId + userTwoId
    } else {
        return userTwoId + userOneId
    }
}



func createRecentChat(members: [String],chatRoomId: String, withUserName: String, type: String,users: [User]?, chatAvatar: String?){
    var tempMembers = members
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else {
            return
        }
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let currentRecent = recent.data() as NSDictionary
                if let currentUserId = currentRecent[kUSERID] {
                    if tempMembers.contains(currentUserId as! String) {
                        tempMembers.remove(at: tempMembers.firstIndex(of: currentUserId as! String)!)
                    }
                }
            }
        }
        for userId in tempMembers {
            createRecentItem(userId: userId, chatRoomId: chatRoomId, members: members, withUserName: withUserName, type: type, users: users, chatAvatar: chatAvatar)
        }
    }
}

func createRecentItem(userId: String, chatRoomId: String, members: [String], withUserName: String, type: String, users: [User]?,chatAvatar: String?){
    let localReference = reference(.Recent).document()
    let recentId = localReference.documentID
    let date = dateFormatter().string(from: Date())
    var recent: [String:Any]!
    if type == kPRIVATE {
        var withUser: User?
        if users != nil && users!.count > 0 {
            if userId == User.userId() {
                withUser = users!.last
            } else {
                withUser = users!.first
            }
            
        }
        recent = [kRECENTID: recentId, kUSERID: userId, kCHATROOMID: chatRoomId,
                  kMEMBERS: members, kMEMBERSTOPUSH: members,
                  kWITHUSERFULLNAME: withUser!.fullname, kWITHUSERUSERID: withUser!.objectId,
            kLASTMESSAGE:"", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: withUser!.avatar] as [String:Any]
        
        
    } else {
        if chatAvatar != nil {
            recent = [kRECENTID: recentId, kUSERID: userId, kCHATROOMID: chatRoomId,
                      kMEMBERS: members, kMEMBERSTOPUSH: members,kWITHUSERFULLNAME: withUserName,
                      kLASTMESSAGE:"", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: chatAvatar!] as [String:Any]
        }
    }
    
    localReference.setData(recent)
}

func updateRecentChatMuteOptionsFromMessage(chatRoomId: String, members: [String], withValues: [String:Any]){
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else {
            return
        }
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let recent = recent.data() as NSDictionary
                updateRecentChatMuteOptions(recentId: recent[kRECENTID] as! String, withValues: withValues)
            }
        }
    }
}

func updateRecentChatMuteOptions(recentId: String,  withValues: [String: Any]){
    reference(.Recent).document(recentId).updateData(withValues)
}




func updateRecentChatFromMessage(chatRoomId: String, lastMessage: String){
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else {
            return
        }
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let currentRecent = recent.data() as NSDictionary
                updateRecentChat(recent: currentRecent, lastMessage: lastMessage)
            }
        }
    }
}


func updateRecentChat(recent:NSDictionary, lastMessage: String){
    let date = dateFormatter().string(from: Date())
    var counter = recent[kCOUNTER] as! Int
    if recent[kUSERID] as? String != User.userId() {
        counter += 1
    }
    let values = [kLASTMESSAGE:lastMessage,kCOUNTER:counter,kDATE:date] as [String:Any]
    reference(.Recent).document(recent[kRECENTID] as! String).updateData(values)
}

func deleteRecentChatForCurrentUser(recent: NSDictionary) {
    if let recentId = recent[kRECENTID] {
        reference(.Recent).document(recentId as! String).delete()
    }
    
}


func restartRecentChatForCurrentUser(recent: NSDictionary) {
    if recent[kTYPE] as! String == kPRIVATE {
        createRecentChat(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserName: User.username()!.firstname, type: kPRIVATE, users: [User.username()!], chatAvatar: nil)
    }
}

func clearUnreadMessageCounterFromMessage(chatRoomId: String){
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else {
            return
        }
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let currentRecent = recent.data() as NSDictionary
                if currentRecent[kUSERID] as? String == User.userId() {
                    clearUnreadMessageCounter(recent: currentRecent)
                }
            }
        }
    }
}

func clearUnreadMessageCounter(recent: NSDictionary){
    reference(.Recent).document(recent[kRECENTID] as! String).updateData([kCOUNTER:0])
}

func blockUser(userToBlock: User) {
    let userId1 = User.userId()
    let userId2 = userToBlock.objectId
    if (userId1.compare(userId2).rawValue) < 0 {
        deleteRecentChats(chatRoomId: (userId1 + userId2))
    } else {
        deleteRecentChats(chatRoomId: (userId2 + userId1))
    }
}

func deleteRecentChats(chatRoomId: String) {
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else { return }

        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let recent = recent.data() as NSDictionary
                deleteRecentChatForCurrentUser(recent: recent)
            }
        }
    }
}



