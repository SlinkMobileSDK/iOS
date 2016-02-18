//  SeciossProtocol.swift
//  test
//
//  Created by katsumi on 2015/08/27.
//  Copyright (c) 2015年 secioss. All rights reserved.
//

import Foundation

class SeciossProtocol: NSURLProtocol, NSURLSessionDataDelegate {

    let protocolNotificationName = "SeciossProtocolNotification"
    
    var _session: NSURLSession?
    var _task: NSURLSessionTask?

    var _response: NSURLResponse?
    var _data: NSMutableData?
    
    var in_certreq: Bool = false
    var in_getresult: Bool = false
    
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        let current_url = request.URL
        let current: String = current_url!.absoluteString
        if NSURLProtocol.propertyForKey("SeciossProtocolKey", inRequest: request) == nil {
            let seciossstorage = SeciossStorage()
            if let back_url = seciossstorage.loadlocalstorage("SECIOSS_BACK_URL") {
                if current.hasPrefix(back_url) {
                    return true
                }
            }
            if let certreq_url = seciossstorage.loadlocalstorage("SECIOSS_CLIENTCERT_REQURL") {
                if current.hasPrefix(certreq_url)  {
                    return true
                }
            }
        }
        return false
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(aRequest: NSURLRequest, toRequest bRequest: NSURLRequest) -> Bool {
        return super.requestIsCacheEquivalent(aRequest, toRequest:bRequest)
    }
    
    override func startLoading() {
        var newRequest = NSMutableURLRequest()
        newRequest = self.request.mutableCopy() as! NSMutableURLRequest
        let request_url = newRequest.URL
        let request_url_str = request_url?.absoluteString
        NSURLProtocol.setProperty(true, forKey: "SeciossProtocolKey", inRequest: newRequest)
        _session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        _task = _session?.dataTaskWithRequest(newRequest, completionHandler: {
            (data, resp, err) in
            if err == nil {
                self.stopLoading()
                if let response_url = resp?.URL {
                    let seciossstorage = SeciossStorage()
                    if let back_url = seciossstorage.loadlocalstorage("SECIOSS_BACK_URL") {
                        var result = ""
                        if request_url_str!.hasPrefix(back_url) {
                            let type = seciossstorage.loadlocalstorage("SECIOSS_RETURN_TYPE")
                            switch type {
                            case .Some("RETURN_CONTENT"), .Some("RETURN_CONTENT"), .Some("RETURN_XML"):
                                result = NSString(data: data!, encoding: NSUTF8StringEncoding) as! String
                                break
                            case .Some("RETURN_HEADER"):
                                result = self.parseHeader("RETURN_HEADER", http_response: resp as! NSHTTPURLResponse)
                                break
                            case .Some("RETURN_COOKIE"):
                                result = self.parseHeader("RETURN_COOKIE", http_response: resp as! NSHTTPURLResponse)
                                break
                            case .None:
                                result = "Bad Request: Type not specified"
                                break
                            default:
                                result = "Bad Request: Invalid Type"
                                break
                            }
                            self.sendmessge(0, message: result)
                        }
                    }
                    if let certreq_url = seciossstorage.loadlocalstorage("SECIOSS_CLIENTCERT_REQURL") {
                        if request_url_str!.hasPrefix(certreq_url) {
                            NSNotificationCenter.defaultCenter().postNotificationName(self.protocolNotificationName, object: self, userInfo: ["url": response_url, "data": data!])
                        }
                    }
                }
            } else {
                self.sendmessge(1, message: "Network Unavailable")
            }
        })
        _task!.resume()
    }
    
    override func stopLoading() {
        if _task != nil {
            _task?.suspend()
            _task?.cancel()
            _task = nil
        }
        if self._session != nil {
            self._session?.invalidateAndCancel()
            self._session = nil
        }
    }
    
    func sendmessge(code: Int, message: String) {
        NSNotificationCenter.defaultCenter().postNotificationName(protocolNotificationName, object: self, userInfo: ["code": code , "value": message])
        stopLoading()
    }

    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        if error != nil {
            _session?.invalidateAndCancel()
        } else {
            _session?.finishTasksAndInvalidate()
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let serverTrust:SecTrustRef = challenge.protectionSpace.serverTrust!
            let credential:NSURLCredential = NSURLCredential(forTrust: serverTrust)
            completionHandler(.UseCredential, credential)
            challenge.sender!.continueWithoutCredentialForAuthenticationChallenge(challenge)
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            if let credential = createCredential() {
                completionHandler(.UseCredential, credential)
            } else {
                completionHandler(.CancelAuthenticationChallenge, nil)
            }
        }
    }

    /**
     * Create NSURLCredential when certification authentication
     * @return NSURLCredential
     */
    func createCredential() -> NSURLCredential? {
        let seciossstorage = SeciossStorage()
        if let cert_data = seciossstorage.load("SECIOSS_CLIENTCERT_FILEPATH") {
            if cert_data.length < 1 {
                return nil
            }
            if let cert_password = seciossstorage.loadlocalstorage("SECIOSS_CLIENTCERT_PASSWORD") {
                let options = [kSecImportExportPassphrase as String : cert_password]
                var cf_items: CFArray?
                if errSecSuccess == SecPKCS12Import(cert_data, options, &cf_items) {
                    let items = cf_items! as Array
                    let cert_dict = items.first as! NSDictionary
                    if let cert = cert_dict as? Dictionary<String, AnyObject> {
                        let identity_pointer = cert["identity"]
                        let identity_ref = identity_pointer as! SecIdentityRef
                        var cert_ref: SecCertificateRef?
                        SecIdentityCopyCertificate(identity_ref, &cert_ref)
                        let cert_arr = NSArray(object: cert_ref!)
                        
                        return NSURLCredential(identity: identity_ref, certificates: cert_arr as [AnyObject], persistence: NSURLCredentialPersistence.ForSession)
                    }
                }
            }
        }
        return nil
    }
        
    func parseHeader(type: String, http_response: NSHTTPURLResponse) -> String {
            
        var str: String = ""
        let headers = http_response.allHeaderFields as! Dictionary<String, AnyObject>
        for (key, value) in headers {
            if (type == "RETURN_HEADER") || (key == "Set-Cookie") {
                str += (key as String) + ": " + (value as! String) + "\n"
            }
        }
            
        return str
    }
}
