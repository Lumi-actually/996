---@diagnostic disable: undefined-field, need-check-nil
local RemoteProxy = requireProxy("RemoteProxy")
local OtherTradingBankProxy = class("OtherTradingBankProxy", RemoteProxy)
OtherTradingBankProxy.NAME = global.ProxyTable.OtherTradingBankProxy
local host =--[[release]] "https://exchange-api-pro.jyh.aml52.com"--[[pre]] --[["http://exchange-api-pre.jyh.aml52.com"]]--[[debug]] --[["http://exchange-api.jyh.aml52.com"]]
local aes256key = --[[release]] "tz5XGiTqcK4ZwGaIdY33sxk4nwvGN40o"--[[pre]] --[["dujXZ0sE4FOUUy59aC3i1czXFgx7eD8W"]] --[[debug]] --[["zKlcyp4S4zt4jKMOMe4RFwL0Jy2qPaPc"]]
local cjson = require("cjson")
function OtherTradingBankProxy:ctor()
    OtherTradingBankProxy.super.ctor(self)
    self.m_userData = nil
    self.m_moneyData = {}
    self.m_yzToken = nil
    self.m_http_layer = {}
    self.m_mobile = nil
    self.AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    self.loginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    self.m_tradingStatus = false --交易行开启状态
    self.m_gameToken = nil
    self.m_funcValues = {}
    self.m_funcIndex = 1
    self.HelpURL = {
        "http://charge-api.996box.com/help.txt", -- 售卖help
        "http://charge-api.996box.com/help.txt", -- 待入账help
        "http://charge-api.996box.com/help.txt", -- 唯一码help
        "http://charge-api.996box.com/help.txt", -- 合作协议
    }
    self.PrivacyPolicyList = {
        "https://kdocs.cn/l/ckeZ232XYBbd", --用户隐私协议
        "https://kdocs.cn/l/co9EgLjV3V5e", --儿童隐私保护指引
        "https://kdocs.cn/l/clplbS9gU28X", --个人信息收集清单
        "https://kdocs.cn/l/caVbpVBTMhku", --用户服务协议
        "https://kdocs.cn/l/ckTCV5fNIp3V", --第三方信息共享清单
    }
    self.m_OnlyOneID = nil --唯一码
    self.m_outTime = 8 -- 商品过期时间

    self.m_screenshotsData = {}

    self._scrollCacheData = {}
    self._scrollCurData = {}
    self._scrollCacheCount = 0
    self._scrollCacheCurCount = 0
    self._timeStep = 4
    self._scrollScheduleID = nil

    self._environment = 2
    ---------
    local currentModule = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv = currentModule:GetGameEnv()

    local environment    = moduleGameEnv:GetCustomDataByKey("environment")
    dump(environment,"environment")
    environment = tonumber(environment) or 2  -- 0 debug  1 pre  2 pro
    self._environment = environment
    local aes256keyList = {"zKlcyp4S4zt4jKMOMe4RFwL0Jy2qPaPc", "dujXZ0sE4FOUUy59aC3i1czXFgx7eD8W", "tz5XGiTqcK4ZwGaIdY33sxk4nwvGN40o"}
    aes256key = aes256keyList[environment + 1]
    local exchangeAppId    = moduleGameEnv:GetCustomDataByKey("exchangeAppId")
    local exchangeSecretKey    = moduleGameEnv:GetCustomDataByKey("exchangeSecretKey")
    dump(exchangeAppId,"exchangeAppId___")
    dump(exchangeSecretKey,"exchangeSecretKey___")
    local exchangeDomain   = moduleGameEnv:GetCustomDataByKey("exchangeDomain")
    dump(exchangeDomain,"exchangeDomain___")
    if exchangeAppId and exchangeAppId ~= "" and exchangeSecretKey and exchangeSecretKey ~= "" and global.OtherTradingBank then 
        self.appid = exchangeAppId
        self.secret = self:Aes256DecodeSecret(exchangeSecretKey)
        dump(self.secret,"self.secret__")
        host = exchangeDomain
        self:initSDK()
        self:initReportParam()
    end
    global.IsConsignmentRole = false
end


function OtherTradingBankProxy:getOutTime()
    return self.m_outTime
end

function OtherTradingBankProxy:setOutTime(time)
    self.m_outTime = time
end

function OtherTradingBankProxy:getOnlyOneID()
    return self.m_OnlyOneID
end

function OtherTradingBankProxy:setOnlyOneID(id)
    self.m_OnlyOneID = id
end

function OtherTradingBankProxy:getOpenStatus()
    return self.m_tradingStatus
end

function OtherTradingBankProxy:setOpenStatus(isOpen)
    self.m_tradingStatus = isOpen
end
--n2g
function OtherTradingBankProxy:callFunc(index, jsonString)
    dump({index, jsonString},"callFunc____")
    if index == -1 or index == "-1" then --h5接口
        local json = cjson.decode(jsonString)
        if json.action == "Capture" then 
            global.Facade:sendNotification(global.NoticeTable.TradingBank_other_Capture)
        elseif json.action == "IsInSafeArea" then 
            self:IsInSafeArea()
        elseif json.action == "GoToRole" then 
            if global.gameWorldController then
                global.gameWorldController:OnGameLeaveWorld()
            end
        elseif json.action == "GoToServer" then
            global.Facade:sendNotification( global.NoticeTable.RestartGame ) 
        elseif json.action == "gameRecvDataFromH5" then--收到h5下发的内容再去返回给h5
            local fromh5 = cjson.decode(json.jsonString)
            dump(fromh5,"gameRecvDataFromH5")
            if fromh5.content and type(fromh5.content) == "string" then
                fromh5.content = cjson.decode(fromh5.content)
                if fromh5.content.action == "screenshots" then
                    if fromh5.content.type == "role" or fromh5.content.type == "prop" then
                        local data = {}
                        data.action = "screenshots"
                        data.type = fromh5.content.type
                        self.m_screenshotsData = fromh5
                        global.Facade:sendNotification(global.NoticeTable.TradingBank_other_Capture,{datatype = data})
                    end
                elseif fromh5.content.action == "checkSecurityZone" then --检测角色是否处于安全区
                    self:sendDataToH5(fromh5,"checkSecurityZone")
                elseif fromh5.content.action == "getLoginSuccessTime" then --发送登录时间
                    self:sendDataToH5(fromh5,"getLoginSuccessTime")
                elseif fromh5.content.action == "backToSelectRole" then --回退到角色选择
                    if global.gameWorldController then
                        global.gameWorldController:OnGameLeaveWorld()
                    end
                elseif fromh5.content.action == "backToSelectServer" then --回退到区服选择
                    global.Facade:sendNotification( global.NoticeTable.RestartGame) 
                end
            end
            
        end
    else
        if self.m_funcValues[index] then
            if self.m_funcValues[index].func and jsonString then
                self.m_funcValues[index].func(jsonString)
            end
            if not self.m_funcValues[index].isNotNeedLoading then
                UIOperator:CloseLoadingBarUI()
            end
            self.m_funcValues[index] = nil
        end
    end
end
--h5和游戏通讯接口
function OtherTradingBankProxy:sendDataToH5(data,action)
    local params = {
        action = "sendDataToH5",
        isH5 = true,
        params = {
        },
    }
    if action == "screenshots" then
        local isHero = false
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        if HeroPropertyProxy:IsHeroOpen() then
            if HeroPropertyProxy:GetIsMakeHero() then
                if HeroPropertyProxy:HeroIsLogin() then
                    isHero = true
                end
            end
        end
        self.m_screenshotsData.content.data = {}
        if isHero then
            self.m_screenshotsData.content.data = {
                uid         = self.AuthProxy:GetUID(),
                game_id     = self.AuthProxy:getGameId(),
                server_id   = self.loginProxy:GetSelectedServerId(),
                server_name = self.loginProxy:GetSelectedServerName(),
                role_id     = global.gamePlayerController:GetMainPlayerID(),
                role        = self.PlayerProperty:GetName(),
                sex         = self.PlayerProperty:GetRoleSex(),
                vip         = 0,
                role_level  = self.PlayerProperty:GetRoleLevel(),
                ablity      = self.PlayerProperty:GetRoleAttByAttType(GUIFunction:PShowAttType().Max_ATK),
                role_type   = self.PlayerProperty:GetRoleJob(),
                images      = data,
                game_type   = 1,

                hero_role_id   = self.HeroPropertyProxy:GetRoleUID(),          --英雄角色ID
                hero_name      = self.HeroPropertyProxy:GetName(),             --英雄角色名字
                hero_sex       = self.HeroPropertyProxy:GetRoleSex(),          --英雄性别
                hero_level     = self.HeroPropertyProxy:GetRoleLevel(),        --英雄角色等级
                hero_role_type = self.HeroPropertyProxy:GetRoleJob(),          --英雄职业
                hero_rein_lv = self.HeroPropertyProxy:GetRoleReinLv(),         --转生
                hero_ability   = self.HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Max_ATK)--英雄战力
            }
        else
            self.m_screenshotsData.content.data = {
                uid         = self.AuthProxy:GetUID(),
                game_id     = self.AuthProxy:getGameId(),
                server_id   = self.loginProxy:GetSelectedServerId(),
                server_name = self.loginProxy:GetSelectedServerName(),
                role_id     = global.gamePlayerController:GetMainPlayerID(),
                role        = self.PlayerProperty:GetName(),
                sex         = self.PlayerProperty:GetRoleSex(),
                vip         = 0,
                role_level  = self.PlayerProperty:GetRoleLevel(),
                ablity      = self.PlayerProperty:GetRoleAttByAttType(GUIFunction:PShowAttType().Max_ATK),
                role_type   = self.PlayerProperty:GetRoleJob(),
                images      = data,
                game_type   = 1
            }
        end
        params.params.jsonStr = cjson.encode(self.m_screenshotsData)
    elseif action == "checkSecurityZone" then
        local MapProxy = global.Facade:retrieveProxy( global.ProxyTable.MapProxy )
        local res =  MapProxy:IsInSafeArea() 
        data.content.data = {}
        data.content.data.success = res and 1 or 0
        params.params.jsonStr = cjson.encode(data)
    elseif action == "getLoginSuccessTime" then
        local uid       = self.AuthProxy:GetUID() or ""
        data.content.data  = {
            time    = os.time(),
            uid     = uid,
            gameId  = tonumber(self.AuthProxy:getGameId()),
        }
        params.params.jsonStr = cjson.encode(data)
    end
    dump(params,"sendDataToH5___")
    self:addToCallFunc(params)
