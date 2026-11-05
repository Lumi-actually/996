local RemoteProxy = requireProxy("RemoteProxy")
local Box996Proxy = class("Box996Proxy", RemoteProxy)
Box996Proxy.NAME = global.ProxyTable.Box996Proxy

local cjson  = require("cjson")
local sha1   = require("sha1/init")
local socket = require("socket")


local signkey = "7PZJImoeAE5Dnjb6pCYu8Ja5Buhb2urL" -- svip
local logSignKey = "e07157b7b815bf2b3add52523f95326b" -- 埋点key

Box996Proxy.BOX_TYPE = {
    TYPE_TITLE = 1, -- 特权称号
    TYPE_EVERY_DAY = 2, -- 每日礼包
    TYPE_SUPER = 3, -- 超级礼包
    TYPE_VIP = 4, -- 会员礼包
    TYPE_SVIP = 5, -- SVIP
    TYPE_CLOUD_PHONE = 6, -- 云手机
}

Box996Proxy.BOX_UP_DATA = {
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 6,
    [5] = 7,
}

Box996Proxy.BOX_UP_GIFT = {
    [1] = 105, -- 每日
    [3] = 106 -- 超级
}

-- 下载按钮数据上报
Box996Proxy.BOX_UP_DOWNLOAD = {
    [2] = 104 -- 每日
}

Box996Proxy.SVIP_REWARD_TYPE = {
    TYPE_ATTR = 1, -- 属性奖励
    TYPE_LIBAO = 2 -- 礼包奖励
}

-- 数据上报事件ID
Box996Proxy.LOGUP_EVENT_ID = {
    [119] = "tiantianshengqian_1150", -- svip页签
    [120] = "tiantianshengqian_1155", -- svip的下载
    [121] = "tiantianshengqian_1154", -- svip的领取礼包
    [122] = "tiantianshengqian_1153", -- svip的属性激活,
    [123] = "tiantianshengqian_1151", -- svip 我的等级点击
    [124] = "tiantianshengqian_1152", -- svip 其他等级点击
    [125] = "tiantianshengqian_1138", -- 天天省钱入口
    [126] = "tiantianshengqian_1139", -- 每日礼包页签
    [127] = "tiantianshengqian_1140", -- 领取每日礼包
    [128] = "tiantianshengqian_1141", -- 领取礼包下载盒子
    [129] = "tiantianshengqian_1142", -- 超级礼包页签
    [130] = "tiantianshengqian_1143", -- 超级礼包  每日礼包
    [131] = "tiantianshengqian_1144", -- 超级礼包  下载盒子
    [132] = "tiantianshengqian_1145", -- 称号  展示自己的盒子称号
    [133] = "tiantianshengqian_1146", -- 称号  隐藏自己的盒子称号
    [134] = "tiantianshengqian_1147", -- 称号  展示他人的盒子称号
    [135] = "tiantianshengqian_1148", -- 称号  隐藏他人的盒子称号
    [136] = "tiantianshengqian_1149", -- 称号  下载盒子
    [137] = "tiantianshengqian_1215", -- 称号页签
    [138] = "tiantianshengqian_1230", -- 会员礼包页签
    [139] = "tiantianshengqian_1231", -- 会员礼包 下载
    [140] = "tiantianshengqian_1232", -- 会员礼包 领取
}

-- 其它数据上报的EVENTID
Box996Proxy.OTHER_UP_EVEIT = {
    -- 交易行 begin
    [1]     = "jiaoyihang_1156",  -- 交易行
    [101]   = "jiaoyihang_1157",  -- 交易行  购买页签
    [102]   = "jiaoyihang_1158",  -- 交易行  寄售页签
    [103]   = "jiaoyihang_1161",  -- 交易行  货架页签
    [104]   = "jiaoyihang_1162",  -- 交易行  我的页签
    [105]   = "jiaoyihang_1163",  -- 交易行  提现 /下载盒子
    [106]   = "jiaoyihang_1159",  -- 交易会  寄售的角色按钮
    [107]   = "jiaoyihang_1160",  -- 交易会  寄售的货币按钮
    -- 交易行 end
}

-- svip界面的按钮上报  对应LOGUP_EVENT_ID
Box996Proxy.SVIP_BOX_UP_UP = {
    [1] = Box996Proxy.LOGUP_EVENT_ID[120],
    [2] = Box996Proxy.LOGUP_EVENT_ID[121],
    [3] = Box996Proxy.LOGUP_EVENT_ID[122],
    [4] = Box996Proxy.LOGUP_EVENT_ID[123],
    [5] = Box996Proxy.LOGUP_EVENT_ID[124],
}

-- 主界面
-- 特权/每日/超级 按钮 对应上报ID   盒子切页  对应LOGUP_EVENT_ID
Box996Proxy.BOX_UP_BTN = {
    [0] = Box996Proxy.LOGUP_EVENT_ID[125],
    [1] = Box996Proxy.LOGUP_EVENT_ID[137],
    [2] = Box996Proxy.LOGUP_EVENT_ID[126],
    [3] = Box996Proxy.LOGUP_EVENT_ID[129],
    [6] = Box996Proxy.LOGUP_EVENT_ID[138],
    [7] = Box996Proxy.LOGUP_EVENT_ID[119]
}

-- 称号
Box996Proxy.BOX_UP_TITLE = {
    [1] = Box996Proxy.LOGUP_EVENT_ID[132],
    [2] = Box996Proxy.LOGUP_EVENT_ID[133],
    [3] = Box996Proxy.LOGUP_EVENT_ID[134],
    [4] = Box996Proxy.LOGUP_EVENT_ID[135],
    [5] = Box996Proxy.LOGUP_EVENT_ID[136],
}

-- 超级礼包
Box996Proxy.BOX_UP_SUPER = {
    [1] = Box996Proxy.LOGUP_EVENT_ID[130],
    [2] = Box996Proxy.LOGUP_EVENT_ID[131],
}

