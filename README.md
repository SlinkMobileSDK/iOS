
# Slink Mobile SDK for iOS
### 1. Source
###### swift:
    ~/src/SeciossAuth.swift
    ~/src/SeciossStorage.swift
    ~/src/SeciossProtocol.swift

###### Assets:
    ~/src/www/jquery.js
    ~/src/www/jsrsasign.js
    ~/src/www/oauth2.html
    ~/src/www/oidc.html
    ~/src/www/seciossauth.js

### 2. Usage
###### Call SeciossAuth in your project
#### 2.1 Invoke SeciossAuth:
``` swift
NSNotificationCenter.defaultCenter().addObserver(self, selector: "getAuthData:", name: "SeciossAuthNotification", object: nil)
var seciossData = SeciossData()
var seciossAuth = SeciossAuth()
seciossData.name = SeciossData.name.value    // name and value are described below in 4.
seciossData.name = value                                    // name and value are described below in 4.
if seciossAuth.startLoginForResult(seciossData) {
    // ......
}
```
#### 2.2 Retrieve SeciossAuth Result:
``` swift
func getAuthData(notification: NSNotification?) {
     if  let data = notification?.userInfo {
         let prefix: String = "\n"
         if data["result"] != nil {
             result_str = prefix + (data["result"] as! String)
         } else if data["code"] != nil {
             result_str = prefix + (data["code"] as! String)
         }
     }
     NSNotificationCenter.defaultCenter().removeObserver(self, name: "SeciossAuthNotification", object: nil)
}
```

### 3. Notice
1. There are required parameters for each authentication type.<br>
2. When error occoured or for cancel the login process, Swipe the screen back to previous view.<br>

### 4. Parameters (Same for both iOS and Android)
###### Parameters for each authentication type
#### 4.1 Common
##### 4.1.1 Parameters
    SECIOSS_AUTH_RESULT*          the result of authentication
    SECIOSS_SESSION_PARAM         the parameter of session when session is used
    SECIOSS_FUNCTION*             which authentication (specified below in 4.1.2)
    SECIOSS_TRUST_HOSTNAME        hostname to trust (separated by comma)
    SECIOSS_SERVERCERT_FILEPATH*  the full path of server certificate necessary if self-signed

##### 4.1.2 Values
###### Values of SECIOSS_FUNCTION
    LOGIN                         Use the web based login to authenticate user
    OAUTH2                        Use the OAuth2.0 to authenticate user
    OIDC                          Use the OpenID Connect authenticate user

#### 4.2 Web Based Login
##### 4.2.1 Parameters
    SECIOSS_INIT_URL*             the initialization url
    SECIOSS_BACK_URL*             the redirection url after login success
    SECIOSS_BASE_URL              the direct login url
    SECIOSS_FAIL_URL              the failure url when login page cannot be open
    SECIOSS_RETURN_TYPE           what to return (specified below in 4.2.2)

##### 4.2.2 Values
###### Values of SECIOSS_RETURN_TYPE
    RETURN_CONTENT	              return the response content after success login
    RETURN_HEADER                 return the response http header after success login
    RETURN_COOKIE                 return the any cookie issued after success login
    RETURN_JSON                   return json formate response body after success login
    RETURN_XML                    return xml formate response body after success login

#### 4.3 Certificate Authentication
##### 4.3.1 Parameters
    SECIOSS_CLIENTCERT_REQURL*    the url (snippet) for certificate authentication
    SECIOSS_CLIENTCERT_FILEPATH*  the full path of user certificate file
    SECIOSS_CLIENTCERT_PASSWORD   the password of user certificate

#### 4.4 OAuth2.0
##### 4.4.1 Parameters
    SECIOSS_OAUTH2_FINISH         what to return (specified below in 4.4.2)
    SECIOSS_OAUTH2_AUTHORIZE      OAuth2.0 authorization endpoint url
    SECIOSS_OAUTH2_TOKEN          OAuth2.0 token endpoint url
    SECIOSS_OAUTH2_RESOURCE       OAuth2.0 resource endpoint url
    SECIOSS_OAUTH2_CLIENT_ID      OAuth2.0 client id
    SECIOSS_OAUTH2_CLIENT_SECRET  OAuth2.0 client secret
    SECIOSS_OAUTH2_REDIRECT_URI   OAuth2.0 client redirect uri
    SECIOSS_OAUTH2_SCOPE          OAuth2.0 authorization scope
    SECIOSS_OAUTH2_RESPONSE_TYPE  OAuth2.0 response type in authorization endpoint

