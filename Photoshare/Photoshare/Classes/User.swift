//
//  User.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/24/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class User {

    let objectId: String
    var pushId: String?
    let createdAt: Date
    var updatedAt: Date
    
    var email: String
    var firstname: String
    var lastname: String
    var fullname: String
    var avatar: String
    var city: String
    var contacts: [String]
    var blockedUsers: [String]
    
    let loginMethod: String
    var isOnline: Bool
    
    //MARK: Initializers
    
    init(_objectId: String, _pushId: String?, _createdAt: Date, _updatedAt: Date, _email: String, _firstname: String, _lastname: String, _avatar: String = "", _loginMethod: String, _city: String) {
        
        objectId = _objectId
        pushId = _pushId
        createdAt = _createdAt
        updatedAt = _updatedAt
        
        email = _email
        firstname = _firstname
        lastname = _lastname
        fullname = _firstname + " " + _lastname
        avatar = _avatar
        city = _city
        blockedUsers = []
        contacts = []
        
        loginMethod = _loginMethod
        isOnline = true
        
    }
    
    
    
    init(_dictionary: NSDictionary) {
        
        objectId = _dictionary[kOBJECTID] as! String
        pushId = _dictionary[kPUSHID] as? String
        
        if let created = _dictionary[kCREATEDAT] {
            if (created as! String).count != 14 {
                createdAt = Date()
            } else {
                createdAt = dateFormatter().date(from: created as! String)!
            }
        } else {
            createdAt = Date()
        }
        if let updateded = _dictionary[kUPDATEDAT] {
            if (updateded as! String).count != 14 {
                updatedAt = Date()
            } else {
                updatedAt = dateFormatter().date(from: updateded as! String)!
            }
        } else {
            updatedAt = Date()
        }
        
        if let mail = _dictionary[kEMAIL] {
            email = mail as! String
        } else {
            email = ""
        }
        
        if let fname = _dictionary[kFIRSTNAME] {
            firstname = fname as! String
        } else {
            firstname = ""
        }
        
        if let lname = _dictionary[kLASTNAME] {
            lastname = lname as! String
        } else {
            lastname = ""
        }
        fullname = firstname + " " + lastname
        
        if let avat = _dictionary[kAVATAR] {
            avatar = avat as! String
        } else {
            avatar = ""
        }
        
        if let onl = _dictionary[kISONLINE] {
            isOnline = onl as! Bool
        } else {
            isOnline = false
        }
        
        if let cont = _dictionary[kCONTACT] {
            contacts = cont as! [String]
        } else {
            contacts = []
        }
        
        if let block = _dictionary[kBLOCKEDUSERID] {
            blockedUsers = block as! [String]
        } else {
            blockedUsers = []
        }
        
        if let cit = _dictionary[kCITY] {
            city = cit as! String
        } else {
            city = ""
        }
        
        if let lgm = _dictionary[kLOGINMETHOD] {
            loginMethod = lgm as! String
        } else {
            loginMethod = ""
        }
        
    }
    
    // MARK: User class functions
    
    
    class func userId() -> String {
        
        return Auth.auth().currentUser!.uid
    }
    
    class func username () -> User? {
        
        if Auth.auth().currentUser != nil {
            
            if let dictionary = UserDefaults.standard.object(forKey: kCURRENTUSER) {
                
                return User.init(_dictionary: dictionary as! NSDictionary)
            }
        }
        
        return nil
        
    }
    
    class func loginUserWith(email: String, password: String, completion: @escaping (_ error: Error?) -> Void) {
        
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            
            if error != nil {
                completion(error)
            } else {
                fetchCurrentUserFromFirestore(userId: user!.user.uid)
                completion(error)
            }
        })
        
    }
    
    class func registerUserWith(email: String, password: String, firstName: String, lastName: String, avatar: String = "", completion: @escaping (_ error: Error?) -> Void ) {
        
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
            
            if error != nil {
                completion(error)
                return
            }
            let fUser = User(_objectId: user!.user.uid, _pushId: "", _createdAt: Date(), _updatedAt: Date(), _email: user!.user.email!, _firstname: firstName, _lastname: lastName, _avatar: avatar, _loginMethod: kEMAIL, _city: "")
            
            saveUserLocally(user: fUser)
            saveUserToFirestore(user: fUser)
            completion(error)
        })
    }

    class func logOutCurrentUser(completion: @escaping (_ success: Bool) -> Void) {
        
        userDefaults.removeObject(forKey: kPUSHID)
        userDefaults.removeObject(forKey: kCURRENTUSER)
        userDefaults.synchronize()
        
        do {
            try Auth.auth().signOut()
            completion(true)
            
        } catch let error as NSError {
            completion(false)
            print(error.localizedDescription)
        }
    }
    class func deleteUser(completion: @escaping (_ error: Error?) -> Void) {
    
        let user = Auth.auth().currentUser
        user?.delete(completion: { (error) in
            completion(error)
        })
    }
    
}

