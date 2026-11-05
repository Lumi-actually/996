local RemoteProxy = requireProxy("RemoteProxy")
local TradingBankProxy = class("TradingBankProxy", RemoteProxy)
TradingBankProxy.NAME = global.ProxyTable.TradingBankProxy


local cjson = require("cjson")
local basehost = "http://charge-api.996box.com" --正式1 --[["http://charge-api.pre.xqhuyu.com"--生产2]] --[["http://charge-api-test.996box.com"--测试3]]
local host = basehost .. "/gameapi/"
local signkey = "7PZJImoeAE5Dnjb6pCYu8Ja5Buhb2urL"
local PhoneHost = "http://user-api.996box.com/v1/UserInfo/" --正式 --[["http://user-api.pre.xqhuyu.com/v1/UserInfo/"--生产]]  --[["http://boxuser-dev.dhsf.xqhuyu.com/v1/UserInfo/"--测试]]
local hostIndex = 1
local uploadHost = "http://uploads.996box.com/cdnapp/upload.php"
local upEquiploadHost = "http://uploads.996box.com/cdnapp/uploadGameEquip.php"

local hostSeekBuy = basehost .. "/gamePurchase/"

local function getHeader()
    local header = {}
    header["Content-Type"] = "application/json"
    return header
end
local function getParam(val)
    local originData = {}
    for k, v in pairs(val) do
        if k ~= "token" then
            table.insert(originData, { key = k, value = v })
        end
    end
    table.sort(originData, function(a, b)
        return a.key < b.key
    end)
    -- dump(originData,"originData___")
    -- 计算sign
    local origin = ""
    for i, v in ipairs(originData) do
        -- origin = origin .. string.format("%s=%s", v.key, v.value)
        -- origin = origin .. (i < #originData and "&" or "")
        -- dump(type(v.value),"type___")
        -- dump(v.value,"number__")
        if type(v.value) == "string" or type(v.value) == "number" then
            origin = origin .. v.value
        elseif type(v.value) == "table" then
            -- for i2,v2 in ipairs(v.value) do
            local str = cjson.encode(v.value)
            str = string.gsub(str, "\\/", "/")
            origin = origin .. str
            -- end

        end
    end
    local rqtime = os.time()
    -- dump(origin..signkey..rqtime,"qqqqqqqqqqqqqqqqqqq")
    local md5 = get_str_MD5(origin .. signkey .. rqtime)
    -- dump(md5,"md5______")

    val.sign = md5
    val.rqtime = rqtime
    return cjson.encode(val), md5, rqtime

end

local EquipOptState = {
    Sell = 1,
    Up = 2,
    Down = 3,
    Modify = 4,
    Get = 5,
}

local CommodityType = {
    Role = 1,
    Money = 2,
    Equip = 3
}

function TradingBankProxy:ctor()
    TradingBankProxy.super.ctor(self)
    self.m_userData = {}
    self.m_moneyData = {}
    self.m_yzToken = nil
    self.m_HelpText = ""
    self.m_http_layer = {}

    self.AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    self.loginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    self.m_tradingStatus = false --交易行开启状态
    self._tipsIndex = 1

    local TradingBankEnvironment = self:GetCustomDataByKey("TradingBankEnvironment")
    if TradingBankEnvironment and string.len(TradingBankEnvironment) > 0 then 
        TradingBankEnvironment = tonumber(TradingBankEnvironment)
        if TradingBankEnvironment == 0 then--新增测试环境盒子签名密钥
            signkey = "1BDC60CAEA65459187113B8B92FCB012"
        end
    end

    local TradingBankDoamin =  self:GetCustomDataByKey("TradingBankDoamin")
    if TradingBankDoamin and string.len(TradingBankDoamin) > 0 then 
        basehost = TradingBankDoamin
    end
    host        = basehost .. "/gameapi/"
    hostSeekBuy = basehost .. "/gamePurchase/"

    local TradingBankPhoneDoamin =  self:GetCustomDataByKey("TradingBankPhoneDoamin")
    if TradingBankPhoneDoamin and string.len(TradingBankPhoneDoamin) > 0 then 
        PhoneHost = TradingBankPhoneDoamin .. "/v1/UserInfo/"
    end

    local UploadTradingBankImageDomin =  self:GetCustomDataByKey("UploadTradingBankImageDomin")
    if UploadTradingBankImageDomin and string.len(UploadTradingBankImageDomin) > 0 then 
        uploadHost = UploadTradingBankImageDomin .. "/cdnapp/upload.php"
        upEquiploadHost = UploadTradingBankImageDomin .. "/cdnapp/uploadGameEquip.php"
    end
    global.IsConsignmentRole = false
    self:readToken()
end

function TradingBankProxy:GetCustomDataByKey(key)
    local currentModule = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv = currentModule:GetGameEnv()
    local customData    = moduleGameEnv:GetCustomData()

    if not customData then
        return nil
    end
    return customData[key]
end

function TradingBankProxy:getOpenStatus()
    return self.m_tradingStatus
end

function TradingBankProxy:setOpenStatus(isOpen)
    self.m_tradingStatus = isOpen
end

function TradingBankProxy:init()
    self.MoneyProxy = global.Facade:retrieveProxy(global.ProxyTable.MoneyProxy)
    self.MoneyType = self.MoneyProxy.MoneyType
    self.PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    self.HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
end

function TradingBankProxy:GetEquipOptState()
    return EquipOptState
end

function TradingBankProxy:GetCommodityType()
    return CommodityType
end
--获取验证后的token
function TradingBankProxy:getToken()
    --"noToken"--
    return self.m_yzToken or "noToken"
end

function TradingBankProxy:saveToken()
    local isBoxLogin    = global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin") == 1 --盒子登录
    if global.isWindows and isBoxLogin then 
        local path = global.FileUtilCtl:getDefaultResourceRootPath()
        local fileName = path .. "TradingBank"
        local jsonStr = cjson.encode({token = self.m_yzToken})
        if global.FileUtilCtl:isFileExist(fileName) then 
            global.FileUtilCtl:removeFile(fileName)
        end
        global.FileUtilCtl:writeStringToFile(jsonStr,fileName)
    else 
        local key       = "TradingBank_token"
        self:getUserDefaultInstance():setStringForKey(key, self.m_yzToken )
    end
end

function TradingBankProxy:readToken()
    local isBoxLogin    = global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin") == 1 --盒子登录
    if global.isWindows and isBoxLogin then 
        local path = global.FileUtilCtl:getDefaultResourceRootPath()
        local fileName = path.. "TradingBank"
        if not global.FileUtilCtl:isFileExist(fileName) then 
            self.m_yzToken = "noToken"
        else
            local jsonStr = global.FileUtilCtl:getDataFromFileEx(fileName)
            local json = cjson.decode(jsonStr)
            if json and json.token then 
                self.m_yzToken = json.token
            else 
                self.m_yzToken = "noToken"
            end 
        end
    else 
        local key       = "TradingBank_token"
        self.m_yzToken = self:getUserDefaultInstance():getStringForKey(key,"noToken")
    end
    if self.m_yzToken == "" then 
        self.m_yzToken = "noToken"
    end
end
function TradingBankProxy:getUserDefaultInstance()
    if not cc.UserDefault:isXMLFileExist() then 
        cc.UserDefault:destroyInstance()
    end
    return cc.UserDefault:getInstance()
end
function TradingBankProxy:clearToken()
    self.m_yzToken = "noToken"
    self:saveToken()
end

function TradingBankProxy:onRegister()
    TradingBankProxy.super.onRegister(self)
end

function TradingBankProxy:RegisterMsgHandler()
    TradingBankProxy.super.RegisterMsgHandler(self)
    local msgType    = global.MsgType
    --返回登陆
    if not global.OtherTradingBank then 
        
        LuaRegisterMsgHandler(msgType.MSG_SC_SELLROLESUCCESS_LOGOUT, handler(self, self.handle_MSG_SC_SELLROLESUCCESS_LOGOUT))----寄售角色成功 退出
        LuaRegisterMsgHandler(msgType.MSG_SC_CHECKBOXSELLITEM, handler(self, self.handle_MSG_SC_CHECKBOXSELLITEM))----返回检测道具是否可以上架
        LuaRegisterMsgHandler(msgType.MSG_SC_QUERYBOXSELLITEM, handler(self, self.handle_MSG_SC_QUERYBOXSELLITEM))----查询交易行装备tips
    end
end
function TradingBankProxy:GetTipsIndex()
    self._tipsIndex = self._tipsIndex + 1
    return self._tipsIndex
end
--查询道具数据
function TradingBankProxy:ReqQueryItemData(commodity_id, tipsIndex)
    dump({commodity_id, tipsIndex}, "ReqQueryItemData____")
    LuaSendMsg(global.MsgType.MSG_CS_QUERYBOXSELLITEM, 0, commodity_id, tipsIndex)--查询交易行装备tips
end
--装备能否上架
function TradingBankProxy:ReqCheckEquipIsCanSell(makeIndex)
    LuaSendHeader6(global.MsgType.MSG_CS_CHECKBOXSELLITEM, makeIndex)
end
--装备能否上架返回
function TradingBankProxy:handle_MSG_SC_CHECKBOXSELLITEM(msg)
    local msgHdr = msg:GetHeader()
    -- recog：1为成功
    -- -1：道具不存在
    -- -2：禁止上架
    -- -3：脚本禁止上架
    -- -4：道具删除失败
    dump(msgHdr,"handle_MSG_SC_CHECKBOXSELLITEM___")
    local recog = msgHdr.recog
    if recog == 1 then 
        global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankUpModifyEquipPanel_CheckSuccess)
    elseif recog == -1 then 
        ShowSystemTips(GET_STRING(600000621))
    elseif recog == -2 then 
        ShowSystemTips(GET_STRING(600000622))
    elseif recog == -3 then 
        ShowSystemTips(GET_STRING(600000623))
    elseif recog == -4 then 
        ShowSystemTips(GET_STRING(600000623))
        
    end

