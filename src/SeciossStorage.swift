//
//  SeciossStorage.swift
//  test
//
//  Created by katsumi on 2016/02/16.
//  Copyright © 2016年 secioss. All rights reserved.
//

import Foundation

class SeciossStorage {
    
    func set(key: String, data: NSData) ->Bool {
        let query: [String:AnyObject] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data
        ]
        
        SecItemDelete(query as CFDictionaryRef)
        
        let status: OSStatus = SecItemAdd(query as CFDictionaryRef, nil)
        
        return status == noErr
    }
    
    func load(key: String) ->NSData? {
        let query: [String:AnyObject] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ]
        var dataTypeRef : Unmanaged<AnyObject>?
        
        let status: OSStatus = withUnsafeMutablePointer(&dataTypeRef) {
            SecItemCopyMatching(query, UnsafeMutablePointer($0))
        }
        if status == noErr {
            return (dataTypeRef!.takeRetainedValue() as? NSData)
        } else {
            return nil
        }
    }
    
    /**
     * Save data in app local storage
     */
    func setlocal(Data: SeciossData)->Bool {
        setlocalstorage("SECIOSS_CLIENTCERT_REQURL", value: Data.SECIOSS_CLIENTCERT_REQURL)
        setlocalstorage("SECIOSS_CLIENTCERT_PASSWORD", value: Data.SECIOSS_CLIENTCERT_PASSWORD)
        setlocalstorage("SECIOSS_TRUST_HOSTNAME", value: Data.SECIOSS_TRUST_HOSTNAME)
        if Data.SECIOSS_FUNCTION != nil {
            switch Data.SECIOSS_FUNCTION! as SeciossData.FUNCTION {
            case .LOGIN:
                if let return_type = Data.SECIOSS_RETURN_TYPE?.toString() {
                    if return_type.characters.count > 0 && Data.SECIOSS_BACK_URL.characters.count > 0 {
                        setlocalstorage("SECIOSS_RETURN_TYPE", value: return_type)
                        setlocalstorage("SECIOSS_BACK_URL", value: Data.SECIOSS_BACK_URL)
                        return true
                    }
                }
                return false
            default:
                return true
            }
        } else {
            return false
        }
    }
    
    /**
     * Clear data in app local storage
     */
    func clearlocal()->Void {
        setlocalstorage("SECIOSS_CLIENTCERT_REQURL", value: "")
        setlocalstorage("SECIOSS_CLIENTCERT_PASSWORD", value: "")
        setlocalstorage("SECIOSS_TRUST_HOSTNAME", value: "")
        setlocalstorage("SECIOSS_RETURN_TYPE", value: "")
        setlocalstorage("SECIOSS_BACK_URL", value: "")
    }
    
    func setlocalstorage(key: String, value: String) ->Void {
        let userdefaults = NSUserDefaults.standardUserDefaults()
        userdefaults.setObject(value, forKey: key)
    }
    
    func loadlocalstorage(key: String) ->String? {
        let userdefaults = NSUserDefaults.standardUserDefaults()
        if let value = userdefaults.stringForKey(key) {
            return value
        }
        return nil
    }
}