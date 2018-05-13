

import Foundation
import RealmSwift

class MissitoRealmDB {
    
    private init() { }
    
    static let shared = MissitoRealmDB()
    
    // MARK: Database Configuration
    
    static func setupRealm(uid: String?) {
        let uid = uid ?? "default"
        
        var config = Realm.Configuration.defaultConfiguration
        
        // Use the default directory, but replace the filename with the username
        config.fileURL = config.fileURL!.deletingLastPathComponent()
            .appendingPathComponent("\(uid).realm")
        
        // Generate a random encryption key
        var key = KeyChainHelper.getRealmKey(userId: uid)
        if key == nil {
            key = Data(count: 64)
            _ = key!.withUnsafeMutableBytes { bytes in
                SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
            }
            _ = KeyChainHelper.saveRealmKey(userId: uid, key: key!)
            
            do {
                if FileManager.default.fileExists(atPath: config.fileURL!.path) {
                    NSLog("WARNING: Realm encryption key changed but the DB was present. User lost all the data!")
                    NSLog("WARNING: This may be the problem with iOS keychain entries not readable sometimes")
                    try FileManager.default.removeItem(at: config.fileURL!)
                }
            } catch {
                print("Could not delete file: \(error)")
            }
        }
        config.encryptionKey = key
        config.schemaVersion = 17
        config.migrationBlock = { migration, oldVersion in
            // V 11
            if oldVersion < 11 {
                // Info: for changing values of properties of created object there is ability to do next: `let obj = migration.create(RealmImage.className())`
                migration.create(RealmAttachment.className())
                migration.create(RealmImage.className())
            }
            
            migration.enumerateObjects(ofType: RealmMessage.className()) { oldObject, newObject in
                if oldVersion < 11 {
                    newObject!["attachment"] = nil
                }
            }
            
            // V 12
            if oldVersion < 12 {
                migration.create(RealmString.className())
                migration.create(RealmAttachmentContact.className())
                migration.create(RealmLocation.className())
                migration.create(RealmAudio.className())
                migration.create(RealmVideo.className())
            }
            
            migration.enumerateObjects(ofType: RealmAttachment.className()) { oldObject, newObject in
                if oldVersion < 12 {
                    newObject!["contacts"] = List<RealmAttachmentContact>()
                    newObject!["locations"] = List<RealmLocation>()
                    newObject!["audio"] = List<RealmAudio>()
                    newObject!["video"] = List<RealmVideo>()
                }
            }
            
            if oldVersion < 13 {
                migration.renameProperty(onType: "TextMessage", from: "incomingStatus", to: "incomingStatusStr")
                migration.renameProperty(onType: "TextMessage", from: "outgoingStatus", to: "outgoingStatusStr")
            }
            
            if oldVersion < 15 {
                migration.enumerateObjects(ofType: "TextMessage", { (oldObject, newObject) in
                    migration.create("RealmMessage", value: oldObject!)
                })
                migration.enumerateObjects(ofType: "RealmContact", { (oldObject, newObject) in
                    migration.create("RealmAttachmentContact", value: oldObject!)
                })
            }
            
            if oldVersion < 16 {
                migration.enumerateObjects(ofType: "RealmAttachmentContact", { (oldObject, newObject) in
                    newObject!["avatar"] = nil
                })
            }
            
            if oldVersion < 17 {
                migration.enumerateObjects(ofType: "RealmVideo", { (oldObject, newObject) in
                    newObject!["localPath"] = nil
                })
            }
            
        }
        
        // Set this as the configuration used for the default Realm
        Realm.Configuration.defaultConfiguration = config
    }
    
    
    //MARK: Database instance
    
    /**
     Get a database instance with shared configuration. This is Realm Database https://realm.io
     
     Threading
     NOTE:
     Database objects are not thread safe and cannot be shared across threads, so you must get a new database instance in each thread/dispatch_queue in which you want to read or write.
     
     To access the same persistent database file from different threads, you must initialize a new database to get a different instance for every thread. This class method instantiate database with the shared configuration object so all database instances accros the threads will map to the same file on disk. Sharing a database instances across threads is not supported.
     
     Database persistent objects are not thread safe and cannot be shared across threads, so you must get a new database instance in each thread/dispatch_queue in which you want to read or write.
     
     Standalone (unpersisted) instances of Objects behave exactly as regular NSObject subclasses, and are safe to pass across threads.
     
     Persisted instances of Realm, Object, Results, or List can only be used on the thread on which they were created. This is one way database enforces transaction version isolation. Otherwise, it would be impossible to determine what should be done when an object is passed between threads at different transaction versions, with a potentially extensive relationship graph.
     
     Instead, there are several ways to represent instances in ways that can be safely passed between threads. For example, an object with a primary key can be represented by its primary key’s value; or a Results can be represented by its NSPredicate or query string; or a Realm can be represented by its Realm.Configuration. The target thread can then re-fetch the Realm, Object, Results, or List using its thread-safe representation. Keep in mind that re-fetching will retrieve an instance at the version of the target thread, which may differ from the originating thread.
     
     
     - throws: error if database failed to instantiate
     
     - returns: Realm database instance
     */
    func database() -> Realm? {
        do {
            return try Realm()
        } catch {
            NSLog("Failed to retriev database!")
        }
        
        return nil
    }
    
    static func fetchChatMessages(companionUid: String) -> Results<RealmMessage> {
        return MissitoRealmDB.shared.database()!.objects(RealmMessage.self)
            .filter(String.init(format: "destUid = '%@' OR senderUid = '%@'", companionUid, companionUid))
            .sorted(byKeyPath: "timeSent", ascending: true)
    }
    
}