end
--查询交易行装备tips
function TradingBankProxy:handle_MSG_SC_QUERYBOXSELLITEM(msg)
    local msgHdr = msg:GetHeader()
    local msgLen = msg:GetDataLength()
    if msgLen == 0 then 
        ShowSystemTips(GET_STRING(600000626))
        return 
    end
    local data = ParseRawMsgToJson(msg)
    
    -- recog：订单ID
    -- msg  道具信息（为空时表示该道具不存在或已被购买）
    local itemMakeIndex = data.MakeIndex or data.makeindex
    data = ChangeItemServersSendDatas(data)
    local tipsIndex
    if msgHdr.param1 ~= 0 then 
        tipsIndex = msgHdr.param1
    end
    dump(tipsIndex,"tipsIndex__")
    global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankBuyEquip_Tips, {itemData = data, tipsIndex = tipsIndex})
    dump(data,"handle_MSG_SC_QUERYBOXSELLITEM___22222")
end

function TradingBankProxy:handle_MSG_SC_SELLROLESUCCESS_LOGOUT(msg)
    if global.IsVisitor then
        return
    end
    global.IsConsignmentRole = true
    global.userInputController:SetKeyboardAble(true)
    global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankTipsLayer_Open, { callback = function(code)
        if code == 1 then
            global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankTipsLayer_Close)
            global.gameWorldController:OnGameLeaveWorld()
        end
    end, notcancel = true,exitTime = 5, txt = GET_STRING(600000448), btntext = { GET_STRING(800802) } })

end

function TradingBankProxy:reqUserData(layer, func)--请求用户数据
    local url = host .. "getUser"--userInfo
    local jData = {
        uid     = tonumber(self.AuthProxy:GetUID()),
    }
    local param = getParam(jData)
    local header = getHeader()

    self:HTTPRequestPost(url, function(success, response, code)
        dump({ success, response, code }, "reqUserData___")
        if success then
            local data = cjson.decode(response)
            if data.code == 200 then
                self:setUserData(data.data)
                func(data.data)
            end

        end
    end, param, header, layer)
end
function TradingBankProxy:setUserData(data)
    dump(data, "setUserData__")
    self.m_userData = data
end
function TradingBankProxy:setMoneyData(data)
    dump(data, "setMoneyData__")
    self.m_moneyData = data
end
function TradingBankProxy:getMoneyData()
    return self.m_moneyData
end
function TradingBankProxy:isBindPhone()
    if self.m_userData and self.m_userData.phone and string.len(self.m_userData.phone) > 0 then
        return true
    else
        return false
    end
end
function TradingBankProxy:setPhone(phone)
    if not self.m_userData then
        self.m_userData = {}
    end
    self.m_userData.phone = phone
end
function TradingBankProxy:getPhone()
    if self.m_userData then
        return self.m_userData.phone
    end
