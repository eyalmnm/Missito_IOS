import Foundation
import CoreTelephony
import Contacts
import Gloss
import libPhoneNumber_iOS
import MBProgressHUD
import MapKit
import AVKit
import AVFoundation

extension UIColor {
    static let greenM = UIColor.init(red: CGFloat(0x05) / 255.0, green: CGFloat(0xE1) / 255.0, blue: CGFloat(0x05) / 255.0, alpha: CGFloat(1))
    static let fountainBlue = UIColor.init(red: CGFloat(0x63) / 255.0, green: CGFloat(0xAF) / 255.0, blue: CGFloat(0xC7) / 255.0, alpha: CGFloat(1))
    static let alto = UIColor.init(red: 215.0 / 255.0, green: 215.0 / 255.0, blue: 215.0 / 255.0, alpha: CGFloat(1))
    
    static let whiteWithAlpha0x44 = UIColor(netHex: 0xFFFFFF, hexAlpha: 0x44)
    
    static let missitoGrayCellBackground = UIColor(netHex: 0xE9E9E9)
    static let missitoDarkGray = UIColor(netHex: 0x424242)
    static let missitoLightGray = UIColor(netHex: 0x8e8e93) // like dial code
    static let missitoLightGrayWithAlpha0x26 = UIColor(netHex: 0x8e8e93, hexAlpha: 0x26) // like selected country background

    static let missitoLightBlue = UIColor(netHex: 0x78b9ff)
    static let missitoUltraLightBlue = UIColor(netHex: 0xb3dcff)
    static let missitoBlue = UIColor(netHex: 0x3b8ede)

    static let badDialCodeOrange = UIColor(netHex: 0xFF5700)
    
    convenience init(red: Int, green: Int, blue: Int, a: Int = 255) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        assert(a >= 0 && a <= 255, "Invalid alpha component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: CGFloat(a) / 255.0)
    }
    
    convenience init(netHex:Int, hexAlpha: Int = 0xFF) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff, a: hexAlpha & 0xff)
    }
    
    convenience init(argb: Int) {
        self.init(
            red: (argb >> 16) & 0xFF,
            green: (argb >> 8) & 0xFF,
            blue: argb & 0xFF,
            a: (argb >> 24) & 0xFF
        )
    }
}

extension String {
    
