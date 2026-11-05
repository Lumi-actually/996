local DataRePort = class("DataRePort")

local cjson = require("cjson")
local sha1 = require( "sha1/init" )

local slspb = nil
if LuaBridgeCtl:Inst() and LuaBridgeCtl:Inst():GetModulesSwitch( 20 ) == 1 then
    slspb = require( "slslogpb" )
end

local baseURL           = "https://api.tj.996sdk.com"            -- init的地址 只针对PC --"测试：https://mapi-test.tj.996sdk.com"
local initAPI           = "/api/v1/app/sdkRule"
local ststokenAPI       = "/api/v1/app/stsToken"
local aliyunLogAPI      = "/logstores/direct-log/shards/lb"       -- aliyun上报地址， 数据是protobuf

local appid             = nil
local secretKey         = nil
local channelid         = nil

local pbFileName        = ""

--------------------------
local ReportModlistURL      = "https://log.tj.996sdk.com"        -- 区服列表异常上报地址
local ReportModlistAPI      = "/v1/apm"
local ReportModlistAPPID    = "nbGzEntGO3QR"
local ReportModlistAPPKey   = "Zlcg5DarX6n37RiNMuHWjaT3quzpoYdR"


--检测modeInfoURL合法性
local mode_info_check       = "https://user-sdkv2.dhsf.xqhuyu.com"  -- "https://user-sdkv2.dhsf.xqhuyu.com" --pre  "https://user-sdkv2-pre.dhsf.xqhuyu.com"  --test  "https://user-sdkv2-test.ppp996.hqyxkj.cn"
local mode_info_interface   = "/api/user/checkHost"

