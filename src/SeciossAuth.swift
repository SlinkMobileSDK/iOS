//
//  SeciossAuth.swift
//  test
//
//  Created by katsumi on 2015/10/19.
//  Copyright © 2015年 secioss. All rights reserved.
//

import UIKit

/**
 * Data class of Slink Mobile SDK for iOS.
 *
 * @author Katsumi Sekiguchi <sekiguchi.shisen@secioss.co.jp>
 * @copyright 2016 SECIOSS, INC.
 * @see http://www.secioss.co.jp
 */
class SeciossData {
    
    enum RETURN_TYPE : String {
        case RETURN_CONTENT
        case RETURN_HEADER
        case RETURN_COOKIE
        case RETURN_JSON
        case RETURN_XML
        func toString()->String {
            switch self {
            case .RETURN_CONTENT:
                return "RETURN_CONTENT"
            case .RETURN_HEADER:
                return "RETURN_HEADER"
            case .RETURN_COOKIE:
                return "RETURN_COOKIE"
            case .RETURN_JSON:
                return "RETURN_JSON"
            case .RETURN_XML:
                return "RETURN_XML"
            }
        }
    }
    
    enum FUNCTION : String {
        case LOGIN
        case OAUTH2
        case OIDC
        func toString()->String {
            switch self {
            case .LOGIN:
                return "LOGIN"
            case .OAUTH2:
                return "OAUTH2"
            case .OIDC:
                return "OIDC"
            }
        }
    }
    
    enum OAUTH2_FINISH : String {
        case userinfo
        case token
        func toString()->String {
            switch self {
            case .userinfo:
                return "userinfo"
            case .token:
                return "token"
            }
        }
    }
    
    enum OIDC_FINISH : String {
        case claims
        case token
        case idtoken
        func toString()->String {
            switch self {
            case .claims:
                return "claims"
            case .token:
                return "token"
            case .idtoken:
                return "idtoken"
            }
        }
    }
    
    var SECIOSS_RETURN_TYPE : RETURN_TYPE?
    var SECIOSS_FUNCTION : FUNCTION?
    var SECIOSS_OAUTH2_FINISH : OAUTH2_FINISH?
    var SECIOSS_OIDC_FINISH : OIDC_FINISH?
    
    var SECIOSS_TRUST_HOSTNAME = ""
    
    var SECIOSS_INIT_URL = ""
    var SECIOSS_BACK_URL = ""
    var SECIOSS_BASE_URL = ""
    var SECIOSS_FAIL_URL = ""
    
    var SECIOSS_CLIENTCERT_REQURL = ""
    var SECIOSS_CLIENTCERT_FILEPATH = ""
    var SECIOSS_CLIENTCERT_PASSWORD = ""
    
    var SECIOSS_OAUTH2_AUTHORIZE = ""
    var SECIOSS_OAUTH2_TOKEN = ""
    var SECIOSS_OAUTH2_RESOURCE = ""
    var SECIOSS_OAUTH2_CLIENT_ID = ""
    var SECIOSS_OAUTH2_CLIENT_SECRET = ""
    var SECIOSS_OAUTH2_REDIRECT_URI = ""
    var SECIOSS_OAUTH2_SCOPE = ""
    var SECIOSS_OAUTH2_RESPONSE_TYPE = ""
    
    var SECIOSS_OIDC_AUTHORIZE = ""
    var SECIOSS_OIDC_TOKEN = ""
    var SECIOSS_OIDC_RESOURCE = ""
    var SECIOSS_OIDC_CLIENT_ID = ""
    var SECIOSS_OIDC_CLIENT_SECRET = ""
    var SECIOSS_OIDC_REDIRECT_URI = ""
    var SECIOSS_OIDC_SCOPE = ""
    var SECIOSS_OIDC_RESPONSE_TYPE = ""
    var SECIOSS_OIDC_JWKS = ""
    var SECIOSS_OIDC_JWKS_URI = ""
    var SECIOSS_OIDC_CLAIMS = ""
    var SECIOSS_OIDC_ISSUER = ""
}