-- 每日礼包
Box996Proxy.BOX_UP_EVERY = {
    [1] = Box996Proxy.LOGUP_EVENT_ID[127],
    [2] = Box996Proxy.LOGUP_EVENT_ID[128],
}

-- 会员礼包
Box996Proxy.BOX_UP_VIP = {
    [1] = Box996Proxy.LOGUP_EVENT_ID[139],
    [2] = Box996Proxy.LOGUP_EVENT_ID[140],
}

-- svip请求的body
local function getSVIPParam(val, isPost)
    local originData = {}
    for k, v in pairs(val) do
        if k ~= "token" then
            table.insert(originData, {
                key = k,
                value = v
            })
        end
    end
    table.sort(originData, function(a, b)
        return a.key < b.key
    end)
    -- 计算sign
    local origin = ""
    for i, v in ipairs(originData) do
        if type(v.value) == "string" or type(v.value) == "number" or type(v.value) == "boolean" then
            origin = origin .. tostring(v.value)
        elseif type(v.value) == "table" then
            local str = cjson.encode(v.value)
            str = string.gsub(str, "\\/", "/")
            origin = origin .. str
        end
    end
    local rqtime = os.time()
    local rqrandom = RandDataID("996Box")
    local md5 = get_str_MD5(origin .. signkey .. rqtime .. rqrandom)
    if not isPost then
        val.rqrandom = rqrandom
        val.rqtime = rqtime
        val.sign = md5
    end

    return {
        valEncode = cjson.encode(val),
        sign = md5,
        rqtime = rqtime,
        rqrandom = rqrandom
    }
end

