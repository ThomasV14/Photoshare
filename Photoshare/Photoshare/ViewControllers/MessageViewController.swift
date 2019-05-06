//
//  MessageViewController.swift
//  Photoshare
//
//  Created by Thomas Varghese on 4/28/19.
//  Copyright © 2019 Thomas. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
import IDMPhotoBrowser
import FirebaseFirestore


class MessageViewController: JSQMessagesViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    
    // MARK: Variables and constants
    
    var outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: #colorLiteral(red: 0.3860103627, green: 0.1123391405, blue: 0.1170053725, alpha: 1))
    var incomingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    
    var newMessageListener: ListenerRegistration?
    var typingListener: ListenerRegistration?
    var updatedMessageStatusListener: ListenerRegistration?
    
    var firstLoadApplication: Bool?
    var withUser: User?
    var titleName: String!
    var chatRoomId: String!
    var memberIds: [String]!
    var membersToPush: [String]!
    var messages: [JSQMessage] = []
    var objectMessages: [NSDictionary] = []
    var loadedMessages: [NSDictionary] = []
    var allPictureMessages: [String] = []
    var initialLoadComplete = false
    var maxMessagesNumber = 0
    var typingCounter = 0 {
        didSet {
            if typingCounter == 0 {
                typingCounterSave(isTyping: false)
            }
        }
    }
    var minMessagesNumber = 0 {
        didSet {
            if minMessagesNumber < 0 {
                minMessagesNumber = 0
            }
        }
    }
    var loadOldMessages = false
    var loadedMessagesCount = 0
    var jsqAvatarDictionary: NSMutableDictionary?
    var avatarImageDictionary: NSMutableDictionary?
    var showAvatars = true
    
    let types = [kTEXT,kPICTURE]
    
    let leftBarButtonView: UIView = {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        return view
    }()
    let avatarButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 10, width: 25, height: 25))
        return button
    }()
    let nameLabel: UILabel = {
        let title = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
        title.textAlignment = .left
        title.font = UIFont(name: title.font.fontName, size: 15)?.bold()
        return title
    }()
    let onlineStatusLabel: UILabel = {
        let subTitle = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
        subTitle.textAlignment = .left
        subTitle.font = UIFont(name: subTitle.font.fontName, size: 10)
        
        return subTitle
    }()
    
    
    // MARK: View Lifecycle Methods
    
    override func viewWillAppear(_ animated: Bool) {
        clearUnreadMessageCounterFromMessage(chatRoomId: chatRoomId)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        clearUnreadMessageCounterFromMessage(chatRoomId: chatRoomId)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.backButtonPressed))]
        self.inputToolbar.tintColor  = #colorLiteral(red: 0.3860103627, green: 0.1123391405, blue: 0.1170053725, alpha: 1)
        self.inputToolbar.contentView.rightBarButtonItem.setTitleColor(#colorLiteral(red: 0.3860103627, green: 0.1123391405, blue: 0.1170053725, alpha: 1), for: .normal)
        
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        collectionView?.loadEarlierMessagesHeaderTextColor = #colorLiteral(red: 0.1687666337, green: 0.3412866232, blue: 0.5414507772, alpha: 1)
        JSQMessagesCollectionViewCell.registerMenuAction(#selector(delete))
        
        
        initVariables()
        setHeader()
        createTypingObserver()
        loadMessages()
        updateSender()
    }
    
    // MARK: JSQMessages Data Source Functions
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let data = messages[indexPath.row]
        if data.senderId == User.userId() {
            cell.textView?.textColor = .white
            
        } else {
            cell.textView?.textColor = .black
        }
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        if data.senderId == User.userId() {
            return outgoingBubble
        } else {
            return incomingBubble
        }
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.row]
        let messageDate = message.date
        if messageDate != nil {
            let currentDate = Date()
            let interval = currentDate.timeIntervalSince(messageDate!)
            if !interval.isLess(than: 1800.0) {
                return JSQMessagesTimestampFormatter.shared()?.attributedTimestamp(for: message.date)
            }
        }
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        let message = messages[indexPath.row]
        let messageDate = message.date
        if messageDate != nil {
            let currentDate = Date()
            let interval = currentDate.timeIntervalSince(messageDate!)
            if !interval.isLess(than: 1800.0) {
                return kJSQMessagesCollectionViewCellLabelHeightDefault
            }
        }
        return 0.0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = objectMessages[indexPath.row]
        let messageStatus = message[kSTATUS] as! String
        let currentUserId = User.userId()
        let messageSenderId = message[kSENDERID] as! String
        let status: NSAttributedString!
        let attributedStringColor = [NSAttributedStringKey.foregroundColor: UIColor.darkGray]
        
        
        
        if messageStatus == kREAD {
            let statusText = "Read" + " " + readTimeFrom(dateString: message[kREADDATE] as! String)
            status = NSAttributedString(string: statusText, attributes: attributedStringColor)
        } else if messageStatus == kDELIVERED {
            status = NSAttributedString(string: kDELIVERED)
        } else {
            status = NSAttributedString(string: "❗️")
        }
        
        if indexPath.row == messages.count - 1 {
            return status
        }
        if objectMessages.count > (indexPath.item + 1) {
            let nextMessage = objectMessages[indexPath.item + 1]
            let nextMessageStatus = nextMessage[kSTATUS] as! String
            let nextMessageSenderId = nextMessage[kSENDERID] as! String
            if  nextMessageSenderId == currentUserId && messageSenderId == currentUserId && messageStatus == kREAD && nextMessageStatus == kDELIVERED{
                return status
            }
        }
        
        
        return NSAttributedString(string:"")
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        let message = messages[indexPath.row]
        if message.senderId == User.userId() {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let message = messages[indexPath.row]
        if isLastInSet(indexOfMessage: indexPath){
            if let avatar = jsqAvatarDictionary!.object(forKey: message.senderId){
                return (avatar as! JSQMessageAvatarImageDataSource)
            } else {
                return JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 50)
            }
        }
        return nil
    }
    
   
    
    
    // MARK: JSQMessages Delegate Functions
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let camera = Camera(delegate_: self)
        
        let accessoryMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        accessoryMenu.view.tintColor = #colorLiteral(red: 0.3860103627, green: 0.1123391405, blue: 0.1170053725, alpha: 1)
        let useCamera = UIAlertAction(title: "Camera", style: .default) { (action) in
            ProgressHUD.show()
            camera.PresentPhotoCamera(target: self, canEdit: false)
            ProgressHUD.dismiss()
        }
        let sendPhoto = UIAlertAction(title: "Send Photo", style: .default) { (action) in
            ProgressHUD.show()
            camera.PresentPhotoLibrary(target: self, canEdit: false)
            ProgressHUD.dismiss()
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            
        }
        
        useCamera.setValue(UIImage(named: "camera"), forKey: "image")
        sendPhoto.setValue(UIImage(named: "picture"), forKey: "image")
        
        accessoryMenu.addAction(useCamera)
        accessoryMenu.addAction(sendPhoto)
        accessoryMenu.addAction(cancel)
        
        if ( UI_USER_INTERFACE_IDIOM() == .pad ){
            if let currentPopoverpresentioncontroller = accessoryMenu.popoverPresentationController{
                
                currentPopoverpresentioncontroller.sourceView = self.inputToolbar.contentView.leftBarButtonItem
                currentPopoverpresentioncontroller.sourceRect = self.inputToolbar.contentView.leftBarButtonItem.bounds
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                self.present(accessoryMenu, animated: true, completion: nil)
            }
            return
        }
        self.present(accessoryMenu, animated: true, completion: nil)
    }
    
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        if text != ""{
            self.sendMessage(text: text, date: date, picture: nil)
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        ProgressHUD.show()
        self.loadMoreMessages(maxNumber: maxMessagesNumber, minNumber: minMessagesNumber)
        self.collectionView.reloadData()
        ProgressHUD.dismiss()
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let messageDictionary = objectMessages[indexPath.row]
        let messageType = messageDictionary[kTYPE] as! String
        
        if messageType == kPICTURE {
            let message = messages[indexPath.row]
            let mediaItem = message.media as! JSQPhotoMediaItem
            
            let photos = IDMPhoto.photos(withImages: [mediaItem.image])
            let browser = IDMPhotoBrowser(photos: photos)
            browser!.displayActionButton = false
            
            self.present(browser!, animated: true, completion: nil)
            
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        let senderId = messages[indexPath.row].senderId
        var selectedUser: User?
        
        if senderId == User.userId(){
            selectedUser = User.username()
        } else {
            selectedUser = withUser
        }
        presentUserProfile(forUser: selectedUser!)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        super.collectionView(collectionView, shouldShowMenuForItemAt: indexPath)
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if messages[indexPath.row].isMediaMessage {
            if action.description == "delete:"{
                return true
            }
        } else {
            if action.description == "delete:" || action.description == "copy:"{
                return true
            }
        }
        return false
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didDeleteMessageAt indexPath: IndexPath!) {
        let messageId = objectMessages[indexPath.row][kMESSAGEID] as! String
        OutgoingMessage.deleteMessage(messageId: messageId, chatRoomId: chatRoomId)
        if isLastInSet(indexOfMessage: indexPath) {
            if objectMessages.count > 1 {
                updateRecentChatFromMessage(chatRoomId: chatRoomId, lastMessage: objectMessages[indexPath.item - 1][kMESSAGE] as! String)
            } else {
                updateRecentChatFromMessage(chatRoomId: chatRoomId, lastMessage: "")
            }
        }
        objectMessages.remove(at: indexPath.row)
        messages.remove(at: indexPath.row)
    }
    
    // MARK: UIImagePicker Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let picture = info[UIImagePickerControllerOriginalImage] as? UIImage
        picker.dismiss(animated: true, completion: nil)
        sendMessage(text: nil, date: Date(), picture: picture)
    }
    
    // MARK: UITextView Delegate
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        typingCounterStart()
        return true
    }
    // MARK: IBActions
    @objc func backButtonPressed(){
        clearUnreadMessageCounterFromMessage(chatRoomId: chatRoomId)
        removeListenersFromChatView()
        self.navigationController?.popViewController(animated: true)
        
    }
    
    @objc func savedImagesButtonPressed(){
        let savedImagesVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "savedImagesView") as! SavedImagesCollectionViewController
        savedImagesVC.imageLinks = allPictureMessages
        self.navigationController?.pushViewController(savedImagesVC, animated: true)
    }
    
    @objc func showUserProfile(){
        let contactVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "contactView") as! ContactTableViewController
        contactVC.user = self.withUser!
        self.navigationController?.pushViewController(contactVC, animated: true)
    }
    
    func presentUserProfile(forUser: User){
        let contactVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "contactView") as! ContactTableViewController
        contactVC.user = forUser
        self.navigationController?.pushViewController(contactVC, animated: true)
    }
    
    
    // MARK: Helper Functions
    
    func initVariables(){
        jsqAvatarDictionary = [:]
    }
    
    func setHeader(){
        leftBarButtonView.addSubview(avatarButton)
        leftBarButtonView.addSubview(nameLabel)
        leftBarButtonView.addSubview(onlineStatusLabel)
        
        avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
        let savedImagesButton = UIBarButtonItem(image: UIImage(named: "save")?.scaleImageToSize(newSize: CGSize(width: 25.0, height: 25.0)), style: .plain, target: self, action: #selector(self.savedImagesButtonPressed))
        self.navigationItem.rightBarButtonItem = savedImagesButton
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButtonView)
        self.navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        
        
        getUsersFromFirestore(withIds: memberIds) { (withUsers) in
            self.withUser = withUsers.first
            self.getAvatarImage()
            self.setHeaderData()
        }
    }
    
    func getAvatarImage(){
        if showAvatars {
            collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 25, height: 25)
            collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 25, height: 25)
            avatarImageFrom(user: User.username()!)
            avatarImageFrom(user: withUser!)
        }
        
        
    }
    
    func avatarImageFrom(user:User){
        if user.avatar != "" {
            dataImageFromString(pictureString: user.avatar) { (imageData) in
                if imageData != nil {
                    if self.avatarImageDictionary != nil {
                        self.avatarImageDictionary!.removeObject(forKey: user.objectId)
                        self.avatarImageDictionary!.setObject(imageData!, forKey: user.objectId as NSCopying)
                    } else {
                        self.avatarImageDictionary = [user.objectId : imageData!]
                    }
                    self.createJSQAvatarsFromImages(avatarDictionary: self.avatarImageDictionary)
                    
                } else {
                    return
                }
                
            }
        }
    }
    
    func createJSQAvatarsFromImages(avatarDictionary: NSMutableDictionary?){
        var jsqAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 50)
        if avatarDictionary != nil {
            for memberId in memberIds {
                if let avatarImageData = avatarDictionary![memberId] {
                    jsqAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: avatarImageData as! Data), diameter: 50)
                }
                self.jsqAvatarDictionary!.setValue(jsqAvatar, forKey: memberId)
            }
            self.collectionView.reloadData()
        }
    }
    
    func updateSender(){
        self.senderId = User.userId()
        self.senderDisplayName = User.username()!.firstname
    }
    
    func setHeaderData(){
        imageFromData(pictureData: self.withUser!.avatar) { (image) in
            if image != nil {
                avatarButton.setImage(image!.circleMasked, for: .normal)
            }
        }
        nameLabel.text = withUser!.fullname
        
        if withUser!.isOnline {
            onlineStatusLabel.text = "Online"
        } else {
            onlineStatusLabel.text = "Offline"
        }
        avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
    }
    
    
    func typingCounterStart(){
        typingCounter += 1
        typingCounterSave(isTyping: true)
        self.perform(#selector(self.typingCounterStop), with: nil, afterDelay: 2.5)
    }
    
    @objc func typingCounterStop(){
        typingCounter -= 1
    }
    
    func typingCounterSave(isTyping:Bool){
        reference(.Typing).document(chatRoomId).updateData([User.userId():isTyping])
    }
    
    
    func createTypingObserver(){
        typingListener = reference(.Typing).document(chatRoomId).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else {
                return
            }
            if snapshot.exists {
                for data in snapshot.data()! {
                    if data.key != User.userId() {
                        let typing = data.value  as! Bool
                        self.showTypingIndicator = typing
                        
                        if typing {
                            self.scrollToBottom(animated: true)
                        }
                        
                    }
                }
            } else {
                reference(.Typing).document(self.chatRoomId).setData([User.userId():false])
            }
            
        })
    }
    
   
    
    
    
    func sendMessage(text: String?, date: Date, picture: UIImage?){
        var outgoingMessage: OutgoingMessage?
        let currentUser = User.username()!
        if let text = text {
            outgoingMessage = OutgoingMessage(message: text, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kTEXT)
        }
        if let picture = picture {
            uploadImage(image: picture, chatRoomId: chatRoomId, view: self.navigationController!.view) { (imageLink) in
                if imageLink != nil {
                    outgoingMessage = OutgoingMessage(message: kPICTURE, imageLink: imageLink!, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kPICTURE)
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    outgoingMessage!.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush)
                }
            }
            return
        }
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        outgoingMessage!.sendMessage(chatRoomId: chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: memberIds, membersToPush: membersToPush)
    }
    
    func loadMessages(){
        ProgressHUD.show()
        
        updatedMessageStatusListener = reference(.Message).document(User.userId()).collection(chatRoomId).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else {
                return
            }
            if !snapshot.isEmpty {
                for change in snapshot.documentChanges {
                    if change.type == .modified {
                        self.updateMessage(messageDictionary: change.document.data() as NSDictionary)
                    }
                }
            }
        })
        reference(.Message).document(User.userId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 10).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else {
                self.initialLoadComplete = true
                self.listenForNewMessages()
                return
            }
            let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
            self.loadedMessages = self.removeInvalidMessages(allMessages: sorted)
            self.insertMessages()
            self.finishReceivingMessage(animated: true)
            self.initialLoadComplete = true
            self.getPicturesMessages()
            self.getOldMessages()
            self.listenForNewMessages()
            ProgressHUD.dismiss()
            
        }
    }
    
    func loadMoreMessages(maxNumber: Int, minNumber: Int){
        if loadOldMessages {
            maxMessagesNumber = minNumber - 1
            minMessagesNumber  = maxMessagesNumber - kNUMBEROFMESSAGES
        }
        
        for i in (minMessagesNumber...maxMessagesNumber).reversed() {
            let messageDictionary = loadedMessages[i]
            self.insertNewMessage(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
        }
        loadOldMessages = true
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    func updateMessage(messageDictionary: NSDictionary) {
        for index in 0..<objectMessages.count {
            let current = objectMessages[index]
            if (messageDictionary[kMESSAGEID] as! String) == (current[kMESSAGEID]  as! String){
                objectMessages[index] = messageDictionary
                self.collectionView!.reloadData()
            }
        }
    }
    func insertNewMessage(messageDictionary: NSDictionary) {
        let incomingMessage = IncomingMessage(collectionView: self.collectionView)
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        objectMessages.insert(messageDictionary, at: 0)
        messages.insert(message!, at: 0)
    }
    
    
    func getOldMessages(){
        if self.loadedMessages.count > 9 {
            let firstMessageDate = (loadedMessages.first!)[kDATE] as! String
            reference(.Message).document(User.userId()).collection(chatRoomId).whereField(kDATE, isLessThan: firstMessageDate).getDocuments { (snapshot, error) in
                guard let snapshot = snapshot else {
                    return
                }
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
                
                
                self.loadedMessages = self.removeInvalidMessages(allMessages: sorted) + self.loadedMessages
                self.getPicturesMessages()
                self.maxMessagesNumber = self.loadedMessages.count - self.loadedMessagesCount - 1
                self.minMessagesNumber = self.maxMessagesNumber - kNUMBEROFMESSAGES
            }
        }
    }
    
    func listenForNewMessages(){
        var lastMessageDate = "0"
        if loadedMessages.count > 0 {
            lastMessageDate = (loadedMessages.last!)[kDATE] as! String
        }
        newMessageListener = reference(.Message).document(User.userId()).collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener({ (snapshot, eroor) in
            guard let snapshot = snapshot else {
                return
            }
            if !snapshot.isEmpty {
                
                for diff in snapshot.documentChanges {
                    if (diff.type == .added) {
                        let item = diff.document.data() as NSDictionary
                        if let type = item[kTYPE] {
                            if self.types.contains(type as! String) {
                                if type as! String == kPICTURE {
                                    self.allPictureMessages.append(item[kPICTURE] as! String)
                                }
                                
                                if self.insertInitialMessages(messageDictionary: item) {
                                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                }
                                self.finishReceivingMessage()
                            }
                        }
                    }
                }
            }
        })
    }
    
    
    func getPicturesMessages(){
        allPictureMessages = []
        for message in loadedMessages {
            if message[kTYPE] as! String == kPICTURE {
                allPictureMessages.append(message[kPICTURE] as! String)
            }
        }
    }
    
    
    func removeListenersFromChatView(){
        if typingListener != nil {
            typingListener!.remove()
        }
        if newMessageListener != nil {
            newMessageListener!.remove()
        }
        if updatedMessageStatusListener != nil {
            updatedMessageStatusListener!.remove()
        }
    }
    
    func insertMessages() {
        maxMessagesNumber = loadedMessages.count - loadedMessagesCount
        minMessagesNumber = maxMessagesNumber - kNUMBEROFMESSAGES
        for i in minMessagesNumber ..< maxMessagesNumber {
            let messageDictionary = loadedMessages[i]
            insertInitialMessages(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
        }
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    func insertInitialMessages(messageDictionary: NSDictionary) -> Bool{
        let incomingMessage = IncomingMessage(collectionView: self.collectionView)
        if (messageDictionary[kSENDERID] as! String) != User.userId() {
            OutgoingMessage.updateMessage(messageId: messageDictionary[kMESSAGEID] as! String, chatRoomId: chatRoomId, memberIds: memberIds)
        }
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        if message != nil {
            objectMessages.append(messageDictionary)
            messages.append(message!)
        }
        
        return (findMessageType(messageDictionary: messageDictionary) == INCOMING_MESSAGE)
    }
    
    func removeInvalidMessages(allMessages: [NSDictionary]) -> [NSDictionary]{
        var messages = allMessages
        for message in messages {
            if message[kTYPE] != nil {
                if !self.types.contains(message[kTYPE] as! String){
                    messages.remove(at: messages.firstIndex(of: message)!)
                }
            } else {
                messages.remove(at: messages.firstIndex(of: message)!)
            }
        }
        return messages
    }
    
    func findMessageType(messageDictionary: NSDictionary) -> String{
        if User.userId() == messageDictionary[kSENDERID] as! String {
            return OUTGOING_MESSAGE
        } else {
            return INCOMING_MESSAGE
        }
    }
    
    func readTimeFrom(dateString: String) -> String {
        let date = dateFormatter().date(from: dateString)
        let currentDateFormat = dateFormatter()
        currentDateFormat.dateFormat = "HH:mm"
        return currentDateFormat.string(from: date!)
    }
    
    func isLastInSet(indexOfMessage: IndexPath) -> Bool {
        if indexOfMessage.item == messages.count - 1 {
            return true
        } else {
            return messages[indexOfMessage.item].senderId != messages[indexOfMessage.item + 1].senderId
        }
    }

}

// MARK: iPhone X Search Bar Constraint Fix
extension JSQMessagesInputToolbar {
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = window else { return }
        if #available(iOS 11.0, *) {
            let anchor = window.safeAreaLayoutGuide.bottomAnchor
            bottomAnchor.constraintLessThanOrEqualToSystemSpacingBelow(anchor, multiplier: 1.0).isActive = true
        }
    }
}

extension UIFont {
    func bold() -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits.traitBold)
        return UIFont(descriptor: descriptor!, size: 0)
    }
}