end

function TradingBankProxy:reqYZPhone(layer, phone, yzm, func)--请求验证或者绑定手机
    local url = PhoneHost .. "checkBindPhone"
    local jData = {
        uid        = tonumber(self.AuthProxy:GetUID()),
        code       = yzm,
        game_token = self.AuthProxy:GetToken()
    }
    if phone then 
        jData.phone = tonumber(phone)
    end
    local header = getHeader()
    local param = getParam(jData)
    self:HTTPRequestPost(url, function(success, response, code)
        dump({ success, response, code }, "reqYZPhone__")
        if success then
            local resData = cjson.decode(response)
            if resData.code == 200 then
                if phone then
                    self:setPhone(phone)
                end
                self.m_yzToken = resData.data.token
                self:saveToken()
            end
            func(success, response, code)
        end
    end, param, header, layer)
end
-- 绑定手机验证码
function TradingBankProxy:reqBindPhone(layer, phone, func)
    local url = PhoneHost .. "get_phone_code"
    local originData = {
        phone = tonumber(phone),
        type = "jyh_identity"
    }
    local header = getHeader()
    local param = getParam(originData)
    self:HTTPRequestPost(url, function(success, response, code)
        dump({ success, response, code }, "reqBindPhone__")
        if success then
            func(success, response, code)
        end
    end, param, header, layer)
end

--验证码新
function TradingBankProxy:reqGetCode(layer, func)
    local url = PhoneHost .. "get_phone_code_new"
    local originData = {
        uid =  self.AuthProxy:GetUID(),
        type = "jyh_identity"
    }
    local header = getHeader()
    local param = getParam(originData)
    self:HTTPRequestPost(url, function(success, response, code)
        dump({ success, response, code }, "ReqGetCode____")
        if success then
            func(success, response, code)
        end
    end, param, header, layer)
end
--卖装备
function TradingBankProxy:sellEquip(layer, val, func)
    self.PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local url = host .. "sellEquip"
    local jData = {
        uid         = self.AuthProxy:GetUID(),
        game_id     = tonumber(self.AuthProxy:getGameId()),
        server_id   = tonumber(self.loginProxy:GetSelectedServerId()),
        server_name = self.loginProxy:GetSelectedServerName(),
        role_id     = global.gamePlayerController:GetMainPlayerID(),
        role        = self.PlayerProperty:GetName(),
        sex         = self.PlayerProperty:GetRoleSex(),
        vip         = 0,
        role_level  = tonumber(self.PlayerProperty:GetRoleLevel()),
        token       = self:getToken()
    }
    -- price 
    -- target_rolename
    -- coin_num
    -- coin_id
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    -- dump(jData,"jData___")
    self:HTTPRequestPost(url, function(success, response, code)
        dump({ success, response, code }, "sellMoney___")
        func(success, response, code)
    end, param, header, layer)
end
--卖货币
function TradingBankProxy:sellMoney(layer, val, func)
    self.PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local url = host .. "sellCoin"
    local jData = {
        uid         = self.AuthProxy:GetUID(),
        game_id     = tonumber(self.AuthProxy:getGameId()),
        server_id   = tonumber(self.loginProxy:GetSelectedServerId()),
        server_name = self.loginProxy:GetSelectedServerName(),
        role_id     = global.gamePlayerController:GetMainPlayerID(),
        role        = self.PlayerProperty:GetName(),
        vip         = 0,
        role_level  = tonumber(self.PlayerProperty:GetRoleLevel()),
        token       = self:getToken()
    }
    -- price 
    -- target_rolename
    -- coin_num
    -- coin_id
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    -- dump(jData,"jData___")
    self:HTTPRequestPost(url, function(success, response, code)
        dump({ success, response, code }, "sellMoney___")
        func(success, response, code)
    end, param, header, layer)
end
--卖角色
function TradingBankProxy:sellRole(layer, data, func)
    self.PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    self.HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    local url = host .. "sellAccount"
    local jData = {
        uid         = self.AuthProxy:GetUID(),
        game_id     = self.AuthProxy:getGameId(),
        server_id   = self.loginProxy:GetSelectedServerId(),
        server_name = self.loginProxy:GetSelectedServerName(),
        role_id     = global.gamePlayerController:GetMainPlayerID(),
        role        = self.PlayerProperty:GetName(),
        sex         = self.PlayerProperty:GetRoleSex(),
        vip         = 0,
        role_level  = self.PlayerProperty:GetRoleLevel(),
        ablity      = 0, --战力
        role_type   = self.PlayerProperty:GetRoleJob(),
        token       = self:getToken(),
        new_version = global.IsNewBoxSellVersion and 1 or 0, --是否是支持收货验证版本
    }
    if self.HeroPropertyProxy then
        if self.HeroPropertyProxy:IsHeroOpen() and SL:GetValue("HERO_IS_ACTIVE") and self.HeroPropertyProxy:HeroIsLogin() then
            jData.hero_type     = self.HeroPropertyProxy:GetRoleJob() or 0
            jData.hero_level    = self.HeroPropertyProxy:GetRoleLevel() or 1
            jData.hero_sex      = self.HeroPropertyProxy:GetRoleSex() or 0
            jData.hero_id       = self.HeroPropertyProxy:GetRoleUID() or ""
            jData.hero          = self.HeroPropertyProxy:GetName() or ""
        end
    end
    for k, v in pairs(data) do
        jData[k] = v
    end
    -- price
    -- target_rolename
    local param = getParam(jData)
    local header = getHeader()
    -- dump(jData,"jData___")
    self:HTTPRequestPost(url, function(success, response, code)
        dump({ success, response, code }, "sellRole___")
        func(success, response, code)
    end, param, header, layer)
end
--获取商品信息
--type    是   int 商品类型 1角色2货币
--role_id 否   int 角色ID 获取指定我商品时传 废弃了
--page    否   int 当前页 不传默认第一页
--pagenum 否   int 每页条数 不传默认10条
--role_type    否 int 角色类型 0战1法2道
--coin_config_id 否 int  货币ID
--order_price 否 string asc 或 desc 价格排序
--order_level
--order_coin_num
function TradingBankProxy:getGoodsInfo(layer, data, func)
    dump({ data, func }, "getGoodsInfo")
    local url = host .. "commodityList"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
        server_id  = self.loginProxy:GetSelectedServerId(),
        uid        = self.AuthProxy:GetUID(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end

    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer, true)
