//
//  ChatController.swift
//  Missito
//
//  Created by George Poenaru on 16/08/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit
import AVKit
import Photos
import Contacts
import MessageUI
import RealmSwift
import ContactsUI
import AVFoundation
import DateToolsSwift
import FontAwesome_swift
import MobileCoreServices
import IQKeyboardManagerSwift
import MBProgressHUD

class ChatController: UIViewController, UITableViewDelegate, ChatDataSourceDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CNContactPickerDelegate,
    MFMailComposeViewControllerDelegate, CNContactViewControllerDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var toolBar: MessageToolbar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lastSeen: UILabel!
    @IBOutlet weak var chatTitle: UILabel!
    private var defaultContentInset = UIEdgeInsets.zero
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    private var toolbarBottomConstraintDefaultConst: CGFloat = 0
    private var bottomScrollButton = UIButton()

    var contact: Contact?
    
    @IBOutlet var equalizerView: EqualizerView!
    @IBOutlet var deleteAudioContainer: DeleteAudioContainerView!
    
    private var deleteOnDrop = false
    
    private var equalizerInitialLocation = CGPoint.zero
    private let imagePicker = UIImagePickerController()
    
    static let mapPlaceholderUIImage = UIImage(named: "map-pointer")
    var mapSnapshotsDictionary: [Int:UIImage] = [:]

    private var dataSource: ChatDataSource?
    private var companionPhone = ""
    
    private var withLocation: RealmLocation?
    private var realmAudio: RealmAudio?
    
    private var status: ContactStatus?

    private var allowedSendTypingOn = true
    private var myTypingDebouncer: Debouncer?
    private var companionTypingDebouncer: Debouncer?
    
    private var initialScrollToBottom = true
    
    private var panGesture: UIPanGestureRecognizer?
    private var longClickGesture: UILongPressGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbarBottomConstraintDefaultConst = toolbarBottomConstraint.constant
        if #available(iOS 11, *) {} else {
            self.defaultContentInset = UIEdgeInsets.init(top: self.navigationController!.navigationBar.frame.height + UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)
        }
        
        let progressRepo = CompositeProgressRepository.init(repo1: CoreServices.senderService!, repo2: CoreServices.downloadService!)
        dataSource = ChatDataSource(contact: contact, delegate: self, loadProgressRepo: progressRepo)
        tableView.dataSource = dataSource
        
        tableView.register(UINib(nibName: "IncomingTextChatCell", bundle: nil), forCellReuseIdentifier: "inTxt")
        tableView.register(UINib(nibName: "IncomingImageChatCell", bundle: nil), forCellReuseIdentifier: "inImg")
        tableView.register(UINib(nibName: "IncomingAudioChatCell", bundle: nil), forCellReuseIdentifier: "inAudio")
        tableView.register(UINib(nibName: "IncomingContactChatCell", bundle: nil), forCellReuseIdentifier: "inContact")
        tableView.register(UINib(nibName: "IncomingMapChatCell", bundle: nil), forCellReuseIdentifier: "inGeo")
        tableView.register(UINib(nibName: "IncomingVideoChatCell", bundle: nil), forCellReuseIdentifier: "inVideo")
        tableView.register(UINib(nibName: "OutgoingTextChatCell", bundle: nil), forCellReuseIdentifier: "outTxt")
        tableView.register(UINib(nibName: "OutgoingImageChatCell", bundle: nil), forCellReuseIdentifier: "outImg")
        tableView.register(UINib(nibName: "OutgoingContactChatCell", bundle: nil), forCellReuseIdentifier: "outContact")
        tableView.register(UINib(nibName: "OutgoingMapChatCell", bundle: nil), forCellReuseIdentifier: "outGeo")
        tableView.register(UINib(nibName: "OutgoingAudioChatCell", bundle: nil), forCellReuseIdentifier: "outAudio")
        tableView.register(UINib(nibName: "OutgoingVideoChatCell", bundle: nil), forCellReuseIdentifier: "outVideo")

        tableView.register(UINib(nibName: "ChatSectionHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "sectionHeader")

        initDebouncers()
        imagePicker.delegate = self
        imagePicker.mediaTypes = ["public.movie", "public.image"]
        
        companionPhone = contact?.phone ?? ""
        status = ContactsStatusManager.getStatus(phone: companionPhone)
        populateMessages()
        
        //Set Scroll Bottom Button
        bottomScrollButton.frame = CGRect(x: self.view.frame.width - 48, y: (self.view.frame.height - 98), width: 40, height: 40)
        bottomScrollButton.addTarget(self, action: #selector(scrollDownAction), for: .touchUpInside)
        bottomScrollButton.layer.cornerRadius = bottomScrollButton.frame.height * 0.5
        bottomScrollButton.layer.masksToBounds = true
        bottomScrollButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        let attributedTitle = NSAttributedString(string: String.fontAwesomeIcon(name: .angleDown), attributes: [NSFontAttributeName: UIFont.fontAwesome(ofSize: 30), NSForegroundColorAttributeName : UIColor.white])
        bottomScrollButton.setAttributedTitle(attributedTitle, for: .normal)
        view.addSubview(bottomScrollButton)
        
        chatTitle.text = contact?.formatFullName()
        lastSeen.text = status?.getStatusLabel()
        
        tableView.contentSize = CGSize(width: tableView.frame.size.width, height: tableView.frame.size.height)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(_:)),
//                                                name: NSNotification.Name.UIKeyboardWillChangeFrame,
//                                                object: nil)

        // Do any additional setup after loading the view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        toolBar.messagesTextField.returnKeyType = .send
        toolBar.messagesTextField.delegate = self
        toolBar.sendMessageButton.addTarget(self, action: #selector (ChatController.sendMessageButtonClicked), for: .touchUpInside)
        toolBar.attachmentButton.action = #selector (ChatController.selectAttachmentType)
        toolBar.cameraButton.action = #selector (ChatController.openCamera)
        toolBar.galleryButton.action = #selector (ChatController.openGallery)
        
        panGesture = UIPanGestureRecognizer(target:self, action: #selector(onDraggedEqualizer))
        longClickGesture = UILongPressGestureRecognizer(target: self, action: #selector(onRecordAudioButtonClicked))
        longClickGesture!.minimumPressDuration = 0.1
        longClickGesture!.delegate = self
        panGesture!.delegate = self
        toolBar.micButton.addGestureRecognizer(panGesture!)
        toolBar.micButton.addGestureRecognizer(longClickGesture!)
        
        equalizerView.timerFinishedCallback = {
            MissitoAudioRecorder.shared?.pause()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatController.onNewMessage(notification:)),
                                               name: MQTTMissitoClient.NEW_MSG_NOTIF, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatController.mqttMessageStatusUpdate(notification:)),
                                               name: MQTTMissitoClient.MESSAGE_STATUS_UPDATE_NOTIF, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatController.localMessageStatusUpdate(notification:)),
                                               name: AuthService.LOCAL_MESSAGE_STATUS_UPDATE_NOTIF, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatController.localContactsStatusUpdate(notification:)),
                                               name: ContactsStatusManager.CONTACT_STATUS_UPDATE_NOTIF, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard),
                                               name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard),
                                               name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ChatController.addNewMessageItem(notification:)),
                                               name: MessageSenderService.ADD_NEW_ITEM_NOTIF, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ChatController.markMessageSaved(notification:)),
                                               name: MessageSenderService.MARK_SAVED_NOTIF, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ChatController.updateMessageItem(notification:)),
                                               name: MessageSenderService.UPD_MSG_ITEM_NOTIF, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ChatController.reportEncryptionFailure(notification:)),
                                               name: MessageSenderService.REPORT_ENCR_FAIL_NOTIF, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ChatController.onDownload(notification:)),
                                               name: DownloadService.DOWNLOAD_FINISH_NOTIF, object: nil)

    }
        
    func adjustForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == Notification.Name.UIKeyboardWillHide {
            tableView.contentInset = defaultContentInset
            toolbarBottomConstraint.constant = toolbarBottomConstraintDefaultConst
        } else {
            tableView.contentInset = UIEdgeInsets(top: defaultContentInset.top, left: defaultContentInset.left,
                                                  bottom: keyboardViewEndFrame.height, right: defaultContentInset.right)
            toolbarBottomConstraint.constant = toolbarBottomConstraintDefaultConst + keyboardViewEndFrame.height
        }
        
        tableView.scrollIndicatorInsets = tableView.contentInset
        // For smooth animation
        self.view.layoutIfNeeded()
        scrollToBottom()
    }
    
    func openCamera() {
        self.showImagePicker(for: .camera)
    }
    
    func openGallery() {
        self.showImagePicker(for: .photoLibrary)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        toolBar.focusReceived()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        toolBar.focusLost()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if (initialScrollToBottom) {
            scrollToBottom(false)
            initialScrollToBottom = false
            toolBar.setCorrectSize()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        toolBar.layoutSubviews()
        toolBar.messagesTextField.delegate = self
        IQKeyboardManager.sharedManager().enable = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MissitoAudioPlayerManager.stop()
        toolBar.messagesTextField.delegate = nil
        toolBar.focusLost()
        IQKeyboardManager.sharedManager().enable = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        toolBar.micButton.removeGestureRecognizer(panGesture!)
        toolBar.micButton.removeGestureRecognizer(longClickGesture!)
        NotificationCenter.default.removeObserver(self)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let missitoAudioRecorder = MissitoAudioRecorder.shared, gestureRecognizer is UIPanGestureRecognizer {
            return missitoAudioRecorder.isRecording() || missitoAudioRecorder.isPaused()
        }
        return true
    }
    
    func onDraggedEqualizer(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        equalizerView.center =
            CGPoint(
                x: equalizerInitialLocation.x + translation.x,
                y: equalizerInitialLocation.y + translation.y
        )
        
        if deleteAudioContainer.frame.contains(equalizerView.center) {
            deleteOnDrop = true
        } else {
            deleteOnDrop = false
        }
        
        deleteAudioContainer.updateIcon(deleteOnDrop)
    }
    
    func onRecordAudioButtonClicked(recognizer: UIGestureRecognizer) {
        switch recognizer.state {
        case .began:
            if let missitoAudioRecorder = MissitoAudioRecorder.shared {
                if missitoAudioRecorder.hasPermission() {
                    missitoAudioRecorder.startRecording(contact?.phone)
                    setupUiForRecording()
                } else {
                    missitoAudioRecorder.requestRecordPermission(with: self)
                }
            } else {
                Utils.alert(viewController: self, title: "An error occured", message: "Could not use audio record tools")
            }
        case .ended:
            deleteAudioContainer.isHidden = true
            deleteAudioContainer.updateIcon(false)
            equalizerView.isHidden = true
            equalizerView.recordingStopped()
            MissitoAudioRecorder.shared?.finishRecording(success: !deleteOnDrop) { realmAudio in
                CoreServices.senderService?.handleNewAudio(destPhone: self.companionPhone, realmAudio: realmAudio)
            }
        default:
            break;
        }
    }

    func setupUiForRecording() {
        equalizerView.isHidden = false
        deleteAudioContainer.isHidden = false
        
        if equalizerInitialLocation == CGPoint.zero {
            equalizerInitialLocation = equalizerView.center
        } else {
            equalizerView.center = equalizerInitialLocation
        }
        
        equalizerView.recordingStarted()
    }
    
    @IBAction func onContactSettingsTap(_ sender: Any) {
        
    }
    
//    @IBAction func onContactBlockTap(_ sender: Any) {
//        ContactsStatusManager.revertUserBlockStatus(phone: companionPhone) { (error, blocked) in
//            if error == nil {
//                self.updateBlockContactButton()
//            }
//        }
//    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMap" {
            let vc = (segue.destination as! MapViewController)
            if let withLocation = withLocation {
                vc.location = withLocation
                self.withLocation = nil
            } else {
                vc.allowSelection = true
                vc.onLocationSelected = { label, latitude, longitude, radius in
                    CoreServices.senderService?.prepareLocationForSend(destPhone: self.companionPhone,
                                                            realmLocation: RealmLocation(label: label,
                                                              lat: latitude,
                                                              lon: longitude,
                                                              radius: radius))
                }
            }
        } else if segue.identifier == "showUser" {
            let vc = (segue.destination as! ContactInfoViewController)
            vc.contact = contact
            vc.onHistoryCleared = {
                self.populateMessages()
                NotificationCenter.default.post(name: MissitoRealmDbHelper.CONVERSATIONS_UPDATE, object: nil, userInfo: nil)
            }
        }
    }
    
    func selectAttachmentType() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let actions = [
            UIAlertAction(title: "Location", style: .default) { action in
                self.performSegue(withIdentifier: "showMap", sender: nil)
            },
            UIAlertAction(title: "Contact", style: .default) { action in
                self.showContactPicker()
            },
            UIAlertAction(title: "Cancel", style: .cancel)
        ]
        
        for action in actions {
            actionSheet.addAction(action)
        }
        
        present(actionSheet, animated: true)
    }
    
    func showContactPicker() {
        let peoplePicker = CNContactPickerViewController()
        
        peoplePicker.delegate = self
        present(peoplePicker, animated: true, completion: nil)
    }
    
    func showImagePicker(for type: UIImagePickerControllerSourceType) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = type
        if type == .camera {
            switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
            case .authorized:
                present(imagePicker, animated: true, completion: nil)
            case .denied, .restricted:
                showNoCameraPermissionAlert()
            case .notDetermined:
                //Ask for permissions
                AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
                    DispatchQueue.main.async {
                        if granted {
                            self.present(self.imagePicker, animated: true, completion: nil)
                        } else {
                            //Nothing to show.
                            //User haven't granted permission and we won't ask him again right now
                        }
                    }
                }
            }
        } else if type == .photoLibrary {
            requestGalleryAuthorization {
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    func requestGalleryAuthorization(_ successfullAuthorization: @escaping ()->()) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            successfullAuthorization()
        case .denied, .restricted:
            showNoGalleryPermissionAlert()
        case .notDetermined:
            //Ask for permissions
            PHPhotoLibrary.requestAuthorization() { status in
                if status == .authorized {
                    DispatchQueue.main.async {
                        successfullAuthorization()
                    }
                }
            }
        }
    }
    
    private func showNoCameraPermissionAlert() {
        Utils.alert(viewController: self, title: "Camera is unavailable", message: "The camera could not be turned on, please check your device's settings", actions:
            [
                UIAlertAction(title: "Cancel", style: .cancel),
                UIAlertAction(title: "Open Settings", style: .default) { action in
                    UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                }
            ]
        )
    }
    
    private func showNoGalleryPermissionAlert() {
        Utils.alert(viewController: self, title: "Photos is unavailable", message: "Photos could not be opened, please check your device's settings", actions:
            [
                UIAlertAction(title: "Cancel", style: .cancel),
                UIAlertAction(title: "Open Settings", style: .default) { action in
                    UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                }
            ]
        )
    }
    
    // MARK: - CNContactPickerViewController delegate methods
    
    func contactPickerDidCancel(picker: CNContactPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        picker.dismiss(animated: true, completion: nil)
        CoreServices.senderService?.prepareContactForSend(destPhone: companionPhone, contact: contact)
    }

    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        // Handle a movie capture
        if mediaType == kUTTypeMovie {
            DispatchQueue.global().async {
                //Reference to new or compressed video in tmp directory
                let mediaURL = info[UIImagePickerControllerMediaURL] as! URL
                do {
                    let videoData = try Data.init(contentsOf: mediaURL)
                    // Get url by contact phone number and file name
                    let url = Utils.getFileURL(phone: self.contact?.phone, fileName: mediaURL.lastPathComponent)
                    // Check url and write data from temp to documents
                    if let url = url {
                        try videoData.write(to: url)
                        DispatchQueue.main.async {
                            CoreServices.senderService?.prepareVideoForSend(destPhone: self.companionPhone, fromURL: url)
                        }
                    } else {
                        Utils.showErrorAdded(to: self.view, duration: 2, title: "Couldn't attach video")
                        NSLog("Error: couldn't get url for video attachment.")
                    }
                } catch {
                    Utils.showErrorAdded(to: self.view, duration: 2, title: "Couldn't attach video")
                    NSLog("Error while copying video file from temp to documents directory. Error domain: \((error as NSError).domain), error description: \(error.localizedDescription)")
                }
            }
        } else {
            let url = info[UIImagePickerControllerReferenceURL] as? URL
            if let url = url,
                let asset = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil).firstObject,
                let assetInfo = PHAssetResource.assetResources(for: asset).first {
                let options = PHImageRequestOptions()
                options.version = .original
                options.isNetworkAccessAllowed = true
                options.isSynchronous = false
                
                let loadingIndicator = Utils.showProgress(message: "Loading image..", view: view)
                PHImageManager.default().requestImageData(for: asset, options: options) {
                    imageData, dataUTI, orientation, info in
                    // More about returned values https://developer.apple.com/documentation/photos/phimagemanager/1616957-requestimagedata
                    if let imageData = imageData, let uiImage = UIImage.init(data: imageData), let dataUTI = dataUTI {
                        print("Loading image")
                        CoreServices.senderService?.prepareImageForSend(destPhone: self.companionPhone, image: uiImage, assetInfo.originalFilename, dataUTI)
                        loadingIndicator.hide(animated: true)
                    }
                }
            } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                CoreServices.senderService?.prepareImageForSend(destPhone: self.companionPhone, image: image, String(NSDate().timeIntervalSince1970) + ".jpeg", "public.jpeg")
            } else {
                NSLog("Path == nil: Failed to receive 'path = UIImagePickerControllerReferenceURL as? URL'. 'path.absoluteString' returned nil")
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func onNewMessage(notification: Notification) {
        if let userInfo = notification.userInfo as Dictionary<AnyHashable, Any>? {
            if let msg = userInfo[MQTTMissitoClient.MISSITO_MESSAGE_KEY] as? MissitoMessage, msg.incomingMessage.senderUid == contact?.phone {

                setMessageSeen(withServerIds: [msg.incomingMessage.serverMsgId])

                let isTypingMessage = msg.body.isTyping()
                let message = IncomingChatMessage(missitoMessage: msg, senderContact: contact!)
                
                var needScrollToBottom = false
                
                // https://stackoverflow.com/questions/4099188/uitableviews-indexpathsforvisiblerows-incorrect
                _ = tableView.visibleCells
                if let lastRow = dataSource?.lastIndexPath()?.row, let lastVisibleRow = tableView.indexPathsForVisibleRows?.last?.row {
                    needScrollToBottom = lastRow - lastVisibleRow <= 3
                }
                
                if isTypingMessage {
                    companionTypingDebouncer?.call()
                    
                    guard let dataSource = dataSource, !dataSource.lastMessageIsForTyping() else {
                        return
                    }
                    
                    dataSource.append(message: message)
                } else {
                    dataSource?.insert(message: message)
                }
                
                tableView.reloadData()
                if needScrollToBottom {
                    scrollToBottom()
                }
            }
        }
    }
    
    func mqttMessageStatusUpdate(notification: Notification) {
        if let userInfo = notification.userInfo {
            if let msgStatus = userInfo[MQTTMissitoClient.MESSAGE_STATUS_KEY] as? MessageStatus,
                let newStatus = RealmMessage.OutgoingMessageStatus(rawValue: msgStatus.status) {
                
                if let indexPath = dataSource?.findBy(serverId: msgStatus.serverMsgId) {
                    
                    guard let message = dataSource![indexPath] as? OutgoingChatMessage else {
                        return
                    }
                    if message.status != .seen {
                        message.status = newStatus
                        NSLog("Message %@ status: %@", msgStatus.serverMsgId, msgStatus.status)
                    } else {
                        NSLog("Attemp to change status from .seen to .%@ was suppressed!", msgStatus.status)
                    }
                    
                    tableView.reloadData()
                }
            }
        }
    }
    
    func localMessageStatusUpdate(notification: Notification) {
        if let userInfo = notification.userInfo {
            if let localUpdate = userInfo[AuthService.MESSAGE_STATUS_KEY] as? LocalMessageStatus {
                
                if let indexPath = dataSource?.findBy(id: localUpdate.id) {
                
                    guard let message = dataSource![indexPath] as? OutgoingChatMessage else {
                        return
                    }
                    let prevStatus = message.status
                    message.status = localUpdate.status
                    message.serverId = localUpdate.serverId
                    message.date = localUpdate.timeSent
                    if prevStatus == .outgoing {
                        dataSource!.insert(message: dataSource!.remove(at: indexPath) as! ChatMessage)
                    }
                    tableView.reloadData()
                }
            }
        }
    }
    
    func localContactsStatusUpdate(notification: Notification) {
        self.status = ContactsStatusManager.getStatus(phone: companionPhone)
        self.lastSeen.text = status?.getStatusLabel()
    }
    
    func populateMessages() {
        let serverIds = dataSource!.populateMessages()
        
        tableView.reloadData()

        if !serverIds.isEmpty {
            setMessageSeen(withServerIds: serverIds)
        }
    }
    
    func setMessageSeen(withServerIds: [String]) {
        MissitoRealmDbHelper.updateMessagesIncomingStatus(withServerIds: withServerIds, status: .seen)
        MissitoRealmDbHelper.updateUnreadMessagesCounter(for: companionPhone, increment: false)
        APIRequests.updateMessageStatus(received: [], seen: withServerIds) {
            (updatedMessages, apiError) in
            if let error = apiError {
                NSLog("Could not confirm message(-s): " + error.localizedDescription)
            } else {
                if let updatedServerIds = updatedMessages?.updated {
                    MissitoRealmDbHelper.updateMessagesIncomingStatus(withServerIds: updatedServerIds, status: .seenAck)
                    NSLog("Message(-s) confirmed")
                } else {
                    NSLog("Not allowed to confirm messages as seen: %@", withServerIds)
                }
            }
        }
    }
    
    func sendTypingMessage() {
        if allowedSendTypingOn {
            allowedSendTypingOn = false
            CoreServices.senderService?.sendTypingMessage(destPhone: companionPhone)
            myTypingDebouncer?.call()
        }
    }
    
    func initDebouncers() {
        myTypingDebouncer = Debouncer(delay: 4) { [weak self] dispatchedWorkItem in
            guard !dispatchedWorkItem.isCancelled else {
                return
            }
            
            self?.allowedSendTypingOn = true
        }
        
        companionTypingDebouncer = Debouncer(delay: 5) { [weak self] dispatchedWorkItem in
            guard !dispatchedWorkItem.isCancelled else {
                return
            }
            
            DispatchQueue.main.sync {
                
                if let dataSource = self?.dataSource, dataSource.lastMessageIsForTyping() {
                    dataSource.removeLast()
                    self?.tableView.reloadData()
                }                
                
            }
        }
    }
    
    func setTypingSendAllowed() {
        allowedSendTypingOn = true
        myTypingDebouncer?.stop()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        toolBar.focusReceived()
        sendTypingMessage()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        CoreServices.senderService?.sendMessage(destPhone: companionPhone, text: textField.text)
        onTextSend()
        return false
    }
    
    func sendMessageButtonClicked() {
        CoreServices.senderService?.sendMessage(destPhone: companionPhone, text: toolBar.messagesTextField.text)
        onTextSend()
    }
    
    func onTextSend() {
        toolBar.messagesTextField.text = nil
        setTypingSendAllowed()
    }
    
    func reloadVisibleCell(messageId: String) {
        for cell in tableView.visibleCells {
            if let cell = cell as? BaseChatCell {
                if cell.message?.id == messageId,
                    let indexPath = tableView.indexPath(for: cell) {
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
    }
    
    func addNewMessageItem(notification: Notification) {
        if let userInfo = notification.userInfo {
            if let message = userInfo[MessageSenderService.MESSAGE_KEY] as? RealmMessage {
                dataSource?.appendCheckingForTyping(message: ChatMessage.make(from: message, companion: contact))
                self.tableView.reloadData()
                self.scrollToBottom()
            }
        }
    }
    
    func updateMessageItem(notification: Notification) {
        if let userInfo = notification.userInfo {
            if let messageId = userInfo[MessageSenderService.MESSAGE_ID_KEY] as? String {
                reloadVisibleCell(messageId: messageId)
            }
        }
    }
    
    func markMessageSaved(notification: Notification) {
        if let userInfo = notification.userInfo {
            if let messageId = userInfo[MessageSenderService.MESSAGE_ID_KEY] as? String,
                let messageIdData = userInfo[MessageSenderService.MESSAGE_ID_DATA_KEY] as? MessageIdData {
                if let indexPath = dataSource?.findBy(id: messageId) {
                    if let msg = dataSource?[indexPath] as? OutgoingChatMessage {
                        msg.status = .sent
                        msg.serverId = messageIdData.serverMsgId
                        tableView.reloadData()
                    }
                }
            }
        }
    }
    
    func reportEncryptionFailure(notification: Notification) {
        if let userInfo = notification.userInfo {
            if let messageId = userInfo[MessageSenderService.MESSAGE_ID_KEY] as? String {
                // TODO: check that messageId belongs to this chat
                NSLog("Encryption failure for %@", messageId)
                Utils.alert(viewController: self, title: "Can't encrypt message", message: "Probably one of chat members has changed his identity key.")
            }
        }
    }
    
    func onDownload(notification: Notification) {
        if let userInfo = notification.userInfo {
//            let fileUrl = userInfo[DownloadService.URL_KEY] as? String
            let error = userInfo[DownloadService.ERROR_KEY] as? Error
            let messageId = userInfo[DownloadService.MESSAGE_ID_KEY] as? String
            
            if let _ = error {
                Utils.alert(viewController: self, title: "Error", message: "Can't download attachment file")
            } else {
                if let messageId = messageId {
                    reloadVisibleCell(messageId: messageId)
                }
            }
        }
    }
    
    func hideKeyboard() {
        toolBar.focusLost()
        toolBar.messagesTextField.endEditing(true)
    }
    
    func keyboardNotification(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo {
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions().rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            UIView.animate(withDuration: duration,
                                       delay: TimeInterval(0),
                                       options: animationCurve,
                                       animations: { self.view.layoutIfNeeded() },
                                       completion: nil)
        }
    }
    
    func saveContact(_ realmContact: RealmAttachmentContact) {
        let controller = CNContactViewController(forUnknownContact : realmContact.toCNContact())
        controller.contactStore = CNContactStore()
        controller.delegate = self
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: - CNContactViewController delegate methods
    
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func sendEmail(_ email: String) {
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        composeVC.setToRecipients([email])
        present(composeVC, animated: true, completion: nil)
    }
    
    // MARK: - MFMailComposeViewController delegate methods
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func call(_ phone: String) {
        Utils.call(phone: phone, viewController: self)
    }
    
    func openMap(message: ChatMessage) {
        if let attachment = message.attachment, attachment.locations.count > 0 {
            withLocation = attachment.locations[0]
            performSegue(withIdentifier: "showMap", sender: nil)
        }
    }
    
    // MARK: - Table view delegate methods
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "sectionHeader") as! ChatSectionHeader
        var deviceIdSwitch = false
        let currentSection = dataSource!.sections[section]
        if section > 0 {
            let prevSection = dataSource!.sections[section - 1]
            deviceIdSwitch = prevSection.counterpartyDeviceId != -1 &&
                prevSection.counterpartyDeviceId != currentSection.counterpartyDeviceId
        }
        headerView.headerLabel.text = currentSection.formatTitle(contact: contact!, switchedSenderDeviceId: deviceIdSwitch)
        return headerView
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func getCellHeight(for indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = UITableViewAutomaticDimension
        
        if let sections = dataSource?.sections {
            let message = sections[indexPath.section].messages[indexPath.row]
            if message.type == .typing {
                return 62
            }
            
            if message.direction == BaseChatMessage.Direction.incoming {
                switch message.type {
                case .text:
                    height = IncomingTextChatCell.getHeight(message as! IncomingChatMessage)
                case .image:
                    height = IncomingImageChatCell.getHeight(message as! IncomingChatMessage)
                case .audio:
                    height = IncomingAudioChatCell.getHeight()
                case .geo:
                    height = IncomingMapChatCell.getMapCellHeight(message as! IncomingChatMessage)
                case .contact:
                    height = IncomingContactChatCell.getHeight(message as! IncomingChatMessage)
                case .video:
                    height = IncomingVideoChatCell.getHeight(message as! IncomingChatMessage)
                default: break
                }
            } else {
                switch message.type {
                case .text:
                    height = OutgoingTextChatCell.getHeight(message as! OutgoingChatMessage)
                case .image:
                    height = OutgoingImageChatCell.getHeight(message as! OutgoingChatMessage)
                case .audio:
                    height = OutgoingAudioChatCell.getHeight()
                case .geo:
                    height = OutgoingMapChatCell.getMapCellHeight(message as! OutgoingChatMessage)
                case .contact:
                    height = OutgoingContactChatCell.getHeight(message as! OutgoingChatMessage)
                case .video:
                    height = OutgoingVideoChatCell.getHeight(message as! OutgoingChatMessage)
                default: break
                }
            }
            height = ceil(height)
        }
//        NSLog("Cell %d %d height=%f", indexPath.section, indexPath.row, ceil(height))
        return height
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return getCellHeight(for: indexPath)
    }
    
    // MARK: - ChatDataSource delegate methods
    
    internal func getMapSnapshot(_ indexPath: IndexPath, _ location: RealmLocation, _ size: CGSize) -> UIImage? {
        if let image = mapSnapshotsDictionary[indexPath.row] {
            return image
        } else {
            mapSnapshotsDictionary[indexPath.row] = ChatController.mapPlaceholderUIImage
            Utils.getMapSnapshot(size, location) { uiImage in
                if let image = uiImage {
                    self.mapSnapshotsDictionary[indexPath.row] = image
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                } else {
                    NSLog("Could not create image")
                }
            }
            return ChatController.mapPlaceholderUIImage
        }
    }
    
    func onContactClicked(message: ChatMessage) {
        if let attachment = message.attachment {
            if attachment.contacts.count > 0 {
                let contact = attachment.contacts[0]
                let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                for x in contact.phones {
                    actionSheet.addAction(UIAlertAction(title: String.init(format: "Call %@", x.stringValue), style: .default) { action in
                        self.call(x.stringValue)
                    })
                }
                if MFMailComposeViewController.canSendMail() {
                    for x in contact.emails {
                        actionSheet.addAction(UIAlertAction(title: String.init(format: "Email %@", x.stringValue), style: .default) { action in
                            self.sendEmail(x.stringValue)
                        })
                    }
                }
                actionSheet.addAction(UIAlertAction(title: "Save Contact", style: .default) { action in
                    self.saveContact(contact)
                })
                actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                self.present(actionSheet, animated: true)
            }
        }
    }
    
    func onImageClicked(message: ChatMessage, indexPath: IndexPath) {
        showImageFullScreen(message: message)
    }
    
    func onTextMessageTap(message: ChatMessage) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let copyAction = UIAlertAction(title: "Copy", style: .default) { (action) in
            UIPasteboard.general.string = message.text
        }
//        let forwardAction = UIAlertAction(title: "Forward", style: .default) { (action) in
//
//        }
//        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
//
//        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(copyAction)
//        alertController.addAction(forwardAction)
//        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func showImageFullScreen(message: ChatMessage) {
        let fullScreenController = UIStoryboard(name: "Chats", bundle: nil)
            .instantiateViewController(withIdentifier: "FullScreenImageViewController") as! FullScreenImageViewController
        
        fullScreenController.message = message
        fullScreenController.phone = contact?.phone
        
        present(fullScreenController, animated: true, completion: nil)
    }
    
    func onVideoClicked(message: ChatMessage, indexPath: IndexPath) {
        if let attach = message.attachment, let video = attach.video.first {
            // Check if file exist under path
            if let fileURL = Utils.getFileURL(phone: contact?.phone, fileName: video.fileName), AVAsset(url: fileURL).isPlayable {
                playVideo(url: fileURL)
            } else {
                CoreServices.downloadService?.downloadVideoFile(senderPhone: companionPhone, message: message)
            }
        }
    }
    
    private func playVideo(url: URL) {
        let player = AVPlayer(url: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
    }
    
    //MARK: - Quick bottom scroll

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateScrollToBottomButtonVisibility()
    }
    
    func updateScrollToBottomButtonVisibility() {
        if tableView.contentOffset.y < tableView.contentSize.height - tableView.frame.height - 0.1 {
            bottomScrollButton.isHidden = false
        } else {
            bottomScrollButton.isHidden = true
        }
    }
    
    func scrollDownAction() {
        self.scrollToBottom()
    }
    
    func scrollToBottom(_ animated: Bool = true) {
        NSLog("SCROLL TO BOTTOM")
        tableView.layoutIfNeeded()
        if (animated) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let indexPath = self.dataSource?.lastIndexPath() {
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
                }
            }
        } else {
            if let indexPath = self.dataSource?.lastIndexPath() {
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
            }
        }
    }
    
    // MARK: - More menu actions
    func onImageMoreMenu(url: URL) {
        let actions = [
            UIAlertAction(title: "Share", style: .default, handler: { (alert) in
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]
                self.present(activityVC, animated: true, completion: nil)
            }),
            UIAlertAction(title: "Save to Gallery", style: .default, handler: { (alert) in
                self.requestGalleryAuthorization {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                    }) { saved, error in
                        DispatchQueue.main.async {
                            if saved {
                                Utils.showDoneAnimation(to: self.view, duration: 1.5, customTitle: "Saved")
                            } else {
                                Utils.alert(viewController: self, title: "Error", message: "Could not save image.")
                            }
                        }
                    }
                }
            })
        ]
        Utils.actionSheet(viewController: self, title: nil, msg: nil, actions: actions, cancelable: true)
    }
    
    func onVideoMoreMenu(url: URL) {
        let actions = [
            UIAlertAction(title: "Share", style: .default, handler: { (alert) in
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]
                self.present(activityVC, animated: true, completion: nil)
            }),
            UIAlertAction(title: "Save to Gallery", style: .default, handler: { (alert) in
                self.requestGalleryAuthorization {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    }) { saved, error in
                        DispatchQueue.main.async {
                            if saved {
                                Utils.showDoneAnimation(to: self.view, duration: 1.5, customTitle: "Saved")
                            } else {
                                Utils.alert(viewController: self, title: "Error", message: "Could not save video file.")
                            }
                        }
                    }
                }
            })
        ]
        Utils.actionSheet(viewController: self, title: nil, msg: nil, actions: actions, cancelable: true)
    }
    
    func onLocationMoreMenu(url: URL) {
        let actions = [
            UIAlertAction(title: "Share", style: .default, handler: { (alert) in
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]
                self.present(activityVC, animated: true, completion: nil)
            })
        ]
        Utils.actionSheet(viewController: self, title: nil, msg: nil, actions: actions, cancelable: true)
    }
}
