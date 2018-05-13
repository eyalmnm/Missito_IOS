//
//  AttachmentRealm.swift
//  Missito
//
//  Created by Jenea Vranceanu on 6/27/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

class RealmAttachment: Object {
    
    var images = List<RealmImage>()
    var contacts = List<RealmAttachmentContact>()
    var locations = List<RealmLocation>()
    var audio = List<RealmAudio>()
    var video = List<RealmVideo>()

    static func make(from missitoAttachment: MissitoAttachment?)->RealmAttachment? {
        if let missitoAttachment = missitoAttachment {
            let attachment = RealmAttachment()
            if let imagesM = missitoAttachment.images, !imagesM.isEmpty {
                for a in imagesM {
                    attachment.images.append(
                        RealmImage(
                            fileName: a.fileName,
                            link: a.link,
                            size: Int64(a.size),
                            secret: a.secret,
                            thumbnail: a.thumbnail)
                    )
                }
            }
            
            if let contactsM = missitoAttachment.contacts, !contactsM.isEmpty {
                for a in contactsM {
                    if !a.isEmpty() {
                        attachment.contacts.append(
                            RealmAttachmentContact(
                                name: a.name,
                                surname: a.surname,
                                avatar: a.avatar,
                                phones: RealmAttachment.getRealmStringList(a.phones),
                                emails: RealmAttachment.getRealmStringList(a.emails),
                                notes: a.notes)
                        )
                    }
                }
            }
            
            if let locationsM = missitoAttachment.locations, !locationsM.isEmpty {
                for a in locationsM {
                    attachment.locations.append(
                        RealmLocation(
                            label: a.label,
                            lat: a.lat,
                            lon: a.lon,
                            radius: a.radius)
                    )
                }
            }
            
            if let audioM = missitoAttachment.audio, !audioM.isEmpty {
                for a in audioM {
                    attachment.audio.append(
                        RealmAudio(
                            title: a.title,
                            fileName: a.fileName,
                            link: a.link,
                            size: Int64(a.size),
                            secret: a.secret)
                    )
                }
            }
            
            if let videoM = missitoAttachment.video, !videoM.isEmpty {
                for a in videoM {
                    attachment.video.append(
                        RealmVideo(
                            title: a.title,
                            fileName: a.fileName,
                            link: a.link,
                            size: Int64(a.size),
                            secret: a.secret,
                            thumbnail: a.thumbnail)
                    )
                }
            }
            return attachment
        }
        return nil
    }
    
    public func cascadeDelete(_ realm: Realm) {
        for image in images {
            realm.delete(image)
        }
        for contact in contacts {
            contact.cascadeDelete(realm)
        }
        for location in locations {
            realm.delete(location)
        }
        for aud in audio {
            realm.delete(aud)
        }
        for vid in video {
            realm.delete(vid)
        }
        realm.delete(self)
    }
    
    static func getRealmStringList(_ from: [String]?) -> List<RealmString> {
        var list = List<RealmString>()
        if from == nil {
            return list
        }
        
        for x in from! {
            list.append(RealmString.make(from: x))
        }
        return list
    }

}