end
--求购列表
function TradingBankProxy:getSeekBuyInfo(layer, data, func)
    dump({ data, func }, "getSeekBuyInfo")
    local url = hostSeekBuy .. "purchaseList"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
        server_id  = self.loginProxy:GetSelectedServerId(),
        uid        = self.AuthProxy:GetUID(),
        token      = self:getToken()
    }
    for k, v in pairs(data) do
        jData[k] = v
    end

    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer, true)
end
--我的收藏
function TradingBankProxy:getMyPurchaseCollection(layer, data, func)
    dump({ data, func }, "getMyPurchaseCollection")
    local url = hostSeekBuy .. "myPurchaseCollection"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
        server_id  = self.loginProxy:GetSelectedServerId(),
        uid        = self.AuthProxy:GetUID(),
        token      = self:getToken()
    }
    for k, v in pairs(data) do
        jData[k] = v
    end

    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer, true)
end

--求购收藏/取消
function TradingBankProxy:getPurchaseCollection(layer, data, func)
    dump({ data, func }, "getPurchaseCollection")
    local url = hostSeekBuy .. "purchaseCollection"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
        server_id  = self.loginProxy:GetSelectedServerId(),
        uid        = self.AuthProxy:GetUID(),
        token      = self:getToken()
    }
    for k, v in pairs(data) do
        jData[k] = v
    end

    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer, true)
end

--计算手续费
function TradingBankProxy:getServiceAmount(layer, data, func)
    dump({ data, func }, "getServiceAmount")
    local url = hostSeekBuy .. "serviceAmount"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
        server_id  = self.loginProxy:GetSelectedServerId(),
        uid        = self.AuthProxy:GetUID(),
        token      = self:getToken()
    }
    for k, v in pairs(data) do
        jData[k] = v
    end

    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer, true)
end

--供应装备
function TradingBankProxy:getSupplyEquip(layer, data, func)
    dump({ data, func }, "getSupplyEquip")
    local url = hostSeekBuy .. "supplyEquip"
    local jData = {
        game_id     = self.AuthProxy:getGameId(),
        server_id   = self.loginProxy:GetSelectedServerId(),
        server_name = self.loginProxy:GetSelectedServerName(),
        uid         = self.AuthProxy:GetUID(),
        token       = self:getToken()
    }
    for k, v in pairs(data) do
        jData[k] = v
    end

    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer, true)
end

--供应货币
function TradingBankProxy:getSupplyCoin(layer, data, func)
    dump({ data, func }, "getSupplyCoin")
    local url = hostSeekBuy .. "supplyCoin"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
        server_id  = self.loginProxy:GetSelectedServerId(),
        server_name = self.loginProxy:GetSelectedServerName(),
        uid        = self.AuthProxy:GetUID(),
        token      = self:getToken()
    }
    for k, v in pairs(data) do
        jData[k] = v
    end

    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer, true)
end
--发起求购
function TradingBankProxy:PurchaseRequest(layer,data,func)
 local url = hostSeekBuy .. "purchase"
    local jData = {
            role_id     =  global.gamePlayerController:GetMainPlayerID(),
            token       = self:getToken(),
            uid         = self.AuthProxy:GetUID(),
            role_name   = self.PlayerProperty:GetName(),
            server_name = self.loginProxy:GetSelectedServerName(),
            server_id   = self.loginProxy:GetSelectedServerId(),
            game_id     = self.AuthProxy:getGameId(),
        }
    for k,v in pairs(data) do
        jData[k] = v
    end
    local param =  getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer, true)
end


--装备类型列表
function TradingBankProxy:getEquipTypeList(layer, data, func)
    dump({ data, func }, "getEquipTypeList")
    local url = hostSeekBuy .. "equipTypeList"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
        server_id  = self.loginProxy:GetSelectedServerId(),
        uid        = self.AuthProxy:GetUID(),
        token      = self:getToken()
    }
    for k, v in pairs(data) do
        jData[k] = v
    end

    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer, true)
end

--装备列表
function TradingBankProxy:getEquipList(layer, data, func)
    dump({ data, func }, "getEquipList")
    local url = hostSeekBuy .. "equipList"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
        server_id  = self.loginProxy:GetSelectedServerId(),
        uid        = self.AuthProxy:GetUID(),
        token      = self:getToken()
    }
    for k, v in pairs(data) do
        jData[k] = v
    end

    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer, true)
end
--求购配置
function TradingBankProxy:getPurchaseConfig(layer, data, func)
    dump({ data, func }, "getPurchaseConfig")
    local url = hostSeekBuy .. "purchaseConfig"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
        server_id  = self.loginProxy:GetSelectedServerId(),
        uid        = self.AuthProxy:GetUID(),
        token      = self:getToken()
    }
    for k, v in pairs(data) do
        jData[k] = v
    end

    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer, true)
end
--请求支付 求购交易币
function TradingBankProxy:reqpayPurchaseOrder(layer, val, func)
    local url = hostSeekBuy .. "pay/balance"
    local jData = {
        token = self:getToken(),
        uid        = self.AuthProxy:GetUID(),
    }
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--请求支付 二维码支付
function TradingBankProxy:reqpayPurchaseOrderEWM(layer, val, func)
    local url = hostSeekBuy .. "pay/qrcode"
    local jData = {
        token = self:getToken(),
        uid        = self.AuthProxy:GetUID(),
    }
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()

    self:HTTPRequestPostEWM(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end

--请求支付 h5支付
function TradingBankProxy:reqpayPurchaseH5Order(layer, val, func)
    local url = hostSeekBuy .. "pay/wap"
    local jData = {
        token = self:getToken(),
        uid        = self.AuthProxy:GetUID(),
    }
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end


----请求支付 跳转支付宝app支付
function TradingBankProxy:reqPurchaseOrderApp(layer, val, func)
    local url = hostSeekBuy .. "pay/app"
    local jData = {
        token = self:getToken(),
        uid        = self.AuthProxy:GetUID(),
    }
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end


--查询支付状态
function TradingBankProxy:reqPurchaseOrderStatus(layer, val, func)
    local url = hostSeekBuy .. "pay/status"
    local jData = {
        token = self:getToken(),
        uid        = self.AuthProxy:GetUID(),
    }
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end

--获取指定我的商品  type类型 1角色2货币
function TradingBankProxy:getTargetGoodsInfo(layer, data, func)
    dump({ data, func }, "getGoodsInfo")
    local url = host .. "targetCommodity"
    local jData = {
        uid        = self.AuthProxy:GetUID(),
        game_id    = self.AuthProxy:getGameId(),
        server_id  = self.loginProxy:GetSelectedServerId(),
        role_id    = global.gamePlayerController:GetMainPlayerID(),
        token      = self:getToken()
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer, true)
end
--获取我的货架  type类型 1角色2货币 3装备
function TradingBankProxy:getMyGoodsInfo(layer, val, func)
    dump({ val, func }, "getGoodsInfo")
    local url = host .. "myCommodity"
    local jData = {
        uid        = self.AuthProxy:GetUID(),
        game_id    = self.AuthProxy:getGameId(),
        role_id    = global.gamePlayerController:GetMainPlayerID(),
        server_id  = self.loginProxy:GetSelectedServerId(),
        token      = self:getToken()
    }
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer, true)
end

