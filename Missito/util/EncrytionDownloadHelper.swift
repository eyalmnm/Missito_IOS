//
//  EncrytionDownloadHelper.swift
//  Missito
//
//  Created by Alex Gridnev on 12/26/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

struct EncryptionDownloadHelper {

    static func encryptAndUpload(destUid: String, destDeviceId: Int, encryptionKey: String, localFilePath: String,
                          progressCallback: @escaping (Float)->(),
                          _ completion: @escaping (AttachmentSpec?, Error?)->()) {

        EncryptionHelper.encryptFile(filePath: localFilePath, key: encryptionKey) { (encryptedFilePath, error) in
            if let error = error {
                NSLog("encryptFile failed: %@", error.localizedDescription)
                completion(nil, error)
                return
            }
            
            guard let encryptedFilePath = encryptedFilePath else {
                // Never should get here
                NSLog("encryptFile failed: missing encryptedFilePath")
                completion(nil, EncryptionDownloadError.unknown)
                return
            }
            
            APIRequests.attachAndUploadFile(destUid: destUid, destDeviceId: destDeviceId, localFilePath: encryptedFilePath, fileSize: Utils.getFileSize(path: encryptedFilePath), progressCallback: progressCallback) {
                (attachmentSpec, error) in
                if let error = error {
                    NSLog("attachAndUploadFile failed: %@", error.localizedDescription)
                    completion(nil, error)
                }
                
                guard let attachmentSpec = attachmentSpec else {
                    // Never should get here
                    NSLog("attachAndUploadFile failed: missing attachmentSpec")
                    completion(nil, EncryptionDownloadError.unknown)
                    return
                }
                NSLog("Upload OK")
                completion(attachmentSpec, nil)
            }
        }
    }
    
    static func downloadAndDecrypt(encryptionKey: String, url: URL, destFileUrl: URL, _ completion: @escaping (EncryptionDownloadError?) -> Void) {
        
        // Create temporary file
        let tempFilePath = Utils.getTempDirectory().appendingPathComponent("temp_\(url.hashValue)")
        guard FileManager.default.createFile(atPath: tempFilePath.path, contents: nil, attributes: nil) else {
            completion(.createTempFileError)
            return
        }
        
        defer {
            // Removing temporary file
            try? FileManager.default.removeItem(at: tempFilePath)
        }
        
        APIRequests.downloadFile(url: url, toFile: tempFilePath) { error in
            guard error == nil else {
                completion(.downloadError)
                return
            }
            
            EncryptionHelper.decryptFile(sourcePath: tempFilePath.path, key: encryptionKey, destinationPath: destFileUrl.path, { (destPath, error) in
                guard error == nil else {
                    completion(.decryptError)
                    return
                }
                completion(nil)
            })
        }
    }

    enum EncryptionDownloadError: Swift.Error {
        case unknown
        case createTempFileError
        case downloadError
        case decryptError
        
        var localizedDescription: String {
            get {
                switch self {
                case .unknown:
                    return "EncryptionDownload unknown error"
                case .createTempFileError:
                    return "Couldn't create temporary file"
                case .downloadError:
                    return "Error while downloading file"
                case .decryptError:
                    return "Error while decrypting file"
                }
            }
        }
    }
}