    func dataFromBase64() -> Data? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return data
    }
    
    func sliceFrom(_ start: String, to: String) -> String? {
        return (range(of: start)?.upperBound).flatMap { sInd in
            (range(of: to, range: sInd..<endIndex)?.lowerBound).map { eInd in
                substring(with: sInd..<eInd)
            }
        }
    }
    
    static func random(_ length: Int = 20) -> String {
        
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.characters.count))
            randomString += "\(base[base.characters.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        
        return randomString
    }
    
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
    
    func removeCharacters(from forbiddenChars: CharacterSet) -> String {
        let passed = self.unicodeScalars.filter { !forbiddenChars.contains($0) }
        return String(String.UnicodeScalarView(passed))
    }
    
    func removeCharacters(from: String) -> String {
        return removeCharacters(from: CharacterSet(charactersIn: from))
    }
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return substring(from: fromIndex)
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return substring(to: toIndex)
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return substring(with: startIndex..<endIndex)
    }
    
    func height(maxWidth: CGFloat, font: UIFont) -> CGFloat {
        let maxSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let actualSize = self.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin],
                                           attributes: [NSFontAttributeName: font], context: nil)
        return ceil(actualSize.height)
    }
    
    func width(maxHeight: CGFloat, maxWidth: CGFloat = UIScreen.main.bounds.width - 60, font: UIFont) -> CGFloat {
        let maxSize = CGSize(width: maxWidth, height: maxHeight)
        let actualSize = self.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin],
                                           attributes: [NSFontAttributeName: font], context: nil)
        
        return ceil(actualSize.width)
    }
}
extension UIControl {
    struct Static {
        static var key = "key"
    }
    var myInfo:Any? {
        get {
            return objc_getAssociatedObject( self, &Static.key ) as Any?
        }
        set {
            objc_setAssociatedObject( self, &Static.key,  newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

extension UIImage {
    
    static let UTI_PNG = "public.png"
    static let UTI_JPEG = "public.jpeg"
    
    static func fromBase64(_ base64String: String)->UIImage? {
        if let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) {
            return UIImage(data: data)
        }
        return nil
    }
    
    func toBase64(_ dataUTI: String, quality: CGFloat = 1) -> String? {
        if dataUTI == UIImage.UTI_JPEG {
            if let jpegRepresentation = UIImageJPEGRepresentation(self, quality) {
                NSLog("JPEG size=\(jpegRepresentation.count) bytes")
                return NSData(data: jpegRepresentation).base64EncodedString(options: .endLineWithCarriageReturn)
            }
        } else if dataUTI == UIImage.UTI_PNG {
            if let pngRepresentation = UIImagePNGRepresentation(self) {
                NSLog("PNG size=\(pngRepresentation.count) bytes")
                return NSData(data: pngRepresentation).base64EncodedString(options: .endLineWithCarriageReturn)
            }
        }
        return nil
    }
    
    func compress(_ quality: CGFloat)->Data? {
        return UIImageJPEGRepresentation(self, quality)
    }
    
    func thumbnail(_ dataUTI: String, _ completion: @escaping (UIImage?)->()) {
        DispatchQueue.global().async{
            
            let maxWidth: CGFloat = 600.0
            let maxHeight: CGFloat = 500.0
            
            let newSize = Utils.downscale(size: self.size, maxWidth: maxWidth, maxHeight: maxHeight)
            
            var thumbnail: UIImage? = self
            
            if !self.size.equalTo(newSize) {
                UIGraphicsBeginImageContext(newSize)
                let newRect = CGRect.init(x: 0, y: 0, width: newSize.width, height: newSize.height)
                self.draw(in: newRect)
                thumbnail = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }
            
            DispatchQueue.main.async {
                completion(thumbnail)
            }
        }
    }
}

extension UIView {
    
    /**
     Rounds the given set of corners to the specified radius
     
     - parameter corners: Corners to round
     - parameter radius:  Radius to round to
     */
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
        layer.masksToBounds = true
        
        if self is UIImageView {
            let borderLayer = CAShapeLayer()
            borderLayer.path = mask.path
            borderLayer.fillColor = UIColor.clear.cgColor
            borderLayer.strokeColor = layer.borderColor
            borderLayer.lineWidth = CGFloat(0.8)
            borderLayer.frame = bounds
            // by default 'layer.sublayers' is empty so next time border layer is removed ...
            layer.sublayers?.removeAll()
            //... and new one is added
            layer.addSublayer(borderLayer)
        }
        
        /* also can add shadow: */
//        let shadowPath2 = UIBezierPath(rect: bounds)
//        layer.shadowColor = UIColor.black.cgColor
//        layer.shadowOffset = CGSize(width: CGFloat(1.0), height: CGFloat(3.0))
//        layer.shadowOpacity = 0.5
//        layer.shadowPath = shadowPath2.cgPath
    }
}

struct Utils {

    static func removePlusFrom(phones: [String]) -> [String] {
        return phones.map(removePlusFrom)
    }

    static func removePlusFrom(phone: String) -> String {
        return phone.starts(with: "+") ? phone.substring(from: 1) : phone
    }

    static func fixPhoneFormat(_ phone: String) -> String {
        return phone.starts(with: "+") ? phone : "+" + phone
    }
    
    static func fixPhonesFormat(_ phones: [String]) -> [String] {
        return phones.map(fixPhoneFormat)
    }
    
    static func makeThumbnailFromVideo(_ filePath: URL, _ completion: @escaping (String?)->()) {
        do {
            let asset = AVURLAsset(url: filePath , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            let _ = UIImage(cgImage: cgImage).thumbnail("public.jpeg") {
                //called on main thread
                thumbnail in
                if let thumbnail = thumbnail, let base64 = thumbnail.toBase64("public.jpeg", quality: CGFloat(0.40)) {
                    completion(base64)
                } else {
                    NSLog("Could not encode to BASE64. Thumbnail = " + thumbnail.debugDescription)
                    completion(nil)
                }
            }
        } catch let error {
            NSLog("Error generating thumbnail: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    static func getPhones(_ contact: RealmAttachmentContact, joinedWith separator: String) -> String {
        var str = ""
        if contact.phones.count > 0 {
            str = RealmString.joined(contact.phones, with: separator)
        }
        
        return str
    }
    
    static func getEmails(_ contact: RealmAttachmentContact, joinedWith separator: String) -> String {
        var str = ""
        
        if contact.emails.count > 0 {
            str = RealmString.joined(contact.emails, with: separator)
        }
        
        return str
    }
    
    static func clearHistory(for phone: String, timePeriod: TimeInterval) {
        MissitoRealmDbHelper.write { realm, error in
            if let realm = realm {
                var date: Date
                if timePeriod == 0 {
                    date = Date.distantPast
                } else {
                    date = Date(timeIntervalSinceNow: -timePeriod)
                }
                
                // Remove all messages from or to phone
                let predicate = NSPredicate(format: "( destUid = %@ OR senderUid = %@ ) AND timeSent > %@", phone, phone, date as NSDate)
                if let realmMessages = MissitoRealmDbHelper.fetch(type: RealmMessage.self, predicate: predicate) {
                    for message in realmMessages {
                        removeFilesFor(message: message, phone: phone)
                        message.cascadeDelete(realm)
                    }
                }
                // Remove all empty chats with phone
                // This code must be changed when we'll be supporting multiple users chats
                // TODO: Can we find a way to do this more efficiently?
                if let realmChats = MissitoRealmDbHelper.fetch(type: RealmConversation.self) {
                    for realmChat in realmChats {
                        if !realmChat.counterparts.isEmpty && realmChat.counterparts[0].phone == phone {
                            MissitoRealmDbHelper.updateLastMessage(chat: realmChat)
                            if realmChat.lastMessage == nil {
                                realm.delete(realmChat)
                                // Remove chat id from contact data
                                if let contact = realm.objects(RealmMissitoContact.self).filter("phone CONTAINS '\(phone)'").first {
                                    contact.defaultConversationId = nil
                                }
                            }
                        }
                    }
                }

            } else {
                NSLog(error.debugDescription)
            }
        }
        
        if let contactDirURL = Utils.getContactDirURL(phone: phone) {
            do {
                if try FileManager.default.contentsOfDirectory(atPath: contactDirURL.path).isEmpty {
                    try FileManager.default.removeItem(at: contactDirURL)
                }
            } catch let exception {
                NSLog("Could not remove item at '%@'. %@", contactDirURL.absoluteString, exception.localizedDescription)
                if FileManager.default.fileExists(atPath: contactDirURL.path) {
                    NSLog("File/dir exists at %@", contactDirURL.absoluteString)
                } else {
                    NSLog("No file/dir exists at %@", contactDirURL.absoluteString)
                }
            }
        }
    }
    
    static func removeFileAt(url: URL?) {
        if let url = url {
            do {
                try FileManager.default.removeItem(at: url)
            } catch let exception {
                NSLog("Could not remove item at '%@'. %@", url.absoluteString, exception.localizedDescription)
                if FileManager.default.fileExists(atPath: url.path) {
                    NSLog("File/dir exists at %@", url.absoluteString)
                } else {
                    NSLog("No file/dir exists at %@", url.absoluteString)
                }
            }
        }
    }
    
    static func removeFilesFor(message: RealmMessage, phone: String) {
        if let attach = message.attachment {
            for audio in attach.audio {
                let fileURL = Utils.getFileURL(phone: phone, fileName: audio.fileName)
                removeFileAt(url: fileURL)
            }
            for image in attach.images {
                let fileURL = Utils.getFileURL(phone: phone, fileName: image.fileName)
                removeFileAt(url: fileURL)
            }
            for video in attach.video {
                let fileURL = Utils.getFileURL(phone: phone, fileName: video.fileName)
                removeFileAt(url: fileURL)
                if !video.localPath.isEmpty {
                    removeFileAt(url: URL.init(fileURLWithPath: video.localPath))
                }
            }
        }
    }
    
    static let phoneUtil = NBPhoneNumberUtil()
    
    static func cleanPhone(_ phone: String) -> String {
        return phone.removeCharacters(from: .whitespacesAndNewlines).removeCharacters(from: "-()")
    }
    
    static func call(phone: String, viewController: UIViewController) {
        let str = phone.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        guard let formattedPhone = str,
            let number = URL(string: "tel:" + formattedPhone)
            else {
                Utils.alert(viewController: viewController, title: "Error", message: String(format: "Can't dial %@", phone))
                return
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(number)
        } else {
            UIApplication.shared.openURL(number)
        }
    }
    
    static func downscale(size: CGSize, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        let verticalRatio = size.height / maxHeight
        let horizontalRatio = size.width / maxWidth
        
        if verticalRatio > 1.0 || horizontalRatio > 1.0 {
            if verticalRatio > horizontalRatio {
                return CGSize(width: size.width / verticalRatio, height: size.height / verticalRatio)
            } else {
                return CGSize(width: size.width / horizontalRatio, height: size.height / horizontalRatio)
            }
        } else {
            return size
        }
    }

    static func upscale(size: CGSize, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        let verticalRatio = maxHeight / size.height
        let horizontalRatio = maxWidth / size.width
        
        if verticalRatio > 1.0 || horizontalRatio > 1.0 {
            if verticalRatio < horizontalRatio {
                return CGSize(width: size.width * verticalRatio, height: size.height * verticalRatio)
            } else {
                return CGSize(width: size.width * horizontalRatio, height: size.height * horizontalRatio)
            }
        } else {
            return size
        }
    }

    static func getCurrentTimeInMillis() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    static func getAudioRecordDuration(_ url: URL)->TimeInterval {
        return (try? AVAudioPlayer(contentsOf: url).duration) ?? 0
    }
    
    // https://stackoverflow.com/a/30075200/7132300
    static func platformName() -> String {
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    static func readImage(localFileURI: String) -> UIImage? {
        return UIImage(contentsOfFile: localFileURI)
    }
    
    static func saveImage(image: UIImage, imageURL: URL?, _ completion: @escaping (String?)->()) {
        DispatchQueue.global().async {
            if let imageURL = imageURL {
                if let _ = UIImage(contentsOfFile: imageURL.path) {
                    DispatchQueue.main.async {
                        completion(imageURL.path)
                    }
                    return
                }
                
                var imageData: Data?
                if imageURL.lastPathComponent.lowercased().hasSuffix(".png") {
                    imageData = UIImagePNGRepresentation(image)
                } else {
                    imageData = UIImageJPEGRepresentation(image, 1)
                }
                
                if let data = imageData {
                    do {
                        try data.write(to: imageURL)
                        DispatchQueue.main.async {
                            completion(imageURL.path)
                        }
                        return
                    } catch let exception {
                        NSLog(exception.localizedDescription)
                    }
                } else {
                    NSLog("Failed to convert UIImage to Data")
                }
            }
        
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    static func getFileURL(phone: String?, fileName: String) -> URL? {
        if let phone = phone {
            do {
                var docDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                docDir = docDir.appendingPathComponent(phone)
                if !FileManager.default.fileExists(atPath: docDir.path) {
                    try FileManager.default.createDirectory(at: docDir.absoluteURL, withIntermediateDirectories: false, attributes: nil)
                }
                return docDir.appendingPathComponent(fileName)
            } catch let exception {
                NSLog("Could not get URL of '%@'. %@", fileName, exception.localizedDescription)
            }
        }
        return nil
    }
    
    static func getContactDirURL(phone: String) -> URL? {
        do {
            let docDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            return docDir.appendingPathComponent(phone)
        } catch let exception {
            NSLog("Could not get URL of '%@' directory. %@", phone, exception.localizedDescription)
        }
        return nil
    }
    
    static func getFileSize(path: String) -> UInt64 {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: path)
            return attr[FileAttributeKey.size] as! UInt64
        } catch {
            NSLog("Can't get file size for %@: %@", path, error.localizedDescription)
            return 0
        }
    }
    
    static func jsonToData(_ json: JSON) -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
        } catch let myJSONError {
            NSLog("jsonToData failed: \(myJSONError)")
        }
        return nil
    }
    
    static func jsonToString(_ json: JSON) -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
            return String(data: data, encoding: .utf8)
        } catch let myJSONError {
            NSLog("jsonToString failed: \(myJSONError)")
        }
        return nil;
    }
    
    //MARK: Time Service
    /**
     Convert ISO 8601 String format used by MDK backend to NSDate
     
     - parameter format: IOS 8601 string format
     
     - returns: NSDate
     */
    static func dateFromISO8601StringFormat(_ string: String?) -> Date? {
        
        guard let dateString = string else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        
        //Validate the received date string against one of available formats.
        guard let validFormat = Utils.iso8601StringFormats.reduce("", { (accumulator, current) -> String? in
            
            dateFormatter.dateFormat = current
            guard let _ = dateFormatter.date(from: dateString) else { return nil }
            
            return current
            
        }) else { return nil }
        
        dateFormatter.dateFormat = validFormat
        return dateFormatter.date(from: dateString)
    }
    
    
    /**
     Convert NSDate to ISO 8601 String format used by MDK backend
     
     - parameter format: NSDate
     
     - returns: IOS 8601 string format
     */
    static func iso8601StringFormatFromDate(_ date: Date?) -> String? {
        
        guard let date = date else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        return dateFormatter.string(from: date) + "Z"
    }
    
    static let iso8601StringFormats = ["yyyy-MM-dd'T'HH:mm:ssZZZZZ", "yyyy-MM-dd'T'HH:mm:ss.SSSZ"]
    
    /// Platform infos
    static let platform: Platform = Platform()
    
    /// OSX current user name
    
    static func username() -> String? {
        
        let pathComponents = Bundle.main.bundlePath.components(separatedBy: "/")
        return pathComponents[2]
    }

    static let countries = {
        
        let unsortedCountries = Locale.isoRegionCodes.map { (countryCode:String) -> Country in
            
            let id = Locale.identifier(fromComponents: [NSLocale.Key.countryCode.rawValue: countryCode])
            let countryName = (Locale(identifier: "en_US") as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(countryCode)"
            
            guard let dialCode = Utils.dialCodeForCountryCode(countryCode) else {
                
                return Country(countryCode: countryCode, countryName: countryName, dialCode:"", flagReference: Utils.flagReferenceForCountryCode(countryCode))
                
            }
            
            return Country(countryCode: countryCode.lowercased(), countryName: countryName, dialCode:dialCode, flagReference: Utils.flagReferenceForCountryCode(countryCode))
        }
        
        let sortedCountries = unsortedCountries.sorted{ $0.countryName < $1.countryName }
        
        return sortedCountries

    }() as [Country]
    
    static let countriesAsDataSource: [[Country]] = {
        
            let alphabet = "abcdefghijklmnopqrstuvwyz".characters
        
            var countriesByLetter: [Character: [Country]] = [:]
            for country in Utils.countries {
                if var letter = country.countryName.characters.first {
                    letter = String(letter).lowercased().characters.first!
                    if countriesByLetter[letter] != nil {
                        countriesByLetter[letter]! += [country]
                    } else {
                        countriesByLetter[letter] = [country]
                    }
                }
            }
        
            print(countriesByLetter)
            
            let countries = alphabet.map({ (char) -> [Country] in
                countriesByLetter[char] ?? []
            })
        
        
            return countries
        
    }()
    
    
    static func indexPathOfCountry(_ country: Country) -> IndexPath {
        
        return Utils.countriesAsDataSource.reduce(IndexPath(row: 0, section: 0)) { (indexPath, subArray) -> IndexPath in
            
            let section = Utils.countriesAsDataSource.index(where: {$0 == subArray})! as Int
            
            if let index = subArray.index(where: { $0 == country}) {
            
                let row = index as Int
                
                let computedIndex = IndexPath(row: row, section: section)
            
                return computedIndex
            }
            
            return indexPath
        }
    }
    
    static func countryForCountryCode(_ code: String) -> Country? {
        
        let country = Utils.countries.filter{ $0.countryCode == code }.first
        
        return country
    }
    
    static func countryForDialCode(_ code: String) -> Country? {
        // Define default country for dial codes that are used by more countries
        let codes = ["1": "us", "61": "au", "44": "gb", "7": "ru"]
        
        if let code = codes[code] {
            return Utils.countryForCountryCode(code)
        } else {
            return Utils.countries.first{ $0.dialCode == code }
        }
    }
    
    static let dialCodeMap = {
        
        guard let path =  Bundle.main.path(forResource: "DiallingCodes", ofType: "plist") else { return nil }
        
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: String] else { return nil }
        
        return dict
        
        }() as [String: String]?
    
    static let countryFlagMap = {
        
        guard let path =  Bundle.main.path(forResource: "Flags", ofType: "plist") else { return nil }
        
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: String] else { return nil }
        
        return dict
        
        }() as [String: String]?
    
    
    static let currentCountryCode = {
        
        guard let isoCountryCode = Utils.carrier?.isoCountryCode else {
           
            guard let currentCountryCode = Locale.current.regionCode else { return nil }
            
            return currentCountryCode.lowercased()
        
        }
        
        return isoCountryCode.lowercased()
        
        }() as String?

    static let carrier = {
        
        let carrierInfo = CTTelephonyNetworkInfo()
        
        let carrier = carrierInfo.subscriberCellularProvider
        
        return carrier
    
        }() as CTCarrier?
    
    fileprivate static func dialCodeForCountryCode(_ code: String?) -> String? {
        
        guard let countryCode  = code else { return nil }
        
        guard let dialCode = Utils.dialCodeMap?[countryCode.lowercased()] else { return nil }
        
        return dialCode
    }
    
    fileprivate static func flagReferenceForCountryCode(_ code: String?) -> String? {
        
        guard let countryCode  = code else { return nil }
        
        guard let flagReference = Utils.countryFlagMap?[countryCode.lowercased()] else { return nil }
        
        return flagReference
    }
    
    static func platformInfo() -> String {
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return NSString(bytes: &sysinfo.machine, length: Int(_SYS_NAMELEN), encoding: String.Encoding.ascii.rawValue)! as String
    }
    
    static func alert(viewController: UIViewController, title: String, message: String, actions: [UIAlertAction]? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        var alreadyHasCancelButton = false
        if let actions = actions {
            for i in 0...actions.count - 1 {
                alreadyHasCancelButton = (alreadyHasCancelButton || (actions[i].style == .cancel))
                alert.addAction(actions[i])
            }
        }
        
        if !alreadyHasCancelButton {
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        }
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    /// Display an action sheet with custom actions, title and message
    ///
    /// - Parameters:
    ///   - viewController: View controller where actionSheet will be presented
    ///   - title: Title
    ///   - msg: Message
    ///   - actions: actions
    ///   - cancelable: true if actionSheet should display cancel button, false otherwise
    /// - Note: actions should't contain cancel action, it is added automatically based on *cancelable* parameter
    static func actionSheet(viewController: UIViewController, title: String?, msg: String?, actions: [UIAlertAction], cancelable: Bool) {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .actionSheet)
        var actions = actions
        
        if cancelable {
            actions.append(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        }
        for action in actions {
            alertController.addAction(action)
        }
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    /// Show saved/done animation with title and checkmark
    ///
    /// - Parameters:
    ///   - view: view where animation will be presented
    ///   - duration: animation duration
    ///   - customTitle: custom title if need, by default title is "Done"
    static func showDoneAnimation(to view: UIView, duration: TimeInterval, customTitle: String? = nil) {
        DispatchQueue.main.async {
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            hud.mode = .customView
            hud.isSquare = true
            hud.label.text = customTitle ?? "Done"
            hud.customView = UIImageView(image: UIImage(named: "checkmark"))
            hud.hide(animated: true, afterDelay: duration)
        }
    }
    
    static func showErrorAdded(to view: UIView, duration: TimeInterval, title: String?) {
        DispatchQueue.main.async {
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            hud.mode = .customView
            hud.isSquare = true
            hud.label.text = title
            hud.customView = UIImageView(image: UIImage(named: "error_outline"))
            hud.hide(animated: true, afterDelay: duration)
        }
    }
    static func getStoredContactsPhones() -> [String] {
        var contacts: [String] = []
        if let db = MissitoRealmDB.shared.database() {
            for contact in db.objects(PhoneBookNumber.self) {
                contacts.append(contact.phone)
            }
        }
        return contacts
    }
    
    static func formatPhones(_ phones: [String]) -> [String] {
        var e164FormattedPhones: [String] = []
        for phone in phones {
            guard let phone = Utils.parseAndValidateNumber(phone) else {
                continue
            }
            
            e164FormattedPhones.append(phone)
        }
        return e164FormattedPhones
    }
    
    
    // Parses a string using the phone's carrier region (when available, ZZ otherwise)
    // This uses the country the sim card in the phone is registered with
    static func parseAndValidateNumber(_ phone: String) -> String? {
        
        var regionCode: String!
        // Check if phone's carrier region is present
        if phoneUtil.countryCodeByCarrier() != "ZZ" {
            regionCode = phoneUtil.countryCodeByCarrier()
        } else {
            // Check if userCountryCode can be extracted from current user phone number
            let userCountryCode = phoneUtil.extractCountryCode(CoreServices.authService!.userId!, nationalNumber: nil) // Return 0 if cannot extract country code
            // Get region code from user country code
            regionCode = phoneUtil.getRegionCode(forCountryCode: userCountryCode) // Return 'ZZ' if cannot get region code
        }
        
        do {
            let phoneNumber = try phoneUtil.parse(phone, defaultRegion: regionCode)
            if phoneUtil.isValidNumber(phoneNumber) {
                let formattedString: String = try (phoneUtil.format(phoneNumber, numberFormat: .E164))
                
                return formattedString
            }
        } catch let error as NSError {
            NSLog("Could not parse and validate number: ", phone, error.description)
        }
        return nil
    }
    
    static func format(phone: String) -> String {
        do {
            let phoneNumber = try phoneUtil.parse(withPhoneCarrierRegion: phone)
            if phoneUtil.isValidNumber(phoneNumber) {
                let formattedString: String = try (phoneUtil.format(phoneNumber, numberFormat: .INTERNATIONAL))
                return formattedString
            }
        } catch let error as NSError {
            NSLog("Could not parse and validate number: ", phone, error.description)
        }
        return phone
    }
    
    static func showProgress(message: String, view: UIView) -> MBProgressHUD {
        let notif = MBProgressHUD.showAdded(to: view, animated: true)
        notif.mode = .indeterminate
        notif.label.text = message
        return notif
    }
    
    static func show(message: String, attachedTo view: UIView) {
        let hud = MBProgressHUD.showAdded(to: view, animated: true);
        hud.mode = .text
        hud.label.numberOfLines = 0
        hud.label.text = message
        hud.margin = 10
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 2)
    }
    
    static func getMapSnapshot(_ size: CGSize, _ realmLocation: RealmLocation, _ completion: @escaping (UIImage?)->()) {
        let coordinate = CLLocationCoordinate2D.init(latitude: CLLocationDegrees(realmLocation.lat), longitude: CLLocationDegrees(realmLocation.lon))
        let options = MKMapSnapshotOptions()
        options.region = MKCoordinateRegionMakeWithDistance(coordinate, realmLocation.radius, realmLocation.radius)
        options.scale = UIScreen.main.scale
        options.size = size
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start(with: DispatchQueue.global()) { snapshot, error in
            guard let snapshot = snapshot else {
                NSLog("Snapshot error: \(error?.localizedDescription ?? "-")")
                return
            }
            
            let pointAnnotation = MKPointAnnotation()
            pointAnnotation.coordinate = coordinate
            let pin = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: nil)
            let image = snapshot.image
            
            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
            image.draw(at: CGPoint.zero)
            
            let visibleRect = CGRect(origin: CGPoint.zero, size: image.size)
            var point = snapshot.point(for: coordinate)
            if visibleRect.contains(point) {
                point.x = point.x + pin.centerOffset.x - (pin.bounds.size.width / 2)
                point.y = point.y + pin.centerOffset.y - (pin.bounds.size.height / 2)
                pin.image?.draw(at: point)
            }
            
            let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            DispatchQueue.main.async {
                completion(compositeImage)
            }
        }
    }
    
    static func getTempDirectory() -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }
}

struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
            isSim = true
        #endif
        return isSim
    }()
}

extension Date {
    
    //NOTE: If you want to compare NSDates please note that Realm have a bug in truncating milisecond of the date during that storing into database.
    //See this: https://realm.io/docs/swift/latest/#nsdate-is-truncated-to-the-second
    //It only compares to seconds granularity
    
    func isGreaterThanDate(_ dateToCompare: Date) -> Bool {
        
        let comparation = (Calendar.current as NSCalendar).compare(self, to: dateToCompare,
                                                                   toUnitGranularity: .second)
        
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if comparation == ComparisonResult.orderedDescending {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    
    func isLessThanDate(_ dateToCompare: Date) -> Bool {
        
        let comparation = (Calendar.current as NSCalendar).compare(self, to: dateToCompare,
                                                                   toUnitGranularity: .second)
        
        //Declare Variables
        var isLess = false
        
        //Compare Values
        if comparation == ComparisonResult.orderedAscending {
            isLess = true
        }
        
        //Return Result
        return isLess
    }
    
    func equalToDate(_ dateToCompare: Date) -> Bool {
        
        let comparation = (Calendar.current as NSCalendar).compare(self, to: dateToCompare,
                                                             toUnitGranularity: .second)
        //Declare Variables
        var isEqualTo = false
        
        //Compare Values
        if comparation == ComparisonResult.orderedSame  {
            isEqualTo = true
        }
        
        //Return Result
        return isEqualTo
    }
    
    func addDays(_ daysToAdd: Int) -> Date {
        let secondsInDays: TimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded: Date = self.addingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    func addHours(_ hoursToAdd: Int) -> Date {
        let secondsInHours: TimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded: Date = self.addingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
    
    var millisecondsSince1970:Int {
        return Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}

extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
}

extension Collection where Iterator.Element == CNContact {
    var initials: [String] {
        return map{
        
            guard let first = $0.givenName.characters.first else { return "" }
            return String(first)
        }
    }
}

extension UIImage {
    class func imageWithLabel(_ label: UILabel) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
    class func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}

extension UITabBarController {
    
    func setTabBarVisible(_ visible:Bool, animated:Bool) {
        
        // bail if the current state matches the desired state
        if (tabBarIsVisible() == visible) { return }
        
        // get a frame calculation ready
        let frame = self.tabBar.frame
        let height = frame.size.height
        let offsetY = (visible ? -height : height)
        
        // animate the tabBar
        UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
            self.tabBar.frame = frame.offsetBy(dx: 0, dy: offsetY)
            self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height + offsetY)
            self.view.setNeedsDisplay()
            self.view.layoutIfNeeded()
        }) 
    }
    
    func tabBarIsVisible() ->Bool {
        return self.tabBar.frame.origin.y < self.view.frame.maxY
    }
}

extension UIFont {
    static func SFUIDisplayLight(size: CGFloat) -> UIFont {
        return UIFont(name: "SFUIDisplay-Light", size: size)!
    }
    