--获取可 上交易行货币
function TradingBankProxy:reqMoneyData(layer, func)
    local url = host .. "coinType"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
    }
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        dump({ success, response, code }, "reqMoneyData")
        local nosuccess = false
        if success then
            local data = cjson.decode(response)
            if data.code == 200 then
                self:setMoneyData(data.data)
                if func then
                    func(data.data)
                end
            else
                nosuccess = true
            end
        else
            nosuccess = true
        end
        if nosuccess then
            local data = {}
            data.txt = GET_STRING(600000186)
            data.callback = function(res)
            end
            data.btntext = { GET_STRING(600000139) }
            global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankTipsLayer_Open, data)
        end

    end, param, header, layer)
end
--查询商品信息
function TradingBankProxy:reqcommodityInfo(layer, val, func)
    local url = host .. "commodityInfo"
    local jData = {
        token      = self:getToken(),
        uid        = self.AuthProxy:GetUID(),
    }
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        dump({ success, response, code }, "commodityInfo")
        func(success, response, code)
    end, param, header, layer)
end


--查询支付状态
function TradingBankProxy:reqOrderStatus(layer, val, func)
    local url = host .. "orderStatus"
    local jData = {
    }
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--请求支付
function TradingBankProxy:reqpayOrder(layer, val, func)
    local url = host .. "payOrder"
    local jData = {
        token = self:getToken(),
        uid        = self.AuthProxy:GetUID(),
        role_id    = global.gamePlayerController:GetMainPlayerID(),
    }
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end

function TradingBankProxy:reqpayOrderEWM(layer, val, func)
    local url = host .. "payOrder"
    local jData = {
        token = self:getToken(),
        uid        = self.AuthProxy:GetUID(),
        role_id    = global.gamePlayerController:GetMainPlayerID(),
    }
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()

    self:HTTPRequestPostEWM(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)

end


--上传图片
function TradingBankProxy:uploadImg(layer, val, func)
    local url = uploadHost
    local jData = {
        role_id    = global.gamePlayerController:GetMainPlayerID(),
    }
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = self:getBody(jData)
    self:HTTPRequestPostFile(url, function(success, response, code)
        func(success, response, code)
    end, param, nil, layer)
end
--上传装备图片
function TradingBankProxy:upEquiploadImg(layer, val, func)
    local url = upEquiploadHost
    local jData = {
        role_id    = global.gamePlayerController:GetMainPlayerID(),
    }
    for k, v in pairs(val) do
        jData[k] = v
    end
    local param = self:getBody(jData)
    self:HTTPRequestPostFile(url, function(success, response, code)
        func(success, response, code)
    end, param, nil, layer)
end

function TradingBankProxy:HTTPRequestPostFile(url, callback, data, header, layer)
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("POST", url)
    if header then
        for k, v in pairs(header) do
            httpRequest:setRequestHeader(k, v)
        end
    end
    if not self:findLayer(layer) then
        self:addLayer(layer)
    end
    if callback then
        local function HttpResponseCB()
            local code = httpRequest.status
            local success = code >= 200 and code < 300
            local response = httpRequest.response

            releasePrint("Http Request Code:" .. tostring(code))
            if self:findLayer(layer) then
                callback(success, response, code)
            end
        end
        httpRequest:setRequestHeader("Content-type", "multipart/form-data, boundary=upload_ymyzt")
        httpRequest:registerScriptHandler(HttpResponseCB)
    end
    httpRequest:send(data)
end
function TradingBankProxy:getBody(val)
    local role_id   = val.role_id
    local filename  = val.role_id .. "_" .. os.time() .. "_" .. val.position
    local file      = val.file
    local param, md5, rqtime = getParam(val)
    local body      = "--upload_ymyzt\r\n" ..
    "content-disposition: form-data; name=\"position\"\r\n" ..
    "\r\n" ..
    val.position .. "\r\n" ..
    "--upload_ymyzt\r\n" ..
    "content-disposition: form-data; name=\"role_id\"\r\n" ..
    "\r\n" ..
    val.role_id .. "\r\n" ..
    "--upload_ymyzt\r\n" ..
    "content-disposition: form-data; name=\"sign\"\r\n" ..
    "\r\n" ..
    md5 .. "\r\n" ..
    "--upload_ymyzt\r\n" ..
    "content-disposition: form-data; name=\"rqtime\"\r\n" ..
    "\r\n" ..
    rqtime .. "\r\n" ..
    "--upload_ymyzt\r\n" ..
    'content-disposition: form-data; name="file"; filename="' .. filename .. '"\r\n' ..
    "Content-Type: image/png\r\n" ..
    "\r\n" ..
    file .. "\r\n" ..
    "--upload_ymyzt--\r\n"

    return body
