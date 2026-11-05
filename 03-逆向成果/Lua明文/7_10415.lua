local MultiVersionData = {
    _mult_init = true
}

local cjson = require("cjson")
local Array = require("lockbox.util.array")
local Stream = require("lockbox.util.stream")
local CBCMode = require("lockbox.cipher.mode.cbc")
local Base64 = require("lockbox.util.base64")
local ZeroPadding = require("lockbox.padding.zero")
local AES256Cipher = require("lockbox.cipher.aes256")

local aes256key = "0CodEiBIMeE8MTjZ/gpAnm2xUJi0DG5WelYBn+mdm6U="    -- 测试： "TdC9aSnhWZRWV+Gg38BPFQVRAqxdvvS73GwzAU2YE9w=" 准生产/正式：  "0CodEiBIMeE8MTjZ/gpAnm2xUJi0DG5WelYBn+mdm6U="

local baseURL = "https://api.tj.996sdk.com"                         -- 测试： "https://api-test.tj.996sdk.com"  准生产/正式： "https://api.tj.996sdk.com"
local multiVersion = "/api/v1/app/getConfig"
local multiVersionKey   =  "Zlcg5DarX6n37RiNMuHWjaT3quzpoYdR"       -- 测试："027fa120e1c2e7a3d9e2258bd9069093"  准生产/正式： "Zlcg5DarX6n37RiNMuHWjaT3quzpoYdR"
local multiVerionAppID  =  "nbGzEntGO3QR"                           -- 测试 "GzE1B0ytgA2z"   准生产/正式： "nbGzEntGO3QR"

local function encodeBase64(source_str)
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local s64 = ''
    local str = source_str

    while #str > 0 do
        local bytes_num = 0
        local buf = 0

        for byte_cnt=1,3 do
            buf = (buf * 256)
            if #str > 0 then
                buf = buf + string.byte(str, 1, 1)
                str = string.sub(str, 2)
                bytes_num = bytes_num + 1
            end
        end

        for group_cnt=1,(bytes_num+1) do
            local b64char = math.fmod(math.floor(buf/262144), 64) + 1
            s64 = s64 .. string.sub(b64chars, b64char, b64char)
            buf = buf * 64
        end

        for fill_cnt=1,(3-bytes_num) do
            s64 = s64 .. '='
        end
    end

    return s64
end

local HTTPRequestPost = function(url, callback, data, header, responseType)
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("POST", url)

    if header then
        for k, v in pairs(header) do
            httpRequest:setRequestHeader(k, v)
        end
    end

    if callback then
        local function HttpResponseCB()
            local code = httpRequest.status
            local success = code >= 200 and code < 300
            local response = httpRequest.response

            -- release_print("Http Request Code:" .. tostring(code))
            -- release_print("收到消息数据：", response)
            callback(success, response, code)
        end
        if not header or not header["Content-type"] then
            httpRequest:setRequestHeader("Content-type", "application/json")
        end
        httpRequest:registerScriptHandler(HttpResponseCB)
    end

    httpRequest:send(data)
end

local calc996SDKSignSuffix = function(originData,secret_key,apiURL,dataStr)
    
    table.sort(originData, function(a, b)
        return a.key < b.key
    end)

    -- 拼接
    local origin = "POST" .. "\n"
    if apiURL and string.len(origin) > 0 then
        origin = origin .. apiURL .. "\n"
    end
    for i, v in ipairs(originData) do
        if v and v.key and v.value and string.len(v.key) > 0 and string.len(v.value) > 0 then
            origin = origin .. string.format("%s=%s", v.key, v.value)
            if i < #originData then
                origin = origin ..  "\n"
            end
        end
    end

    if dataStr and string.len(dataStr) > 0 then
        origin = origin .. "\n" .. dataStr
    end

    origin = origin .. "\n" .. "key=" .. secret_key

    local md5Str = get_str_MD5(origin)
    return md5Str
end

local calcAliYunSuffix = function(originData, url, md5Str, dateStr, secret_key)
    -- -- ascii排序
    table.sort(originData, function(a, b)
        return a.key < b.key
    end)

    -- 拼接
    local origin = ""
    for i, v in ipairs(originData) do
        if v and v.key and v.value and string.len(v.key) > 0 and string.len(v.value) > 0 then
            origin = origin .. string.format("%s:%s", v.key, v.value)
            origin = origin ..  "\n"
        end
    end
    origin = string.sub(origin, 1, string.len(origin)-1)

    -- URL编码
    local signStr = "POST\n" .. md5Str .. "\n" .. "application/x-protobuf\n" .. dateStr .. "\n" .. origin .. "\n".. url
    -- HMAC-SHA1
    local sign = sha1.hmac_binary(secret_key, signStr)
    -- Base64
    sign = encodeBase64(sign)
    return sign
end