class SeciossAuth: UIViewController, UIWebViewDelegate, UIGestureRecognizerDelegate {

    let protocolNotificationName = "SeciossProtocolNotification"
    let authNotificationName = "SeciossAuthNotification"

    private var _protocol: SeciossProtocol = SeciossProtocol()
    private let header = "<html><head><script type=\"text/javascript\">"
    private let footer = "</script></head><body onload=\"a()\"></body></html>"
    
    private var _tmpdir: String?
    private var _webview: UIWebView?
    
    let seciossstorage = SeciossStorage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    /**
     * process when swipe gesture
     */
    func setupSwipeCancel() {
        let swipe = UISwipeGestureRecognizer(target: self, action: "swipeclose")
        swipe.delegate = self
        swipe.direction = UISwipeGestureRecognizerDirection.Right
        self._webview!.addGestureRecognizer(swipe)
    }
    
    func swipeclose() {
        close(1, message: "Canceled")
    }
    
    func close(code: Int, message: String) {
        NSURLProtocol.unregisterClass(SeciossProtocol)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: protocolNotificationName, object: nil)
        seciossstorage.clearlocal()
        NSNotificationCenter.defaultCenter().postNotificationName(authNotificationName, object: self, userInfo: ["result": message])
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func invokeGetData(notification: NSNotification?) {
        if  let auth_data = notification?.userInfo {
            if auth_data["code"] != nil && auth_data["value"] != nil {
                close(auth_data["code"] as! Int, message: auth_data["value"] as! String)
                return
            } else if auth_data["url"] != nil {
                let url = auth_data["url"] as! NSURL
                if auth_data["data"] != nil {
                    let data = auth_data["data"] as! NSData
                    let response_str = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
                    _webview!.loadHTMLString(response_str, baseURL: url)
                }
                return
            }
        }
        close(99, message: "Unknown Error")
    }
    
    func loadLocalFile(url: NSURL) {
        var req_url: NSURL?
        let url_str = url.absoluteString
        let elms = url_str.componentsSeparatedByString("://")
        var path = elms[1]
        let file_manager = NSFileManager.defaultManager()
        if !file_manager.fileExistsAtPath(path) {
            let document_root = copyHTML()
            if document_root == nil || document_root?.characters.count < 1 {
                close(3, message: "Page Not Found")
                return
            }
            if path.hasPrefix("www/oauth2.html") {
                path = document_root! + "/oauth2.html"
            } else if path.hasPrefix("www/oidc.html") {
                path = document_root! + "/oidc.html"
            }
            if !file_manager.fileExistsAtPath(path) {
                close(3, message: "Page Not Found")
                return
            }
            let comp = NSURLComponents()
            let elts = url_str.componentsSeparatedByString("?")
            comp.scheme = "file"
            comp.path = path
            comp.query = elts[1]
            req_url = comp.URL
        } else {
            req_url = NSURL(fileURLWithPath: path)
        }
        let req = NSURLRequest(URL: req_url!)
        _webview!.loadRequest(req)
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let request_url = request.URL {
            if request_url.scheme == "seciossauth" {
                if request_url.host == "result" {
                    let result = (request_url.query! as String).stringByRemovingPercentEncoding!
                    close(0, message: result)
                } else {
                    loadLocalFile(request_url)
                }
                return false
            }
        }
        return true
    }

    /**
     * WebView Client start the authentication process
     */
    func startLoginForResult(Data: SeciossData)->Bool {
        
        let seciossstorage = SeciossStorage()
        if !seciossstorage.setlocal(Data) {
            return false
        }
        if _webview != nil {
            _webview = nil
        }
        if _tmpdir != nil {
            _tmpdir = nil
        }
        _webview = UIWebView(frame: CGRectZero)
        _webview?.delegate = self
        self.view = _webview
        
        NSURLProtocol.registerClass(SeciossProtocol)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "invokeGetData:", name: protocolNotificationName, object: nil)