end
--上架
function TradingBankProxy:reqOnShelf(layer, data, func)
    local url = host .. "onShelf"
    local jData = {
        token = self:getToken(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--下架
function TradingBankProxy:reqDownShelf(layer, data, func)
    local url = host .. "downShelf"
    local jData = {
        token = self:getToken(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--修改价格
function TradingBankProxy:reqModifyPrice(layer, data, func)
    local url = host .. "modifyPrice"
    local jData = {
        token = self:getToken(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--取回
function TradingBankProxy:reqTakeBack(layer, data, func)
    local url = host .. "takeBack"
    local jData = {
        token = self:getToken(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--删除
function TradingBankProxy:reqDelete(layer, data, func)
    local url = host .. "delCommodity"
    local jData = {
        token = self:getToken(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--验证token
function TradingBankProxy:checkToken(layer, data, func)
    local url = host .. "checkToken"
    local jData = {
        token = self:getToken(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end


--查询账号
function TradingBankProxy:reqAccountInfo(layer, data, func)
    local url = host .. "checkUser"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
        server_id    = self.loginProxy:GetSelectedServerId(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
function TradingBankProxy:reqRoleInfo(layer, data, func)
    local url = host .. "roleInfo"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
        server_id    = self.loginProxy:GetSelectedServerId(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--下单
function TradingBankProxy:reqOrderPlace(layer, data, func)
    self.PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local url = host .. "orderPlace"
    local jData = {
        role_id     = global.gamePlayerController:GetMainPlayerID(),
        token       = self:getToken(),
        uid         = self.AuthProxy:GetUID(),
        role        = self.PlayerProperty:GetName(),
        level       = self.PlayerProperty:GetRoleLevel(),
        server_name = self.loginProxy:GetSelectedServerName(),
        server_id   = self.loginProxy:GetSelectedServerId(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
function TradingBankProxy:setHelpText(val)
    self.m_HelpText = val
end
function TradingBankProxy:getHelpText()
    return self.m_HelpText
end

--获取help
function TradingBankProxy:reqHelpText(layer, data, func)
    local url = basehost .. "/help.txt"
    if not self:findLayer(layer) then
        self:addLayer(layer)
    end
    HTTPRequest(url, function(success, response, code)
        dump({ success, response, code }, "reqHelpText__")
        if self:findLayer(layer) then
            local nosuccess = false
            if success then
                local data = cjson.decode(response)
                -- if data.code == 200 then
                dump(data, "help___")
                self:setHelpText(data)
                if func then
                    func(data)
                end
                -- end
            else
                nosuccess = true
            end
            if nosuccess then
                local data = {}
                data.txt = GET_STRING(600000186)
                data.callback = function(res)
                end
                data.btntext = { GET_STRING(600000139) }
                global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankTipsLayer_Open, data)
            end
        end
    end
    )
end
--获取交易币help
function TradingBankProxy:reqTradeCoinHelpText(layer, data, func)
    local url = basehost .. "/trade_coin.txt"
    if not self:findLayer(layer) then
        self:addLayer(layer)
    end
    HTTPRequest(url, function(success, response, code)
        dump({ success, response, code }, "reqTradeCoinHelpText__")
        if self:findLayer(layer) then
            local nosuccess = false
            if success then
                local data = cjson.decode(response)
                -- if data.code == 200 then
                dump(data, "text___")
                -- self:setHelpText(data)
                if func then
                    func(data)
                end
                -- end
            else
                nosuccess = true
            end
            if nosuccess then
                local data = {}
                data.txt = GET_STRING(600000186)
                data.callback = function(res)
                end
                data.btntext = { GET_STRING(600000139) }
                global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankTipsLayer_Open, data)
            end
        end
    end
    )
end
--取消订单
function TradingBankProxy:reqCancelorder(layer, data, func)
    local url = host .. "cancelPay"
    local jData = {
        token = self:getToken(),
        uid    = self.AuthProxy:GetUID(),
        role_id = global.gamePlayerController:GetMainPlayerID(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--取回角色
function TradingBankProxy:takeBackRole(layer, data, func)
    local url = host .. "takeBackRole"
    local jData = {
        token   = self:getToken(),
        uid     = self.AuthProxy:GetUID(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--角色是否有在售的货币
function TradingBankProxy:userCoinSell(layer, data, func)
    local url = host .. "userCoinSell"
    local jData = {
        token   = self:getToken(),
        uid     = self.AuthProxy:GetUID(),
        role_id = global.gamePlayerController:GetMainPlayerID(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--查询卖角色的996盒子货币
function TradingBankProxy:reqUserMoney(layer, data, func)
    local url = host .. "userMoney"
    local jData = {
        token   = self:getToken(),
        uid     = self.AuthProxy:GetUID(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--查询卖角色的配置
function TradingBankProxy:reqSellConfig(layer, data, func)
    local url = host .. "sellConfig"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
        token      = self:getToken(),
        uid        = self.AuthProxy:GetUID(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--收货/拒绝收货
function TradingBankProxy:reqReceivingRole(layer, data, func)
    local url = host .. "ReceivingRole"
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    self.PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local role = LoginProxy:GetSelectedRole()
    local order = role.ORDER
    local jData = {
        order_id    = order,
        token       = self:getToken(),
        uid         = self.AuthProxy:GetUID(),
        game_id     = self.AuthProxy:getGameId(),
        server_id   = tonumber(self.loginProxy:GetSelectedServerId()),
        server_name = self.loginProxy:GetSelectedServerName(),
        role_id     = global.gamePlayerController:GetMainPlayerID(),
        role        = self.PlayerProperty:GetName(),
        vip         = 0,
        role_level  = tonumber(self.PlayerProperty:GetRoleLevel()),
        ablity      = 0, --战力
        role_type   = self.PlayerProperty:GetRoleJob(),
        sex         = self.PlayerProperty:GetRoleSex()
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
--收货倒计时
function TradingBankProxy:reqGetReceivingCountdown(layer, data, func)
    local url = host .. "ReceivingCountdown"
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local role = LoginProxy:GetSelectedRole()
    local order = role.ORDER
    local jData = {
        order_id    = order,
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
-- 获取装备类型
function TradingBankProxy:reqEquipType(layer, data, func)
    local url = host .. "getEquipType"
    local jData = {
        game_id     = self.AuthProxy:getGameId(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end
-- 取回到可寄售间隔 (上架时效)
function TradingBankProxy:reqGetSellCDTime(layer, data, func)
    local url = host .. "onShelfLimit"
    local jData = {}
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end

function TradingBankProxy:getTradingBankStatus(data, func, isNotNeedLoading,isNotErrTips)
    local url = host .. "chargeState"
    local jData = {
        game_id    = self.AuthProxy:getGameId(),
    }
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost2(url, function(success, response, code)
        func(success, response, code)
    end, param, header, isNotNeedLoading,isNotErrTips)
end

function TradingBankProxy:getTxtConf(layer, data, func)
    local url = host .. "getTxtConf"
    local jData = {}
    for k, v in pairs(data) do
        jData[k] = v
    end
    local param = getParam(jData)
    local header = getHeader()
    self:HTTPRequestPost(url, function(success, response, code)
        func(success, response, code)
    end, param, header, layer)
end

function TradingBankProxy:HTTPRequestPost2(url, callback, data, header, isNotNeedLoading,isNotErrTips)
    dump({ url, callback, data, header }, "ssss____")
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("POST", url)
    if not isNotNeedLoading then 
        UIOperator:OpenLoadingBarUI()
    end
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
            if not isNotNeedLoading then 
                UIOperator:CloseLoadingBarUI()
            end
            releasePrint("Http Request Code:" .. tostring(code))
            releasePrint(success)
            if success then
                if pcall(cjson.decode, response) then
                    -- 没有错误
                else--数据异常
                    if not isNotErrTips then 
                        local data = {}
                        data.txt = GET_STRING(600000186)
                        data.callback = function(res)
                        end
                        data.btntext = { GET_STRING(600000139) }
                        global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankTipsLayer_Open, data)
                    end
                    return
                end
                callback(success, response, code)
            else--请求失败
                if not isNotErrTips then 
                    local data = {}
                    data.txt = GET_STRING(600000188)
                    data.callback = function(res)
                    end
                    data.btntext = { GET_STRING(600000139) }
                    global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankTipsLayer_Open, data)
                end
                return
            end
        end
        -- httpRequest:setRequestHeader("Content-type", "application/x-www-form-urlencoded")
        httpRequest:registerScriptHandler(HttpResponseCB)
    end

    --httpRequest:setRequestHeader
    httpRequest:send(data)
end
function TradingBankProxy:HTTPRequestPostEWM(url, callback, data, header, layer)
    dump({ url, callback, data, header }, "ssss____")
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("POST", url)
    UIOperator:OpenLoadingBarUI()
    if header then
        for k, v in pairs(header) do
            httpRequest:setRequestHeader(k, v)
        end
    end
    if not self:findLayer(layer) then
        self:addLayer(layer)
    end
    if callback then
        local function HttpResponseCB()
            local code = httpRequest.status
            local success = code >= 200 and code < 300
            local response = httpRequest.response
            UIOperator:CloseLoadingBarUI()
            releasePrint("Http Request Code:" .. tostring(code))
            releasePrint(success)
            if self:findLayer(layer) then
                dump({ success, response, code }, "____")
                if code == 200 then
                    callback(success, response, code)
                else--请求失败
                    ShowSystemTips(GET_STRING(30103202))
                end
            end
        end
        -- httpRequest:setRequestHeader("Content-type", "application/x-www-form-urlencoded")
        httpRequest:registerScriptHandler(HttpResponseCB)
    end

    --httpRequest:setRequestHeader
    httpRequest:send(data)
end
function TradingBankProxy:HTTPRequestPost(url, callback, data, header, layer, neederr)
    dump({ url, callback, data, header }, "ssss____")
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("POST", url)
    UIOperator:OpenLoadingBarUI()
    if header then
        for k, v in pairs(header) do
            httpRequest:setRequestHeader(k, v)
        end
    end
    if not self:findLayer(layer) then
        self:addLayer(layer)
    end
    if callback then
        local function HttpResponseCB()
            local code = httpRequest.status
            local success = code >= 200 and code < 300
            local response = httpRequest.response
            UIOperator:CloseLoadingBarUI()
            releasePrint("Http Request Code:" .. tostring(code))
            releasePrint(success)
            if self:findLayer(layer) then
                dump({ success, response, code }, "____")
                if success then
                    if pcall(cjson.decode, response) then
                        -- 没有错误
                    else--数据异常
                        local data = {}
                        data.txt = GET_STRING(600000186)
                        data.callback = function(res)
                        end
                        data.btntext = { GET_STRING(600000139) }
                        global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankTipsLayer_Open, data)
                        return
                    end
                    callback(success, response, code)
                else--请求失败
                    local data = {}
                    data.txt = GET_STRING(600000188)
                    data.callback = function(res)
                    end
                    data.btntext = { GET_STRING(600000139) }
                    global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankTipsLayer_Open, data)
                    if neederr then
                        callback(success, response, code)
                    end
                    return
                end
            end
        end
        -- httpRequest:setRequestHeader("Content-type", "application/x-www-form-urlencoded")
        httpRequest:registerScriptHandler(HttpResponseCB)
    end

    --httpRequest:setRequestHeader
    httpRequest:send(data)
end

function TradingBankProxy:addLayer(layer)
    if not self:findLayer(layer) then
        table.insert(self.m_http_layer, layer)
    end
end
function TradingBankProxy:findLayer(layer)
    for i, v in ipairs(self.m_http_layer) do
        if v == layer then
            return true
        end
    end
    return false
end
function TradingBankProxy:removeLayer(layer)
    for i, v in ipairs(self.m_http_layer) do
        if v == layer then
            table.remove(self.m_http_layer, i)
            return
        end
    end
end
--取消 EditBox 的空白输入
function TradingBankProxy:cancelEmpty(node)
    node:onEditHandler(function(event)
        if event.name == "changed" then
            local s = event.target:getString()
            s = string.gsub(s, "%s", "")
            event.target:setString(s)
        end
    end)
end
function TradingBankProxy:addNewLine(count)
    if type(count) == "string" and string.find(count, "%(") then
        local index = string.find(count, "%(") 
        local l = string.sub(count, 1, index -1) or ""
        local r = string.sub(count, index) or ""
        return string.format("%s\n%s", l, r)
    end
    return count
end
local client_type = "盒子游戏"
local unknown = "未知"
local partner_type = "996游戏" --合作类型
local appid = {"VjrDreUax7zG","dJ40beFLGXJ6","dJ40beFLGXJ6"}
local appkey = {"61e5584244fd31b655628f1db0d22cbb","91ad96c2b94aa61475378d38a8971df5","91ad96c2b94aa61475378d38a8971df5"}

TradingBankProxy.UpLoadData = {
    TraingIconBtnClick = {event_name = "entrance",map = {}},--点击交易行入口
    TraingExit = {event_name = "exit", map = {}},--交易行退出
    TraingBuyLayerSecondTab = {event_name = "Trade_game_purchase_tab_click",map = {}},--交易行购买页二级页签
    TraingBuyLayerRoleJobFilter = {event_name = "Trade_game_pcharactertab_filter_click",map = {}},--交易行购买页角色 职业 筛选
    TraingBuyLayerRoleDetail = {event_name = "visit_prod",map = {}},--交易行购买页角色 角色详情
    TraingBuyLayerRoleDetailSecondTab = {event_name = "Trade_purchasecharacter_click",map = {}},--交易行购买页角色 角色详情
    TraingBuyLayerMe = {event_name = "Trade_purchase_designatedme_click",map = {}},--交易行购买页指定我
    TraingBuyClick = {event_name = "Trade_game_Purchase_button_click",map = {}},--交易行购买按钮
    -- TraingBuyAlipayEWM = {event_name = "Trade_game_Purchase_AlipayQ_click",map = {}},--交易行支付宝二维码按钮
    TraingBuyJYB = {event_name = "Trade_game_Purchasetrade_coins_click",map = {}},--交易行交易币按钮
    TraingBuyConfirmPay = {event_name = "Trade_game_Purchase_confirm_payment_click",map = {}},--交易行确认支付
    TraingBuyBargainClick = {event_name = "Trade_game_Counterofferbutton_click",map = {}},--还价按钮
    TraingBuyBargainToBoxClick = {event_name = "Trade_game_counter_back_to_box_click",map = {}},--还价去盒子
    TraingBuyBargainToDownClick = {event_name = "Trade_game_counter_download_box_click",map = {}},--还价去下载
    TraingBuyBargainCancelClick = {event_name = "Trade_game_counteroffer_cancel_click",map = {}},--还价取消
    TraingBuySearchClick = {event_name = "Trade_game_Searchbutton_click",map = {}},--搜索
    TraingSellTabClick = {event_name = "Trade_game_sell_tab_click",map = {}},--寄售
    TraingSellRoleNextClick = {event_name = "Trade_sellcharactersale_next_click",map = {}},--寄售角色下一步
    TraingSellRolePreClick = {event_name = "Trade_sellcharacter_previous_click",map = {}},--寄售角色上一步
    TraingSellRoleGenImageClick = {event_name = "Trade_sellcgenerateimage_click",map = {}},--寄售角色生成图片
    TraingSellRoleReGenImageClick = {event_name = "Trade_saleregenerate_reimage_click",map = {}},--寄售角色重新生成图片
    TraingSellRoleImageOkPreClick = {event_name = "Trade_sellcprevious_click",map = {}},--寄售角色已生成图片上一步
    TraingSellRoleButtonClick = {event_name = "Trade_sellc_sale_click",map = {}},--寄售角色
    TraingSellMoneyUpClick = {event_name = "Trade_sellc_clickonthe_sell",map = {}},--寄售货币 上架
    TraingSellEquipGoodsClickUp = {event_name = "Trade_selleclick_sell_goods",map = {}},--寄售装备 道具点击
    TraingSellEquipUpClick = {event_name = "Trade_seleqnof_goods",map = {}},--寄售装备 上架点击
    TraingSellEquipUpCancelClick = {event_name = "Trade_cancel_listedbutton_ofthegoods",map = {}},--寄售装备 取消上架点击
    TraingSellRuleClick = {event_name = "Trade_sellrules_click",map = {}},--寄售装备 取消上架点击
    TraingShelfTabClick = {event_name = "Trade_shelf_tab_click",map = {}},--货架
    TraingMyTabClick = {event_name = "Trade_game_my_tab_click",map = {}},--我的
    TraingGetMoneyClick = {event_name = "Trade_game_withdraw_button_click",map = {}},--提现
    TraingGameBuyTabClk = {event_name = "game_buy_tab_clk",map = {}},   --游戏内点击求购页签
    TraingBuyTabFavClk= {event_name = "buy_tab_fav_clk",map = {}},    --求购页签内点击我收藏的
    TraingBuyTabFiltClk = {event_name = "buy_tab_filt_clk",map = {}},   --求购页签点击筛选
    TraingBugTabSortClk = {event_name = "buy_tab_sort_clk",map = {}},   --求购页签点击排序
    TraingBuyTabSupplyClk = {event_name = "buy_tab_supply_clk",map = {}}, --求购页签内点击任意求购单的供应按钮
    TraingBuyTabCollectClk = {event_name = "buy_tab_collect_clk",map = {}},--求购页签内点击任意求购单的收藏按钮
    TraingBuyTabSrch = {event_name = "buy_tab_srch",map = {}},       --求购页签内发起搜索
    TraingGameBuySucc = {event_name = "game_buy_succ",map = {}},      --在游戏内成功发起一次求购
    TraingGameBuyErr = {event_name = "game_buy_err",map = {}},       --在游戏内发起求购报错
    TraingGameSupplySucc = {event_name = "game_supply_succ",map = {}},   --在游戏内点击确认供应并供应成功
    TraingGameSupplyErr = {event_name = "game_supply_err",map = {}},    --在游戏内点击确认供应报错
}

--数据上报
function TradingBankProxy:doTrack(val, params)
    self.PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local environment = tonumber(envProxy:GetCustomDataByKey("environment")) or 2
    local val = val or {}
    val.map = val.map or {}
    val.map.customize_app_id    = appid[environment + 1]
    val.map.customize_app_key   = appkey[environment + 1]
    val.map.role_game_name      = SL:GetMetaValue("GAME_NAME")
    val.map.role_game_id        = SL:GetMetaValue("GAME_ID")
    val.map.game_name           = SL:GetMetaValue("GAME_NAME")
    val.map.game_id             = SL:GetMetaValue("GAME_ID")
    val.map.role_game_type      = unknown
    val.map.servid              = tonumber(self.loginProxy:GetSelectedServerId())
    val.map.server_name         = self.loginProxy:GetSelectedServerName()
    val.map.role_att            = SL:GetMetaValue("MAXDC") or 0
    val.map.role_createtime     = self.loginProxy:GetSelectedRoleCTime()
    val.map.role_amount         = 0
    val.map.role_id             = global.gamePlayerController:GetMainPlayerID()
    val.map.role_name           = self.PlayerProperty:GetName()
    val.map.role_level          = tonumber(self.PlayerProperty:GetRoleLevel())
    val.map.job_id              = self.PlayerProperty:GetRoleJob()
    val.map.job_name            = self.PlayerProperty:GetRoleJobName()
    val.map.client_type         = client_type
    val.map.partner_type        = partner_type
    val.map.h5_ver              = unknown
    
    if params and params  then 
        for k, v in pairs(params) do
            val.map[k] = v
        end
    end
    dump(val,"上报数据t——————————")
    local jsonStr = cjson.encode(val) 
    local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    NativeBridgeProxy:GN_ReportCustomEvent(jsonStr)
end

return TradingBankProxy