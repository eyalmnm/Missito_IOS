//
//  EncryptionHelper.swift
//  Missito
//
//  Created by Alex Gridnev on 12/13/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import CryptoSwift

struct EncryptionHelper {
    
    private static func readFrom(fileHandle: FileHandle, maxLength: Int) -> Data? {
        var data: Data?
        __try {
            data = fileHandle.readData(ofLength: maxLength)
        }
        _catch {
            (exception: NSException?) in
            NSLog("Read from file handle failed! %@", exception?.callStackSymbols ?? [])
            data = nil
        }
        return data
    }
    
    private static func writeTo(fileHandle: FileHandle, data: Data) -> Bool {
        var success = false
        __try {
            fileHandle.write(data)
            success = true
        }
        _catch {
            (exception: NSException?) in
            NSLog("Write to file handle failed! %@", exception?.callStackSymbols ?? [])
        }
        return success
    }
    
    static func encryptFile(filePath: String, key: String, _ completion: @escaping (String?, Error?)->()) {
        
        guard let keyData = Data(base64Encoded: key), keyData.count == 32 else {
            completion(nil, EncryptionError.badKey)
            return
        }
        
        NSLog("Encrypting file at: %@", filePath)

        DispatchQueue.global().async {
            
            // TODO: control this path more thoroughly
            let destFilePath = filePath + ".enc"
            
            func callCompletion(_ error: Error?) {
                DispatchQueue.main.async {
                    if error == nil {
                        completion(destFilePath, nil)
                    } else {
                        // Error encountered. Removing destination file
                        try? FileManager.default.removeItem(atPath: destFilePath)
                        completion(nil, error)
                    }
                }
            }
            
            do {
                
                guard let inputFileHandle = FileHandle(forReadingAtPath: filePath) else {
                    callCompletion(EncryptionError.inputFileError)
                    return
                }
                var oh = FileHandle(forWritingAtPath: destFilePath)
                if oh == nil {
                    FileManager.default.createFile(atPath: destFilePath, contents: nil, attributes: nil)
                    oh = FileHandle(forWritingAtPath: destFilePath)
                }
                guard let outputFileHandle = oh else {
                    callCompletion(EncryptionError.outputFileError)
                    return
                }
                
                let iv = AES.randomIV(AES.blockSize)
                var encryptor = try AES(key: keyData.bytes, iv: iv, blockMode: .CBC, padding: .pkcs7).makeEncryptor()

                guard writeTo(fileHandle: outputFileHandle, data: Data(bytes: iv)) else {
                    callCompletion(EncryptionError.outputFileError)
                    return
                }
                
                while true {
                    guard let data = readFrom(fileHandle: inputFileHandle, maxLength: 32 * 1024) else {
                        callCompletion(EncryptionError.inputFileError)
                        return
                    }

                    if data.count == 0 {
                        break
                    }
                    
                    let ciphertext = try encryptor.update(withBytes: data.bytes)
                    
                    guard writeTo(fileHandle: outputFileHandle, data: Data(bytes: ciphertext)) else {
                        callCompletion(EncryptionError.outputFileError)
                        return
                    }
                    
                }
                
                let ciphertext = try encryptor.finish()
                guard writeTo(fileHandle: outputFileHandle, data: Data(bytes: ciphertext)) else {
                    callCompletion(EncryptionError.outputFileError)
                    return
                }
                
                outputFileHandle.closeFile()
                callCompletion(nil)
            } catch {
                print(error)
                callCompletion(error)
            }

        }
    }
    
    static func decryptFile(sourcePath: String, key: String, destinationPath: String, _ completion: @escaping (String?, Error?) -> ()) {
        
        guard let keyData = Data(base64Encoded: key), keyData.count == 32 else {
            completion(nil, EncryptionError.badKey)
            return
        }
        
        DispatchQueue.global().async {
            
            func callCompletion(_ error: Error?) {
                DispatchQueue.main.async {
                    if error == nil {
                        completion(destinationPath, nil)
                    } else {
                        // Error encountered. Removing destination file
                        try? FileManager.default.removeItem(atPath: destinationPath)
                        completion(nil, error)
                    }
                }
            }
            
            do {
                
                guard let inputFileHandle = FileHandle(forReadingAtPath: sourcePath) else {
                    callCompletion(EncryptionError.inputFileError)
                    return
                }
                var oh = FileHandle(forWritingAtPath: destinationPath)
                if oh == nil {
                    FileManager.default.createFile(atPath: destinationPath, contents: nil, attributes: nil)
                    oh = FileHandle(forWritingAtPath: destinationPath)
                }
                guard let outputFileHandle = oh else {
                    callCompletion(EncryptionError.outputFileError)
                    return
                }
                
                guard let iv = readFrom(fileHandle: inputFileHandle, maxLength: 16), inputFileHandle.offsetInFile == 16 else {
                    callCompletion(EncryptionError.inputFileError)
                    return
                }
                var decryptor = try AES(key: keyData.bytes, iv: iv.bytes, blockMode: .CBC, padding: .pkcs7).makeDecryptor()
                
                while true {
                    guard let data = readFrom(fileHandle: inputFileHandle, maxLength: 32 * 1024) else {
                        callCompletion(EncryptionError.inputFileError)
                        return
                    }
                    
                    if data.count == 0 {
                        break
                    }
                    
                    let ciphertext = try decryptor.update(withBytes: data.bytes)
                    
                    guard writeTo(fileHandle: outputFileHandle, data: Data(bytes: ciphertext)) else {
                        callCompletion(EncryptionError.outputFileError)
                        return
                    }
                    
                }
                
                let ciphertext = try decryptor.finish()
                guard writeTo(fileHandle: outputFileHandle, data: Data(bytes: ciphertext)) else {
                    callCompletion(EncryptionError.outputFileError)
                    return
                }
                
                outputFileHandle.closeFile()
                callCompletion(nil)
            } catch {
                print(error)
                callCompletion(error)
            }
            
        }
    }
    
    static func generateRandomAES256Key() -> String {
        
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, keyData.count, $0)
        }
        if result == errSecSuccess {
            return keyData.base64EncodedString()
        } else {
            print("Problem generating random bytes")
            // TODO: use simple random here
            return ""
        }
    }
    
    enum EncryptionError: Swift.Error {
        case badKey
        case inputFileError
        case outputFileError

        var localizedDescription: String {
            get {
                switch self {
                case .badKey:
                    return "Bad encryption key supplied"
                case .inputFileError:
                    return "Can't read input file"
                case .outputFileError:
                    return "Can't write output file"

                }
            }
        }
    }
}