    static func vagrundSchriftDot(size: CGFloat) -> UIFont {
        return UIFont(name: "VAGRundschriftDOT-Regular", size: size)!
    }
}

extension UIImage {
    
    static func coloredImage(image: UIImage?, color: UIColor) -> UIImage? {
        
        guard let image = image else {
            return nil
        }
        
        let backgroundSize = image.size
        UIGraphicsBeginImageContextWithOptions(backgroundSize, false, UIScreen.main.scale)
        
        let ctx = UIGraphicsGetCurrentContext()!
        
        var backgroundRect=CGRect()
        backgroundRect.size = backgroundSize
        backgroundRect.origin.x = 0
        backgroundRect.origin.y = 0
        
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        ctx.setFillColor(red: r, green: g, blue: b, alpha: a)
        ctx.fill(backgroundRect)
        
        var imageRect = CGRect()
        imageRect.size = image.size
        imageRect.origin.x = (backgroundSize.width - image.size.width) / 2
        imageRect.origin.y = (backgroundSize.height - image.size.height) / 2
        
        // Unflip the image
        ctx.translateBy(x: 0, y: backgroundSize.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        
        ctx.setBlendMode(.destinationIn)
        ctx.draw(image.cgImage!, in: imageRect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

extension Int {
    func format(_ f: String) -> String {
        return String(format: "%\(f)d", self)
    }
}
