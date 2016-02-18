/**
 * The JavaScript Class of Slink Mobile SDK
 * This class is designated for the process of OAuth and OpenID Connect by AJAX
 * 
 * @author Shuu Shisen <shuu.shisen@secioss.co.jp>
 * @copyright 2016 SECIOSS, INC.
 * @see http://www.secioss.co.jp
 */

var resource_method = 'header';
function getResources() {
    if (!resource) {
        doFinish('invalid_params');
    }
    var headerContent = {};
    var postContent = {};

    if (resource_method == 'post') {
        resource_method = 'header';
        postContent = '&access_token=' + encodeURIComponent(access_token);
    }
    else {
        resource_method = 'post';
        headerContent = {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization': token_type + ' ' + access_token,
        };
    }
    getWebContents(resource, headerContent, postContent, 'resources');
}

function getTokens(authorization_code, refresh_token) {
    if (authorization_code) {
        var postContent = '&grant_type=authorization_code';
        postContent += '&code=' + encodeURIComponent(authorization_code);
        postContent += '&redirect_uri=' + encodeURIComponent(redirect_uri);
    }
    else if (refresh_token) {
        var postContent = '&grant_type=refresh_token';
        postContent += '&refresh_token=' + encodeURIComponent(refresh_token);
    }
    postContent += '&client_id=' + encodeURIComponent(client_id);
    postContent += '&client_secret=' + encodeURIComponent(client_secret);
    getWebContents(token, '', postContent, 'tokens');
}

function parseResources(jsonObject) {
    if (jsonObject == null) {
        doFinish('error_resource');
    }
    doFinish(JSON.stringify(jsonObject));
}

function parseTokens(jsonObject) {
    if (jsonObject == null) {
        doFinish('error_token');
    }

    if (jsonObject.token_type && jsonObject.access_token) {
        token_type = jsonObject.token_type;
        access_token = jsonObject.access_token;
        if (_orign == 'oauth2') {
            localStorage.setItem('SECIOSS_OAUTH2_TOKEN_TYPE', token_type);
            localStorage.setItem('SECIOSS_OAUTH2_ACCESS_TOKEN', access_token);
        }
        else if (_orign == 'oidc') {
            localStorage.setItem('SECIOSS_OIDC_TOKEN_TYPE', token_type);
            localStorage.setItem('SECIOSS_OIDC_ACCESS_TOKEN', access_token);
        }
        if (finish == 'TOKEN') {
            doFinish(JSON.stringify(jsonObject));
        }
    }
    else {
        doFinish('error_token');
    }

    if (jsonObject.refresh_token) {
        refresh_token = jsonObject.refresh_token;
        if (_orign == 'oauth2') {
            localStorage.setItem('SECIOSS_OAUTH2_REFRESH_TOKEN', refresh_token);
        }
        else if (_orign == 'oidc') {
            localStorage.setItem('SECIOSS_OIDC_REFRESH_TOKEN', refresh_token);
        }
    }

    if (jsonObject.id_token) {
        parseIdToken(jsonObject.id_token);
        if (finish == 'IDTOKEN') {
            doFinish(_beans['id_token_payload']);
        }
    }

    getResources();
}

function parseQuery() {
    var query = window.location.search.substring(1);
    if (query) {
        var regex = /([^&=]+)=([^&]*)/g, matches;
        while (matches = regex.exec(query)) {
            var tmpkey = decodeURIComponent(matches[1]);
            var tmpval = decodeURIComponent(matches[2].replace(/\+/g,  ' '));
            _beans[tmpkey] = tmpval;
        }

        // verify state
        if (!_beans['state'] || _beans['state'] != _state) {
            doFinish('invalid_state');
        }

        if (_beans['error']) {
            doFinish(_beans['error']);
        }

        if (_beans['code']) {
            getTokens(_beans['code']);
        }
    }
}

function parseJwks(jsonObject) {
    if (jsonObject == null) {
        doFinish('jwks_error');
    }
    json_web_keys = jsonObject;
    localStorage.setItem('SECIOSS_OIDC_JSON_WEB_KEYS', JSON.stringify(jsonObject));
    init();
}