        if Data.SECIOSS_FUNCTION != nil {
            var req:NSURLRequest?
            switch Data.SECIOSS_FUNCTION! as SeciossData.FUNCTION {
            case .LOGIN:
                if Data.SECIOSS_INIT_URL.characters.count > 0 {
                    if let init_url = NSURL(string: Data.SECIOSS_INIT_URL) {
                        req = NSURLRequest(URL: init_url)
                        break
                    }
                }
                return false
            case .OAUTH2:
                let init_path = createOAuthContents("oauth2", Data: Data)
                if init_path != nil {
                    let init_url = NSURL(fileURLWithPath: init_path!)
                    req = NSURLRequest(URL: init_url)
                    break
                }
                return false
            case .OIDC:
                let init_path = createOAuthContents("oauth2", Data: Data)
                if init_path != nil {
                    let init_url = NSURL(fileURLWithPath: init_path!)
                    req = NSURLRequest(URL: init_url)
                    break
                }
                return false
            }
            
            setupSwipeCancel()
            _webview?.loadRequest(req!)
            return true
        }
        return false
    }
    
    /**
     * Create web contents when oauth2 or oidc authentication
     * @param type Authentication type
     * @return file path of first access
     */
    func createOAuthContents(type: String, Data: SeciossData)->String? {
        let file_manager = NSFileManager.defaultManager()
        let document_root = copyHTML()
        if document_root == nil || document_root?.characters.count < 1 {
            return nil
        }
        let init_path = document_root! + "/" + type + ".html"
        if !file_manager.fileExistsAtPath(init_path) {
            return nil
        }
        
        if let html_str = createOAuthInithtml(type, path: init_path, Data: Data) {
            let file = document_root! + "/init.html"
            do {
                if file_manager.fileExistsAtPath(file) {
                    try file_manager.removeItemAtPath(file)
                }
                try html_str.writeToFile(file, atomically: false, encoding: NSUTF8StringEncoding)
            } catch {
                return nil
            }
            return file
        }
        return nil
    }

    /**
     * Create html strings for first access when oauth2 or oidc authentication
     * @param type Authentication type
     * @param path file path of redirect to
     * @param Data SeciossData
     * @return html strings for first access
     */
    func createOAuthInithtml(type: String, path: String, Data: SeciossData)->String? {
        var contents: String?
        if type == "oauth2" {
            if let finish = Data.SECIOSS_OAUTH2_FINISH?.toString() {
                var html_str = header + "function a() {"
                html_str += "sessionStorage.setItem('SECIOSS_OAUTH2_FINISH', '\(finish)');"
                html_str += "sessionStorage.setItem('SECIOSS_OAUTH2_AUTHORIZE', '\(Data.SECIOSS_OAUTH2_AUTHORIZE)');"
                html_str += "sessionStorage.setItem('SECIOSS_OAUTH2_TOKEN', '\(Data.SECIOSS_OAUTH2_TOKEN)');"
                html_str += "sessionStorage.setItem('SECIOSS_OAUTH2_RESOURCE', '\(Data.SECIOSS_OAUTH2_RESOURCE)');"
                html_str += "sessionStorage.setItem('SECIOSS_OAUTH2_CLIENT_ID', '\(Data.SECIOSS_OAUTH2_CLIENT_ID)');"
                html_str += "sessionStorage.setItem('SECIOSS_OAUTH2_CLIENT_SECRET', '\(Data.SECIOSS_OAUTH2_CLIENT_SECRET)');"
                html_str += "sessionStorage.setItem('SECIOSS_OAUTH2_REDIRECT_URI', '\(Data.SECIOSS_OAUTH2_REDIRECT_URI)');"
                html_str += "sessionStorage.setItem('SECIOSS_OAUTH2_SCOPE', '\(Data.SECIOSS_OAUTH2_SCOPE)');"
                html_str += "sessionStorage.setItem('SECIOSS_OAUTH2_RESPONSE_TYPE', '\(Data.SECIOSS_OAUTH2_RESPONSE_TYPE)');"
                html_str += "window.location='file://\(path)';}" + footer
                contents = html_str
            }
        } else if type == "oidc" {
            if let finish = Data.SECIOSS_OIDC_FINISH?.toString() {
                var html_str = header + "function a() {"
                html_str += "sessionStorage.setItem('SECIOSS_OIDC_FINISH', '\(finish)');"
                html_str += "sessionStorage.setItem('SECIOSS_OIDC_AUTHORIZE', '\(Data.SECIOSS_OIDC_AUTHORIZE)');"
                html_str += "sessionStorage.setItem('SECIOSS_OIDC_TOKEN', '\(Data.SECIOSS_OIDC_TOKEN)');"
                html_str += "sessionStorage.setItem('SECIOSS_OIDC_RESOURCE', '\(Data.SECIOSS_OIDC_RESOURCE)');"
                html_str += "sessionStorage.setItem('SECIOSS_OIDC_CLIENT_ID', '\(Data.SECIOSS_OIDC_CLIENT_ID)');"
                html_str += "sessionStorage.setItem('SECIOSS_OIDC_CLIENT_SECRET', '\(Data.SECIOSS_OIDC_CLIENT_SECRET)');"
                html_str += "sessionStorage.setItem('SECIOSS_OIDC_REDIRECT_URI', '\(Data.SECIOSS_OIDC_REDIRECT_URI)');"
                html_str += "sessionStorage.setItem('SECIOSS_OIDC_SCOPE', '\(Data.SECIOSS_OIDC_SCOPE)');"
                html_str += "sessionStorage.setItem('SECIOSS_OIDC_RESPONSE_TYPE', '\(Data.SECIOSS_OIDC_RESPONSE_TYPE)');"
                html_str += "sessionStorage.setItem('SECIOSS_OIDC_JWKS', '\(Data.SECIOSS_OIDC_JWKS)');"
                html_str += "sessionStorage.setItem('SECIOSS_OIDC_JWKS_URI', '\(Data.SECIOSS_OIDC_JWKS_URI)');"
                html_str += "sessionStorage.setItem('ECIOSS_OIDC_CLAIMS', '\(Data.SECIOSS_OIDC_CLAIMS)');"
                html_str += "sessionStorage.setItem('SECIOSS_OIDC_ISSUER', '\(Data.SECIOSS_OIDC_ISSUER )');"
                html_str += "window.location='file://\(path)';}" + footer
                contents = html_str
            }
        }
        return contents
    }
    
    /**
     * Copy web contents to accessible area when oauth2 or oidc authentication
     * @param type Authentication type
     * @return base directory
     */
    func copyHTML() -> String? {
        
        if let existdir: String = _tmpdir {
            return existdir
        }
        
        let dir = NSBundle.mainBundle().resourcePath
        let file_manager = NSFileManager.defaultManager()
        let dir_org = dir! + "/www"
        let dir_tmp = NSTemporaryDirectory() + "www"
        
        if !file_manager.fileExistsAtPath(dir_tmp) {
            do {
                try file_manager.createDirectoryAtPath(dir_tmp, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        let dir_enum = file_manager.enumeratorAtPath(dir_org)
        while let name = dir_enum?.nextObject() {
            let file = dir_org + "/" + (name as! String)
            let target = dir_tmp + "/" + (name as! String)
            if !file_manager.fileExistsAtPath(target) {
                do {
                    try file_manager.copyItemAtPath(file, toPath: target)
                } catch {
                    return nil
                }
            } else {
                do {
                    let old = try NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding)
                    let new = try NSString(contentsOfFile: target, encoding: NSUTF8StringEncoding)
                    if old != new {
                        try file_manager.removeItemAtPath(target)
                        try file_manager.copyItemAtPath(file, toPath: target)
                    }
                } catch {
                    return nil
                }
            }
        }
        _tmpdir = dir_tmp
        
        return dir_tmp
    }
}

extension NSURLRequest {
    static func allowsAnyHTTPSCertificateForHost(host: String) -> Bool {
        return true
    }
}