local Aes256Decode = function (params)
    local decipher = CBCMode.Decipher()
            .setKey(Array.fromString(aes256key))
            .setBlockCipher(AES256Cipher)
            .setPadding(ZeroPadding);
    local decodeBytes = decipher
                        .init()
                        .update(Stream.fromString("gamesdk996start1"))
                        .update(Base64.toStream(params))
                        .finish()
                        .asBytes();  

    return string.match(Array.toString(decodeBytes), "%b{}")
end

function MultiVersionData:ctor()
    self._mult_channelid = nil
end

function MultiVersionData:initMultiVersCustomConfig()
    -- body
    local multiVersURL      = global.L_GameEnvManager:GetModlistCustomDataByKey("multiVersURL")
    local multiVersVersion      = global.L_GameEnvManager:GetModlistCustomDataByKey("multiVersVersion")

    if multiVersURL and string.len(multiVersURL) > 0 then
        baseURL =  multiVersURL
    end

    if multiVersVersion and tonumber(multiVersVersion) == 2 then
        aes256key = "TdC9aSnhWZRWV+Gg38BPFQVRAqxdvvS73GwzAU2YE9w="
        multiVersionKey = "027fa120e1c2e7a3d9e2258bd9069093"
        multiVerionAppID = "GzE1B0ytgA2z"
    end
end


function MultiVersionData:GetNewAppData(subMod)
    if self._mult_init then
        -- 读取配置
        self._mult_init = false
        self:initMultiVersCustomConfig()
    end

    if cc.PLATFORM_OS_WINDOWS == global.Platform then
        return false
    end

    if not subMod then
        return false
    end

    local gameLists = global.L_ModuleManager:GetAllGameID() or {}
    if #gameLists < 2 then
        return false
    end

    local platformID = subMod.GetPlatformID and subMod:GetPlatformID() or "" 
    if platformID == "" then
        return false
    end

    if self._mult_platformID == platformID then
        return false
    end 

    self._mult_platformID = platformID

    local gameid = subMod:GetOperID()
    if not gameid then
        return false
    end

    local requestBody = {
        game_id = tostring(gameid)
    }

    local requestHeader = {
        ["x-996sdk-algo"] = "MD5",
        ["x-996sdk-appid"] = multiVerionAppID,
        ["x-996sdk-nonce"] = string.format("%09d", math.random(1, 999999999)) .. string.format("%09d", math.random(1, 999999999)),
        ["x-996sdk-timestamp"] = "" .. os.time(),
    }

    -- 计算签名
    local signHeader = {}
    for k, v in pairs(requestHeader) do
        table.insert(signHeader, {key = k, value = v})
    end
    requestHeader["x-996sdk-sign"] = calc996SDKSignSuffix(signHeader, multiVersionKey, multiVersion, cjson.encode(requestBody))
    requestHeader["user-agent"] = "lua-http-client/1.0"
    
    -- post to server
    local function postCB(success, response, code)
        if not success then
            release_print("--------multi verSion http error: ", code)
            return
        end


        release_print("---------multi verSion response: ", response)
        -- 获取数据
        local json = cjson.decode(response)
        if not json then
            return
        end

        if json.code ~= 200 then
            return
        end

        if not json.data then
            return
        end

        local aesDecode = Aes256Decode(json.data)

        if not aesDecode or aesDecode == "" then
            release_print("--------multi verSion aesDecode is null")
            return
        end

        local cjsonData  = cjson.decode(aesDecode)

        if not cjsonData then
            return
        end

        local appid  = cjsonData.appid

        if not appid or string.len(appid) == 0 then
            release_print("----------multi verSion appid is null")
            return
        end

        local appkey = cjsonData.appkey

        if not appkey or string.len(appkey) == 0 then
            release_print("----------multi verSion appkey is null")
            return
        end

        local sdk_app_id = cjsonData.sdk_app_id

        if not sdk_app_id or string.len(sdk_app_id) == 0 then
            release_print("----------multi verSion sdk_app_id is null")
            return
        end

        local sdk_app_key = cjsonData.sdk_app_key

        if not sdk_app_key or string.len(sdk_app_key) == 0 then
            release_print("----------multi verSion sdk_app_key is null")
            return
        end

        local appsign = cjsonData.appsign
        if not appsign or string.len(appsign) == 0 then
            release_print("----------multi verSion appsign is null")
            return
        end
        
        local channelid     = global.L_GameEnvManager:GetChannelID() or ""

        -- 通知java
        local jsonData = {
            appId           = sdk_app_id,
            appKey          = sdk_app_key,
            loginAppId      = appid,
            loginSignKey    = appkey,
            loginChannel    = appid,
            sdkSign         = appsign,
            gameId          = gameid,
        }
        global.L_NativeBridgeManager:GN_SDKinit(jsonData)
    end
    local postURL = baseURL .. multiVersion
    local postData = cjson.encode(requestBody)
    local postHeader = requestHeader
    HTTPRequestPost(postURL, postCB, postData, postHeader)
    release_print("--------------- post URL: ", postURL)
    release_print("--------------- post body: ", postData)
    release_print("--------------- post header: ", cjson.encode(postHeader))
    release_print("---------------")
end

return MultiVersionData