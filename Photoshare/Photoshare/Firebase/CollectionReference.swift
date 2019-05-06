//
//  CollectionReference.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/24/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import Foundation
import FirebaseFirestore


enum FirebaseCollection: String {
    case User
    case Message
    case Post
    case Recent
    case Typing
}


func reference(_ collectionReference: FirebaseCollection) -> CollectionReference {
    let db = Firestore.firestore()
    let settings = db.settings
    //settings.areTimestampsInSnapshotsEnabled = true
    db.settings = settings
    return db.collection(collectionReference.rawValue)
}