function parseFragment() {
    var fragment = window.location.hash.substring(1);
    if (fragment) {
        var regex = /([^&=]+)=([^&]*)/g, matches;
        while (matches = regex.exec(fragment)) {
            var tmpkey = decodeURIComponent(matches[1]);
            var tmpval = decodeURIComponent(matches[2].replace(/\+/g,  ' '));
            _beans[tmpkey] = tmpval;
        }

        // verify state
        if (!_beans['state'] || _beans['state'] != _state) {
            doFinish('invalid_state');
        }

        if (_beans['error']) {
            doFinish(_beans['error']);
        }

        if (_beans['id_token']) {
            parseIdToken(_beans['id_token']);
            if (finish == 'IDTOKEN') {
                doFinish(_beans['id_token_payload']);
            }
        }
        if (_beans['token_type'] && _beans['access_token']) {
            var at_hash = _beans['at_hash'];
            var alg = _beans['alg'];
            if (!at_hash) {
                doFinish('invalid_at_hash');
            }
            if (verifyAtHash(at_hash, _beans['access_token'], alg)) {
                if (finish == 'USERINFO' || finish == 'CLAIMS') {
                    token_type = _beans['token_type'];
                    access_token = _beans['access_token'];
                    if (_orign == 'oauth2') {
                        localStorage.setItem('SECIOSS_OAUTH2_TOKEN_TYPE', token_type);
                        localStorage.setItem('SECIOSS_OAUTH2_ACCESS_TOKEN', access_token);
                    }
                    else if (_orign == 'oidc') {
                        localStorage.setItem('SECIOSS_OIDC_TOKEN_TYPE', token_type);
                        localStorage.setItem('SECIOSS_OIDC_ACCESS_TOKEN', access_token);
                    }

                    getResources();
                }
                else {
                    doFinish(_beans['sub']);
                }
            }
            else {
                doFinish('invalid_token');
            }
        }
    }
}

function parseIdToken(id_token) {
    var jwt = id_token.split('.');
    var uHeaders = b64utos(jwt[0]);
    var uPayload = b64utos(jwt[1]);
    var pHeaders = KJUR.jws.JWS.readSafeJSONString(uHeaders);
    var pPayload = KJUR.jws.JWS.readSafeJSONString(uPayload);
    var sHeaders = JSON.stringify(pHeaders, null, '  ');
    var sPayload = JSON.stringify(pPayload, null, '  ');

    // verify nonce if presents
    var nonce = pPayload.nonce;
    if (nonce && nonce != _nonce) {
        doFinish('invalid_nonce');
    }
    // nonce is REQUIRED in implicit flow
    if (!nonce && (response_type == 'id_token token' || response_type == 'id_token')) {
        doFinish('invalid_nonce');
    }

    _beans['id_token_jose'] = sHeaders;
    _beans['id_token_payload'] = sPayload;
    _beans['sub'] = pPayload.sub;
    _beans['alg'] = pHeaders.alg;            // for verify at_hash
    _beans['at_hash'] = pPayload.at_hash;    // for verify at_hash

    // verify signature
    verifySignature(id_token, pHeaders.kid, pHeaders.alg);
}

function verifySignature(sJWT, kid, alg) {
    var isValid = false;
    var error;
    if (json_web_keys && json_web_keys['keys']) {
        for (i = 0; i < json_web_keys['keys'].length; i++) {
            var kidI = json_web_keys['keys'][i]['kid'];
            var algI = json_web_keys['keys'][i]['alg'];
            if (kidI == kid && (!algI || algI == alg)) {
                var keyI = KEYUTIL.getKey(json_web_keys['keys'][i]);
                try {
                    var acceptField = {};
                    acceptField.alg = new Array(alg);
                    acceptField.iss = new Array(issuer);
                    acceptField.aud = new Array(client_id);
                    isValid = KJUR.jws.JWS.verifyJWT(sJWT, keyI, acceptField);
                    break;
                } catch (ex) {
                    error = ex;
                }
            }
        }
        if (!isValid) {
            localStorage.removeItem('SECIOSS_OIDC_JSON_WEB_KEYS');
            error = error ? error : 'invalid_sig'
            doFinish(error);
        }
    }
    else {
        doFinish('invalid_jwks');
    }
}

function verifyAtHash(at_hash, access_token, alg) {
    var isValid = false;
    var bit = alg.substring(2);
    if (bit == 256) {
        var hash1 = CryptoJS.SHA256(access_token).words;
        var hash2 = new CryptoJS.lib.WordArray.init(hash1, bit / 16).toString(CryptoJS.enc.Base64);
        var hash3 = hash2.replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');
    }
    if (at_hash && hash3 && at_hash == hash3) {
        isValid = true;
    }
    return isValid;
}