end

function OtherTradingBankProxy:addToCallFunc(params, func, layer, isNotNeedLoading)
    dump(params,"addToCallFunc___")
    if params.isH5 then 
        local index = self:getFuncIndex()
        params.index = index
        local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
        NativeBridgeProxy:GN_TradingBank_Interface(params)
    else
        if layer then
            if not self:findLayer(layer) then
                self:addLayer(layer)
            end
        end
        if not isNotNeedLoading then
            UIOperator:OpenLoadingBarUI()
        end
        local index = self:getFuncIndex()
        params.index = index
        local callback = function(jsonStr)
            -- if _DEBUG then 
            --     if ShowSystemTips then 
            --         ShowSystemTips((params.action or "")..":"..jsonStr)
            --     end 
            -- end
            if layer then
                if not self:findLayer(layer) then
                    return
                end
            end
            local json = cjson.decode(jsonStr)
            if json.code == 50003 or json.code == 50000 then --token过期
                if not (params.action == "takeBackRole" or params.action == "onShelfLimit") then 
                    self.m_yzToken = ""
                    -- global.Facade:sendNotification(global.NoticeTable.SystemTips, json.msg)
                    self:Login1_2(function(code, msg)--重新登录操作
                        if code == 200 then
                            self:addToCallFunc(params, func, layer, isNotNeedLoading)
                        else
                            ShowSystemTips(msg or "")
                        end
                    end)
                    return
                end
            end
            func(json.code, json.data, json.msg)
        end
        self.m_funcValues[index] = { func = callback, isNotNeedLoading = isNotNeedLoading }
        local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
        NativeBridgeProxy:GN_TradingBank_Interface(params)
    end
end

function OtherTradingBankProxy:getFuncIndex()
    self.m_funcIndex = self.m_funcIndex + 1
    return self.m_funcIndex
end

function OtherTradingBankProxy:init()
    self.MoneyProxy = global.Facade:retrieveProxy(global.ProxyTable.MoneyProxy)
    self.MoneyType = self.MoneyProxy.MoneyType
    self.PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    self.HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
end

function OtherTradingBankProxy:getGameToken()
    --"noToken"--
    return self.m_gameToken or ""
end

function OtherTradingBankProxy:setGameToken(token)
    self.m_gameToken  = token
end

function OtherTradingBankProxy:getToken()
    return self.m_yzToken or ""
end

function OtherTradingBankProxy:setToken(token)
    self.m_yzToken = token
end

function OtherTradingBankProxy:getMobile()
    return self.m_mobile
end


function OtherTradingBankProxy:setMobile(phone)
    self.m_mobile = phone
end

function OtherTradingBankProxy:onRegister()
    OtherTradingBankProxy.super.onRegister(self)

end

function OtherTradingBankProxy:RegisterMsgHandler()
    OtherTradingBankProxy.super.RegisterMsgHandler(self)
    local msgType    = global.MsgType
    --返回登陆
    if global.OtherTradingBank then
        LuaRegisterMsgHandler(msgType.MSG_SC_SELLROLESUCCESS_LOGOUT, handler(self, self.handle_MSG_SC_SELLROLESUCCESS_LOGOUT))
    end
    LuaRegisterMsgHandler(msgType.MSG_SC_LYTOKEN, handler(self, self.handle_MSG_SC_LYTOKEN)) -- token
end

function OtherTradingBankProxy:handle_MSG_SC_LYTOKEN(msg)
    local header = msg:GetHeader()
    local msgLen = msg:GetDataLength()
    if msgLen <= 0 then
        return nil
    end
    local token = msg:GetBodyStr()
    dump(token, "token___")
    dump(global.OtherTradingBankH5,"global.OtherTradingBankH5____")
    self.m_yzToken = nil --需要清理一下交易行token
    self.m_gameToken = token
    self:getTradingBankStatus({}, function(code, data, msg)
        if code == 200 then 
            if global.OtherTradingBankH5 then 
                if self:getGameToken() == "" then 
                    return 
                end
                self:setGameTokenToH5(token)
            end
        end
    end, true)
    
end

function OtherTradingBankProxy:handle_MSG_SC_SELLROLESUCCESS_LOGOUT(msg)
    if global.IsVisitor then
        return
    end
    global.IsConsignmentRole = true
    local outtime = self:getOutTime()
    local tipsStr = string.format(GET_STRING(600000457), outtime, "%s")
    global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankTipsLayer_Open_other, { callback = function(code)
        if code == 1 then
            global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankTipsLayer_Close_other)
            global.gameWorldController:OnGameLeaveWorld()
        end
    end, notcancel = true, exitTime = 30, txt = tipsStr, btntext = { GET_STRING(800802) } })

end
function OtherTradingBankProxy:reqUserData(layer, func)--请求用户数据
    local url = host.."/user/df/api/user/v1/userInfo"
    self:HTTPRequest(url, func, {}, nil, layer)
end

function OtherTradingBankProxy:setUserData(data)
    dump(data, "setUserData__")
    self.m_userData = data
end

function OtherTradingBankProxy:getUserData()
    return self.m_userData
end

function OtherTradingBankProxy:setMoneyData(data)
    dump(data, "setMoneyData__")
    self.m_moneyData = data
end

function OtherTradingBankProxy:getMoneyData()
    return self.m_moneyData
end

function OtherTradingBankProxy:LoginOut()
    if not self._isLogin then
        return 
    end 
    self.m_yzToken = nil
    self._isLogin = false
end

function OtherTradingBankProxy:reqYZPhone(layer, phone, yzm, func)--手机登录
    local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local packageName = envProxy:GetAPKPackageName()
    local val = {
            phone = phone,
            code = yzm,
            gameToken = self:getGameToken(),
            serverId = tonumber(self.loginProxy:GetSelectedServerId()),
            gameId    = tonumber(self.AuthProxy:getGameId()),
            packageName = packageName,
    }
    local url = host.."/user/pb/api/user/v1/phoneLogin"
    self:HTTPRequestPost(url, func, val, nil, layer)
end

function OtherTradingBankProxy:openLock(layer, phone, yzm, func)--开启寄售锁
    local url = host.."/exchange/df/api/exchange/v1/verifyCode"
    local val = {
        phone = phone,
        code = yzm,
        gameToken = self:getGameToken(),
        serverId = tonumber(self.loginProxy:GetSelectedServerId()),
        gameId    = tonumber(self.AuthProxy:getGameId()),
    }
    self:HTTPRequestPost(url, func, val, nil, layer)
end

--验证码 登录
function OtherTradingBankProxy:reqLoginGetCode(layer, data, func)
    local url = host.."/user/pb/api/user/v1/sendSms"
    local val = {
        smsType = "phoneLogin"
    }
    for k, v in pairs(data) do
        val[k] = v
    end
    self:HTTPRequestPost(url, func, val, nil, layer)
end

--验证码 寄售锁
function OtherTradingBankProxy:reqGetCode(layer, data, func)
    local url = host.."/user/pb/api/user/v1/sendSms"
    local val = {
        smsType = "verifyCode"
    }
    for k, v in pairs(data) do
        val[k] = v
    end
    self:HTTPRequestPost(url, func, val, nil, layer)
end


--是否实名
function OtherTradingBankProxy:checkAuthentication(layer, func)
    local url = host.."/user/df/api/user/v1/checkAuthentication"
    local val = {}
    self:HTTPRequest(url, func, val, nil, layer)
end

