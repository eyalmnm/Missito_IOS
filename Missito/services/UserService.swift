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


//  If you wonder why more class then struct please read this: http://faq.sealedabstract.com/structs_or_classes/
@objc(MDKUserService)
final public class UserService: NSObject, AsyncEventType, EventHandler {
    
    private let apiProvider: ApiProvider
    
    
    init(apiProvider: ApiProvider) {
        
        self.apiProvider = apiProvider
        super.init()
        self.handleUserEvents()
        
    }
    
    private func handleUserEvents() {
        
         //Handle User
        self.handleEvent { event in
            
            guard (event.type == EventType.UserUpdate)  && event.direction == Direction.IN  else { return }
            
            //Return on Null Event Payloady
            guard let content = event.content else { return }
            
            guard let json = content["user"] else { return }
            
            guard let user = Mapper<User>().map(json) else { return }
            
            self.emit(UserEvent.UpdateUser(user: user))
            
        }
        
        //Handle User
        self.handleEvent { event in
            
            guard (event.type == EventType.MeUpdate)  && event.direction == Direction.IN  else { return }
            
            //Return on Null Event Payloady
            guard let content = event.content else { return }
            
            guard let json = content["user"] else { return }
            
            guard let me = Mapper<User>().map(json) else { return }
            
            self.emit(UserEvent.UpdateMe(me: me))
        }
        
    }
    
    //MARK: SWIFT
    /**
     Get current user details
     
     - parameter completion: completion callback
     */
    public func getMe(completion: (call: Call<User>) -> Void ) {
        
        _ = apiProvider.getMe().subscribeNext({ me in
            
            completion(call: Call.onSuccess(me))

        })
    }
    /**
     Get user details by it's userId
     
     - parameter userId: userId
     - parameter completion: completion callback
     */
    public func getUser(userId: String, completion: (call: Call<User>) -> Void ) {
        
        _ = apiProvider.getUser(userId).subscribeNext({ user in
            
            completion(call: Call.onSuccess(user))
            
        })
        
    }
    
    /**
     Update current user lastSeen property
     
     - parameter completion: completion callback
     */
    public func updateLastSeenMe(completion: (call: Call<Bool>) -> Void ) {
        
        guard let date = Mdk.getTimeService()?.iso8601StringFormatFromDate(NSDate()) else {
            Mdk.log.error("Failed to convert date to iso8601 string format!")
            return
        }
        
        _ = apiProvider.updateLastSeenMe(date).subscribeNext({ done in
            
            completion(call: Call.onSuccess(done))
            
        })
    }
    
    /**
     Update current user lastSeen property
     */
    @objc
    public func updateLastSeenMe() {
        
        self.updateLastSeenMe { (call) in
         
        }
    }
    
    //MARK: ObjC
    /**
     Get current user details
     
     - parameter completion: completion callback
     */
    @objc(getMeWithCompletion:)
    public func getMeObjC(completion: (User?, NSError?) -> Void) {
        
        self.getMe { (call) in
            
            switch call {
                
            case .onSuccess(let user):
                completion(user, nil)
                break
            case .onError(let error as NSError):
                completion(nil, error)
                break
            default: break
                
            }
        }
    }

    /**
     Get user details by it's userId
     
     - parameter userId: userId
     - parameter completion: completion callback
     */
    @objc(getUserByUserId:completion:)
    public func getUserObjC(userId: String, completion: (User?, NSError?) -> Void) {
        
        self.getUser(userId, completion: { (call) in
            
            switch call {
                
            case .onSuccess(let user):
                completion(user, nil)
                break
            case .onError(let error as NSError):
                completion(nil, error)
                break
            default: break
                
            }
        })
    }
    
    /**
     Update current user lastSeen property
     
     - parameter completion: completion callback
     */
    @objc(updateLastSeenMeWithCompletion:)
    public func updateLastSeenMeObjC(completion: (Bool, NSError?) -> Void) {
        
        self.updateLastSeenMe { (call) in
            
            switch call {
                
            case .onSuccess( _):
                completion(true, nil)
                break
            case .onError(let error as NSError):
                completion(false, error)
                break
            default: break
                
            }
        }
    }
    

}