/**
 * When cross-domain with jsonp, only GET is allowed.
 * When cross-domain with header, only GET is allowed.
 */
function getWebContents(url, headerContent, postContent, processType) {
    $('#resultdiv').html('retrieving ' + processType + '...');
    $.ajax({
        url: url,
        method: 'POST',
        timeout: 10000,
        data: postContent,
        headers: headerContent,
        success: function(data, status, xhr) {successAjax(data, processType);},
        error: function(xhr, status, error) {errorAjax(xhr, status, error, processType);},
    });
}

function successAjax(data, processType) {
    if (processType == 'jwks') {
        parseJwks(data);
    }
    else if (processType == 'tokens') {
        parseTokens(data);
    }
    else if (processType == 'resources') {
        parseResources(data);
    }
}

function errorAjax(xhr, status, error, processType) {
    _retry++;
    if (_retry > _limit) {
        doFinish(xhr.responseText);
    }
    else if (processType == 'jwks') {
        getWebContents(jwks_uri, '', '', 'jwks');
    }
    else if (processType == 'tokens') {
        if (_orign == 'oauth2') {
            localStorage.removeItem('SECIOSS_OAUTH2_REFRESH_TOKEN');
            _point = 'init';
        }
        else if (_orign == 'oidc') {
            localStorage.removeItem('SECIOSS_OIDC_REFRESH_TOKEN');
            _point = 'init';
        }
        init();
    }
    else if (processType == 'resources') {
        if (_orign == 'oauth2') {
            localStorage.removeItem('SECIOSS_OAUTH2_TOKEN_TYPE');
            localStorage.removeItem('SECIOSS_OAUTH2_ACCESS_TOKEN');
            _point = refresh_token ? 'token' : 'init';
        }
        else if (_orign == 'oidc') {
            localStorage.removeItem('SECIOSS_OIDC_TOKEN_TYPE');
            localStorage.removeItem('SECIOSS_OIDC_ACCESS_TOKEN');
            _point = refresh_token ? 'token' : 'init';
        }
        init();
    }
}

function init() {
    if (_point == 'init') {
        sessionStorage.setItem('_point', 'authorize');
        url = authorize + '?client_id=' + client_id + '&redirect_uri=' + redirect_uri + '&scope=' + scope;
        url += '&response_type=' + response_type + '&state=' + _state + '&nonce=' + _nonce;
        window.location = url;
    }
    else if (_point == 'authorize') {
        if (response_type == 'id_token token' || response_type == 'id_token' || response_type == 'token') {
            parseFragment();
        }
        else if (response_type == 'code') {
            parseQuery();
        }
    }
    else if (_point == 'token') {
        getTokens('', refresh_token);
    }
    else if (_point == 'resource') {
        getResources();
    }
}

function doFinish(rs) {
    if (!rs) {
        rs = '';
    }
    if (window.SeciossJSI) {
        window.SeciossJSI.processResponse(rs);
    }
    else if (window.webkit.messageHandlers.SeciossJSI) {
        window.webkit.messageHandlers.SeciossJSI.postMessage(rs);
    }
    else {
        //$('#resultdiv').html(rs);
        window.location = 'seciossauth://result/?' + encodeURIComponent(rs);
    }
}

function randString(len) {
    var text = '';
    var possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    for (var i = 0; i < len; i++) {
        text += possible.charAt(Math.floor(Math.random() * possible.length));
    }
    return text;
}


// =============================================================================
// =================================== DEBUG ===================================
// =============================================================================

function getCookie(c_name) {
    if (document.cookie.length>0) {
        c_start = document.cookie.indexOf(c_name + '=');
        if (c_start != -1) {
            c_start = c_start + c_name.length + 1;
            c_end = document.cookie.indexOf(';', c_start);
            if (c_end == -1) {
                c_end = document.cookie.length;
            }
            return unescape(document.cookie.substring(c_start,c_end));
        }
    }
    return '';
}

function setCookie(c_name, value, expiredays) {
    var exdate = new Date();
    exdate.setDate(exdate.getDate() + expiredays);
    document.cookie = c_name + '=' + escape(value) +
        ((expiredays==null) ? '' : ';expires=' + exdate.toGMTString());
}

function dump(obj) {
    var s = '';
    for (prop in obj) {
        if (prop == 'channel') continue;
        try {
            s += '[' + prop + '] ' + obj[prop] + '<br>\n';
        }
        catch (e) {
            s += '<br>dump exception: ' + e;
            continue;
        }
    }
    return s;
}
