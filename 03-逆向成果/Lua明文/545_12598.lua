local DebugProxy = requireProxy("DebugProxy")
local ManualService996Proxy = class("ManualService996Proxy", DebugProxy)
ManualService996Proxy.NAME = global.ProxyTable.ManualService996Proxy

local cjson = require("cjson")
local socket = require("socket")

local signkey = "385755076a9b81c9ea85b7570679d6ca"

local function calcSuffix(originData)
    -- 计算sign
    local origin = ""
    local realOrigin = ""
    for i, v in ipairs(originData) do
        local send_value = v.value
        if send_value then
            if string.find(send_value, "%%") then
                local strList = string.split(send_value, "%")
                local t = urlencodeT("%")
                send_value = table.concat(strList, t)
            end

            if string.find(send_value, "%+") then
                local strList = string.split(send_value, "+")
                local t = urlencodeT("+")
                send_value = table.concat(strList, t)
            end

            if string.find(send_value, "%&") then
                local strList = string.split(send_value, "&")
                local t = urlencodeT("&")
                send_value = table.concat(strList, t)
            end

        end
        origin = origin .. string.format("%s=%s", v.key, v.value)
        origin = origin .. (i < #originData and "&" or "")

        realOrigin = realOrigin .. string.format("%s=%s", v.key, send_value)
        realOrigin = realOrigin .. (i < #originData and "&" or "")
    end
    -- 拼接sign
    local suffix = get_str_MD5(realOrigin)
    return suffix
end


local function HTTPRequestPost1(url, callback, data, header)
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

            releasePrint("Http Request Code:" .. tostring(code))
            callback(success, response, code)
        end
        httpRequest:registerScriptHandler(HttpResponseCB)
    end

    httpRequest:send(data)
end


function ManualService996Proxy:ctor()
    ManualService996Proxy.super.ctor(self)

    -- 请求地址
    --[[
        test: https://api-test.kf.996sdk.net/api/third/syncUserInfo
        pre:  https://api-pre.kf.996sdk.net/api/third/syncUserInfo
        prod: https://api.kf.996sdk.net/api/third/syncUserInfo
    ]]

    self._is_sdk_ui = false
    self._show = false
    self._url = nil

    local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local visitorLinkUrl = envProxy:GetCustomDataByKey("visitorLinkUrl")
    if visitorLinkUrl and string.len(visitorLinkUrl) > 0 then 
        self._url = visitorLinkUrl
        self._show = true
    end

    local queryUrl = envProxy:GetCustomDataByKey("queryVisitorMsgUrl")
    if queryUrl and string.len(queryUrl) > 0 then 
        self._query_url = queryUrl
    end

    self._un_read_nums = 0

    self._is_show_maual_service = false

    self._schedule_id = nil                 -- 兜底检测
    self._is_query_visitor_ing = false

    self._is_web_open = false
end

function ManualService996Proxy:SetShowMaulServiceState(state)
    self._is_show_maual_service = state == true
end

function ManualService996Proxy:IsShow()
    return self._show
end

function ManualService996Proxy:SetSDKUI(value)
    self._is_sdk_ui = value == true
end

function ManualService996Proxy:IsSDKUIShow()
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        return self._is_sdk_ui
    end
    return false
end

function ManualService996Proxy:SetUnReadNums(nums)
    self._un_read_nums = nums
end

function ManualService996Proxy:GetUnReadNums()
    return self._un_read_nums
end

function ManualService996Proxy:SetWebOpenState( state )
    self._is_web_open = state == true
end

function ManualService996Proxy:OnCheckRedPoint()
    if self._schedule_id then
        return
    end
    local totalTimes = 5 * 60       --5分钟之后自行停止
    local delayTime  = 10
    local checkTimes = 0
    self._schedule_id = Schedule(function()
        checkTimes = checkTimes + delayTime
        self:RequestQueryVisitorMsg()
        if checkTimes >= totalTimes then
            self:RemoveCheck()
        end
    end, delayTime)
end

function ManualService996Proxy:RemoveCheck(isUnRed)
    if self._schedule_id then
        UnSchedule(self._schedule_id)
        self._schedule_id = nil
    end

    if isUnRed then
        self:SetUnReadNums(0)
    end
end

function ManualService996Proxy:RequestManualService()
    -- 盒子打开的PC端  启用PC端盒子
    if global.isBoxLogin and SL:GetMetaValue("PLATFORM_WINDOWS") then
        local currModule = global.L_ModuleManager:GetCurrentModule()
        local gameid = currModule:GetOperID()
        local url    = "box996://callCustomService/id=" .. gameid
        -- 点击npc打开导致touch为invalid
        PerformWithDelayGlobal(function()
            cc.Application:getInstance():openURL(url)
        end,0.1)
        return
    end

    if not self._url then
        return
    end

    if self._is_web_open then
        self:SetUnReadNums(0)
        SLBridge:onLUAEvent(LUA_EVENT_MANUAL_SERVICE_MESSAGE_UN_READ, {unReadNums = 0})
        global.Facade:sendNotification(global.NoticeTable.Layer_Manual_Service_996_Open)
        return
    end

    -- body
     --[[
        box996://callCustomService/id=游戏id   --盒子唤醒
    ]]

    local AuthProxy = global.Facade:retrieveProxy( global.ProxyTable.AuthProxy )
    local loginProxy= global.Facade:retrieveProxy( global.ProxyTable.LoginProxy )
    local propertyProxy = global.Facade:retrieveProxy( global.ProxyTable.PlayerPropertyProxy )
    local currModule = global.L_ModuleManager:GetCurrentModule()

    local userId = tostring( AuthProxy:GetUID() )
    local name   = loginProxy:GetSelectedRoleName()
    local account= tostring( AuthProxy:GetUID() )
    local phone  = ""
    local nonce     = RandDataID("996Box")
    local timestamp = math.floor(socket.gettime() * 1000) -- 时间戳  毫秒13位

    local customField = {
        {
            attributeKey = "gameName",
            attributeName= "游戏名称",
            attributeValue = currModule:GetName(),
        },
        {
            attributeKey = "gameId",
            attributeName= "游戏id",
            attributeValue = currModule:GetOperID(),
        },
        {
            attributeKey = "account",
            attributeName= "账号UID",
            attributeValue = account,
        },
        {
            attributeKey = "serverRoleName",
            attributeName= "区服角色",
            attributeValue = loginProxy:GetSelectedRoleName(),
        },
        {
            attributeKey = "serverName",
            attributeName= "区服名称",
            attributeValue = loginProxy:GetSelectedServerName(),
        },
        {
            attributeKey = "roleId",
            attributeName= "角色id",
            attributeValue = loginProxy:GetSelectedRoleID(),
        },
        {
            attributeKey = "roleLevel",
            attributeName= "角色等级",
            attributeValue = propertyProxy:GetRoleLevel(),
        },
        {
            attributeKey = "serverId",
            attributeName= "区服id",
            attributeValue = loginProxy:GetSelectedServerId(),
        }
    }

    --[[
        "userId": 21, //用户id
        "name": "我是名称拉", //用户名称
        "account": "yy", //游戏账号
        "visitorSource": 1, //  1, "app端/h5端", 2, "pc端 3, "游戏" 4. 交易行
        "headImg": "xx", //访客头像
        "phone":"18896856652", //手机号
        "lastGameInfo":"传奇2", //最近在玩游戏(3款)
        "customField": "xx" //自定义字段  json格式
        "nonce": "1221", //随机字符串
        "timestamp": 1704778924000, //时间戳  
        "signature": "xx", //加密后的参数 
        "gameId": 2519
    ]]

    local data = {
        userId = userId,
        name = name,
        account = account,
        visitorSource = 3,
        source = 3,
        headImg = "",
        phone = "",
        lastGameInfo = currModule:GetName() or "",
        customField = cjson.encode(customField),
        nonce = nonce,
        timestamp = timestamp,
        gameId = tostring(currModule:GetOperID()),
    }

    local originData = {
        { key="userId", value=data.userId or ""},
        { key="name", value=data.name or ""},
        { key="account", value=data.account or ""},
        { key="phone", value=data.phone or ""},
        { key="nonce", value=data.nonce or ""},
        { key="timestamp", value=data.timestamp},
        { key="sign",  value=signkey or ""},
    }

    data.signature = calcSuffix(originData)

    local jsonStr = cjson.encode(data)
    local header = {}
    header["Content-Type"] = "application/json"
    HTTPRequestPost1(self._url, function( success, response )
        if not success then
            ShowSystemTips("请求失败")
            return false
        end
        
        releasePrint("========kefu：", response)
        local jsonData = cjson.decode(response)
        if not jsonData then
            ShowSystemTips("解析失败")
            return false
        end

        if not (jsonData.code == 200) then
            ShowSystemTips("获取验证码失败, 状态异常 "  .. jsonData.msg)
            return false
        end

        local linkURL = jsonData.data and jsonData.data.visitorLinkUrl
        if not linkURL or linkURL == "" or string.len(linkURL) == 0 then
            ShowSystemTips("获取客服地址失败")
            return false
        end

        local uid = ""
        if jsonData.chatting then
            linkURL = linkURL .. "&uid=" .. jsonData.customerId
        end

        -- self:SetShowMaulServiceState(false)
        self:SetUnReadNums(0)
        SLBridge:onLUAEvent(LUA_EVENT_MANUAL_SERVICE_MESSAGE_UN_READ, {unReadNums = 0})
        if cc.PLATFORM_OS_WINDOWS ~= global.Platform and not self:IsSDKUIShow() then
            linkURL = linkURL .. "&sourceType=game"
            global.Facade:sendNotification(global.NoticeTable.Layer_Manual_Service_996_Open, {url = linkURL})
            return
        end

        local NativeBridgeProxy = global.Facade:retrieveProxy( global.ProxyTable.NativeBridgeProxy )
        NativeBridgeProxy:GN_ShowCustomerService({
            url = linkURL
        })
    end, jsonStr, header)
    releasePrint("RequestAuthCode url: " .. self._url .. "   postData: " .. jsonStr)
end

-- 检测访客信息
function ManualService996Proxy:RequestQueryVisitorMsg()
    if not self._query_url then
        return
    end
    if self._is_query_visitor_ing then
        return
    end

    self._is_query_visitor_ing = true
    local AuthProxy = global.Facade:retrieveProxy( global.ProxyTable.AuthProxy )

    local userId = tostring( AuthProxy:GetUID() )
    local url = string.format("%s?visitorId=%s&visitorSource=%s", self._query_url, userId, 3)
    releasePrint("===self._query_url111: ", url )
    HTTPRequest(url, function( success, response )
        self._is_query_visitor_ing = false
        if not success then
            releasePrint("查询请求失败")
            return false
        end

        releasePrint("========查询kefu：", response)
        local jsonData = cjson.decode(response)
        if not jsonData then
            releasePrint("查询解析失败")
            return false
        end

        local unReadMsg = jsonData and jsonData.data and jsonData.data.unReadMsg
        if unReadMsg then
            local unReadNums = self._un_read_nums or 0
            unReadNums       = unReadNums + 1
            self:SetUnReadNums(unReadNums)
            self:RemoveCheck()
            SLBridge:onLUAEvent(LUA_EVENT_MANUAL_SERVICE_MESSAGE_UN_READ, {unReadNums = unReadNums})
        end
    end)
end

return ManualService996Proxy
