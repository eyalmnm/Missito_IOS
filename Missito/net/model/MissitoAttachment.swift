//
//  Attachment.swift
//  Missito
//
//  Created by Jenea Vranceanu on 6/27/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss
import RealmSwift
    
final class MissitoAttachment: Gloss.Decodable, Gloss.Encodable {

    let images: [MissitoImage]?
    let contacts: [MissitoContact]?
    let locations: [MissitoLocation]?
    let audio: [MissitoAudio]?
    let video: [MissitoVideo]?
    
    init(_ images: [MissitoImage]) {
        self.images = images
        self.contacts = nil
        self.locations = nil
        self.audio = nil
        self.video = nil
    }
    
    init(_ contacts: [MissitoContact]) {
        self.images = nil
        self.contacts = contacts
        self.locations = nil
        self.audio = nil
        self.video = nil
    }
    
    init(_ locations: [MissitoLocation]) {
        self.images = nil
        self.contacts = nil
        self.locations = locations
        self.audio = nil
        self.video = nil
    }
    
    init(_ audio: [MissitoAudio]) {
        self.images = nil
        self.contacts = nil
        self.locations = nil
        self.audio = audio
        self.video = nil
    }
    
    init(_ video: [MissitoVideo]) {
        self.images = nil
        self.contacts = nil
        self.locations = nil
        self.audio = nil
        self.video = video
    }
    
    init?(json: JSON) {
        let keys = json.keys
        if keys.contains("images") ||
            keys.contains("contacts") ||
            keys.contains("locations") ||
            keys.contains("audio") ||
            keys.contains("video") {
            
            self.images = "images" <~~ json
            self.contacts = "contacts" <~~ json
            self.locations = "locations" <~~ json
            self.audio = "audio" <~~ json
            self.video = "video" <~~ json
        } else {
            return nil
        }
    }
    
    func toJSON() -> JSON? {
        return jsonify([
                "images" ~~> images,
                "contacts" ~~> contacts,
                "locations" ~~> locations,
                "audio" ~~> audio,
                "video" ~~> video
            ]);
    }
    
    static func make(from realmAttachment: RealmAttachment?)->MissitoAttachment? {
        if let realmAttachment = realmAttachment {
            
            if !realmAttachment.images.isEmpty {
                var images: [MissitoImage] = []
                for a in realmAttachment.images {
                    images.append(
                        MissitoImage(
                            fileName: a.fileName,
                            link: a.link,
                            size: UInt64(a.size),
                            secret: a.secret,
                            thumbnail: a.thumbnail)
                    )
                }
                
                return MissitoAttachment(images)
            }
            
            if !realmAttachment.contacts.isEmpty {
                var contacts: [MissitoContact] = []
                for a in realmAttachment.contacts {
                    let contact = MissitoContact(
                        name: a.name,
                        surname: a.surname,
                        notes: a.notes,
                        avatar: a.avatar,
                        phones: getStringArray(a.phones),
                        emails: getStringArray(a.emails))
                    
                    if let contact = contact {
                        contacts.append(contact)
                    }
                }
                
                return MissitoAttachment(contacts)
            }
            
            if !realmAttachment.locations.isEmpty {
                var locations: [MissitoLocation] = []
                for a in realmAttachment.locations {
                    locations.append(
                        MissitoLocation(
                            label: a.label,
                            lat: a.lat,
                            lon: a.lon,
                            radius: a.radius)
                    )
                }
                
                return MissitoAttachment(locations)
            }
            
            if !realmAttachment.audio.isEmpty {
                var audio: [MissitoAudio] = []
                for a in realmAttachment.audio {
                    audio.append(
                        MissitoAudio(
                            title: a.title,
                            fileName: a.fileName,
                            link: a.link,
                            size: UInt64(a.size),
                            secret: a.secret)
                    )
                }
                
                return MissitoAttachment(audio)
            }
            
            if !realmAttachment.video.isEmpty {
                var video: [MissitoVideo] = []
                for a in realmAttachment.video {
                    video.append(
                        MissitoVideo(
                            title: a.title,
                            fileName: a.fileName,
                            link: a.link,
                            size: UInt64(a.size),
                            secret: a.secret,
                            thumbnail: a.thumbnail)
                    )
                }
                
                return MissitoAttachment(video)
            }
        }
        return nil
    }
    
    static func getStringArray(_ list: List<RealmString>) -> [String]? {
        if list.isEmpty {
            return nil
        }
        
        var strings: [String] = []
        for x in list {
            strings.append(x.stringValue)
        }
        return strings
    }
}