// MARK: User Functions

func saveUserToFirestore(user: User) {
    reference(.User).document(user.objectId).setData(userDictionaryFrom(user: user) as! [String : Any]) { (error) in
        
        print("error is \(String(describing: error?.localizedDescription))")
    }
}

func saveUserLocally(user: User) {
    UserDefaults.standard.set(userDictionaryFrom(user: user), forKey: kCURRENTUSER)
    UserDefaults.standard.synchronize()
}



func fetchCurrentUserFromFirestore(userId: String) {
    
    reference(.User).document(userId).getDocument { (snapshot, error) in
        guard let snapshot = snapshot else {
            return
        }
        if snapshot.exists {
            UserDefaults.standard.setValue(snapshot.data() as! NSDictionary, forKeyPath: kCURRENTUSER)
            UserDefaults.standard.synchronize()
        }
    }
}


func fetchCurrentUserFromFirestore(userId: String, completion: @escaping (_ user: User?)->Void) {
    
    reference(.User).document(userId).getDocument { (snapshot, error) in
        guard let snapshot = snapshot else {
            return
        }
        if snapshot.exists {
            let user = User(_dictionary: snapshot.data()! as NSDictionary)
            completion(user)
        } else {
            completion(nil)
        }
    }
}

func checkBlockedStatus(withUser: User) -> Bool {
    return withUser.blockedUsers.contains(User.userId())
}

func userDictionaryFrom(user: User) -> NSDictionary {
    
    let createdAt = dateFormatter().string(from: user.createdAt)
    let updatedAt = dateFormatter().string(from: user.updatedAt)
    
    return NSDictionary(
        objects: [user.objectId,  createdAt, updatedAt, user.email, user.loginMethod, user.pushId!, user.firstname, user.lastname, user.fullname, user.avatar, user.contacts, user.blockedUsers, user.isOnline, user.city],
                        
        forKeys: [kOBJECTID as NSCopying, kCREATEDAT as NSCopying, kUPDATEDAT as NSCopying, kEMAIL as NSCopying, kLOGINMETHOD as NSCopying, kPUSHID as NSCopying, kFIRSTNAME as NSCopying, kLASTNAME as NSCopying, kFULLNAME as NSCopying, kAVATAR as NSCopying, kCONTACT as NSCopying, kBLOCKEDUSERID as NSCopying, kISONLINE as NSCopying, kCITY as NSCopying]
    )
    
}

func getUsersFromFirestore(withIds: [String], completion: @escaping (_ usersArray: [User]) -> Void) {
    
    var count = 0
    var usersArray: [User] = []
    for userId in withIds {
        reference(.User).document(userId).getDocument { (snapshot, error) in
            guard let snapshot = snapshot else {
                return
            }
            if snapshot.exists {
                
                let user = User(_dictionary: snapshot.data() as! NSDictionary)
                count += 1
                if !isCurrentlyLoggedInUser(user: user) {
                    usersArray.append(user)
                }
            } else {
                completion(usersArray)
            }
            if count == withIds.count {
                completion(usersArray)
            }
        }
    }
}

func updateCurrentUserInFirestore(withValues : [String : Any], completion: @escaping (_ error: Error?) -> Void) {
    
    if let dictionary = UserDefaults.standard.object(forKey: kCURRENTUSER) {
        
        var tempWithValues = withValues
        let currentUserId = User.userId()
        let updatedAt = dateFormatter().string(from: Date())
        tempWithValues[kUPDATEDAT] = updatedAt
        let userObject = (dictionary as! NSDictionary).mutableCopy() as! NSMutableDictionary
        userObject.setValuesForKeys(tempWithValues)
        
        reference(.User).document(currentUserId).updateData(withValues) { (error) in
    
            if error != nil {
                completion(error)
                return
            }
            UserDefaults.standard.setValue(userObject, forKeyPath: kCURRENTUSER)
            UserDefaults.standard.synchronize()

            completion(error)
        }
    }
}

func isCurrentlyLoggedInUser(user:User) -> Bool {
    if user.objectId == User.userId() {
        return true
    }
    else {
        return false
    }
}
