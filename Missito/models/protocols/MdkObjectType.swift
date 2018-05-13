/*******************************************************************************
 * Copyright 2015 MDK Labs GmbH All rights reserved.
 * Confidential & Proprietary - MDK Labs GmbH ("TLI")
 *
 * The party receiving this software directly from TLI (the "Recipient")
 * may use this software as reasonably necessary solely for the purposes
 * set forth in the agreement between the Recipient and TLI (the
 * "Agreement"). The software may be used in source code form solely by
 * the Recipient's employees (if any) authorized by the Agreement. Unless
 * expressly authorized in the Agreement, the Recipient may not sublicense,
 * assign, transfer or otherwise provide the source code to any third
 * party. MDK Labs GmbH retains all ownership rights in and
 * to the software
 *
 * This notice supersedes any other TLI notices contained within the software
 * except copyright notices indicating different years of publication for
 * different portions of the software. This notice does not supersede the
 * application of any third party copyright notice to that third party's
 * code.
 ******************************************************************************/
//  Created by George Poenaru on 25/11/15.

import Foundation
import ObjectMapper
import RealmSwift



public protocol MdkDynamicObjectType {
    
    var id: String? { get set }
    var key: String? { get set }
    var value: String? { get set }
    init(key: String, value: String, ownerId: String)

}

public protocol MdkObjectType {
    
    var id: String? { get }

}
//Default behaviour
extension MdkObjectType where Self: Object, Self: Mappable {
    
    
    func write(closure: () -> Void) {
        
        if let database = self.realm { database.beginWrite() }

        closure()
        
        if let database = self.realm {
            do {
                try database.commitWrite()
            } catch {
                
                Mdk.log.error("Failed to write object into database. Commit transaction failed.")
            }
        }
    }
    
    /**
     Transform a dictionary into a dynamic object (key, value). ChatProperties and MessageBody are dynamic objects
     
     - parameter dictionary: dictionary
     
     - returns: dynamic object type: ChatProperty, MessageBody
     */
    func mapDictionaryToDynamics<T: MdkDynamicObjectType>(dictionary: [String: String], ownerId: String ) -> [T] {
        
        let objects = dictionary.map{ (key, value) -> T in
            
            let object = T(key: key, value: value, ownerId: ownerId)
            return object
        }
        
        return objects
    }
    
    /**
     Transform a dynamic object (key, value) into dictionary. ChatProperties and MessageBody are dynamic objects
     
     - parameter dynamics: dynamic object type: ChatProperty, MessageBody
     
     - returns: dictionary
     */
    func mapDynamicsToDictionary<T: MdkDynamicObjectType>(dynamics: [T]?) -> [String: String]? {
        
        guard let objects = dynamics else { return nil }
        
        guard let JSON = (objects.reduce([:]) { (dictionary, object) -> [String: String]?  in
            
            guard var dict = dictionary else { return nil }
            
            if let key = object.key, let value = object.value {
                
                dict[key] = value
            }
            
            return dict
            
        }) else { return nil }
        
        return JSON
    }
    
    /**
     Custom Map transform primitive to RealmOptional
     
     - returns: custom map transform implementation
     */
    public func transformRealmOptional<T>() -> TransformOf<RealmOptional<T>, T> {
        
        //Map Bool
        return TransformOf<RealmOptional<T>, T>(fromJSON: { (value: T?) -> RealmOptional<T>? in
            
            return RealmOptional<T>(value)
            
            }) { (optional: RealmOptional<T>?) -> T? in
                
                return optional?.value
        }
        
    }
    
    /**
     Custom Map transform NSDate from ISO8601 String formating
     
     - returns: custom map transform implementation
     */
    public func transformDate() -> TransformOf<NSDate, String> {
        
        //Map NSDate
        return TransformOf<NSDate, String>(fromJSON: { (string: String?) -> NSDate? in
            //ISO8601 to NSDate
            return Mdk.getTimeService()?.dateFromISO8601StringFormat(string)
            
            }) { (date: NSDate?) -> String? in
            
            //NSDate to ISO8601
            return Mdk.getTimeService()?.iso8601StringFormatFromDate(date)
        }
    }

    
}

//MARK: Results extension
extension Results {
    
    /**
     Get a specific object from the list by a key. 
     Your object has to have a property String named "key" and a property named "value".
     
     - parameter key: key name
     
     - returns: value for the key
     */
    public subscript(key: String) -> String {
        
        get {
            
            //Find dbObject by key property
            guard let object = self.filter("key = %@", key).first else { return "" }
            //Return object value property
            return  object["value"] as! String
        }
        
    
    }
    
}