--卖货币
function OtherTradingBankProxy:sellMoney(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/publishCoin"
    local val = {
        uid        = self.AuthProxy:GetUID(),
        gameId    = tonumber(self.AuthProxy:getGameId()),
        serverId = tonumber(self.loginProxy:GetSelectedServerId()),
        serverName = self.loginProxy:GetSelectedServerName(),
        roleId    = global.gamePlayerController:GetMainPlayerID(),
        role        = self.PlayerProperty:GetName(),
        vip        = 0,
        roleLevel = tonumber(self.PlayerProperty:GetRoleLevel()),
        token    = self:getToken(),
        coinId = data.coin_id,
        coinNum = data.coin_num,
        gameType = 1,
        price = data.price,
        targetRoleName = data.target_rolename,
        desc                = "",
        title               = "",
    }
    self:HTTPRequestPost(url, func, val, nil, layer)
end
--卖角色
function OtherTradingBankProxy:sellRole(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/publishAccount"
    local val = {
        uid         = self.AuthProxy:GetUID(),
        gameId      = self.AuthProxy:getGameId(),
        serverId    = self.loginProxy:GetSelectedServerId(),
        serverName  = self.loginProxy:GetSelectedServerName(),
        roleId      = global.gamePlayerController:GetMainPlayerID(),
        role        = self.PlayerProperty:GetName(),
        sex         = self.PlayerProperty:GetRoleSex(),
        vip         = 0,
        roleLevel   = self.PlayerProperty:GetRoleLevel(),
        ablity      = 0, --战力
        gameType    = 1,
        roleType    = self.PlayerProperty:GetRoleJob(),
        token       = self:getToken(),
        new_version = global.IsNewBoxSellVersion and 1 or 0, --是否是支持收货验证版本
        price       = data.price,
        attributeImages     = data.attribute,
        bagImages           = data.bag,
        clothesImages       = data.clothes,
        equipImages         = data.equip,
        skillImages         = data.skill,
        statusImages        = data.status,
        titleImages         = data.title,
        warehouseImages     = data.warehouse,
        heroAttributeImages = data.hero_attribute,
        heroBagImages       = data.hero_bag,
        heroClothesImages   = data.hero_clothes,
        heroEquipImages     = data.hero_equip,
        heroSkillImages     = data.hero_skill,
        heroStatusImages    = data.hero_status,
        heroTitleImages     = data.hero_title,
        desc                = "",
        targetAccount       = data.target_account,
        title               = "",
    }
    self:HTTPRequestPost(url, func, val, nil, layer)
end

--装备交易 确定收货
function OtherTradingBankProxy:equipTakeSure(layer, data, func)
    local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local val = {
        operationCode  = data.operationCode,
        orderId        = data.orderId,
        emailId        = data.emailId
    }
    local url = host.."/exchange/pb/api/h5sdk/exchange/v1/itemConfirm"
    self:HTTPRequestPost(url, func, val, nil, layer)
end


--装备交易 取消收货
function OtherTradingBankProxy:equipTakeRefuse(layer, data, func)
    local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local val = {
        operationCode  = data.operationCode,
        orderId        = data.orderId,
        emailId        = data.emailId
    }
    local url = host.."/exchange/pb/api/h5sdk/exchange/v1/itemReject"
    self:HTTPRequestPost(url, func, val, nil, layer)
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
function OtherTradingBankProxy:getGoodsInfo(layer, data, func)
    dump(data, "getGoodsInfo")
    local url = host.."/exchange/df/api/exchange/v1/commodityList"
    local val = {
        serverId        = data.server_id or tonumber(self.loginProxy:GetSelectedServerId()),
        roleId          = global.gamePlayerController:GetMainPlayerID(),
        gameId          = self.AuthProxy:getGameId(),
        page            = data.page,
        pagenum         = data.pagenum,
        type            = data.type,
        coinConfigId    = data.coin_config_id,
        orderCoinNum    = data.order_coin_num,
        orderLevel      = data.order_level,
        orderPrice      = data.order_price,
        roleName        = data.role_name,
        roleType        = data.role_type,
        curServerId     = tonumber(self.loginProxy:GetSelectedServerId())

    }
    
    self:HTTPRequest(url, func, val, nil, layer)
end

--获取我的货架  type类型 1角色2货币
function OtherTradingBankProxy:getMyGoodsInfo(layer, data, func)
    dump(data, "getMyGoodsInfo")
    local url = host.."/exchange/df/api/exchange/v1/myCommodity"
    local val = {
        uid         = self.AuthProxy:GetUID(),
        gameId      = self.AuthProxy:getGameId(),
        roleId      = global.gamePlayerController:GetMainPlayerID(),
        serverId    = self.loginProxy:GetSelectedServerId(),
        token       = self:getToken(),
        page        = data.page,
        pageNum     = data.pagenum
    }
    self:HTTPRequest(url, func, val, nil, layer)
end

--获取可 上交易行货币
function OtherTradingBankProxy:reqMoneyData(layer, func)
    local url = host.."/exchange/pb/api/exchange/v1/coinType"
    local val = {
        gameId    = self.AuthProxy:getGameId(),
    }
    local callback = function(code, data, msg)
        if code == 200 then
            self:setMoneyData(data)
        end
        func(code, data, msg)
    end
    self:HTTPRequest(url, callback, val, nil, layer)
end

--查询商品信息
function OtherTradingBankProxy:reqcommodityInfo(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/commodityInfo"
    local val = {
        commodity_id = data.commodity_id
    }
    self:HTTPRequest(url, func, val, nil, layer)
end

--查询支付状态
function OtherTradingBankProxy:reqOrderStatus(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/orderStatus"
    local val = {
        orderId = data.order_id
    }
    self:HTTPRequest(url, func, val, nil, layer)
end

--寄售锁  第一次【我的】【货架】【寄售】】验证手机号
function OtherTradingBankProxy:checkConsignmentSwitch(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/checkConsignmentSwitch"
    
    local val = {
        gameId = self.AuthProxy:getGameId(),
        serverId = self.loginProxy:GetSelectedServerId(),
    }
    self:HTTPRequest(url, func, val, nil, layer)
end

--上架
function OtherTradingBankProxy:reqOnShelf(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/onShelf"
    local val = {
        commodityId = data.commodity_id
    }
    
    self:HTTPRequestPut(url, func, val, nil, layer)
end
--下架
function OtherTradingBankProxy:reqDownShelf(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/downShelf"
    local val = {
        commodityId = data.commodity_id
    }
    
    self:HTTPRequestPut(url, func, val, nil, layer)
end
--修改价格
function OtherTradingBankProxy:reqModifyPrice(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/modifyPrice"
    local val = {
        commodityId = data.commodity_id,
        price       = data.price
    }
    
    self:HTTPRequestPut(url, func, val, nil, layer)
end
--取回
function OtherTradingBankProxy:reqTakeBack(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/takeBack"
    local val = {
        commodityId = data.commodity_id
    }
    
    self:HTTPRequestPost(url, func, val, nil, layer)
end
-- --删除
-- function OtherTradingBankProxy:reqDelete(layer, data, func)
--     local params = {
--         action = "delCommodity",
--         params = {
--             token = self:getToken(),
--         },
--     }
--     for k, v in pairs(val) do
--         params.params[k] = v
--     end
--     self:addToCallFunc(params,func,layer)
-- end

--查询账号
function OtherTradingBankProxy:reqAccountInfo(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/takeBack"
    local val = {
        gameAccount = data.account
    }
    
    self:HTTPRequest(url, func, val, nil, layer)
end

function OtherTradingBankProxy:reqRoleInfo(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/takeBack"
    local val = {
        gameId      = self.AuthProxy:getGameId(),
        serverId    = self.loginProxy:GetSelectedServerId(),
        roleName    = data.role_name
    }
    
    self:HTTPRequest(url, func, val, nil, layer)
end

--下单
function OtherTradingBankProxy:reqOrderPlace(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/orderPlace"
    local device_t  = global.isAndroid and "android" or "ios"
    local val = {
        commodityId     = data.commodity_id,
        commodityQty    = 1,
        deviceType      = device_t,
        gameId          = self.AuthProxy:getGameId(),
        roleId          = global.gamePlayerController:GetMainPlayerID(),
        token           = self:getToken(),
        uid             = self.AuthProxy:GetUID(),
        role            = self.PlayerProperty:GetName(),
        level           = self.PlayerProperty:GetRoleLevel(),
        serverName      = self.loginProxy:GetSelectedServerName(),
        serverId        = self.loginProxy:GetSelectedServerId(),
        tradeId         = data.commodity_id,
    }
    
    self:HTTPRequestPost(url, func, val, nil, layer)
end


--获取help
function OtherTradingBankProxy:reqHelpText(layer, data, func)
    local type = data.type or 1
    local url = self.HelpURL[type] or self.HelpURL[1] or ""
    if not self:findLayer(layer) then
        self:addLayer(layer)
    end
    dump(url, "url_____")
    HTTPRequest(url, function(success, response, code)
        dump({ success, response, code }, "reqHelpText__")
        if self:findLayer(layer) then
            local nosuccess = false
            if success then
                local data = cjson.decode(response)
                dump(data, "help___")
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
                global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankTipsLayer_Open_other, data)
            end
        end
    end
    )
end

--取消订单
function OtherTradingBankProxy:reqCancelorder(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/cancelOrder"
    local val = {
        orderId = data.order_id
    }
    self:HTTPRequest(url, func, val, nil, layer)
end

--取回角色
function OtherTradingBankProxy:takeBackRole(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/takeBackRole"
    local val = {
        roleId = data.role_id
    }
    self:HTTPRequestPost(url, func, val, nil, layer)
end

--角色是否有在售货币 等级 充值等
function OtherTradingBankProxy:publishAccountCheck(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/publishAccountCheck"
    local val = {
        token           = self:getToken(),
        uid             = self.AuthProxy:GetUID(),
        roleId          = global.gamePlayerController:GetMainPlayerID(),
        gameId          = self.AuthProxy:getGameId(),
        serverId        = tonumber(self.loginProxy:GetSelectedServerId()),
        serverName      = self.loginProxy:GetSelectedServerName(),
        role            = self.PlayerProperty:GetName(),
        vip             = 0,
        roleLevel       = tonumber(self.PlayerProperty:GetRoleLevel()),
        ablity          = 0, --战力
        gameType        = 1,
        price           = data.price,
        roleType        = self.PlayerProperty:GetRoleJob(),
        sex             = self.PlayerProperty:GetRoleSex(),
        desc            = "",
        targetAccount   = data.target_account,
        new_version     = global.IsNewBoxSellVersion and 1 or 0, --是否是支持收货验证版本
    }
    self:HTTPRequest(url, func, val, nil, layer)
end

--查询卖角色的配置
function OtherTradingBankProxy:reqSellRoleInfo(layer, data, func)
    local url = host.."/exchange/pb/api/exchange/v1/sellConfig"
    self:HTTPRequest(url, func, data, nil, layer)
end

-- 取回到可寄售间隔 (上架时效)
function OtherTradingBankProxy:reqGetSellCDTime(layer, data, func)
    local url = host.."/exchange/pb/api/exchange/v1/onShelfLimit"
    self:HTTPRequest(url, func, data, nil, layer)
end
--交易行是否开启
function OtherTradingBankProxy:getTradingBankStatus(data, func, isNotNeedLoading, layer)
    local url = host.."/user/pb/api/user/v1/appParam"
    local deviceType = 1
    if global.isWindows then 
        deviceType = 3
    elseif global.isIOS then 
        deviceType = 2
    end

    local val = {
        deviceType = deviceType,
        serverId   = tonumber(self.loginProxy:GetSelectedServerId()),
        channelId  = SL:GetValue("CHANNEL_ID"),
    }
    local urlKey = {
        "helpFileUrl", -- 售卖help
        "extractMemoUrl", -- 待入账help
        "onlyCodeMemoUrl", -- 唯一码help
        "cooperationAgreementUrl", --合作协议
    }
    local PrivacyPolicyKey = {
        "userPrivacyPolicyUrl", --用户隐私协议
        "childPrivacyProtectionGuidelinesUrl", --儿童隐私保护指引
        "personalInformationCollectionListUrl", --个人信息收集清单
        "userAgreementUrl", --用户服务协议
        "thirdPartyInformationSharingListUrl", --第三方信息共享清单
    }
    local callback = function(code, data, msg)
        if code == 200 and data then
            for i, v in ipairs(urlKey) do
                if data[v] then
                    self.HelpURL[i] = data[v]
                end
            end
            for i, v in ipairs(PrivacyPolicyKey) do
                if data[v] then
                    self.PrivacyPolicyList[i] = data[v]
                end
            end
            -- if data.appid then 
            --     self.appid = data.appid
            -- end
            -- if data.secret then 
            --     self.secret = data.secret
            -- end
            if data.isUseH5 and data.isUseH5 == 1 then
                global.OtherTradingBankH5 = true 
            end
            dump(data,"getTradingBankStatus____")
        end
        func(code, data, msg)
    end
    self:HTTPRequest(url, callback, val, nil, layer, isNotNeedLoading)
end

--用户余额
function OtherTradingBankProxy:getUserMoneyBalance(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/userBalance"
    self:HTTPRequest(url, func, data, nil, layer)
end

--唯一码
function OtherTradingBankProxy:getTradeId(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/getTradeId"
    self:HTTPRequest(url, func, data, nil, layer)
end

--提现账户信息
function OtherTradingBankProxy:getExtractAccountInfo(layer, data, func)
    local url = host.."/extract/pt/api/extractApply/v1/userInfo"
    self:HTTPRequest(url, func, data, nil, layer)
end

--提现配置
function OtherTradingBankProxy:getExtractConfig(layer, data, func)
    local url = host.."/extract/pt/api/extractApply/v1/config"
    self:HTTPRequest(url, func, data, nil, layer)
end

--提现红点
function OtherTradingBankProxy:getExtractRedPoint(layer, data, func)
    local url = host.."/extract/pt/api/extractApply/v1/redPoint"
    self:HTTPRequest(url, func, data, nil, layer)
end
--提现申请
function OtherTradingBankProxy:reqExtractApplyFor(layer, data, func)
    local url = host.."/extract/pt/api/extractApply/v1/save"
    local device_t  = global.isAndroid and "android" or "ios"
    local val = {
        serverId        = tonumber(self.loginProxy:GetSelectedServerId()),
        gameId          = tonumber(self.AuthProxy:getGameId()),
        device          = device_t,
        alipayAccount   = data.account,
        money           = (tonumber(data.money) or 0) * 100 
    }
    self:HTTPRequestPost(url, func, val, nil, layer)
end
--提现记录
function OtherTradingBankProxy:reqExtractRecordList(layer, data, func)
    local url = host.."/extract/pt/api/extractApply/v1/page"
    local val = {
        pageNum = data.page,
        pageSize = data.pagenum
    }
    self:HTTPRequest(url, func, val, nil, layer)
end
--提现记录详情
function OtherTradingBankProxy:reqExtractRecordDetails(layer, data, func)
    local url = host.."/extract/pt/api/extractApply/v1/detail"
    local val = {
        id = data.id
    }
    self:HTTPRequest(url, func, val, nil, layer)
end
--撤销提现
function OtherTradingBankProxy:cancelExtractApplyFor(layer, data, func)
    local url = host.."/extract/pt/api/extractApply/v1/cancel"
    local val = {
        extractApplyId = data.id
    }
    self:HTTPRequestPost(url, func, val, nil, layer)
end
--获取已购买列表
function OtherTradingBankProxy:getFinishOrderList(layer, data, func)
    local url = host.."/exchange/df/api/exchange/v1/getFinishBuyOrderList"
    local val = {
        commodityType   = data.type,
        page            = data.page,
        pageNum         = data.pagenum,
        type            = data.type,
        orderPrice      = data.orderPrice,
    }
    self:HTTPRequest(url, func, val, nil, layer)
end

--获取反馈类型
function OtherTradingBankProxy:userFeedBackTypeList(layer, data, func)
    local url = host.."/user/pb/api/user/v1/userFeedbackTypeList"
    local val = {}
    self:HTTPRequest(url, func, val, nil, layer)
end

--用户反馈
function OtherTradingBankProxy:userFeedBack(layer, data, func)
    local url = host.."/user/df/api/user/v1/feedback"
    local val = {
        feedBackTypeId  = data.id,
        text            = data. content
    }
    self:HTTPRequestPost(url, func, val, nil, layer)
end

--帮助中心 详情
function OtherTradingBankProxy:HelpList(layer, data, func)
    local url = host.."/user/pb/api/user/v1/faqList"
    local val = {
        keyword = data.keyword
    }
    self:HTTPRequest(url, func, val, nil, layer)
end

function OtherTradingBankProxy:addLayer(layer)
    if not self:findLayer(layer) then
        table.insert(self.m_http_layer, layer)
    end
end
function OtherTradingBankProxy:findLayer(layer)
    for i, v in ipairs(self.m_http_layer) do
        if v == layer then
            return true
        end
    end
    return false
end
function OtherTradingBankProxy:removeLayer(layer)
    for i, v in ipairs(self.m_http_layer) do
        if v == layer then
            table.remove(self.m_http_layer, i)
            return
        end
    end
end
--取消 EditBox 的空白输入
function OtherTradingBankProxy:cancelEmpty(node)
    node:onEditHandler(function(event)
        if event.name == "changed" then
            local s = event.target:getString()
            s = string.gsub(s, "%s", "")
            event.target:setString(s)
        end
    end)
end
-----------------------
--临时用 后面要放到sdk
local HMAC = require("lockbox.mac.hmac");
local SHA1 = require("lockbox.digest.sha1");
local Array = require("lockbox.util.array");
local Stream = require("lockbox.util.stream");
local ECBMode = require("lockbox.cipher.mode.ecb");
local Base64 = require("lockbox.util.base64");
local ZeroPadding = require("lockbox.padding.zero");
local AES256Cipher = require("lockbox.cipher.aes256");

function OtherTradingBankProxy:getParam(val)
    val = val or {}
    val.timestamp = os.time()

    local originData = {}
    for k, v in pairs(val) do
        table.insert(originData, { key = k, value = v })
    end
    
    table.sort(originData, function(a, b)
        return a.key < b.key
    end)
    -- 计算sign
    local origin = ""
    local isFirst = true
    for i, v in ipairs(originData) do
        local valueStr = v.value
        if type(v.value) == "table" then 
            valueStr = cjson.encode(v.value)
        end 
        if isFirst then 
            origin = string.format("%s=%s", v.key, valueStr)
            isFirst = false
        else
            origin = string.format("%s&%s=%s", origin, v.key, valueStr)
        end
    end
    origin = string.gsub(origin,"\\/","/")
    dump(val,"val___")
    dump(self.secret,"secret:")
    dump(origin,"origin____")
    local hash = HMAC();
    local sign = hash
                .setBlockSize(64)
                .setDigest(SHA1)
                .setKey(Array.fromString(self.secret))
                .init()
                .update(Stream.fromString(origin))
                .finish()
                .asHex();

    val.sign = sign
    dump(sign,"sign____")
    return cjson.encode(val) 

end
local function urlencodechar(char)
    return "%" .. string.format("%02X", string.byte(char))
end

local function urlencodeT(input)
    -- convert line endings
    input = string.gsub(tostring(input), "\n", "\r\n")

    -- escape all characters but alphanumeric, '.' and '-'
    input = string.gsub(input, "([^%w%.%-%_%~ :/=?&#])", urlencodechar)
    -- convert spaces to "+" symbols
    return string.gsub(input, " ", "+")
end



local Aes256Encode = function(params)
    --AES256/ecb/ZeroPadding 加密  加base64
    local cipher = ECBMode.Cipher()
            .setKey(Array.fromString(aes256key))
            .setBlockCipher(AES256Cipher)
            .setPadding(ZeroPadding);
    local Output = cipher
        .init()
        .update(Stream.fromString(""))
        .update(Stream.fromString(params))
        .finish()
        .asBytes();
    local encodeStr =  Base64.fromArray(Output)
    return encodeStr
end

local Aes256Decode = function (params)
    local decipher = ECBMode.Decipher()
            .setKey(Array.fromString(aes256key))
            .setBlockCipher(AES256Cipher)
            .setPadding(ZeroPadding);
    local decodeBytes = decipher
                        .init()
                        .update(Stream.fromString(""))
                        .update(Base64.toStream(params))
                        .finish()
                        .asBytes();
                        
    local decodedata = Array.toString(decodeBytes)
    return decodedata
end
function OtherTradingBankProxy:Aes256DecodeSecret(secret)
    -- local decipher = ECBMode.Decipher()
    --         .setKey(Array.fromString(aes256key))
    --         .setBlockCipher(AES256Cipher)
    --         .setPadding(ZeroPadding);
    -- local decodeBytes = decipher
    --                     .init()
    --                     .update(Stream.fromString(""))
    --                     .update(Stream.fromString(secret))
    --                     .finish()
    --                     .asBytes();
    -- local decodedata = Array.toString(decodeBytes)
    -- return decodedata
    local decodedata = Aes256Decode(secret)
    -- dump(decodedata,"decodedata___")
    for i = 1,#decodedata do
        local char = string.byte(decodedata, i)
        if char == 0 then 
            decodedata = string.sub(decodedata, 1, i - 1)
            return decodedata
        end
    end
    return decodedata
end
function OtherTradingBankProxy:HTTPRequest(url, callback, data, header, layer, isNotNeedLoading)
    if layer then 
        if not self:findLayer(layer) then
            self:addLayer(layer)
        end
    end
    if not isNotNeedLoading then 
        UIOperator:OpenLoadingBarUI()
    end
    local params = self:getParam(clone(data))
    local encodeStr = Aes256Encode(params)
    local resUrl = string.format("%s?aes_params=%s",url,urlencodeT(encodeStr))
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("GET", resUrl)
    dump(encodeStr,"encodeStr___")
    dump(resUrl,"get __url")
    httpRequest:setRequestHeader("X-AppId", self.appid)
    httpRequest:setRequestHeader("Content-type", "application/json")
    httpRequest:setRequestHeader("X-Token", self:getToken())
    dump("token__",self:getToken())
    if header then
        for k, v in pairs(header) do
            httpRequest:setRequestHeader(k, v)
        end
    end
    ------------------------------
    if callback then
        local function HttpResponseCB()
            if not isNotNeedLoading then 
                UIOperator:CloseLoadingBarUI()
            end
            if layer then 
                if not self:findLayer(layer) then
                    return 
                end
            end
            local code = httpRequest.status
            local response = httpRequest.response
            dump({code = code,response = response},"HttpResponseCB_____Get")
            ------------------
            releasePrint("Http Request Code:" .. tostring(code))
            if code >= 200 and code < 300 then 
                local json = cjson.decode(response)
                if json.code == 50003 or json.code == 50000 then --token过期
                    if not (params.action == "takeBackRole" or params.action == "onShelfLimit") then 
                        self.m_yzToken = ""
                        self:Login1_2(function(code, msg)--重新登录操作
                            if code == 200 then
                                self:HTTPRequest(url, callback, data, header, layer)
                            else
                                ShowSystemTips(msg or "")
                            end
                        end)
                        return
                    end
                end
                ------------------解密
                local resData = json.data
                if json.code == 200 then 
                    if resData then 
                        local decodedata =  Aes256Decode(resData)
                        -- dump(decodedata,"decodedata___")
                        resData =  cjson.decode(decodedata)
                    end
                end
                ----------------------
                callback(json.code,  resData and resData.data, json.msg)
            else 
                callback(code, "", "接口异常")
            end
        end
        httpRequest:registerScriptHandler(HttpResponseCB)
    end
    httpRequest:send()
end

function OtherTradingBankProxy:HTTPRequestPost(url, callback, data, header, layer)
    if layer then 
        if not self:findLayer(layer) then
            self:addLayer(layer)
        end
    end
    UIOperator:OpenLoadingBarUI()
    local params = self:getParam(clone(data))
    -- dump(params,"params___")
    local encodeStr = Aes256Encode(params)
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("POST", url)
    dump(encodeStr,"encodeStr___")
    dump(url,"url___")
    httpRequest:setRequestHeader("X-AppId", self.appid)
    httpRequest:setRequestHeader("Content-type", "application/json")
    httpRequest:setRequestHeader("X-Token", self:getToken())
    dump(self:getToken(),"token__")
    if header then
        for k, v in pairs(header) do
            httpRequest:setRequestHeader(k, v)
        end
    end
    ------------------------------
    if callback then
        local function HttpResponseCB()
            UIOperator:CloseLoadingBarUI()
            if layer then 
                if not self:findLayer(layer) then
                    return 
                end
            end
            local code = httpRequest.status
            local response = httpRequest.response
            dump({code = code,response = response},"HttpResponseCB_____POST")
            ------------------
            releasePrint("Http Request Code:" .. tostring(code))
            
            if code >= 200 and code < 300 then 
                local json = cjson.decode(response)
                if json.code == 50003 or json.code == 50000 then --token过期
                    if not (params.action == "takeBackRole" or params.action == "onShelfLimit") then 
                        self.m_yzToken = ""
                        self:Login1_2(function(code, msg)--重新登录操作
                            if code == 200 then
                                self:HTTPRequestPost(url, callback, data, header, layer)
                            else
                                ShowSystemTips(msg or "")
                            end
                        end)
                        return
                    end
                end
                ------------------解密
                local resData = json.data
                if json.code == 200 then 
                    local decodedata =  Aes256Decode(resData)
                    -- dump(decodedata,"decodedata___")
                    resData =  cjson.decode(decodedata)
                end
                ----------------------
                callback(json.code, resData.data, json.msg)
            else 
                ShowSystemTips(string.format("请求失败 code:%s", code))
                --callback(code, "", "")
            end
        end
        httpRequest:registerScriptHandler(HttpResponseCB)
    end
    -- dump(cjson.encode({aes_params = encodeStr}),"????")
    httpRequest:send(cjson.encode({aes_params = encodeStr}))
end
function OtherTradingBankProxy:HTTPRequestPut(url, callback, data, header, layer)
    if layer then 
        if not self:findLayer(layer) then
            self:addLayer(layer)
        end
    end
    UIOperator:OpenLoadingBarUI()
    local params = self:getParam(clone(data))
    -- dump(params,"params___")
    local encodeStr = Aes256Encode(params)
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("PUT", url)
    dump(encodeStr,"encodeStr___")
    dump(url,"url___")
    httpRequest:setRequestHeader("X-AppId", self.appid)
    httpRequest:setRequestHeader("Content-type", "application/json")
    httpRequest:setRequestHeader("X-Token", self:getToken())
    dump(self:getToken(),"token__")
    if header then
        for k, v in pairs(header) do
            httpRequest:setRequestHeader(k, v)
        end
    end
    ------------------------------
    if callback then
        local function HttpResponseCB()
            UIOperator:CloseLoadingBarUI()
            if layer then 
                if not self:findLayer(layer) then
                    return 
                end
            end
            local code = httpRequest.status
            local response = httpRequest.response
            dump({code = code,response = response},"HttpResponseCB_____POST")
            ------------------
            releasePrint("Http Request Code:" .. tostring(code))
            
            if code >= 200 and code < 300 then 
                local json = cjson.decode(response)
                if json.code == 50003 or json.code == 50000 then --token过期
                    if not (params.action == "takeBackRole" or params.action == "onShelfLimit") then 
                        self.m_yzToken = ""
                        self:Login1_2(function(code, msg)--重新登录操作
                            if code == 200 then
                                self:HTTPRequestPut(url, callback, data, header, layer)
                            else
                                ShowSystemTips(msg or "")
                            end
                        end)
                        return
                    end
                end
                ------------------解密
                local resData = json.data
                if json.code == 200 then 
                    local decodedata =  Aes256Decode(resData)
                    -- dump(decodedata,"decodedata___")
                    resData =  cjson.decode(decodedata)
                end
                ----------------------
                callback(json.code, resData.data, json.msg)
            else 
                ShowSystemTips(string.format("请求失败 code:%s", code))
                --callback(code, "", "")
            end
        end
        httpRequest:registerScriptHandler(HttpResponseCB)
    end
    -- dump(cjson.encode({aes_params = encodeStr}),"????")
    httpRequest:send(cjson.encode({aes_params = encodeStr}))
end

--实名认证
function OtherTradingBankProxy:identification(layer, val, callback)
    local url = host.."/user/df/api/user/v1.2/identification"
    self:HTTPRequestPost(url, callback, val, nil, layer)
end

function OtherTradingBankProxy:Login1_2(func)
    -------------新登陆
    local params = {
        serverId = tonumber(self.loginProxy:GetSelectedServerId()),
        gameToken = self:getGameToken(),
        gameId    = tonumber(self.AuthProxy:getGameId()),
        packageName = SL:GetValue("PACKAGE_NAME"),
        roleName    = self.PlayerProperty:GetName(),
        roleId      = self.PlayerProperty:GetRoleUID()
    }
    local callback = function(code, data, msg)
        dump(data,"Login  data___")
        if code == 200 then
            self:doTrack(OtherTradingBankProxy.UpLoadData.TraingLogin)
            --self:Login(func)--再调老的  让sdk用他的token
            self.m_yzToken = data.token
            self.m_mobile = data.mobile
            self._isLogin = true
        else 
            ShowSystemTips(msg or "")
        end
        func(code, msg)
        
        -- func(code, data)
    end
    self:gameTokenLogin(params,callback)
end
--gameTokenLogin
function OtherTradingBankProxy:gameTokenLogin(val, callback)
    local url = host.."/user/pb/api/user/v1.2/gameTokenLogin"
    -- dump(url,"url")
    self:HTTPRequestPost(url, callback, val)
end
--checkBindPhone
function OtherTradingBankProxy:checkBindPhone(layer,val,callback)
    local url = host.."/user/df/api/user/v1.2/checkBindPhone"
    -- dump(url,"url")
    self:HTTPRequest(url, callback, val, nil, layer)
end
--bindPhone
function OtherTradingBankProxy:bindPhone(layer,val,callback)
    local url = host.."/user/df/api/user/v1.2/bindPhone"
    -- dump(url,"url")
    val.gameId = tonumber(self.AuthProxy:getGameId())
    val.gameToken = self:getGameToken()
    val.serverId = tonumber(self.loginProxy:GetSelectedServerId())
    self:HTTPRequestPost(url, callback, val, nil, layer)
end
--是否自己下单
function OtherTradingBankProxy:commodityIsMyOrder(layer,val,callback)
    local url = host.."/exchange/df/api/exchange/v1/commodityIsMyOrder"
    self:HTTPRequest(url, callback, val, nil, layer)
end
--获取跑马灯数据
function OtherTradingBankProxy:getScrollDataItem(layer, func)
    if #self._scrollCurData == 0 then 
        if self._scrollCacheCurCount >= self._scrollCacheCount then
            local tFunc
            tFunc = function (code, data, msg, isSchedule)
                dump({code,data,msg},"跑马灯数据")
                if code == 200 then 
                    if self._scrollScheduleID then 
                        UnSchedule(self._scrollScheduleID)
                        self._scrollScheduleID = nil
                    end
                    self._scrollCacheCurCount = 0
                    local cacheTime = data.cacheTime or 10 --缓存时间 分钟
                    cacheTime = cacheTime * 60
                    self._scrollCacheCount = data.cacheCount or 0 --缓存读取次数
                    local quickUpdate =  data.quickUpdate or 0 -- 0 缓存滚完刷新  1立即刷新
                    self._timeStep = data.timeStep or 4
                    local msgList = data.msgList or {}
                    self._scrollCacheData =  msgList
                    if isSchedule then 
                        if quickUpdate == 1  then--立即刷新
                            self._scrollCacheCurCount = 1
                            self._scrollCurData = clone(self._scrollCacheData)
                        end
                    else
                        self._scrollCacheCurCount = 1
                        self._scrollCurData = clone(self._scrollCacheData)
                        func(table.remove(self._scrollCurData, 1), self._timeStep)
                    end
                    
                    self._scrollScheduleID = PerformWithDelayGlobal(function ()
                        self._scrollScheduleID = nil
                        self:reqMarqueeList(layer, function (code, data, msg)
                            tFunc(code, data, msg, true)
                        end)
                    end, cacheTime)
                else
                    ShowSystemTips(msg or "")
                    func(nil, self._timeStep)
                end
            end
            self:reqMarqueeList(layer,tFunc)
        else 
            self._scrollCacheCurCount = self._scrollCacheCurCount + 1
            self._scrollCurData = clone(self._scrollCacheData)
            func(table.remove(self._scrollCurData, 1), self._timeStep)
        end
    else 
        func(table.remove(self._scrollCurData, 1), self._timeStep)
    end 
end
--跑马灯列表
function OtherTradingBankProxy:reqMarqueeList(layer,func)
    local url = host.."/exchange/pb/api/exchange/v1/marqueeList"
    self:HTTPRequest(url, func, nil, nil, layer, true)
end

--获取服务器名字
function OtherTradingBankProxy:getServerNames(layer,val,callback)
    local url = host.."/exchange/pb/api/exchange/v1/serverPage"
    -- val.gameIds = {tonumber(self.AuthProxy:getGameId())}
    self:HTTPRequest(url, callback, val, nil, layer)
end
--交易行公告
function OtherTradingBankProxy:getNotice(layer,val,callback)
    local url = host.."/exchange/pb/api/exchange/v1/announcement"
    -- val.gameIds = {tonumber(self.AuthProxy:getGameId())}
    self:HTTPRequest(url, callback, val, nil, layer)
end

--求购列表
function OtherTradingBankProxy:getRequestBuyData(layer,val,callback)
    local url = host.."/exchange/df/api/exchange/v1/commodityRequest/list"
    -- val.gameIds = {tonumber(self.AuthProxy:getGameId())}
    self:HTTPRequest(url, callback, val, nil, layer)
end

--提交求购
function OtherTradingBankProxy:addRequestBuyData(layer,val,callback)
    local url = host.."/exchange/df/api/exchange/v1/commodityRequest/add"
    -- val.gameIds = {tonumber(self.AuthProxy:getGameId())}
    self:HTTPRequestPost(url, callback, val, nil, layer)
end

--获取求购次数
function OtherTradingBankProxy:getRequestBuyCount(layer,val,callback)
    local url = host.."/exchange/df/api/exchange/v1/commodityRequest/todayAddQuestCount"
    -- val.gameIds = {tonumber(self.AuthProxy:getGameId())}
    self:HTTPRequest(url, callback, val, nil, layer)
end

--获取求购记录
function OtherTradingBankProxy:getRequestBuyRecord(layer,val,callback)
    local url = host.."/exchange/df/api/exchange/v1/commodityRequest/myList"
    -- val.gameIds = {tonumber(self.AuthProxy:getGameId())}
    val.pageNum = val.page
    val.pageSize = val.pagenum
    self:HTTPRequest(url, callback, val, nil, layer)
end

--删除求购记录
function OtherTradingBankProxy:deleteRequestBuyRecord(layer,val,callback)
    local url = host.."/exchange/df/api/exchange/v1/commodityRequest/delete"
    -- val.gameIds = {tonumber(self.AuthProxy:getGameId())}
    self:HTTPRequestPost(url, callback, val, nil, layer)
end

--支付
function OtherTradingBankProxy:reqpayOrder2(layer, val, callback)
    local url = host.."/pay/pt/api/pay/v1/wap/alipay"
    -- val.gameIds = {tonumber(self.AuthProxy:getGameId())}
    local params = {}
    params.bizNo = val.order_id
    params.price = val.price
    params.payChannelType =  val.channel == "HUABEI" and 4 or 1
    self:HTTPRequestPost(url, callback, params, nil, layer)
end

------------------------------
---图片上传
-----上传图片
function OtherTradingBankProxy:uploadImg2(layer, val, func)
    local params = {
        game_id = self.AuthProxy:getGameId(),
        roleId    = global.gamePlayerController:GetMainPlayerID(),
        imageType = val.position
    }
    -- --imageType
    -- for k, v in pairs(val) do
    --     params[k] = v
    -- end
    local path = val.path

    local upFunc = function (code, data, msg)
        if code == 200 then 
            dump(data,"上传接口")
            local FileUtils = cc.FileUtils:getInstance()
            if not FileUtils:isFileExist(path) then
                func(-1,"","文件不存在")
                return 
            end
            local upUrl = data
            local imageServerPath = string.match(data,"commodity_.*%.jpg")
            dump(imageServerPath,"imageServerPath___")
            local httpRequest = cc.XMLHttpRequest:new()
            httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
            httpRequest.timeout = 100000 -- 10 s
            httpRequest:open("PUT", upUrl)
            httpRequest:setRequestHeader("X-AppId", self.appid)
            httpRequest:setRequestHeader("Content-type", "image/jpeg")
            httpRequest:setRequestHeader("X-Token", self:getToken())
            dump("token__",self:getToken())
            UIOperator:OpenLoadingBarUI()
            ------------------------------
            local function HttpResponseCB()
                UIOperator:CloseLoadingBarUI()
                if layer then 
                    if not self:findLayer(layer) then
                        return 
                    end
                end
                local code = httpRequest.status
                local response = httpRequest.response
                ------------------
                releasePrint("Http Request Code:" .. tostring(code))
                if code >= 200 and code < 300 then 
                    func(code,  imageServerPath, "")
                else 
                    func(code, "", "上传图片接口异常")
                end
            end
            httpRequest:registerScriptHandler(HttpResponseCB)
            local fileData = FileUtils:getDataFromFileEx(path)
            dump(fileData,"fileData___")
            httpRequest:send(fileData)
        else
            ShowSystemTips(msg or "")
            func(code, data, msg)
        end
    end
    self:getUploadImgUrl(layer, params, upFunc)
end

function OtherTradingBankProxy:getUploadImgUrl(layer,val,callback)
    local url = host.."/exchange/df/api/exchange/v1/generatePreSignedUrl"
    -- val.gameIds = {tonumber(self.AuthProxy:getGameId())}
    self:HTTPRequest(url, callback, val, nil, layer)
end

-----上传图片 图片地址已经拿到
function OtherTradingBankProxy:uploadImg3(layer, serverurl, path, func)
    dump({serverurl,path},"上传图片地址和本地路径")
    local FileUtils = cc.FileUtils:getInstance()
    if not FileUtils:isFileExist(path) then
        func(-1,"","文件不存在")
        return 
    end
    local upUrl = serverurl
    local imageServerPath = string.match(serverurl,"commodity_.*%.jpg")
    dump(imageServerPath,"imageServerPath___")
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("PUT", upUrl)
    httpRequest:setRequestHeader("X-AppId", self.appid)
    httpRequest:setRequestHeader("Content-type", "image/jpeg")
    httpRequest:setRequestHeader("X-Token", self:getToken())
    dump("token__",self:getToken())
    UIOperator:OpenLoadingBarUI()
    ------------------------------
    local function HttpResponseCB()
        UIOperator:CloseLoadingBarUI()
        local code = httpRequest.status
        local response = httpRequest.response

        releasePrint("Http Request Code:" .. tostring(code))
        if code >= 200 and code < 300 then 
            func(code,  imageServerPath, "")
        else 
            func(code, "", "上传图片接口异常")
        end
    end
    httpRequest:registerScriptHandler(HttpResponseCB)
    local fileData = FileUtils:getDataFromFileEx(path)
    dump(fileData,"fileData___")
    httpRequest:send(fileData)
end

---------------
OtherTradingBankProxy.UpLoadData = {
    TraingIconBtnClick = {event = {name = "click"},properities = {button_name = "交易行入口按钮"}},
    TraingBuyLayerClick = {event = {name = "click"},properities = {button_name = "购买页签按钮"}},
    TraingBuyLayerBuyBtnClick = {event = {name = "click"},properities = {button_name = "购买界面“购买”按钮"}},
    TraingBuyLayerSearchBtnClick = {event = {name = "click"},properities = {button_name = "购买界面“搜索”按钮"}},
    TraingBuyLayerOKBtnClick = {event = {name = "click"},properities = {button_name = "购买界面“确认支付”按钮"}},
    TraingSellLayerClick = {event = {name = "click"},properities = {button_name = "寄售页签按钮"}},
    TraingSellLayerNextBtnClick = {event = {name = "click"},properities = {button_name = "寄售界面”下一步“按钮"}},
    TraingGoodsLayerClick = {event = {name = "click"},properities = {button_name = "货架页签按钮"}},
    TraingGoodsLayerDownBtnClick = {event = {name = "click"},properities = {button_name = "货架界面“下架”按钮"}},
    TraingGoodsLayerGetBtnClick = {event = {name = "click"},properities = {button_name = "货架界面“取回”按钮"}},
    TraingGoodsLayerModityBtnClick = {event = {name = "click"},properities = {button_name = "货架界面“修改”按钮"}},
    TraingMeLayerClick = {event = {name = "click"},properities = {button_name = "我的页签按钮"}},
    TraingMeLayerGetMoneyBtnClick = {event = {name = "click"},properities = {button_name = "我的界面“提现”按钮"}},
    TraingGetMoneyLayerApplyBtnClick = {event = {name = "click"},properities = {button_name = "提现确认界面“申请提现”按钮"}},
    --TraingGetMoneyLayerApplyBtnClick = {event = {name = "click"},properities = {button_name = "指定我按钮"}},
    TraingRoleSell = {event = {name = "put_on_shelves"},properities = {goods_type = "角色",num = 1 }},
    TraingMoneySell = {event = {name = "put_on_shelves"},properities = {goods_type = "货币" }},
    TraingCreateOrder = {event = {name = "prepay"},properities = {platform = "alipay"}},
    TraingLogin = {event = {name = "user_login"},properities = {}},
    TraingRegister = {event = {name = "user_register"},properities = {}},
    TraingBuyLayerReqBuyBtnClick = {event = {name = "click"},properities = {button_name = "购买界面“求购”页签"}},
    TraingReqBuyShowGoSellClick = {event = {name = "click"},properities = {button_name = "求购展示页-去寄售按钮"}},
    TraingReqBuyLayerPutClick = {event = {name = "click"},properities = {button_name = "求购页-发布求购按钮"}},
    TraingMeLayerReqBuyRecordBtnClick = {event = {name = "click"},properities = {button_name = "我的页面“求购记录“按钮"}},
    TraingReqBuyRecordOKBtnClick = {event = {name = "click"},properities = {button_name = "求购记录”确认删除“按钮"}},
}
--数据上报
function OtherTradingBankProxy:doTrack(val, params)
    local url = host.."/exchange/pb/api/eventTracking/v1/doTrack"
    local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local netType = envProxy:GetNetType()
    local networkDesc = {[-1] = "UNKNOWN", [0] = "WIFI", [1] = "2G", [2] = "3G", [3] = "4G"}
    local device_t  = global.isAndroid and "android" or "ios"
    local director = global.Director
    local view = director:getOpenGLView()
    local framesize = view:getFrameSize()
    if global.isWindows then
        device_t = "pc"
    end
    -- dump(url,"url")
    val.sdk_ver = "1.0.10"
    val.app_ver = SL:GetValue("REMOTE_RES_VERSION")--游戏版本号
    val.channel = SL:GetValue("CHANNEL_ID")
    val.net_type = networkDesc[netType]

    val.device = {
        type = device_t,
        model = "UNKNOWN",
        id = self:getUUID(),
        os = "UNKNOWN",
        width = framesize.width,
        height = framesize.height,
    }
    val.event = val.event or {}
    val.event.time = os.time()
    val.event.type = "track"

    val.user ={
        id = tostring( self.AuthProxy:GetUID() )
    } 

    val.properities = val.properities or {}
    val.properities.servid      = tonumber(self.loginProxy:GetSelectedServerId())
    val.properities.server_name = self.loginProxy:GetSelectedServerName()
    val.properities.role_id     = global.gamePlayerController:GetMainPlayerID()
    val.properities.role_name   = self.loginProxy:GetSelectedRoleName()
    val.properities.role_level  = self.PlayerProperty:GetRoleLevel()
    val.properities.job_id      = self.PlayerProperty:GetRoleJob()
    val.properities.job_name = SL:GetValue("JOB_NAME",val.job_id)--职业名
    val.properities.game_id = tonumber(self.AuthProxy:getGameId())
    if params and params.properities  then 
        for k, v in pairs(params.properities) do
            val.properities[k] = v
        end
    end
    dump(val,"上报数据——————————")
    local jsonStr = cjson.encode(val) 
    local p = {eventJson = jsonStr}
    local func = function (code,data,msg)
        dump({code,data,msg},"上报结果")
    end
    self:HTTPRequestPostUpLoad(url, func, p)
end

--模拟一下  就第一个角色id+时间戳
function OtherTradingBankProxy:getUUID()
    local path = "TradingBankConfig"
    local userData = UserData:new(path)
    local key = "uuid"
    local jsonStr = userData:getStringForKey(key, "")
    if not jsonStr or string.len(jsonStr) == 0 then
        jsonStr = string.format("%s_%s", global.gamePlayerController:GetMainPlayerID(), os.time())   
        userData:setStringForKey(key, jsonStr)
    end
    return jsonStr
end
function OtherTradingBankProxy:HTTPRequestPostUpLoad(url, callback, data)
    local params = self:getParam(clone(data))
    -- dump(params,"params___")
    local encodeStr = Aes256Encode(params)
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("POST", url)
    dump(encodeStr,"encodeStr___")
    dump(url,"url___")
    httpRequest:setRequestHeader("X-AppId", self.appid)
    httpRequest:setRequestHeader("Content-type", "application/json")
    httpRequest:setRequestHeader("X-Token", self:getToken())
    ------------------------------
    if callback then
        local function HttpResponseCB()
            local code = httpRequest.status
            local response = httpRequest.response
            dump({code = code,response = response},"HttpResponseCB_____POST上报")
            ------------------
            releasePrint("Http Request Code:" .. tostring(code))
            
            if code >= 200 and code < 300 then 
                local json = cjson.decode(response)
                ------------------解密
                local resData = json.data
                if json.code == 200 then 
                    local decodedata =  Aes256Decode(resData)
                    -- dump(decodedata,"decodedata___")
                    resData =  cjson.decode(decodedata)
                end
                ----------------------
                callback(json.code, resData.data, json.msg)
            else 
            end
        end
        httpRequest:registerScriptHandler(HttpResponseCB)
    end
    -- dump(cjson.encode({aes_params = encodeStr}),"????")
    httpRequest:send(cjson.encode({aes_params = encodeStr}))
end
----------------------
function OtherTradingBankProxy:captureResult(data)
    local params = {
        action = "captureResult",
        isH5 = true,
        params = {
        },
    }
    local isHero = false
    local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    if HeroPropertyProxy:IsHeroOpen() then
        if HeroPropertyProxy:GetIsMakeHero() then
            if HeroPropertyProxy:HeroIsLogin() then
                isHero = true
            end
        end
    end
    local res = {}
    dump(isHero,"isHero")
    if isHero then
        res = {
            uid         = self.AuthProxy:GetUID(),
            game_id     = self.AuthProxy:getGameId(),
            server_id   = self.loginProxy:GetSelectedServerId(),
            server_name = self.loginProxy:GetSelectedServerName(),
            role_id     = global.gamePlayerController:GetMainPlayerID(),
            role        = self.PlayerProperty:GetName(),
            sex         = self.PlayerProperty:GetRoleSex(),
            vip         = 0,
            role_level  = self.PlayerProperty:GetRoleLevel(),
            ablity      = self.PlayerProperty:GetRoleAttByAttType(GUIFunction:PShowAttType().Max_ATK),
            role_type   = self.PlayerProperty:GetRoleJob(),
            images      = data,
            game_type   = 1,

            hero_role_id   = self.HeroPropertyProxy:GetRoleUID(),          --英雄角色ID
            hero_name      = self.HeroPropertyProxy:GetName(),             --英雄角色名字
            hero_sex       = self.HeroPropertyProxy:GetRoleSex(),          --英雄性别
            hero_level     = self.HeroPropertyProxy:GetRoleLevel(),        --英雄角色等级
            hero_role_type = self.HeroPropertyProxy:GetRoleJob(),          --英雄职业
            hero_rein_lv = self.HeroPropertyProxy:GetRoleReinLv(),         --转生
            hero_ability   = self.HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Max_ATK)--英雄战力
        }
    else
        res = {
            uid         = self.AuthProxy:GetUID(),
            game_id     = self.AuthProxy:getGameId(),
            server_id   = self.loginProxy:GetSelectedServerId(),
            server_name = self.loginProxy:GetSelectedServerName(),
            role_id     = global.gamePlayerController:GetMainPlayerID(),
            role        = self.PlayerProperty:GetName(),
            sex         = self.PlayerProperty:GetRoleSex(),
            vip         = 0,
            role_level  = self.PlayerProperty:GetRoleLevel(),
            ablity      = self.PlayerProperty:GetRoleAttByAttType(GUIFunction:PShowAttType().Max_ATK),
            role_type   = self.PlayerProperty:GetRoleJob(),
            images      = data,
            game_type   = 1
        }
    end
    -- for k, v in pairs(data) do
    --     res[k] = v
    -- end
    params.params.res = cjson.encode(res)
    self:addToCallFunc(params)
end

function OtherTradingBankProxy:setGameTokenToH5(token)
    local params = {
        action = "setGameToken",
        isH5 = true,
        params = {
        },
    }
    local currentModule     = global.L_ModuleManager:GetCurrentModule()
    local gameName = currentModule:GetName()
    local job_id = self.PlayerProperty:GetRoleJob()


    local gameSkdEnv = "pro"
    if self._environment == 0 then 
        gameSkdEnv = "test"
    elseif self._environment == 1 then 
        gameSkdEnv = "pre"
    end
    params.params.info = cjson.encode({
        game_token = token,
        game_id = tonumber(self.AuthProxy:getGameId()), 
        server_id = tonumber(self.loginProxy:GetSelectedServerId()),
        role        = self.PlayerProperty:GetName(),
        server_name = self.loginProxy:GetSelectedServerName(),
        role_id     = global.gamePlayerController:GetMainPlayerID(),
        game_name = gameName,
        vip = 0,
        role_level = self.PlayerProperty:GetRoleLevel(),
        game_type    = 1,
        job_id      = job_id,
        job_name =  GUIFunction:GetJobNameByID(job_id),
        h5sdkApiVer = "v2",
        gameSkdEnv = gameSkdEnv
    })
    self:addToCallFunc(params)
end

function OtherTradingBankProxy:showTradingView()
    local params = {
        action = "showTradingView",
        isH5 = true,
        params = {
        },
    }
    
    self:addToCallFunc(params)
end

function OtherTradingBankProxy:IsInSafeArea()
    
    local MapProxy = global.Facade:retrieveProxy( global.ProxyTable.MapProxy )
    local res =  MapProxy:IsInSafeArea() 
    local params = {
        action = "IsInSafeArea",
        isH5 = true,
        params = {
            res = res and 1 or 0
        },
    }
    dump(params,"IsInSafeArea___")
    self:addToCallFunc(params)
end

function OtherTradingBankProxy:showBackToView()
    if self._showBackToView then 
        return 
    end
    local params = {
        action = "showBackToView",
        isH5 = true,
        params = {
        },
    }
    self._showBackToView = true
    self:addToCallFunc(params)
end

function OtherTradingBankProxy:dismissBackToView()
    if not self._showBackToView then 
        return 
    end
    self._showBackToView = false
    local params = {
        action = "dismissBackToView",
        isH5 = true,
        params = {
        },
    }
    
    self:addToCallFunc(params)
end

function OtherTradingBankProxy:setLoginSuccessTimes()
        local uid       = self.AuthProxy:GetUID() or ""
        local params = {
            action = "setLoginSuccessTimes",
            isH5 = true,
            params = {
                time    = os.time(),
                uid     = uid,
                gameId  = tonumber(self.AuthProxy:getGameId()),
            },
        }

    self:addToCallFunc(params)
end

function OtherTradingBankProxy:initSDK()
    local currModule = global.L_ModuleManager:GetCurrentModule()
    local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local manifestVer = currModule:GetRemoteVersion() or ""
    local channelID = envProxy:GetChannelID() or ""
    local uid       = self.AuthProxy:GetUID() or ""
    local exData = {
        app_ver = manifestVer,
        channel = channelID,
        id =  uid
    }
    local jsonStr = cjson.encode(exData)
    local params = {
        action = "initSDK",
        isH5 = true,
        params = {
            appid = self.appid ,
            secret = self.secret,
            serverId = tonumber(self.loginProxy:GetSelectedServerId()),
            exJsonStr = jsonStr
        },
    }
    self:addToCallFunc(params)
end

function OtherTradingBankProxy:initReportParam()
    local currModule = global.L_ModuleManager:GetCurrentModule()
    local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local manifestVer = currModule:GetRemoteVersion() or ""
    local channelID = envProxy:GetChannelID() or ""
    local uid       = self.AuthProxy:GetUID() or ""
    local exData = {
        app_ver = manifestVer,
        channel = channelID,
        id =  uid 
    }
    local jsonStr = cjson.encode(exData)
    local params = {
        action = "initReportParam",
        isH5 = true,
        params = {
            exJsonStr = jsonStr
        },
    }
    self:addToCallFunc(params)
end
return OtherTradingBankProxy