local tableMerge = function(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

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

local simpleEncryKey = {50,30,20,43}
local stringToByteSimpleEncry = function(str)
    local bytes={}
    for i=1,string.len(str) do
        table.insert(bytes,string.byte(string.sub(str,i,i)))
    end

    local newBytes = {}
    local i = 1
    for k,v in ipairs(bytes) do
        newBytes[k] = v+simpleEncryKey[i]
        if i > #simpleEncryKey then
            i = 1
        end
    end
    return cjson.encode(newBytes)
end

local stringToByteSimpleDecry = function(byteStr)
    local bytes = cjson.decode(byteStr)
    local newBytes = {}
    local i = 1
    local str = ""
    for k,v in ipairs(bytes) do
        newBytes[k] = v-simpleEncryKey[i]
        if i > #simpleEncryKey then
            i = 1
        end
    end
    local str = string.char(unpack(newBytes))
    return str
end

local GetMacID = function()
    local userData   = UserData:new("data_report")
    local deviceID  = userData:getStringForKey( "id" )
    local newDeviceID = getDeviceID and getDeviceID() or nil
    if not deviceID or deviceID == "" then
        deviceID = newDeviceID or (getMac and getMac()) or nil
        if not deviceID or deviceID == "" then
            local uuid = function()
                local seed={'e','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
                local tb={}
                for i=1,32 do
                    table.insert(tb,seed[math.random(1,16)])
                end
                local sid=table.concat(tb)
                return string.format('%s-%s-%s-%s-%s',
                    string.sub(sid,1,8),
                    string.sub(sid,9,12),
                    string.sub(sid,13,16),
                    string.sub(sid,17,20),
                    string.sub(sid,21,32)
                )
            end
            deviceID = uuid()
        end
        userData:setStringForKey( "id", stringToByteSimpleEncry( deviceID ) )
    else
        deviceID = stringToByteSimpleDecry(deviceID)
    end

    -- 重新保存  使用最新的
    if newDeviceID and deviceID and newDeviceID ~= deviceID then
        deviceID = newDeviceID
        userData:setStringForKey( "id", stringToByteSimpleEncry( deviceID ) )
    end

    return deviceID
end

-- 获取系统版本
local function getWindownVersion()
    if getWindowsVersion then
        local windowVersion = getWindowsVersion()
        local versions = string.split(windowVersion,"_")
        local majorVer = tonumber(versions[1])
        local minorVer = tonumber(versions[2])
        local buildNum = tonumber(versions[3])
        if majorVer >= 10 then
            if buildNum >= 22000 then
                return "Win11"
            end
            return "Win10"
        elseif majorVer >= 6 then
            if minorVer >= 3 then
                return "Win8.1"
            elseif minorVer >= 2 then
                return "Win8"
            elseif minorVer >= 1 then
                return "Win7"
            end
        elseif majorVer >= 5 then            
            return "WinXP"
        end
    end
    return "windows"
end

function DataRePort:ctor()
    self._reportURL = nil                                       --上报地址  通过aliyun获取
    self._isCanRePort = false                                   --是否能上报
    self._infoData     = {}                                     --数据上报的固定数据
    self._stsToken     = {}                                     --ststoken数据
    self._initFinish   = false
    self._LuaBridgeCtl = nil
    self._token_timeout = -1                                    --token失效时间
    self._isCubeReport  = false                                 --是否c++上报
end

function DataRePort:Init()
    if self._initFinish then
        return
    end
    self._initFinish = true

    local isMac = global.L_GameEnvManager:GetEnvDataByKey("platform") == "mac"
    if not (cc.PLATFORM_OS_WINDOWS == global.Platform or isMac) then
        return
    end

    appid = global.L_GameEnvManager:GetEnvDataByKey("sdkAppid")
    if not appid then
        return
    end

    secretKey = global.L_GameEnvManager:GetEnvDataByKey("sdkAppkey")
    if not secretKey then
        return
    end

    channelid = global.L_GameEnvManager:GetEnvDataByKey("sdkChannel")
    if not channelid then
        return
    end

    if not self._LuaBridgeCtl then
        self._LuaBridgeCtl = LuaBridgeCtl:Inst()
    end

    if self._LuaBridgeCtl and self._LuaBridgeCtl:GetModulesSwitch(22) == 1 then
        self._isCubeReport = true
    end

    if self._isCubeReport then
        return
    end

    if not self._LuaBridgeCtl or self._LuaBridgeCtl:GetModulesSwitch( 17 ) ~= 1 then
        appid = nil
        return
    end

    pbFileName = string.format("%s%s",cc.FileUtils:getInstance():getDefaultResourceRootPath(),"cache/mod_launcher/stab/scripts/pb_message/DataRePort.pb")
    
    if not cc.FileUtils:getInstance():isFileExist(pbFileName) then
        pbFileName = string.format("%s%s",cc.FileUtils:getInstance():getDefaultResourceRootPath(),"mod_launcher/stab/scripts/pb_message/DataRePort.pb")
    end

    local isMac = global.L_GameEnvManager:GetEnvDataByKey("platform") == "mac"
    local type = isMac and "mac" or "pc"
    local macID = isMac and (global.L_GameEnvManager:GetEnvDataByKey("macAddress") or "") or (GetMacID() or "")
    local width = isMac and (global.L_GameEnvManager:GetEnvDataByKey("displayWidth") or 1136) or (getWindowWidth and getWindowWidth() or 1136)
    local height = isMac and (global.L_GameEnvManager:GetEnvDataByKey("displayHeight") or 1136) or (getWindowHeight and getWindowHeight() or 640)
    local model = isMac and (global.L_GameEnvManager:GetEnvDataByKey("model") or "") or "pc"
    local osVersion = isMac and (global.L_GameEnvManager:GetEnvDataByKey("osVersion") or "") or (getWindownVersion() or "")
    self._infoData = {
        ["device"] = {
            type = type,
            id = macID,
            width = width, 
            height = height,
            model = model,
            os = osVersion
        },
        appid = appid,
        channel = channelid or "",
        sdk_ver = "1.0.0",
        app_ver = isMac and (global.L_GameEnvManager:GetEnvDataByKey("app_ver") or "") or (global.L_GameEnvManager:GetAPKVersionName() or ""),
        net_type = "UNKNOWN",
    }
    self.isDeviceLoginFinish = false
end

-- 
function DataRePort:UpDeviceLogin(subMod)
    if not appid or not secretKey or not channelid then
        return
    end

    self:UpdateSelectModule(subMod)

    if self.isDeviceLoginFinish then
        return
    end
    self.isDeviceLoginFinish = true

    -- 初始化 c++ 上报
    if self._isCubeReport then
        local isTest = false
        local data = {
            appid = appid,
            secretKey = secretKey,
            channel = channelid,
            boxid = self._infoData.boxid,
            isDev = isTest
        }
        global.L_NativeBridgeManager:GN_InitClientCube(data)
        return
    end

    -- init sdk
    local data = {
        ["appid"] = appid
    }
    local jsonStr = cjson.encode(data)

    local timeMS    = os.time()
    local nonce     = string.format("%s%09d", timeMS, math.random(1, 999999999))

    local originData = {
        {key="x-996sdk-appid", value = appid},
        {key="x-996sdk-timestamp", value = ""..timeMS},
        {key="x-996sdk-nonce", value = nonce},
        {key="x-996sdk-algo", value = "MD5"},
    }

    local headerData = {
        ["x-996sdk-appid"] = appid,
        ["x-996sdk-timestamp"] = ""..timeMS,
        ["x-996sdk-nonce"] = nonce,
        ["x-996sdk-algo"] = "MD5",
        ["x-996sdk-sign"] = calc996SDKSignSuffix(originData,secretKey,initAPI,jsonStr)
    }

    -- 上报地址走配置
    if subMod then
        local modGameEnv    = subMod:GetGameEnv()
        local reportDataURL = modGameEnv:GetCustomDataByKey("reportDataURL")
        if reportDataURL and string.len(reportDataURL) > 0 then
            baseURL = reportDataURL
        end
    end

    HTTPRequestPost(baseURL..initAPI, function(success, response, code)
        local json = cjson.decode(response)
        if json.code == 200 then
            self._stsToken = json.data and json.data.sts_token or {}
            if self._stsToken.project and self._stsToken.project ~= "" and self._stsToken.endpoint and self._stsToken.endpoint ~= "" then
                self._reportURL = self._stsToken.project .. "." .. self._stsToken.endpoint
                local pattern="(%d+)-(%d+)-(%d+)(%u)(%d+):(%d+):(%d+)(%u)"
                local year,month,day,T,hour,min,sec,Z=self._stsToken.Expiration:match(pattern)
                self._token_timeout = os.time({day=day*1, month=month*1, year=year*1, hour=hour*1, min=min*1, sec=sec*1})
                -- app 启动
                local timeStamp = os.time()
                local dataParam = {
                    event={time=timeStamp,name = "device_login",type = "track"}
                }
                self:SendRePortData(dataParam)
            end
        end
    end,jsonStr,headerData)
end

-- c++上报传过来的设备数据
function DataRePort:SetDeviceInfo( data )
    local boxid = self._infoData and self._infoData.boxid
    if data and type(data) == "table" and next(data) then
        data.boxid = boxid
    else
        data = {}
    end
    self._infoData = data
end


-- 读取设备数据
function DataRePort:GetDeviceInfo()
    return self._infoData or {}
end

-- 打开聚合
function DataRePort:OpenJuheMode()
    -- body
    local juheRoleUrl   = global.L_GameEnvManager:GetEnvDataByKey("juheSdkRoleUrl")
    local juhePayURL    = global.L_GameEnvManager:GetEnvDataByKey("juheSdkPayUrl")
    local jsonData = {
        juheRoleUrl = juheRoleUrl,
        juhePayURL = juhePayURL
    }
    global.L_NativeBridgeManager:GN_OpenJuheMode(jsonData)
end

-- 发送登录事件
function DataRePort:SendLoginEvent( data )
    local dataParam = {
        event={time=timeStamp,name = "device_login",type = "track"}
    }
    self:SendRePortData(dataParam)
end

function DataRePort:UpdateAliYunSTSToken( callbackFunc,callbackData )
    local initSDKApi = "/api/v1/app/sdkRule"
    local data = {
        ["module"] = "apm",   
    }
    tableMerge(data,self._infoData or {})

    local jsonStr = cjson.encode(data)
    local timeMS    = os.time()
    local nonce     = string.format("%s%09d", timeMS, math.random(1, 999999999))

    local originData = {
        {key="x-996sdk-appid", value = appid},
        {key="x-996sdk-timestamp", value = ""..timeMS},
        {key="x-996sdk-nonce", value = nonce},
        {key="x-996sdk-algo", value = "MD5"},
    }

    local headerData = {
        ["x-996sdk-appid"] = appid,
        ["x-996sdk-timestamp"] = ""..timeMS,
        ["x-996sdk-nonce"] = nonce,
        ["x-996sdk-algo"] = "MD5",
        ["x-996sdk-sign"] = calc996SDKSignSuffix(originData,secretKey,ststokenAPI,jsonStr)
    }

    self._token_timeout = -1
    HTTPRequestPost(baseURL..ststokenAPI, function(success, response, code)
        local json = cjson.decode( response )
        if json.code == 200 then
            local jsonData = json.data or {}
            self._stsToken = jsonData or {}
            if jsonData.project and jsonData.project ~= "" and jsonData.endpoint and jsonData.endpoint ~= "" then
                self._reportURL = jsonData.project .. "." .. jsonData.endpoint
                local pattern="(%d+)-(%d+)-(%d+)(%u)(%d+):(%d+):(%d+)(%u)"
                local year,month,day,T,hour,min,sec,Z=self._stsToken.Expiration:match(pattern)
                self._token_timeout = os.time({day=day*1, month=month*1, year=year*1, hour=hour*1, min=min*1, sec=sec*1})
                if callbackFunc then
                    callbackFunc(callbackData)
                end
            end
        end
    end,jsonStr,headerData)
end

function DataRePort:GetLogGroupPortData(data,timeStamp)
    local LogGroup = nil

    if self._LuaBridgeCtl and self._LuaBridgeCtl:GetModulesSwitch( 20 ) == 1 then
        if data and type(data) == "table" and next(data) then
            -- info data
            tableMerge(data, self._infoData or {})
            LogGroup = {LogTags={}, Topic = "", Source = "",Logs={}}
            local Log = {Time = timeStamp or os.time(), Contents = {}}
            for k,v in pairs( data ) do
                local vStr = ""
                if type(v) == "table" then
                    vStr = cjson.encode(v)
                else
                    vStr = v
                end

                table.insert(Log.Contents, {
                    Key = tostring(k),
                    Value = vStr
                })
            end
            LogGroup.Logs[1] = Log
        end
    else

        if data and type(data) == "table" and next(data) then
            -- info data
            tableMerge(data, self._infoData or {})
            LogGroup = {Logs={{Time = timeStamp or os.time(), Contents = {}}},LogTags={}}
            for k,v in pairs( data ) do
                local vStr = ""
                if type(v) == "table" then
                    vStr = cjson.encode(v)
                else
                    vStr = v
                end
                table.insert(LogGroup.Logs[1].Contents,{
                    Key = tostring(k), Value = vStr
                })
            end
        end
    end
    return LogGroup
end

function DataRePort:SendRePortData( data )
    -- 试玩不上报任何数据
    local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
    if shiwan and tonumber(shiwan) == 1 then
        return
    end

    local isMac = global.L_GameEnvManager:GetEnvDataByKey("platform") == "mac"
    if not (cc.PLATFORM_OS_WINDOWS == global.Platform or isMac) then
        if data and data.event then
            data.game_event = data.event
            data.event = nil
        end
        if data and data.properities then
            data.game_properities = data.properities
            data.properities = nil
        end
        global.L_NativeBridgeManager:GN_customRePortData(data)
        return
    end

    -- c++ 上报
    if self._isCubeReport then
        self:SendCubeRePortData( data )
        return
    end

    if self._token_timeout < 0 then
        return true
    end

    local function getTimeUTC() --UTC时间
        local utcTime = os.time(os.date("!*t", now))
        return utcTime
    end

    local psSend = function( sData )
        local LogGroup = self:GetLogGroupPortData( sData )
        self:RePortDataContent(LogGroup)
    end

    if getTimeUTC() >= self._token_timeout then
        self:UpdateAliYunSTSToken(psSend,data)
        return
    end
    psSend(data)
end

-- 上报  c++接口
function DataRePort:SendCubeRePortData( data )
    local eventName  = data and data.event and data.event.name or ""
    local uid        = data and data.user and data.user.id or ""
    local properties = data and data.properities or {}
    global.L_NativeBridgeManager:GN_SendLogGroupCube({
        event = eventName,
        user = uid,
        properties = cjson.encode(properties)
    })
end

function DataRePort:RePortDataContent(dataContent,pbMessageName,pbName )
    if not self._reportURL then --上报地址没有
        return
    end

    if type(dataContent) ~= "table" or not next(dataContent) then
        return
    end

    local pbContent     = nil
    if self._LuaBridgeCtl and self._LuaBridgeCtl:GetModulesSwitch( 20 ) == 1 then
        local encodeLogPb   = function(data)
            local ok, resultOrErrMsg = pcall(function()
                return slspb.GetLogGroupPBBytes(data)
            end)
    
            if not ok then
                release_print(resultOrErrMsg);
                return nil
            end
            return resultOrErrMsg
        end    
        pbContent     = encodeLogPb(dataContent)
    else
        pbName = pbName or pbFileName
        if not global.L_ProtoBuf:registerPB(pbName) then
            return
        end
        pbContent = global.L_ProtoBuf:encodePB(pbMessageName or "LogGroup", dataContent)
    end

    if not pbContent then
        return
    end

    local pbSize        = string.len(pbContent)

    local originData = {
        {key="x-log-apiversion", value = "0.6.0"},
        {key="x-log-bodyrawsize", value = pbSize},
        {key="x-log-signaturemethod", value = "hmac-sha1"},
        {key="x-acs-security-token", value = self._stsToken.SecurityToken or ""},
    }

    local md5Str = string.upper(get_str_MD5(pbContent))
    local dateStr = os.date("!%a, %d %b %Y %X GMT", os.time())
    local signStrt = calcAliYunSuffix(originData, aliyunLogAPI, md5Str, dateStr, self._stsToken.AccessKeySecret)
    local headerData = {
        ["Content-Length"] = pbSize,
        ["Content-type"] = "application/x-protobuf",
        ["x-log-bodyrawsize"] = pbSize,
        ["Content-MD5"] = md5Str,
        ["Date"] = dateStr,
        ["x-log-apiversion"] = "0.6.0",
        ["x-log-signaturemethod"] = "hmac-sha1",
        ["Authorization"] = "LOG " .. (self._stsToken.AccessKeyId or "") .. ":" .. signStrt,
        ["x-acs-security-token"] = self._stsToken.SecurityToken or "",
    }

    -- 上报
    local url = "https://" .. self._reportURL .. aliyunLogAPI
    HTTPRequestPost(url,function(success, response, code)
        if success then
            release_print("***********============success")
        else
            release_print("***********============fail")
        end
    end,pbContent,headerData)
end

-- 上报区服列表访问失败信息至服务器
function DataRePort:ReportErrorModlistURL(errorType, errorCode, errorMsg, errorURL, httpCode)
    local deviceT = {
        [cc.PLATFORM_OS_WINDOWS] = "pc",
        [cc.PLATFORM_OS_ANDROID] = "android",
        [cc.PLATFORM_OS_IPHONE] = "ios",
        [cc.PLATFORM_OS_IPAD] = "ios",
        [cc.PLATFORM_OS_HARMONY] = "ohos",
    }
    -- -1:未识别 0:wifi 1:2g 2:3g 3:4g
    local netTypeT = {
        [-1] = "UNKNOWN",
        [0] = "WIFI",
        [1] = "2G",
        [2] = "3G",
        [3] = "4G",
    }
    local requestBody = {
        ["device"] = 
        {
            type    = deviceT[global.Platform] or "pc",
            width   = global.Director:getVisibleSize().width,
            height  = global.Director:getVisibleSize().height,
            model   = "empty",
            os      = "empty",
            net_type= netTypeT[global.L_GameEnvManager:GetNetType()] or "UNKNOWN",
        },
        appid       = ReportModlistAPPID,
        channel     = global.L_GameEnvManager:GetEnvDataByKey("sdkChannel") or "",
        sdk_ver     = "1.0.0",
        app_ver     = global.L_GameEnvManager:GetAPKVersionName() or "",

        ["event_type"] = "http_request",
        ["event_content"] = 
        {
            ["extend"] = cjson.encode({
                ["content"] = errorType,
                ["code"] = errorCode,
                ["msg"] = errorMsg,
            }),
            ["url"] = errorURL,
            ["status_code"] = httpCode,
        }
    }

    local requestHeader = {
        ["x-996sdk-algo"] = "MD5",
        ["x-996sdk-appid"] = ReportModlistAPPID,
        ["x-996sdk-nonce"] = string.format("%09d", math.random(1, 999999999)) .. string.format("%09d", math.random(1, 999999999)),
        ["x-996sdk-timestamp"] = "" .. os.time(),
    }

    -- 计算签名
    local signHeader = {}
    for k, v in pairs(requestHeader) do
        table.insert(signHeader, {key = k, value = v})
    end
    requestHeader["x-996sdk-sign"] = calc996SDKSignSuffix(signHeader, ReportModlistAPPKey, ReportModlistAPI, cjson.encode(requestBody))
    requestHeader["user-agent"] = "lua-http-client/1.0"
    
    -- post to server
    local function postCB(success, response, code)
        print("ReportErrorModlistURL", success, response, code)
    end
    local postURL = ReportModlistURL .. ReportModlistAPI
    local postData = cjson.encode(requestBody)
    local postHeader = requestHeader
    HTTPRequestPost(postURL, postCB, postData, postHeader)
    print("--------------- post URL")
    print(postURL)
    print(postData)
    print(cjson.encode(postHeader))
    print("---------------")
end

function DataRePort:RequestModeInfoCheck(subMod)
    if global.isDebugMode or global.isGMMode then
        return nil
    end

    if not subMod then
        return nil
    end

    local modGameEnv    = subMod:GetGameEnv()
    local ModeInfoCheckDoamin = modGameEnv:GetCustomDataByKey("ModeInfoCheckDoamin")
    if ModeInfoCheckDoamin and string.len(ModeInfoCheckDoamin) > 0 then
        mode_info_check = ModeInfoCheckDoamin
    end

    local checkURLs = global.L_GameEnvManager:GetEnvDataByKey("modlist") or ""
    local planBURL = global.L_GameEnvManager:GetEnvDataByKey("modlistPlanB")
    if planBURL and string.len(planBURL) > 0 then
        checkURLs = checkURLs .. "," .. planBURL
    end

    local url = string.format("%s%s?type=%s&host=%s", mode_info_check, mode_info_interface, "c2", checkURLs)

    HTTPRequest(url, function( success, response )
        -- body
        if not success then
            PerformWithDelayGlobal(function()
                self:RequestModeInfoCheck(subMod)
            end, 5 * 60)
        end

        success = true
        if response and string.len(response) > 0 then
            local jsonData = cjson.decode(response)
            if jsonData and jsonData.data == 0 then
                success = false
            end
        end

        releasePrint("======CHECK: ", response or "")

        if not success then
            local function callback(bType, custom)
                if bType == 1 then
                    if global.isWindows then
                        global.Director:endToLua()
                    else
                        global.L_NativeBridgeManager:GN_accountLogout()
                        global.L_GameEnvManager:RestartGame()
                    end
                end
            end
            local data = {}
            data.str = "渠道获取失败，请联系客服"
            data.btnDesc = { "退出" }
            data.callback = callback
            global.L_CommonTipsManager:OpenLayer(data)
            if not global.L_CommonTipsManager._layer then
                global.Facade:sendNotification(global.NoticeTable.Layer_CommonTips_Open, data)
            end
        end
    end)

end

function DataRePort:UpdateSelectModule(subMod)
    if not appid or not secretKey or not channelid then
        return
    end

    if global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin") == 1 then
        local boxBoxGameID  = subMod:GetOperID() or ""
        local boxChannelID  = global.L_GameEnvManager:GetChannelID() or ""
        local platformId    = subMod:GetPlatformID()
        if platformId and string.len( tostring(platformId) ) > 0 then
            boxChannelID = tostring(platformId)
        end

        local oldBoxid = self._infoData.boxid
        self._infoData.boxid= boxBoxGameID .. ":" .. boxChannelID
        if self.isDeviceLoginFinish and oldBoxid ~= self._infoData.boxid then
            if self._isCubeReport then
                local data = {
                    appid = appid,
                    secretKey = secretKey,
                    channel = channelid,
                    boxid = self._infoData.boxid,
                }
                global.L_NativeBridgeManager:GN_UpdateDeviceInfo(data)
                return
            end
            self:SendLoginEvent()
        end
    end
end


return DataRePort