##### 4.4.2 Values
###### Values of SECIOSS_OAUTH2_FINISH
    USERINFO                      return user information
    TOKEN                         return access token or refresh token in json string

#### 4.5 OpenID Connect (OIDC)
##### 4.5.1 Parameters
    SECIOSS_OIDC_FINISH           what to return (specified below in 4.4.2)
    SECIOSS_OIDC_AUTHORIZE        OIDC authorization endpoint url
    SECIOSS_OIDC_TOKEN            OIDC token endpoint url
    SECIOSS_OIDC_RESOURCE         OIDC resource endpoint url
    SECIOSS_OIDC_CLIENT_ID        OIDC client id
    SECIOSS_OIDC_CLIENT_SECRET    OIDC client secret
    SECIOSS_OIDC_REDIRECT_URI     OIDC client redirect uri
    SECIOSS_OIDC_SCOPE            OIDC authorization scope
    SECIOSS_OIDC_RESPONSE_TYPE    OIDC response type in authorization endpoint
    SECIOSS_OIDC_JWKS             OIDC JSON web keys
    SECIOSS_OIDC_JWKS_URI         OIDC JSON web keys uri
    SECIOSS_OIDC_CLAIMS           OIDC request claims
    SECIOSS_OIDC_ISSUER           OIDC idtoken issuer to trust (verify)

##### 4.5.2 Values
###### Values of SECIOSS_OIDC_FINISH
    CLAIMS                        return OIDC claims (user information)
    TOKEN                         return access token or refresh token in json string
    IDTOKEN                       return id token

### 5. Samples
###### Samples for each authentication type
#### 5.1 ID/PW Authentication
``` swift
NSNotificationCenter.defaultCenter().addObserver(self, selector: "getAuthData:", name: "SeciossAuthNotification", object: nil)
var seciossData = SeciossData()
var seciossAuth = SeciossAuth()
seciossData.SECIOSS_FUNCTION = SeciossData.SECIOSS_FUNCTION.LOGIN
seciossData.SECIOSS_INIT_URL = "https://slink.secioss.com/user/"
seciossData.SECIOSS_BACK_URL = "https://slink.secioss.com/user/index.php"
seciossData.SECIOSS_RETURN_TYPE = SeciossData.SECIOSS_RETURN_TYPE.RETURN_COOKIE
if seciossAuth.startLoginForResult(seciossData) {
    // ......
}
```

#### 5.2 Client Certificate Authentication
``` swift
NSNotificationCenter.defaultCenter().addObserver(self, selector: "getAuthData:", name: "SeciossAuthNotification", object: nil)
var seciossData = SeciossData()
var seciossAuth = SeciossAuth()
seciossData.SECIOSS_FUNCTION = SeciossData.SECIOSS_FUNCTION.LOGIN
seciossData.SECIOSS_INIT_URL = "https://slink.secioss.com/user/"
seciossData.SECIOSS_BACK_URL = "https://slink.secioss.com/user/index.php"
seciossData.SECIOSS_CLIENTCERT_REQURL = "https://slink-cert.secioss.com/"
seciossData.SECIOSS_CLIENTCERT_FILEPATH = "user01.p12"
seciossData.SECIOSS_CLIENTCERT_PASSWORD = "password"
if seciossAuth.startLoginForResult(seciossData) {
    // ......
}
```

#### 5.3 OAuth 2.0 Authorization
``` swift
NSNotificationCenter.defaultCenter().addObserver(self, selector: "getAuthData:", name: "SeciossAuthNotification", object: nil)
var seciossData = SeciossData()
var seciossAuth = SeciossAuth()
seciossData.SECIOSS_FUNCTION = SeciossData.SECIOSS_FUNCTION.OAUTH2
seciossData.SECIOSS_OAUTH2_AUTHORIZE = "https://slink.secioss.com/service/oauth/authorize.php"
seciossData.SECIOSS_OAUTH2_TOKEN = "https://slink.secioss.com/service/oauth/token.php"
seciossData.SECIOSS_OAUTH2_RESOURCE = "https://slink.secioss.com/service/oauth/resource.php"
seciossData.SECIOSS_OAUTH2_CLIENT_ID = "28x426fK8e249Cz8WaBHGrQHvBxrLn5t"
seciossData.SECIOSS_OAUTH2_CLIENT_SECRET = "secret"
seciossData.SECIOSS_OAUTH2_REDIRECT_URI = "seciossauth://www/oauth2.html"
if seciossAuth.startLoginForResult(seciossData) {
    // ......
}
```