-- 数据上报的post请求的data
local function getLogUpSuffix(originData)
    -- ascii排序
    table.sort(originData, function(a, b)
        return a.key < b.key
    end)

    -- 计算sign
    local origin = ""
    local realOrigin = ""

    local val = {}
    for i, v in ipairs(originData) do
        local valueV = v.value
        if type(v.value) == "table" then
            local str = cjson.encode(v.value)
            valueV = string.gsub(str, "\\/", "/")
        end

        local send_value = valueV
        if send_value then
            val[v.key] = valueV
            if string.find(send_value, "%%") then
                local strList = G_GetSplitArray(send_value, "%")
                local t = urlencodeT("%")
                send_value = table.concat(strList, t)
            end

            if string.find(send_value, "%+") then
                local strList = G_GetSplitArray(send_value, "+")
                local t = urlencodeT("+")
                send_value = table.concat(strList, t)
            end

            if string.find(send_value, "%&") then
                local strList = G_GetSplitArray(send_value, "&")
                local t = urlencodeT("&")
                send_value = table.concat(strList, t)
            end
        end
        origin = origin .. string.format("%s=%s", v.key, v.value)
        origin = origin .. (i < #originData and "&" or "")

        realOrigin = realOrigin .. string.format("%s=%s", v.key, send_value)
        realOrigin = realOrigin .. (i < #originData and "&" or "")
    end

    local sign = sha1.hmac(logSignKey, realOrigin)
    local signC = string.format("sign=%s", sign)
    local suffix = realOrigin .. "&" .. signC
    val.sign = sign
    return cjson.encode(val)
end

-- 数据上报的post请求的header
local function getLogUpHeader()
    local device = ""
    
    return {
        device = device,
        deviceOs = "",
        deviceId = "",
        deviceModel = "",
        deviceBrand = "",
        netType = ""
    }
end

local hostIndex = 1
function Box996Proxy:ctor()
    Box996Proxy.super.ctor(self)

    self._box_data = {
        sState = true,
        oState = true
    }

    self._login_qequist_count = 0

    self._post_url = "https://user-api.996box.com/v1/ChannelDownLink/getDownUrl"

    local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local BoxDoamin = envProxy:GetCustomDataByKey("996BoxDoamin")
    if BoxDoamin and string.len(BoxDoamin) > 0 then 
        self._post_url = BoxDoamin .. "/v1/ChannelDownLink/getDownUrl"
    end

    self._default_download_url = "https://tgdata.996box.com/down_url.json"

    local BoxDefaultDoamin = envProxy:GetCustomDataByKey("996BoxDefaultDoamin")
    if BoxDefaultDoamin and string.len(BoxDefaultDoamin) > 0 then 
        self._default_download_url = BoxDefaultDoamin .. "/down_url.json"
    end

    local TradingBankEnvironment = envProxy:GetCustomDataByKey("TradingBankEnvironment")
    if TradingBankEnvironment and string.len(TradingBankEnvironment) > 0 then 
        TradingBankEnvironment = tonumber(TradingBankEnvironment)
        if TradingBankEnvironment == 0 then--新增测试环境盒子签名密钥
            signkey = "1BDC60CAEA65459187113B8B92FCB012"
        end
    end

    -- svip
    self._svip_data = {
        isInitRequest = true
    } -- svip数据
    self._svip_states = {} -- svip 领取状态
    self._svip_level = 0 -- svip等级
    self._svip_base_url = nil -- svip地址
    self._query_svip_level = "querySvipUserBaseInfo" -- 查询svip用户信息
    self._query_svip_title = "querySvipBaseGameRight/" -- 查询svip等级配置
    self._query_svip_state = "querySvipUserGameRightState/" -- 查询领取状态
    self._query_svip_reward = "useSvipUserGameRight" -- 领取svip奖励
    self._query_svip_remind_flag = "saveSvipUserGameRightRemind" -- 提醒开关
    self._query_svip_attr = "/game/game-server/v1/sendPropResourceToGame"  --游戏属性

    self._giftUsedMessage   =nil    -- 提醒语
    self._remindFlag        = false -- 提醒开关是否标识
    self._svip_show_btn     = nil -- 是否显示svip按钮

    -- 埋点
    self._log_url = "http://box-collect.xqhuyu.com" -- 测试 "box-collect.dev.xqhuyu.com"  生产 "box-collect.xqhuyu.com"
    self._log_query = "/v1/newLog" -- 埋点接口

    local BoxLogDoamin = envProxy:GetCustomDataByKey("996BoxLogDoamin")
    if BoxLogDoamin and string.len(BoxLogDoamin) > 0 then 
        self._log_url = BoxLogDoamin
    end


    -- 云手机
    local cloudPhoneURL = "https://user-api.996box.com/cloud/v1/engine/present/"
    if BoxDoamin and string.len(BoxDoamin) > 0 then
        cloudPhoneURL = BoxDoamin .. "/cloud/v1/engine/present/"
    end

    -- 测试用
    cloudPhoneURL = "https://test-api.996box.com/cloud/v1/engine/present/"

    self._cloud_pohe_base_url = cloudPhoneURL
    self._query_cloud_phone_check = "check"         -- 云手机权益查询,
    self._query_cloud_phone_receive = "receive"     -- 云手机权益领取

    self._cloud_phone_show     = nil                -- 云手机切页是否显示
    self._cloud_phone_down_time= 0                  -- 云手机权益领取倒计时
    self._cloud_phone_flag     = false              -- 云手机权益领取状态
    self._cloud_phone_time     = 0                  -- 云手机权益时间
end

function Box996Proxy:loginRequest()
    self._svip_level = 0 -- svip等级
    self._svip_base_url = nil -- svip地址
    self._svip_show_btn = nil
    self._login_qequist_count = 0
    self:requestBoxGetState()
    self:requestBoxList()
    self:requestSVIPAttr()
end

function Box996Proxy:openUIRequest()
    self._login_qequist_count = 0
    self:requestBoxGetState()
    self:requestBoxList()
    self:IsShowSVIP()
end

function Box996Proxy:getBoxData()
    return self._box_data
end

function Box996Proxy:getResLocalPanel()
    local module = global.L_ModuleManager:GetCurrentModule()
    local modulePath = module:GetSubModPath()
    local storagePath = global.WritablePath .. modulePath .. "res/private/box_996_ui/guide_ui/"
    if not global.FileUtilCtl:isDirectoryExist(storagePath) then
        global.FileUtilCtl:createDirectory(storagePath)
    end
    return storagePath
end

function Box996Proxy:getGifGetState(getType)
    if self._box_data.gifGet then
        return self._box_data.gifGet[getType] == 1
    end
    return false
end

function Box996Proxy:ParseRewards(str, sp)
    str = str or ""
    sp = sp or "&"
    local rewards = {}
    local sliceStr = G_GetSplitArray(str, sp)
    for i = 1, #sliceStr do
        local sliceStr2 = G_GetSplitArray(sliceStr[i], "#")
        local id = tonumber(sliceStr2[1])
        if id then
            local count = tonumber(sliceStr2[3]) or 1
            table.insert(rewards, {
                id = id,
                count = count
            })
        end
    end
    return rewards
end

function Box996Proxy:isShowOneTitle()
    return self._box_data.sState == true
end

function Box996Proxy:isShowOtherTitle()
    return self._box_data.oState == true
end

function Box996Proxy:isShowTitleByActor(actor)
    if not actor then
        return false
    end
    if actor:IsPlayer() and actor:GetHorseCopilotID() then
        return false
    end
    if actor:GetValueByKey(global.MMO.HUD_SNEAK) then
        return 
    end
    if actor:GetID() == global.gamePlayerController:GetMainPlayerID() then
        return self._box_data.sState == true
    end
    return self._box_data.oState == true
end

function Box996Proxy:isBoxOpen()
    return self._box_data.isBoxOpen == true
end

local function urlencodechar(char)
    return "%" .. string.format("%02X", string.byte(char))
end

local function urlencodeT(input)
    -- convert line endings
    input = string.gsub(tostring(input), "\n", "\r\n")

    -- escape all characters but alphanumeric, '.' and '-'
    input = string.gsub(input, "([^%w%.%-%_%~ :/=?&])", urlencodechar)
    -- convert spaces to "+" symbols
    return string.gsub(input, " ", "+")
end

-- 渠道类型 1：游戏称号特权   2：游戏每日礼包     3：游戏超级礼包     4：游戏会员礼包      5：游戏交易行      6：PC官网
function Box996Proxy:getBox996DownloadURL(channelType)
    if not tonumber(channelType) then
        return
    end

    local device = ""
    if global.isWindows then
        device = "pc"
    elseif global.isAndroid then
        device = "android"
    elseif global.isOHOS then
        device = "ohos"
    elseif global.isIOS then
        device = "ios"
    end

    if device == "" then
        release_print("not find device")
        return
    end

    local suffix = string.format("channel_type=%d&device=%s", channelType, device)

    if global.isIOS then
        local revcData = global.L_NativeBridgeManager._revcData
        local iosVerSion = revcData and revcData.sysversion or ""
        suffix = string.format("%s&ios_version=%s", suffix, iosVerSion)
    end

    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local userid = tostring(AuthProxy:GetUID() or "")

    local currModule = global.L_ModuleManager:GetCurrentModule()
    local gameid = currModule:GetOperID()
    suffix = string.format("%s&game_id=%s&userid=%s", suffix, gameid, userid)


    releasePrint("getBox996DownloadURL url: " .. self._post_url .. "  post: " .. suffix)
    HTTPRequestPost(self._post_url, function(success, response)
        local jsonData = {}
        if response and string.len(response) > 0 then
            releasePrint(response)
            jsonData = cjson.decode(response)
        end

        local url = ""
        local urls = jsonData.data and jsonData.data.url
        if urls and next(urls) then
            for i, v in pairs(urls) do
                if v.deviceType == device then
                    url = v.download_url
                    break
                end
            end
        end
        if url and url ~= "" then
            if global.isIOS then
                url = urlencodeT(url)
            end
            cc.Application:getInstance():openURL(url)
        else
            self:getBox996DefaultDownloadURL(channelType)
        end
    end, suffix)
end

-- 下载默认的地址
function Box996Proxy:getBox996DefaultDownloadURL(channelType)

    HTTPRequest(self._default_download_url, function(success, response)
        local jsonData = {}
        if response and string.len(response) > 0 then
            releasePrint(response)
            jsonData = cjson.decode(response)
        end

        local url = nil
        if global.isWindows then
            url = jsonData["pc_down_url"]
        elseif global.isAndroid then
            url = jsonData["android_down_url"]
        elseif global.isOHOS then
            url = jsonData["ohos_down_url"]
        elseif global.isIOS then
            url = jsonData["ios_down_url"]
        end

        if url and url ~= "" then
            if global.isIOS then
                url = urlencodeT(url)
            end
            cc.Application:getInstance():openURL(url)
        end
    end)
end

-- 获取奖励数据
function Box996Proxy:getBoxGiftData(boxType)
    if not boxType then
        return {}
    end

    local giftType = {
        [Box996Proxy.BOX_TYPE.TYPE_EVERY_DAY] = 1,
        [Box996Proxy.BOX_TYPE.TYPE_SUPER] = 3,
        [Box996Proxy.BOX_TYPE.TYPE_VIP] = 4
    }

    local rewards = {}
    local rewardType = giftType[boxType]
    local boxgift = self._box_data and self._box_data.BoxGift or {}
    for i, v in ipairs(boxgift or {}) do
        if v and tonumber(v.type) == rewardType then
            rewards = self:ParseRewards(v.reward)
            break
        end
    end
    return rewards or {}
end

function Box996Proxy:requestBoxList()
    LuaSendMsg(global.MsgType.MSG_CS_SENDBOXGIFTLIST_REQUEST)
end

-- 请求上报数据
-- 天天省钱7100（主界面按钮） 称号7101  每日礼包 7102 超级礼包 7103 vip礼包 7106  svip 7107  后端有加7100
-- upType: 0：打开页面上报类型   1：下载上报类型
function Box996Proxy:requestBoxUpData(upId, upType)

    -- 走客户端的数据上报
    if Box996Proxy.LOGUP_EVENT_ID[upId] then
        self:requestLogUp(Box996Proxy.LOGUP_EVENT_ID[upId])
        return
    end

    -- upType = upType or 0
    -- if not upId then
    --     return
    -- end
    -- local platform = 2
    -- if cc.PLATFORM_OS_ANDROID == global.Platform then
    --     platform = 0
    -- elseif cc.PLATFORM_OS_IPAD == global.Platform or cc.PLATFORM_OS_IPHONE == global.Platform then
    --     platform = 1
    -- end
    -- LuaSendMsg(global.MsgType.MSG_CS_SENDBOXGIFTBUTTONID_REQUEST, upId, upType, platform)
    local platform = 2
    if cc.PLATFORM_OS_ANDROID == global.Platform or global.isOHOS then
        platform = 0
    elseif cc.PLATFORM_OS_IPAD == global.Platform or cc.PLATFORM_OS_IPHONE == global.Platform then
        platform = 1
    end
    LuaSendMsg( global.MsgType.MSG_CS_SENDBOXGIFTBUTTONID_REQUEST, upId, upType, platform)
end

-- 请求获取盒子请求状态
function Box996Proxy:requestBoxGetState(getState)
    LuaSendMsg(global.MsgType.MSG_CS_SENDBOXGIFTSTATE_REQUEST)
end

-- 请求获取盒子奖励
-- param1:类型：1是每日礼包，3是超级礼包
-- msg：礼包码
function Box996Proxy:requestBoxReward(boxType, reward)
    if not boxType then
        return
    end

    -- 礼包  数字和字母的组合
    if string.match(reward or "", "([0-9a-zA-Z]+)") ~= reward then
        local data = {}
        data.str = GET_STRING(310000417)
        data.btnType = 1
        UIOperator:OpenCommonTipsUI(data)
        return
    end

    if boxType == 3 then
        LuaSendMsg(global.MsgType.MSG_CS_GETBOXGIFTBYTYPE_REQUEST, 0, boxType, 0, 0, reward, string.len(reward))
    else
        LuaSendMsg(global.MsgType.MSG_CS_GETBOXGIFTBYTYPE_REQUEST, 0, boxType)
    end
    self:requestBoxUpData(Box996Proxy.BOX_UP_GIFT[boxType], 2)
end

-- 请求称号状态
-- param1:类型：1自身称号显示状态，2他人称号显示状态
-- param2: 值 0或1
function Box996Proxy:requestBoxTitleState(titleType, state)
    if not titleType then
        return
    end
    local param2 = state and 1 or 0
    LuaSendMsg(global.MsgType.MSG_CS_SETBOXGIFTSTATE_REQUEST, 0, titleType, param2)
end

-----------------------------------------------SVIP      begin----------------------------------
function Box996Proxy:IsShowSVIP()
    if not self._svip_base_url then
        local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
        self._svip_base_url = envProxy:GetCustomDataByKey("svipURL") or ""
        self:getBackSVIPData()
    end

    return self._svip_show_btn
end

function Box996Proxy:getSVIPData()
    if self._svip_data.isInitRequest then
        self:getBackSVIPData()
        return nil
    end
    return self._svip_data
end

-- 进入svip界面时重新检测一遍
function Box996Proxy:joinSvipUpdateSvipState()
    for k, v in pairs(self._svip_states) do
        if not next(v) then
            self._svip_states[k] = nil
        end
    end
end

function Box996Proxy:getSVIPState(svip)
    if not self._svip_states[svip] then
        self:requestSVIPStates(svip)
        return {}
    end
    return self._svip_states[svip] or {}
end

function Box996Proxy:getSvipRemindFlag()
    return self._remindFlag == true
end

function Box996Proxy:getSvipUseMessage(svip)
    return self._giftUsedMessage or ""
end

function Box996Proxy:getSvipLevel()
    return self._svip_level or 0
end

function Box996Proxy:requestSVIPLevel()
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local userid = tonumber(AuthProxy:GetUID()) or 0
    local data = {
        userid = userid
    }
    local param = getSVIPParam(data)
    local suffix = string.format("?userId=%s&rqtime=%s&rqrandom=%s&sign=%s", userid, param.rqtime, param.rqrandom,
        param.sign)
    local url = self._svip_base_url .. self._query_svip_level .. suffix
    HTTPRequest(url, function(success, response, code)
        if not success then
            return 0
        end
        -- body
        local jsonData = cjson.decode(response)
        if not jsonData or not jsonData.data then
            return 0
        end

        if self._svip_level ~= jsonData.data.svipLevel then
            self._svip_level = jsonData.data.svipLevel
            self._svip_states[self._svip_level] = nil
        end

        global.Facade:sendNotification(global.NoticeTable.Layer_Box996SVIP_Refresh, {
            isSvipLevel = true,
            data = jsonData.data
        })
    end)
end

-- 请求属性下发
function Box996Proxy:requestSVIPAttr()
    local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local baseURL = envProxy:GetCustomDataByKey("svipAttrURL") or ""
    if baseURL == "" then
        self:IsShowSVIP()
        return
    end

    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local loginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local gameid = global.L_ModuleManager:GetCurrentModule():GetOperID()
    local roleId = loginProxy:GetSelectedRoleID()
    local serverId = loginProxy:GetSelectedServerId()
    local userid = tonumber(AuthProxy:GetUID()) or 0    -- 0是非盒子用户查询id
    local data = {
        userid = userid,
        gameid = gameid,
        serverId = serverId,
        roleId = roleId
    }
    local param = getSVIPParam(data)
    local suffix = string.format("?roleId=%s&userId=%s&gameId=%s&serverId=%s&rqtime=%s&rqrandom=%s&sign=%s", roleId, userid, gameid,
        serverId, param.rqtime, param.rqrandom, param.sign)
    local url = baseURL .. self._query_svip_attr .. suffix

    HTTPRequest(url, function(success, response, code)
        releasePrint("svip attr: ", success, response)
    end)
end

-- 从后台获取svip配置数据
-- 只请求一次
function Box996Proxy:getBackSVIPData()
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local loginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local userid = tonumber(AuthProxy:GetUID()) or 0    -- 0是非盒子用户查询id
    local gameid = global.L_ModuleManager:GetCurrentModule():GetOperID()
    local serverId = loginProxy:GetSelectedServerId()
    local roleId    = loginProxy:GetSelectedRoleID()
    local data = {
        userid = userid,
        gameid = gameid,
        serverId = serverId,
        roleId = roleId
    }
    local param = getSVIPParam(data)
    local suffix = string.format("?roleId=%s&userId=%s&gameId=%s&serverId=%s&rqtime=%s&rqrandom=%s&sign=%s", roleId, userid, gameid,
        serverId, param.rqtime, param.rqrandom, param.sign)
    local url = self._svip_base_url .. self._query_svip_title .. suffix
    HTTPRequest(url, function(success, response, code)
        if self._svip_data.isInitRequest then
            self._svip_data.isInitRequest = false
        end
        if not success then
            global.Facade:sendNotification(global.NoticeTable.Layer_Box996Main_Refresh, {
                isSvipBtn = true,
                value = false
            })
            return
        end
        -- body
        local jsonData = cjson.decode(response)
        if not jsonData or not jsonData.data then
            global.Facade:sendNotification(global.NoticeTable.Layer_Box996Main_Refresh, {
                isSvipBtn = true,
                value = false
            })
            return
        end
        self._svip_data.levelNum = tonumber(jsonData.data.levelNum) or 0
        self._svip_data.data = {}
        self._svip_show_btn = false
        for k, v in pairs(jsonData.data.rights or {}) do
            if v.svipLevel then
                self._svip_data.data[v.svipLevel] = v
                self._svip_show_btn = true
            end
        end
        global.Facade:sendNotification(global.NoticeTable.Layer_Box996SVIP_Refresh, {
            isTitleList = true,
            data = self._svip_data
        })
        global.Facade:sendNotification(global.NoticeTable.Layer_Box996Main_Refresh, {
            isSvipBtn = true,
            value = self._svip_show_btn
        })
    end)
end
-- 从后台获取svip状态
function Box996Proxy:requestSVIPStates(svip)
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local userid = tonumber(AuthProxy:GetUID()) or 0
    local gameid = global.L_ModuleManager:GetCurrentModule():GetOperID()
    local loginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local serverId = loginProxy:GetSelectedServerId()
    local roleid  = loginProxy:GetSelectedRoleID()
    local data = {
        userid = userid,
        gameid = gameid,
        svipLevel = svip,
        serverId = serverId,
        roleId = roleid,
    }

    local param = getSVIPParam(data)
    local suffix = string.format("?userId=%s&gameId=%s&svipLevel=%s&serverId=%s&roleId=%s&rqtime=%s&rqrandom=%s&sign=%s", userid, gameid,
        svip, serverId, roleid, param.rqtime, param.rqrandom, param.sign)
    local url = self._svip_base_url .. self._query_svip_state .. suffix
    HTTPRequest(url, function(success, response, code)
        if not success then
            return
        end
        -- body
        local jsonData = cjson.decode(response)
        if not jsonData or not jsonData.data then
            return
        end
        local svip = jsonData.data.svipLevel
        if not svip then
            return
        end

        if svip == self._svip_level then
            self._giftUsedMessage    = jsonData.data.giftUsedMessage
            self._remindFlag         = jsonData.data.remindFlag == true
        end

        self._svip_states[svip] = jsonData.data
        global.Facade:sendNotification(global.NoticeTable.Layer_Box996SVIP_Refresh, {
            isState = true,
            svip = svip,
            isRemindFlag = true
        })
    end)
end

-- 请求svip激活属性, 只能激活当前的属性
-- sviptype 1: 属性   2: 礼包
function Box996Proxy:requestSVIPReward(svip, sviptype)
    local function urlencodeT(input)
        input = string.gsub(tostring(input), "\n", "\r\n")
        input = string.gsub(input, "([^%w%.%-%_%~ :/=?&])", urlencodechar)
        return string.gsub(input, " ", "+")
    end

    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local loginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local userid = tonumber(AuthProxy:GetUID()) or 0
    local gameid = global.L_ModuleManager:GetCurrentModule():GetOperID()
    local serverId = loginProxy:GetSelectedServerId()
    local roleId = global.gamePlayerController:GetMainPlayerID()
    local roleName = loginProxy:GetSelectedRoleName()
    local data = {
        userId = userid,
        gameId = gameid,
        svipLevel = svip,
        serverId = serverId,
        roleId = roleId,
        roleName = roleName,
        rightType = sviptype
    }

    local param = getSVIPParam(data, true)
    local suffix = string.format("?rqtime=%s&rqrandom=%s&sign=%s", param.rqtime, param.rqrandom, param.sign)
    local url = self._svip_base_url .. self._query_svip_reward .. suffix
    self:HTTPRequestPostSVIP(url, function(success, response, code)
        if not success then
            return
        end
        -- body
        local jsonData = cjson.decode(response)

        if jsonData.msg and string.len(jsonData.msg) > 0 then
            ShowSystemTips(jsonData.msg)
        end

        if not jsonData or not jsonData.data then
            return
        end
        local svip = jsonData.data.svipLevel
        if not svip then
            return
        end

        local state = jsonData.data.state
        local rewardType = jsonData.data.rightType
        if rewardType == Box996Proxy.SVIP_REWARD_TYPE.TYPE_ATTR then
            self._svip_states[svip].propState = state
        elseif rewardType == Box996Proxy.SVIP_REWARD_TYPE.TYPE_LIBAO then
            self._svip_states[svip].giftState = state

            -- 刷新开关提示
            if self:getSvipLevel() == svip and state == 1 then
                self:requestSVIPStates(svip)
            end
        end

        global.Facade:sendNotification(global.NoticeTable.Layer_Box996SVIP_Refresh, {
            isGetState = true,
            svip = svip,
            isRemindFlag = true
        })
    end, param.valEncode)
end

-- 请求svip权益提醒配置保存
-- remindFlag 1: 提醒标识 true/false
function Box996Proxy:requestSVIPRemindOnOff(remindFlag)
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local userid = tonumber(AuthProxy:GetUID()) or 0
    local gameid = global.L_ModuleManager:GetCurrentModule():GetOperID()
    local loginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local serverId = loginProxy:GetSelectedServerId()
    local data = {
        userId = userid,
        gameId = gameid,
        remindFlag = remindFlag == true,
        serverId = serverId
    }

    local param = getSVIPParam(data, true)
    local suffix = string.format("?rqtime=%s&rqrandom=%s&sign=%s", param.rqtime, param.rqrandom, param.sign)
    local url = self._svip_base_url .. self._query_svip_remind_flag .. suffix
    self:HTTPRequestPostSVIP(url, function(success, response, code)
        if not success then
            return
        end
        -- body
        local jsonData = cjson.decode(response)

        if jsonData.msg and string.len(jsonData.msg) > 0 then
            ShowSystemTips(jsonData.msg)
        end

        if jsonData.data then
            self._remindFlag = not self._remindFlag
            global.Facade:sendNotification(global.NoticeTable.Layer_Box996SVIP_Refresh, {
                isRemindFlag = true,
            })
        end
        
        
    end, param.valEncode)
end

function Box996Proxy:HTTPRequestPostSVIP(url, callback, data, header)
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

            release_print("Http Request Code:" .. tostring(code))
            callback(success, response, code)
        end
        httpRequest:setRequestHeader("Content-type", "application/json")
        httpRequest:registerScriptHandler(HttpResponseCB)
    end

    httpRequest:send(data)
end

-----------------------------------------------SVIP        end----------------------------------

-----------------------------------------------cloud phone begin--------------------------------
-- 云手机切页按钮是否显示
function Box996Proxy:getCloudPhoneShow()
    if self._cloud_phone_show == nil then
        self:requestCloudPhoneCheck()
    end

    if self._cloud_phone_show and self._cloud_phone_down_time > 0 then
        if self._cloud_phone_down_time - GetServerTime() <= 0 then
            return false
        end
    end
    return self._cloud_phone_show
end

-- 获取云手机活动倒计时
function Box996Proxy:getCloudPhoneRewardGetDownTime()
    return self._cloud_phone_down_time
end

-- 获取是否已领取云手机奖励
function Box996Proxy:getCloudPhoneReceiveFlag()
    return self._cloud_phone_flag
end

-- 获取云手机奖励时间
function Box996Proxy:getCloudPhoneRewardTime()
    return self._cloud_phone_time
end

-- 请求获取云手机数据
function Box996Proxy:requestCloudPhoneCheck()
    local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local userid = tonumber(AuthProxy:GetUID()) or 0
    local gameid = global.L_ModuleManager:GetCurrentModule():GetOperID()
    local gameLevel  = PlayerProperty:GetRoleLevel()
    local data = {
        userId = userid,
        gameId = gameid,
        gameLevel = gameLevel,
    }

    local param = getSVIPParam(data)
    local suffix = string.format("?userId=%s&gameId=%s&gameLevel=%s&rqtime=%s&rqrandom=%s&sign=%s", userid, gameid, gameLevel, param.rqtime, param.rqrandom, param.sign)
    local url = self._cloud_pohe_base_url .. self._query_cloud_phone_check .. suffix
    HTTPRequest(url, function(success, response, code)
        if not success then
            return
        end
        -- body
        local jsonData = cjson.decode(response)
        if not jsonData or not jsonData.data then
            return
        end
        
        --[[
            data: {
                expireTime = 0,     --活动过期时间， 时间戳: 秒
                rewardTime = 0,     --云机奖励时间   秒
                receiveDevice = true, -- 是否已领取
            }
        ]]

        local data = {
            expireTime = tonumber(jsonData.data.expireTime) or 0,
            rewardTime = tonumber(jsonData.data.rewardTime) or 0,
            receiveDevice = jsonData.data.receiveDevice == true,
        }

        self._cloud_phone_down_time = data.expireTime
        self._cloud_phone_time = data.rewardTime
        self._cloud_phone_flag = data.receiveDevice

        self._cloud_phone_show = data.expireTime > 0 

        global.Facade:sendNotification(global.NoticeTable.Layer_Box996Main_Refresh, {
            isCloudPhoneBtn = true,
            value = self._cloud_phone_show
        })

        global.Facade:sendNotification(global.NoticeTable.Layer_Box996CloudPhone_Refresh, {
            getTime = self._cloud_phone_down_time,
            rewardTime = self._cloud_phone_time,
        })
    end)
end

-- 请求领取云手机奖励时间
function Box996Proxy:requestCloudPhoneReceive()
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local userid = tonumber(AuthProxy:GetUID()) or 0
    local gameid = global.L_ModuleManager:GetCurrentModule():GetOperID()
    local data = {
        userId = userid,
        gameId = gameid,
    }

    local param = getSVIPParam(data, true)
    local suffix = string.format("?rqtime=%s&rqrandom=%s&sign=%s", param.rqtime, param.rqrandom, param.sign)
    local url = self._cloud_pohe_base_url .. self._query_cloud_phone_receive .. suffix
    self:HTTPRequestPostSVIP(url, function(success, response)
        local jsonData = {}
        if response and string.len(response) > 0 then
            releasePrint(response)
            jsonData = cjson.decode(response)
        end

        -- 是否成功
        self._cloud_phone_flag = jsonData.data == true
        
        -- 刷新
        global.Facade:sendNotification(global.NoticeTable.Layer_Box996CloudPhone_Refresh, {
            getFinish = true,
        })

    end, param.valEncode)
end
-----------------------------------------------cloud phone   end--------------------------------

-----------------------------------------------埋点       begin---------------------------------
-- 请求数据上报
-- eventID 上报事件
function Box996Proxy:requestLogUp(eventID)
    if not eventID then
        return
    end

    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local userid = AuthProxy:GetUID()
    local logUpTime = math.floor(socket.gettime() * 1000) -- 时间戳  毫秒13位
    local gameid = global.L_ModuleManager:GetCurrentModule():GetOperID()
    local data = {{
        key = "i",
        value = eventID
    }, {
        key = "d",
        value = {
            uid = userid,
            gameid = gameid
        }
    }, {
        key = "t",
        value = tostring(logUpTime)
    }}

    local header = getLogUpHeader()
    local sendParam = getLogUpSuffix(data)
    local url = self._log_url .. self._log_query

    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("POST", url)
    if header then
        for k, v in pairs(header) do
            httpRequest:setRequestHeader(k, v)
        end
    end

    local function HttpResponseCB()
        local code = httpRequest.status
        local success = code >= 200 and code < 300
        local response = httpRequest.response
        release_print("Http Request Code:" .. tostring(code))
        release_print("response:" , response)
    end
    httpRequest:setRequestHeader("Content-type", "application/json")
    httpRequest:registerScriptHandler(HttpResponseCB)
    httpRequest:send(sendParam)
end

------------------------------------------------埋点        end----------------------------------

--  服务端返回盒子礼包内容
function Box996Proxy:handle_MSG_SC_SENDBOXGIFTLIST_RESPON(msg)
    self._login_qequist_count = self._login_qequist_count + 1
    local data = ParseRawMsgToJson(msg)
    if not data then
        return
    end

    self._box_data.BoxTitleID = tonumber(data.BoxTitleID)
    if self._box_data.BoxTitleID and self._box_data.BoxTitleID > 0 then
        self._box_data.BoxTitleID = self._box_data.BoxTitleID + 5099
    end
    self._box_data.BoxTitle = data.BoxTitle
    self._box_data.BoxGift = data.BoxGift

    self._box_data.BoxGuide = data.BoxGuide

    if self._login_qequist_count == 2 then
        global.Facade:sendNotification(global.NoticeTable.Layer_Box996EveryDay_Refresh, self._box_data)
        global.Facade:sendNotification(global.NoticeTable.Layer_Box996Super_Refresh, self._box_data)
        global.Facade:sendNotification(global.NoticeTable.Layer_Box996VIP_Refresh, self._box_data)
        global.Facade:sendNotification(global.NoticeTable.Layer_Box996Title_Refresh, self._box_data)
    end
    global.Facade:sendNotification(global.NoticeTable.Layer_Box996Main_Refresh)
end

-- 服务端返回盒子礼包领取状态
--  param1：自身称号显示状态
--  param2：他人称号显示状态
--  param3：是否盒子登录
--  msg：礼包领取状态：结构：1=0,2=0
function Box996Proxy:handle_MSG_SC_SENDBOXGIFTSTATE_RESPON(msg)
    self._login_qequist_count = self._login_qequist_count + 1
    local msgLen = msg:GetDataLength()
    local msgHdr = msg:GetHeader()

    local refreshNotice = {
        [global.NoticeTable.Layer_Box996EveryDay_Refresh] = 1,
        [global.NoticeTable.Layer_Box996Super_Refresh] = 1,
        [global.NoticeTable.Layer_Box996VIP_Refresh] = 1,
        [global.NoticeTable.Layer_Box996Title_Refresh] = 1
    }

    if msgLen > 0 then
        if not self._box_data.gifGet then
            self._box_data.gifGet = {}
        end

        local dataString = SL:GBKToUTF8(msg:GetBodyLuaBuffer():ReadString())
        local dataStrArray = G_GetSplitArray(dataString, ",")
        local gifGet = {}
        for i, v in ipairs(dataStrArray) do
            if v and v ~= "" then
                local kv = G_GetSplitArray(v, "=")
                if tonumber(kv[1]) and tonumber(kv[2]) then
                    gifGet[tonumber(kv[1])] = tonumber(kv[2])
                end
            end
        end

        if gifGet[1] ~= self._box_data.gifGet[1] then -- 刷新
            self._box_data.gifGet[1] = gifGet[1]
            global.Facade:sendNotification(global.NoticeTable.Layer_Box996EveryDay_Refresh, self._box_data)
            refreshNotice[global.NoticeTable.Layer_Box996EveryDay_Refresh] = nil
        end
        if gifGet[3] ~= self._box_data.gifGet[3] then -- 超级礼包刷新
            self._box_data.gifGet[3] = gifGet[3]
            global.Facade:sendNotification(global.NoticeTable.Layer_Box996Super_Refresh, self._box_data)
            refreshNotice[global.NoticeTable.Layer_Box996Super_Refresh] = nil
        end
        if gifGet[4] ~= self._box_data.gifGet[4] then -- vip刷新
            self._box_data.gifGet[4] = gifGet[4]
            global.Facade:sendNotification(global.NoticeTable.Layer_Box996VIP_Refresh, self._box_data)
            refreshNotice[global.NoticeTable.Layer_Box996VIP_Refresh] = nil
        end
        self._box_data.gifGet = gifGet
    end

    local isupdateTitle = false
    if (not self._box_data.sState) == (msgHdr.param1 == 1) then
        self._box_data.sState = msgHdr.param1 == 1
        isupdateTitle = true

        -- 996 盒子称号（自己）
        self:Set996BoxTitle(true)
    end

    if (not self._box_data.oState) == (msgHdr.param2 == 1) then
        self._box_data.oState = msgHdr.param2 == 1
        isupdateTitle = true

        -- 996 盒子称号（别人）
        self:Set996BoxTitle()
    end

    self._box_data.isBoxOpen = msgHdr.param3 == 1

    if isupdateTitle then
        global.Facade:sendNotification(global.NoticeTable.Layer_Box996Title_Refresh, self._box_data)
        refreshNotice[global.NoticeTable.Layer_Box996Title_Refresh] = nil
    end

    if self._login_qequist_count == 2 then
        for k, v in pairs(refreshNotice) do
            if v then
                global.Facade:sendNotification(k, self._box_data)
            end
        end
    end
end

function Box996Proxy:Set996BoxTitle(isMySelf)
    local optionsUtils = requireUtil("optionsUtils")
    if isMySelf then
        local mainPlayer = global.gamePlayerController:GetMainPlayer()
        if mainPlayer then
            optionsUtils:InitHUDVisibleValue(mainPlayer, global.MMO.HUD_TITLE_VISIBLE)
            optionsUtils:RefreshHUDTitleVisible(mainPlayer)
        end
    else
        local playerVec, nPlayer = global.playerManager:GetAllPlayerInCurrViewField()
        for i = 1, nPlayer do
            local player = playerVec[i]
            if player then
                optionsUtils:InitHUDVisibleValue(player, global.MMO.HUD_TITLE_VISIBLE)
                optionsUtils:RefreshHUDTitleVisible(player)
            end
        end
    end
end

-- 领取礼包返回的提示
function Box996Proxy:handle_MSG_SC_GET_AWARD_STATET_RESPON(msg)
    local titleStr = ""
    local msgHdr = msg:GetHeader()
    if msgHdr.param1 == 2 then
        -- 领取成功
        titleStr = GET_STRING(310000412)

    elseif msgHdr.param1 == 6 then
        -- 已领取过该礼包
        titleStr = GET_STRING(310000416)

    elseif msgHdr.param1 == 7 then
        -- 对不起礼包码填写错误
        titleStr = GET_STRING(310000417)

    elseif msgHdr.param1 == 8 then
        -- 无法使用该礼包码
        titleStr = GET_STRING(310000418)

    elseif msgHdr.param1 == 9 then
        -- 未从盒子登录，无法领取该礼包
        titleStr = GET_STRING(310000419)

    elseif msgHdr.param1 == 10 then
        -- 账号不存在
        titleStr = GET_STRING(310000420)

    elseif msgHdr.param1 == 11 then
        -- 对不起，小号无法领取游戏礼包
        titleStr = GET_STRING(310000421)
        
    elseif msgHdr.param1 == 17 then
        -- 只有盒子会员才能领取
        titleStr = GET_STRING(310000427)

    elseif msgHdr.param1 == 18 then
        -- 盒子会员过期
        titleStr = GET_STRING(310000428)

    else
        titleStr = GET_STRING(310000499)
    end

    if titleStr and titleStr ~= "" then
        local data = {}
        data.str = titleStr
        data.btnType = 1
        UIOperator:OpenCommonTipsUI(data)
    end
end

function Box996Proxy:RegisterMsgHandler()
    Box996Proxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_SENDBOXGIFTLIST_RESPON,
        handler(self, self.handle_MSG_SC_SENDBOXGIFTLIST_RESPON))
    LuaRegisterMsgHandler(msgType.MSG_SC_SENDBOXGIFTSTATE_RESPON,
        handler(self, self.handle_MSG_SC_SENDBOXGIFTSTATE_RESPON))
    LuaRegisterMsgHandler(msgType.MSG_SC_GET_AWARD_STATET_RESPON,
        handler(self, self.handle_MSG_SC_GET_AWARD_STATET_RESPON))
end

return Box996Proxy
