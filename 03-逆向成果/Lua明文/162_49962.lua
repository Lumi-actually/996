local RemoteProxy = requireProxy("RemoteProxy")
local LoginProxy = class("LoginProxy", RemoteProxy)
LoginProxy.NAME = global.ProxyTable.LoginProxy
local cjson = require("cjson")

-- for debug mode, login whitelist
local DebugToken = "sJAsOn001"
local checkLoginConnectTime = 10

local function RestartGame()
    -- pc关闭游戏，方便使用新的登录信息和更新exe
    if global.isWindows and not (global.isDebugMode or global.isGMMode) then
        global.Facade:sendNotification(global.NoticeTable.ShutdownGame)
    else
        global.L_NativeBridgeManager:GN_accountLogout()
        global.Facade:sendNotification( global.NoticeTable.RestartGame ) 
    end
end

-- 网络消息水印头
function GET_NET_MSG_STAMP_HEAD_PARAM0()
    return 900000
end
function GET_NET_MSG_STAMP_HEAD_PARAM1()
    return math.random(1,1000000000)
end

LoginProxy.param1Ex = nil
function GET_NET_MSG_STAMP_HEAD_PARAM1_NEW(func)
    if LoginProxy.param1Ex then 
        func(LoginProxy.param1Ex)
        return 
    end
    local currentModule = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv = currentModule:GetGameEnv()
    local NetStampHost  = moduleGameEnv:GetCustomDataByKey("NetStampHost")
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local serverID = tonumber(LoginProxy:GetMainSelectedServerId() or LoginProxy:GetSelectedServerId()) or 0
    local netUrl = string.format("%s%s.txt", NetStampHost, get_str_MD5(tostring(serverID))) 
    local fileUtil = global.FileUtilCtl
    local filePath = global.WritablePath .. "_temp_net_"
    if fileUtil:isFileExist(filePath) then
        fileUtil:removeFile(filePath)
    end
    HTTPRequest(netUrl,function (success, response)
        local param1 = bit.band(math.random(100000000,2100000000),0xFFFF00FF)  
        if success then 
            fileUtil:writeStringToFile(response, filePath)
            local netInfoStr = fileUtil:getDataFromFileEx(filePath)
            local netInfo = cjson.decode(netInfoStr)
            local index = L8Bit(netInfo.UnixTime) + 1
            param1 = netInfo.Sequence[index]
            param1 = tonumber(param1) or 0
            LoginProxy.param1Ex = param1
        end
        func(param1)
    end)
end

----------------------------------------------------------------------
function LoginProxy:ctor()
    LoginProxy.super.ctor(self)

    self._roleServerPort    = nil
    self._gameServerIP      = nil
    self._gameServerPort    = nil
    self._loginKey          = ""   -- 529号消息返回的key
    self._sessionID         = nil

    -- 角色
    self._roleInfo          = {}
    self._selectRole        = {}
    self._restoreRoleInfo   = {}
    self._restoreTag        = nil

    -- 公告内容+服务端版本号
    self._tipsContent       = ""
    self._serviceVer        = ""

    -- 服务器返回开关
    self._forbidName        = false -- 服务器控制开关，是否禁止取名字
    self._forbidChat        = false -- 服务器控制开关，是否禁止聊天等

    self._loginScheduler    = nil

    self._requestEnterWorld = false
    self._closeGameWorldStatus = false
end

function LoginProxy:IsForbidName()
    return self._forbidName
end

function LoginProxy:SetForbidChat(v)
    self._forbidChat = v
end
function LoginProxy:IsForbidChat()
    return self._forbidChat
end

function LoginProxy:SetTipsContent(content)
    self._tipsContent = content
end
function LoginProxy:GetTipsContent()
    return self._tipsContent
end

function LoginProxy:SetServiceVer(ver)
    self._serviceVer = ver
end
function LoginProxy:GetServiceVer()
    return self._serviceVer
end

function LoginProxy:GetSelectedServer()
    local currentModule = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv = currentModule:GetGameEnv()
    return moduleGameEnv:GetSelectedServer()
end

function LoginProxy:GetSelectedServerDomain() -- 当前选择的服务器 域名
    local server = self:GetSelectedServer()
    if server then
        return server.ip
    end

    return nil
end

function LoginProxy:GetMainSelectedServerId() -- 当前选择的服务器 主服id
    local server = self:GetSelectedServer()
    if server then
        return server.mainServerId
    end

    return nil
end

function LoginProxy:GetMainSelectedServerName() -- 当前选择的服务器 主服name
    local server = self:GetSelectedServer()
    if server then
        return server.mainServerName
    end

    return nil
end

function LoginProxy:GetSelectedServerId() -- 当前选择的服务器 id
    local server = self:GetSelectedServer()
    if server then
        return server.serverId
    end

    return nil
end

function LoginProxy:GetSelectedServerName() -- 当前选择的服务器 name
    local server = self:GetSelectedServer()
    if server then
        return server.serverName
    end

    return nil
end

function LoginProxy:GetSelectedServerUrlSuffix() -- 当前选择的服务器 资源URL 后缀
    local server = self:GetSelectedServer()
    if server then
        return server.urlSuffix
    end

    return nil
end

function LoginProxy:GetSelectedServerIp() -- 当前选择的服务器 ip 地址
    local server = self:GetSelectedServer()
    if server then
        return server.ip
    end

    return nil
end

function LoginProxy:GetSelectedServerPort() -- 当前选择的服务器 端口
    local server = self:GetSelectedServer()
    if server then
        return tonumber(server.port)
    end

    return nil
end

function LoginProxy:GetSelectedServerProxyPort() -- 当前选择的服务器 代理端口
    local server = self:GetSelectedServer()
    if server then
        return tonumber(server.proxyport)
    end

    return nil
end

function LoginProxy:SetGameServerIP(ip)
    self._gameServerIP = ip
end

function LoginProxy:GetGameServerIP()
    return self._gameServerIP
end

function LoginProxy:SetGameServerPort(port)
    self._gameServerPort = port
end

function LoginProxy:GetGameServerPort()
    return self._gameServerPort
end

function LoginProxy:SetRoleServerPort(port)
    self._roleServerPort = port
end

function LoginProxy:GetRoleServerPort()
    return self._roleServerPort
end

-- roles
function LoginProxy:SetSelectedRole(role)
    self._selectRole = role
end

function LoginProxy:GetSelectedRole()
    return self._selectRole
end

function LoginProxy:SetSelectedRoleByIndex(index)
    local role = self._roleInfo[index]
    if role then
        self._selectRole = role
    else
        self._selectRole = nil
    end
end

function LoginProxy:GetSelectedRoleName() -- 当前选择的角色 name
    if self._selectRole then
        return self._selectRole.name
    end
    return nil
end

function LoginProxy:GetSelectedRoleID() --当前选择的角色ID
    if self._selectRole then
        return self._selectRole.roleid
    end
    return nil
end

function LoginProxy:GetSelectedRoleCTime() --当前选择的角色创建时间
    if self._selectRole and self._selectRole.ctime then
        return self._selectRole.ctime
    end
    return 0
end

function LoginProxy:GetAllRoleInfo()
    return self._roleInfo
end

function LoginProxy:AddRole(role)
    table.insert(self._roleInfo, role)

    for i, v in ipairs(self._roleInfo) do
        v.index = i
    end
end

function LoginProxy:DecRoleByID(roleid)
    for k, v in pairs(self._roleInfo) do
        if v.roleid == roleid then
            table.remove(self._roleInfo, k)
            break
        end
    end
    for i, v in ipairs(self._roleInfo) do
        v.index = i
    end
end

function LoginProxy:ClearAllRoleInfo()
    self._roleInfo = {}
    self._selectRole = nil
end
--- 

-- 服务器LoginKey
function LoginProxy:SetLoginKey(value)
    self._loginKey = value
end
function LoginProxy:GetLoginKey()
    return self._loginKey
end

-- 服务器session
function LoginProxy:SetSessionID(value)
    self._sessionID = value
end
function LoginProxy:GetSessionID()
    return self._sessionID
end

-- 
function LoginProxy:StartLoginScheduler(msg)
    if self._loginScheduler then
        return
    end
    self._loginScheduler = SL:ScheduleOnce(function()
        UIOperator:CloseLoadingBarUI()
        self:ClearRequestStatus()

        local data = {}
        data.str = string.format("连接服务器超时 %s", msg)
        data.btnDesc = {GET_STRING(1002)}
        data.callback = RestartGame
        UIOperator:OpenCommonTipsUI(data)
    end, checkLoginConnectTime)
end

function LoginProxy:StopLoginScheduler()
    if self._loginScheduler then
        UnSchedule(self._loginScheduler)
        self._loginScheduler = nil
    end
end

function LoginProxy:SetCloseGameWorldStatus(value)
    self._closeGameWorldStatus = value == true
end

function LoginProxy:IsCloseGameWorldStatus()
    return self._closeGameWorldStatus
end

function LoginProxy:ClearRequestStatus()
    self._requestEnterWorld = false
    self._closeGameWorldStatus = false
end

----------------------------------------------------------------------
-- -> step 0. connect
function LoginProxy:RequestConnectLoginServer() 
    releasePrint(" -> step 0. RequestConnectLoginServer")

    local selectServer = self:GetSelectedServer()

    releasePrint(cjson.encode(selectServer), "____selectServer")

    -- 没有选择服务器
    if not selectServer or not selectServer.ip or not selectServer.port then
        local data = {}
        data.str = GET_STRING(30009001)
        data.btnDesc = {GET_STRING(1002)}
        data.callback = RestartGame
        UIOperator:OpenCommonTipsUI(data)
        return
    end

    -- 服务器未开启
    local currentModule = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv = currentModule:GetGameEnv()
    if selectServer.state == 4 and (moduleGameEnv:IsWhitelist() == false) then
        local data = {}
        data.str = GET_STRING(30009002)
        data.btnDesc = {GET_STRING(1002)}
        data.callback = RestartGame
        UIOperator:OpenCommonTipsUI(data)
        return
    end

    local ip          = self:GetSelectedServerIp()
    local port        = self:GetSelectedServerPort()
    local proxyport   = self:GetSelectedServerProxyPort()
    local connectIP   = tostring(ip)
    local connectPort = tonumber(proxyport or port)
    self:SetRoleServerPort(connectPort)

    local debugPort     = nil
    local debugIp       = nil
    if SL._DEBUG then 
        debugPort     = global.L_GameEnvManager:GetEnvDataByKey("DebugPort")
        debugIp       = global.L_GameEnvManager:GetEnvDataByKey("DebugIp")
        if debugIp and debugPort then
            connectIP     = tostring(debugIp)
            connectPort   = tonumber(debugPort)
        end
    end

    -- // connect server
    local connectFunc = function (param1Ex)
        global.networkCtl:Disconnect()
        global.networkCtl:Connect(connectIP, connectPort)
        releasePrint("tcp connect to: ", connectIP, connectPort, global.networkCtl:IsConnected())
        if global.networkCtl:IsConnected() then
            self:RequestLoginServer()
        else
            local data = {}
            data.str = GET_STRING(30009003)
            data.btnDesc = {GET_STRING(1002)}
            data.callback = RestartGame
            UIOperator:OpenCommonTipsUI(data)
        end
    end
    if proxyport then 
        GET_NET_MSG_STAMP_HEAD_PARAM1_NEW(function (param1Ex)
            connectFunc(param1Ex)
        end)
    else
        connectFunc()
    end
end

-- -> step 1. 2001
function LoginProxy:RequestLoginServer()
    -- // 1. message 2001 - request server lis
    -- login
    local envProxy  = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local channelID = envProxy:GetChannelID()
    local encodechannelID = Encode6BitBuf(channelID, string.len(channelID))
    local account   = AuthProxy:GetUID()
    local password  = AuthProxy:GetToken()
    -- for debug mode, login whitelist
    if global.isDebugMode then
        password = DebugToken
    end
    local pwdSession = Encode6BitBuf(password, string.len(password))
    
    local sendStr = string.format("%s/%s/%s", account, pwdSession, encodechannelID)
    local param0 = GET_NET_MSG_STAMP_HEAD_PARAM0()
    local param1 = LoginProxy.param1Ex or GET_NET_MSG_STAMP_HEAD_PARAM1()
    local param2 = tonumber(self:GetMainSelectedServerId() or self:GetSelectedServerId()) or 0
    local param3 = tonumber(self:GetSelectedServerPort()) or 0
    
    self:StartLoginScheduler("2001 -> 529 / 503")
    LuaSendMsg(global.MsgType.MSG_CS_REQUEST_SERVER_LIST, param0, param1, param2, param3, sendStr)
    releasePrint(" -> step 1. 2001 MSG_CS_REQUEST_SERVER_LIST", sendStr)
end

-- <- step 2. 503
function LoginProxy:handle_MSG_SC_RESPOINSE_CHECK_TOKEN_FAIL(msg)
    releasePrint(" <- step 2. 503 handle_MSG_SC_RESPOINSE_CHECK_TOKEN_FAIL")
    self:StopLoginScheduler()

    -- recog  -99 = 信息不全  -6 = 认证失败！   101 = 二次验证失败  999 = 账号被封
    local header = msg:GetHeader()
    local bodyStr   = msg:GetBodyStr()
    local bodyTitle = nil
    if bodyStr and string.len(bodyStr) > 0 then
        bodyTitle = Decode6BitBuf(bodyStr, string.len(bodyStr))
    end

    if header.recog == -99 then
        local data = {}
        data.str    = bodyTitle or GET_STRING(30009104)
        data.btnDesc = { GET_STRING(1002)}
        data.callback = RestartGame
        UIOperator:OpenCommonTipsUI(data)
        
    elseif header.recog == -6 then
        local data = {}
        data.str    = bodyTitle or GET_STRING(30009105)
        data.btnDesc = { GET_STRING(1002)}
        data.callback = RestartGame
        UIOperator:OpenCommonTipsUI(data)
    elseif header.recog == 101 then
        local data = {}
        data.str    = bodyTitle or "账号认证失败，请重新登录游戏。"
        data.btnDesc = { GET_STRING(1002)}
        data.callback = RestartGame
        UIOperator:OpenCommonTipsUI(data)
    elseif header.recog == 999 then
        local time = header.param3
        local date = os.date("*t", time)
        local timeStr = string.format("%d-%02d-%02d %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec)
        local titlStr = bodyTitle or "账号或IP已被限制登录,请稍后再试!\n"
        local data = {}
        data.str    = string.format("%s\n解封时间:%s", titlStr, timeStr)
        data.btnDesc = { GET_STRING(1002)}
        data.callback = RestartGame
        UIOperator:OpenCommonTipsUI(data)
    end
end

-- <- step 2. 529
function LoginProxy:handle_MSG_SC_RESPONSE_SERVER_LIST(netPkg, msgID)
    releasePrint(" <- step 2. 529 handle_MSG_SC_RESPONSE_SERVER_LIST")
    self:StopLoginScheduler()

    local bodyStr  = netPkg:GetBodyStr()
    local slices   = G_GetSplitArray(bodyStr, "/")
    local loginKey = slices[1] or ""
    local userID   = slices[2]
    self:SetLoginKey(loginKey)

    -- 
    local DataTrackProxy = global.Facade:retrieveProxy(global.ProxyTable.DataTrackProxy)
    DataTrackProxy:OnResponseLoginUserID(userID)
    DataTrackProxy:RecordBuglyLoginUserData()
    
    -- next
    self:RequestServerInfo()
end

-- -> step 3. 104
function LoginProxy:RequestServerInfo()
    releasePrint(" -> step 3. 104 RequestServerInfo")

    local loginKey = self:GetLoginKey()
    self:StartLoginScheduler("104 -> 530")
    LuaSendMsg(global.MsgType.MSG_CS_REQUEST_SERVER_INFO, 0, 0, 0, 0, loginKey)
end

-- <- step 4. 530
function LoginProxy:handle_MSG_SC_RESPONSE_SERVER_INFO(netPkg)
    releasePrint(" <- step 4. 530 handle_MSG_SC_RESPONSE_SERVER_INFO")
    self:StopLoginScheduler()

    local sessionID = netPkg:GetP0()
    self:SetSessionID(sessionID)

    -- next
    self:RequestRoleInfo()
end

-- -> step 5. 100
function LoginProxy:RequestRoleInfo()
    releasePrint(" -> step 5. 100 RequestRoleInfo")
    self:StartLoginScheduler("100 -> 520 / 527")

    local envProxy   = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local AuthProxy  = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local gameID     = global.L_ModuleManager:GetCurrentModule():GetOperID() or "0"
    local channelID  = envProxy:GetChannelID()
    local account    = AuthProxy:GetUID()
    local sessionID  = self:GetSessionID()
    local serverID   = self:GetSelectedServerId()
    local loginkey   = self:GetLoginKey()

    -- 请求角色信息
    -- login
    -- 100 （查询角色）  格式：帐号/SessionId/服务器名/主SdkId/子SdkId
    -- TODO, sdk id
    local param0 = GET_NET_MSG_STAMP_HEAD_PARAM0()
    local param1 = GET_NET_MSG_STAMP_HEAD_PARAM1()
    local param2 = tonumber(self:GetMainSelectedServerId() or self:GetSelectedServerId()) or 0
    local param3 = tonumber(self:GetSelectedServerPort()) or 0
    local sendStr = string.format("%s/%d/%s/%s/%s/%s", account, sessionID, serverID, channelID, gameID, loginkey)
    LuaSendMsg(global.MsgType.MSG_CS_REQUEST_ROLE_INFO, param0, param1, param2, param3, sendStr)
end

-- <- step 6. 527
function LoginProxy:handle_MSG_SC_RESPOINSE_ROLE_INFO_FAIL(netPkg)
    releasePrint(" <- step 6. 527 handle_MSG_SC_RESPOINSE_ROLE_INFO_FAIL")
    self:StopLoginScheduler()

    UIOperator:CloseLoadingBarUI()

    local param1 = netPkg:GetP1()
    if param1 == 1 then
        -- 会话错误
        ShowSystemTips(GET_STRING(30009080))
    elseif param1 == 2 then
        -- serverID为空
        ShowSystemTips(GET_STRING(30009081))
        
    elseif param1 == 3 then
        -- serverID异常
        ShowSystemTips(GET_STRING(30009082))

    end

    local function callback(bType, custom)
        if bType == 1 then
            self:RequestLoginServer()
        elseif bType == 2 then
            RestartGame()
        end
    end
    local data = {}
    data.str = GET_STRING(30009004)
    data.btnDesc = {GET_STRING(30009045), GET_STRING(30009046)}
    data.callback = callback
    UIOperator:OpenCommonTipsUI(data)
end

-- <- step 6. 520
function LoginProxy:handle_MSG_SC_RESPOINSE_ROLE_INFO(netPkg)
    releasePrint(" <- step 6. 520 handle_MSG_SC_RESPOINSE_ROLE_INFO")
    self:StopLoginScheduler()

    UIOperator:CloseLoadingBarUI()

    -- 清除角色信息
    self:ClearAllRoleInfo()

    -- headr 第一个：封第一个角色 第二个：封第二个角色
    local p0 = netPkg:GetP0()
    local p1 = netPkg:GetP1()
    local p2 = netPkg:GetP2()
    local p3 = netPkg:GetP3()
    local blocked = {}
    blocked[1] = (p0 == 2)
    blocked[2] = (p1 == 2)

    -- 禁止自定义取名编辑
    self._forbidName = p3 == 1

    local jsonStr = netPkg:GetBodyStr()
    local jsonData = cjson.decode(jsonStr)
    
    -- 无角色
    if not jsonData.list or not next(jsonData.list) then
    else
        local lastIndex = 0
        for i, v in ipairs(jsonData.list) do
            v.name   = v.chr
            v.renew  = v.relevel
            v.ctime  = v.create_time or GetServerTime()
            v.roleid = v.UserID
            v.blocked = (v.deny_ip == 1 or v.deny_account == 1 or v.deny_uid == 1)
            v.newChar = v.newChar
            v.LockChar = v.LockChar
            v.deny_msg = v.deny_msg
            v.deny_time = v.deny_time
            self:AddRole(v)
    
            if v.last == 1 then
                lastIndex = i
            end

            if self._restoreTag and self._restoreTag == v.UserID then   -- 恢复角色id
                self._restoreIndex = i
            end
        end

        -- 计算上次选择
        if lastIndex > 0 then
            self:SetSelectedRoleByIndex(lastIndex)
        elseif #jsonData.list >= 1 then
            self:SetSelectedRoleByIndex(1)
        end

        -- 恢复角色下标
        if self._restoreIndex then
            self:SetSelectedRoleByIndex(self._restoreIndex)
            self._restoreIndex = nil
            self._restoreTag = nil
        end
    end

    -- 登录服务器成功
    SLBridge:onLUAEvent(LUA_EVENT_LOGIN_SERVER_SUCCESS)
    SLBridge:onLUAEvent(LUA_EVENT_LOGIN_ROLE_INFO_DATA)


    -- 数据上报
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local account   = AuthProxy:GetUID()
    local jData     = {}
    jData.zoneId    = self:GetSelectedServerId()
    jData.zoneName  = self:GetSelectedServerName()
    jData.userId    = account
    jData.promoteId = tostring(global.L_GameEnvManager:GetGMName())
    local DataTrackProxy = global.Facade:retrieveProxy(global.ProxyTable.DataTrackProxy)
    DataTrackProxy:OnRoleInfo(jData)

    -- 刷新角色数量 (上次登录数据来源)
    local module            = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv     = module:GetGameEnv()
    local roleData          = self._roleInfo or {}
    if moduleGameEnv.SetRoleCountByServerID then 
        moduleGameEnv:SetRoleCountByServerID(self:GetSelectedServerId(), #roleData)
    end
 
end

function LoginProxy:CheckRoleIsBlocked(role, autoShowTips)
    if role and role.blocked then
        if autoShowTips then
            self:ShowRoleBlockedTips(role)
        end

        return true
    end

    return false
end

function LoginProxy:ShowRoleBlockedTips(role)
    UIOperator:CloseLoadingBarUI()

    -- 封禁客户端自行拼接时间轴，封禁时间 > 15天时不提醒时间
    local str = GET_STRING(30009034)
    if role.deny_msg and role.deny_msg ~= "" then
        str = role.deny_msg
        if role.deny_time and role.deny_time > os.time() and role.deny_time - os.time() < 15*24*60*60 then
            local date = os.date("*t", role.deny_time)
            local timeStr = string.format("%d-%02d-%02d %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec)
            str = str .. "<br>" .. string.format(GET_STRING(30009079), timeStr)
        end
    end

    local data = {}
    data.str = str
    data.btnDesc = {GET_STRING(1002)}
    data.callback = RestartGame
    UIOperator:OpenCommonTipsUI(data)
end

-- -> step 6.1 101
function LoginProxy:RequestCreateRole(name, job, sex)
    releasePrint(" -> step 6.1 101 RequestCreateRole")
    self:StartLoginScheduler("101 -> 521 / 522")

    local envProxy  = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local account   = AuthProxy:GetUID()
    -- login
    -- 101 （创建角色）  格式：帐号/角色名/职业/性别/服务器名/主SdkId/子SdkId
    -- TODO, sdk id
    local jsonData = {}
    jsonData.account = account
    jsonData.chr = name
    jsonData.job = job
    jsonData.sex = sex
    jsonData.server_name = self:GetSelectedServerId()
    jsonData.sdkid = envProxy:GetChannelID()
    jsonData.secsdk = "0"
    local jsonString = cjson.encode(jsonData)
    LuaSendMsg(global.MsgType.MSG_CS_CREATE_ROLE, 0, 0, 0, 0, jsonString, string.len(jsonString))
    releasePrint("RequestCreateRole " .. jsonString)

    -- record create info
    self._createName = name
    self._createJob = job
    self._createSex = sex
end

-- <- step 6.2 521
function LoginProxy:handle_MSG_SC_CREATE_ROLE_SUCCESS(netPkg, msgID)
    releasePrint(" <- step 6.2 521 handle_MSG_SC_CREATE_ROLE_SUCCESS")
    self:StopLoginScheduler()

    local dataStr   = netPkg:GetBodyStr()
    local slices    = G_GetSplitArray(dataStr, "/")
    local roleName  = slices[1]

    local role  = {}
    role.roleid = slices[2]
    role.name   = roleName
    role.level  = 1
    role.job    = self._createJob
    role.sex    = self._createSex
    role.ctime  = GetServerTime()

    self:AddRole(role)
    self:SetSelectedRole(role)

    -- clear create info
    self._createName = nil
    self._createJob = nil
    self._createSex = nil

    -- go
    -- self:RequestEnterGame()
    SLBridge:onLUAEvent(LUA_EVENT_LOGIN_CREATE_ROLE_SUCCESS)

    -- Data recording
    local AuthProxy     = global.Facade:retrieveProxy( global.ProxyTable.AuthProxy )
    local jData = {}
    jData.zoneId        = self:GetSelectedServerId()
    jData.zoneName      = self:GetSelectedServerName()
    jData.roleId        = self:GetSelectedRoleID()
    jData.roleName      = self:GetSelectedRoleName()
    jData.roleCTime     = role.ctime
    jData.roleLevel     = "1"
    jData.roleVIPLev    = "0"
    jData.roleBalance   = "0"
    jData.roleGuild     = ""
    jData.userId        = tostring( AuthProxy:GetUID() )
    jData.reinLevel     = "0"
    jData.promoteId     = tostring(global.L_GameEnvManager:GetGMName())
    jData.roleJobName   = GUIFunction:GetJobNameByID(role.job)
    jData.roleJobId     = role.job
    jData.roleAtt       = 0

    -- 新增 主服id和主服name
    jData.main_servid       = self:GetMainSelectedServerId()
    jData.main_server_name  = self:GetMainSelectedServerName()

    local DataTrackProxy = global.Facade:retrieveProxy( global.ProxyTable.DataTrackProxy )
    DataTrackProxy:OnCreateRole(jData)

    -- 刷新角色数量
    local module            = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv     = module:GetGameEnv()
    local roleData          = self._roleInfo or {}
    if moduleGameEnv.SetRoleCountByServerID then 
        moduleGameEnv:SetRoleCountByServerID(self:GetSelectedServerId(), #roleData)
    end
end

-- <- step 6.2 522
function LoginProxy:handle_MSG_SC_CREATE_ROLE_FAIL(netPkg, msgID)
    releasePrint(" <- step 6.2 522 handle_MSG_SC_CREATE_ROLE_FAIL", netPkg:GetP0())
    self:StopLoginScheduler()

    --[[
        1 角色名称已存在
        2 角色名称存在过滤字符
        3 创建角色超过两个
        5 角色名称存在特殊字符
        6 角色名称长度小于 2 大于 16 字节
        7 服务器禁止创建角色(代理自己设置)
        100 服务器不允许创建角色
        102 服务器禁止创建全英文名称
        103 角色名称存在禁言关键词
        999 创建错误时候json格式错误
    --]]

    SLBridge:onLUAEvent(LUA_EVENT_LOGIN_CREATE_ROLE_FAIL, netPkg:GetP0())
end

function LoginProxy:RequestDeleteRole(uid)
    local sendStr = uid
    LuaSendMsg(global.MsgType.MSG_CS_DELETE_ROLE, 0, 0, 0, 0, sendStr, string.len(sendStr))
end

function LoginProxy:handle_MSG_SC_DELETE_ROLE_SUCCESS(netPkg, msgID)
    -- HideLoadingBar()
    -- del
    self:DecRoleByID(self:GetSelectedRoleID())
    
    -- select
    local roles = self:GetAllRoleInfo()
    if #roles == 0 then
        self:SetSelectedRole(nil)
    else
        self:SetSelectedRoleByIndex(1)
    end

    SLBridge:onLUAEvent(LUA_EVENT_LOGIN_DELETE_ROLE_SUCCESS)

    -- 刷新角色数量
    local module            = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv     = module:GetGameEnv()
    local roleData          = self._roleInfo or {}
    if moduleGameEnv.SetRoleCountByServerID then 
        moduleGameEnv:SetRoleCountByServerID(self:GetSelectedServerId(), #roleData)
    end
end

function LoginProxy:handle_MSG_SC_DELETE_ROLE_FAIL(netPkg, msgID)
    SLBridge:onLUAEvent(LUA_EVENT_LOGIN_DELETE_ROLE_FAIL)
end

function LoginProxy:RequestRestoreRoleInfo()
    self._restoreRoleInfo = {}

    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local account   = tostring(AuthProxy:GetUID())

    LuaSendMsg(global.MsgType.MSG_CS_RESTORE_ROLE_LIST, 0, 0, 0, 0, account, string.len(account))
end

function LoginProxy:handle_MSG_SC_RESTORE_ROLE_LIST(netPkg, msgID)
    -- 558[{uid,uname,ulevel,ujob},{uid,uname,ulevel,ujob},]
    local dataStr = netPkg:GetBodyStr()
    local jsonData = cjson.decode(dataStr)
    if not jsonData then
        return nil
    end

    for _,v in pairs(jsonData) do
        table.insert(self._restoreRoleInfo, v)
    end

    SLBridge:onLUAEvent(LUA_EVENT_LOGIN_RESTORE_ROLE_DATA_REFRESH)
end

function LoginProxy:GetRestoreRoleInfo()
    return self._restoreRoleInfo
end

function LoginProxy:RequestRestoreRole(uid, uname)
    local sendStr = uid .. "/" .. uname
    LuaSendMsg(global.MsgType.MSG_CS_RESTORE_ROLE, 0, 0, 0, 0, sendStr, string.len(sendStr))

    releasePrint("request restore role", sendStr)
end

function LoginProxy:handle_MSG_SC_RESTORE_ROLE(netPkg, msgID)
    -- 559 Recog
    -- -1禁止恢复
    -- 0恢复失败
    -- >0恢复成功

    local recog = netPkg:GetP0()
    if recog > 0 then
        self._restoreTag = netPkg:GetBodyStr()
        SLBridge:onLUAEvent(LUA_EVENT_LOGIN_RESTORE_ROLE_SUCCESS, recog)
    else
        SLBridge:onLUAEvent(LUA_EVENT_LOGIN_RESTORE_ROLE_FAIL, recog)
    end

    releasePrint("restore role resp", recog)
end

-- -> step 7. 103
function LoginProxy:RequestEnterGame()
    releasePrint(" <- step 7. 103 RequestEnterGame")

    local selectRole = self:GetSelectedRole()
    if not selectRole then
        ShowSystemTips("[01] ERROR Request Enter Game!")
        return false
    end
    if self:CheckRoleIsBlocked(selectRole, true) then
        return false
    end

    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local account   = AuthProxy:GetUID()
    local roleID    = self:GetSelectedRoleID()
    local roleName  = self:GetSelectedRoleName()
    local sendStr   = string.format("%s/%s/%s", account, roleName, roleID)
    self:StartLoginScheduler("103 -> 525")
    LuaSendMsg(global.MsgType.MSG_CS_SELECT_ROLE, 0, 0, 0, 0, sendStr)
    return true
end

-- <- step 8. 525
function LoginProxy:handle_MSG_SC_GAMESERVER_INFO(netPkg)
    -- debug
    releasePrint(" <- step 8. 525 handle_MSG_SC_GAMESERVER_INFO")
    self:StopLoginScheduler()

    UIOperator:CloseLoadingBarUI()

    local recog   = netPkg:GetP0()
    local dataStr = netPkg:GetBodyStr()
    local slices  = G_GetSplitArray(dataStr, "/")
    local ip      = tostring(slices[1])
    local port    = tonumber(slices[2])
    -- recog = 1 你就用我下发的 IP 或 域名
    if recog == 1 then
        self:SetGameServerIP(ip)
    end
    self:SetGameServerPort(port)
    self:RequestConnectGameServer()
end

-- -> step 9. tcp connect
function LoginProxy:RequestConnectGameServer()
    releasePrint(" == step 9. RequestConnectGameServer")

    -- 游戏服务器ip优先用游戏服下发的
    local ip          = self:GetGameServerIP() or self:GetSelectedServerIp()
    local port        = self:GetGameServerPort()
    local proxyport   = self:GetSelectedServerProxyPort()
    local connectIP   = tostring(ip)
    local connectPort = tonumber(proxyport or port)

    local debugPort     = nil
    local debugIp       = nil
    if SL._DEBUG then 
        debugPort     = global.L_GameEnvManager:GetEnvDataByKey("DebugPort")
        debugIp       = global.L_GameEnvManager:GetEnvDataByKey("DebugIp")
        if debugIp and debugPort then
            connectIP     = tostring(debugIp)
            connectPort   = tonumber(debugPort)
        end
    end
    -- // disconnect current server and connect new server
    local connectFunc = function(param1Ex)
        global.networkCtl:Disconnect()
        global.networkCtl:Connect(connectIP, connectPort)
        releasePrint("tcp connect to: ", connectIP, connectPort, global.networkCtl:IsConnected())
        if global.networkCtl:IsConnected() then
            -- 20消息
            self:RequestLoginGameServer()
        else
            local data = {}
            data.str = GET_STRING(30009003)
            data.btnDesc = {GET_STRING(1002)}
            data.callback = RestartGame
            UIOperator:OpenCommonTipsUI(data)
        end
    end
    if proxyport then 
        GET_NET_MSG_STAMP_HEAD_PARAM1_NEW(function (param1Ex)
            connectFunc(param1Ex)
            LoginProxy.param1Ex = nil
        end)
    else
        connectFunc()
    end
end

-- -> step 10. 20
function LoginProxy:RequestLoginGameServer()
    releasePrint(" -> step 10. 20 RequestLoginGameServer")
    self:StartLoginScheduler("20 -> 658 / 526")

    -- 20消息
    local param0 = GET_NET_MSG_STAMP_HEAD_PARAM0()
    local param1 = LoginProxy.param1Ex or GET_NET_MSG_STAMP_HEAD_PARAM1()
    local param2 = tonumber(self:GetMainSelectedServerId() or self:GetSelectedServerId()) or 0
    local param3 = tonumber(self:GetGameServerPort()) or 0
    local sendStr = self:GetConnectGameServerStr()
    LuaSendMsg(global.MsgType.MSG_CS_LOGIN_SERVER, param0, param1, param2, param3, sendStr)
    UIOperator:OpenLoadingBarUI(10)

    releasePrint("+++++++++++++++++MSG_CS_LOGIN_SERVER  20: " .. sendStr )
end

-- 获取进入游戏世界的参数字符串，在登录和断线重连时使用
function LoginProxy:GetConnectGameServerStr()
    -- // *#账户/名称/UID/会话/设备类别/渠道号/白名单/实名认证/18岁/盒子登录
    -- channelid 渠道号 string
    -- whitelist 白名单 1/0  1.白名单 0.非白名单
    local AuthProxy     = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local envProxy      = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local currentModule = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv = currentModule:GetGameEnv()
    local account       = AuthProxy:GetUID()
    local whitelist     = (moduleGameEnv:IsWhitelist() == true and 1 or 0)
    local channelID     = envProxy:GetChannelID()
    local cert          = global.L_NativeBridgeManager:GetCertification() == true and 1 or 0
    local adult         = global.L_NativeBridgeManager:GetAdult() == true and 1 or 0
    local isBoxLogin    = global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin") or 0
    local selectRoleID  = self:GetSelectedRoleID()
    local selectRoleName = self:GetSelectedRoleName()

    -- android:0, ios:1  except:2
    local platform = 0
    if global.isAndroid or global.isOHOS then
        platform = 0
    elseif global.isIOS then
        platform = 1
    else
        platform = 2
    end
    local sendStr = string.format("*#%s/%s/%s/%s/%s/%s/%s/%s/%s/%s",
        account,
        selectRoleName,
        selectRoleID,
        self:GetSessionID(),
        platform,                            --920080512 改 platform参数
        channelID,
        whitelist,
        cert,
        adult,
        isBoxLogin
    )
    return sendStr
end

-- <- step 11. 526
function LoginProxy:handle_MSG_SC_GAMESERVER_INFO_ERROR(netPkg, msgID)
    -- debug
    releasePrint(" <- step 11. 526 handle_MSG_SC_GAMESERVER_INFO_ERROR")
    self:StopLoginScheduler()

    UIOperator:CloseLoadingBarUI()

    -- nRecog = 99 标识服务器隐藏 或者 维护 不在名单内不能进
    local descStr = GET_STRING(30009003)
    local header = netPkg:GetHeader()
    if header.recog == 99 then
        descStr = GET_STRING(30009106)
    end

    -- 
    local data = {}
    data.str = descStr .. "[526]"
    data.btnDesc = { GET_STRING(30009046)}
    data.callback = RestartGame
    UIOperator:OpenCommonTipsUI(data)
end

-- <- step 11. 658
function LoginProxy:handle_MSG_SC_GAME_HELLO_TIPS(netPkg)
    releasePrint(" <- step 11. 658 handle_MSG_SC_GAME_HELLO_TIPS")
    self:StopLoginScheduler()

    UIOperator:CloseLoadingBarUI()

    local jsonData = netPkg:GetJsonData() or {}
    local mainPlayerID = jsonData.UserID
    local tipsContent = global.isWinPlayMode and jsonData.PcMsg or jsonData.Msg
    local serverVer = jsonData.ver or ""
    self:SetServiceVer(serverVer)
    self:SetTipsContent(tipsContent)

    -- begin loading
    global.Facade:sendNotification( global.NoticeTable.LoadingBegin )
    global.Facade:sendNotification( global.NoticeTable.ReconnectGameWorld )

    releasePrint( "main player ID  " .. mainPlayerID )
end

-- -> step 12. 1018
function LoginProxy:RequestEnterWorld(isReconnect)
    if not isReconnect and self._requestEnterWorld then
        print("Warning: Repeat Send 1018 RequestEnterWorld Message.")
        return
    end
    releasePrint(" -> step 12. 1018 RequestEnterWorld")
    self:StartLoginScheduler("1018 -> 2")

    local envProxy          = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local currModule        = global.L_ModuleManager:GetCurrentModule()
    local GameConfigMgrProxy = global.Facade:retrieveProxy(global.ProxyTable.GameConfigMgrProxy)

    local contentFix        = GameConfigMgrProxy:getContentFix()
    local jsonData          = contentFix
    jsonData.gameid         = currModule:GetOperID() 
    jsonData.channelId      = envProxy:GetChannelID()
    jsonData.packageName    = envProxy:GetAPKPackageName()
    jsonData.tripartite     = global.OtherTradingBank and 1 or 0
    local sendJson          = cjson.encode( jsonData )

    local visibleSize       = global.Director:getVisibleSize()
    local screenwidth       = visibleSize.width
    local screenheight      = visibleSize.height
    local devicecode        = self:GetDeviceCode()
    local platform          = global.OperatingMode
    local connectV          = isReconnect and 1 or 0
    local isEMU             = global.L_GameEnvManager:IsEmulator() and 1 or 0
    local param2            = Merge16Bit(connectV, isEMU)
    local param3            = Merge16Bit(screenwidth, screenheight)
    LuaSendMsg(global.MsgType.MSG_CS_ENTER_GAME_DUMMY, platform, param2, param3, devicecode, sendJson, string.len(sendJson))
    self._requestEnterWorld = true
    -- debug
    -- releasePrint(platform, param2, param3, devicecode, sendJson)
end

function LoginProxy:RequestRoleName(job, sex)
    LuaSendMsg(global.MsgType.MSG_CS_ROLE_NAME, job, sex)
end

function LoginProxy:handle_MSG_SC_ROLE_NAME(msg, msgID)
    local sliceStr = msg:GetBodyStr()
    SLBridge:onLUAEvent(LUA_EVENT_LOGIN_RAND_ROLE_NAME_REFRESH, sliceStr)
end

function LoginProxy:RequestLeaveWorldNotify()
    -- 小退要发送一个消息给服务器
    LuaSendMsg(global.MsgType.MSG_CS_REBACK_TO_ROLE)
end

function LoginProxy:RequestSoftClose()
    -- 请求小退  服务器返回可以小退才能小退
    LuaSendMsg(global.MsgType.MSG_CS_QURYSOFTCLOSE)
end

function LoginProxy:handle_MSG_SC_SERVER_FORBIDDEN(msg)
    releasePrint("step 10 handle_MSG_SC_SERVER_FORBIDDEN")
    self:StopLoginScheduler()

    local function callback(bType, custom)
        RestartGame()
    end
    local data = {}
    data.str    = GET_STRING(30009053)
    data.btnDesc = { GET_STRING(30009046)}
    data.callback = callback
    UIOperator:OpenCommonTipsUI(data)

    -- 重连禁用
    global.Facade:sendNotification(global.NoticeTable.ReconnectForbidden)
end

function LoginProxy:handle_MSG_SC_SERVER_FORBIDDEN_NET_ERROR(msg, msgID)
    releasePrint("step 10 handle_MSG_SC_SERVER_FORBIDDEN_NET_ERROR")
    self:StopLoginScheduler()

    -- 重连禁用
    global.Facade:sendNotification(global.NoticeTable.ReconnectForbidden)

    -- 不弹提醒
    local header = msg:GetHeader()

    releasePrint("handle_MSG_SC_SERVER_FORBIDDEN_NET_ERROR CODE: ", header.recog)
    
    if header.recog == 1 then
        return
    end

    local function callback(bType, custom)
        RestartGame()
    end
    local data = {}
    data.str    = GET_STRING(30009061)
    data.btnDesc = { GET_STRING(30009046)}
    data.callback = callback
    UIOperator:OpenCommonTipsUI(data)
end

function LoginProxy:handle_MSG_SC_SERVER_KICKOUT(msg)
    releasePrint("step 10 handle_MSG_SC_SERVER_KICKOUT")
    self:StopLoginScheduler()

    -- 主动断开
    global.networkCtl:Disconnect()

    -- 重连禁用
    global.Facade:sendNotification(global.NoticeTable.ReconnectForbidden)

    if global.IsVisitor then
        return
    end

    --寄售成功客户端禁止踢人
    if global.IsConsignmentRole then
        return
    end

    local data = {}
    data.str = "断开连接"
    data.btnDesc = {GET_STRING(30009046)}
    data.callback = RestartGame
    UIOperator:OpenCommonTipsUI(data)
end

--小退
function LoginProxy:handle_MSG_SC_REBACK_TO_ROLE(msg, msgID)
    -- body
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return
    end
    
    if jsonData.SoftCloseSuccess == 1 then
        if self:GetSelectedRoleID() == jsonData.UserID then --小退处理
            global.gameWorldController:OnGameLeaveWorld()
        end
    else
        global.Facade:sendNotification( global.NoticeTable.SystemTips, GET_STRING(310000100) )
    end
end

-- 2020->
function LoginProxy:SyncVersion()
    local AuthProxy     = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local currModule    = global.L_ModuleManager:GetCurrentModule()
    local account       = AuthProxy:GetUID()
    local resOriginVer  = currModule:GetOriginVersion()
    local resRemoteVer  = currModule:GetRemoteVersion()
    local sdkuid        = global.L_NativeBridgeManager:GetSdkuid() or global.L_NativeBridgeManager:GetUsername()
    
    local isBoxLogin    = global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin") == 1 --盒子登录
    local hasBuf        = global.L_NativeBridgeManager:GetHasBuff() or "0"
    local versionCode   = global.L_GameEnvManager:GetAPKVersionCode()
    versionCode         = isBoxLogin and tonumber(versionCode) + 1000 or versionCode
    local channelID     = global.L_GameEnvManager:GetChannelID()
    local hasNp         = tostring(SL:GetValue("PC_NP_STATUS") and 1 or 0)
    local is996cloudDevice         = tostring(SL:GetValue("CLOUD996_DEVICE") and 1 or 0)
    local promoteId     = tostring(global.L_GameEnvManager:GetGMName() or "0")

    local sendStr = string.format("%s/%s/%s/%s/%s/%s/%s/%s/%s/%s", account, resOriginVer, resRemoteVer, tostring(sdkuid), hasBuf, versionCode, channelID, hasNp,
        is996cloudDevice, promoteId)
    local sendLen = string.len(sendStr)
    releasePrint("sync version:" .. sendStr)
    LuaSendMsg(global.MsgType.MSG_CS_SYNC_VERSION, 0, 0, 0, 0, sendStr, sendLen)
end

--sdk设备信息
function LoginProxy:SendDeviceInfo() 
    local strData = ""
    local boxID = nil
    if global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin") == 1 then
        local boxBoxGameID  = global.L_ModuleManager:GetCurrentModule():GetOperID() or ""
        local boxChannelID  = global.L_GameEnvManager:GetChannelID() or ""
        boxID               = boxBoxGameID .. ":" .. boxChannelID
    end

    local isMac = global.L_GameEnvManager:GetEnvDataByKey("platform") == "mac"
    if SL:GetMetaValue("IS_PC_OPER_MODE") or isMac then
        local DataRePortProxy = global.Facade:retrieveProxy( global.ProxyTable.DataRePortProxy )
        local infoData = DataRePortProxy:GetDeviceInfo()
        local PCStrData = infoData.device or {}
        PCStrData.boxid = boxID
        strData = cjson.encode(PCStrData)

    else
        local deviceInfo = global.L_NativeBridgeManager.GetLoginDataByKey and global.L_NativeBridgeManager:GetLoginDataByKey("deviceInfo") or ""
        if deviceInfo and string.len(deviceInfo) > 0 then
            local deviceData = cjson.decode(deviceInfo)
            if deviceData and next(deviceData) then
                deviceData.boxid = boxID
                strData = cjson.encode(deviceData)
            end
        end
    end

    local jsonString = strData
    releasePrint("SendDeviceInfo = " .. jsonString)
    LuaSendMsg(global.MsgType.MSG_SC_MOBILE_DEVICE_INFO, 0, 0, 0, 0, jsonString, string.len(jsonString))
end

--sdk参数渠道号 appid appkey等
function LoginProxy:SendSDKInfo() 
    local strData = ""

    local isMac = global.L_GameEnvManager:GetEnvDataByKey("platform") == "mac"
    if SL:GetMetaValue("IS_PC_OPER_MODE") or isMac then
        local DataRePortProxy = global.Facade:retrieveProxy( global.ProxyTable.DataRePortProxy )
        local infoData = DataRePortProxy:GetDeviceInfo()
        local PCStrData = {
            sdkver  = "1.0.0",
            channel = infoData.channel or "",
            appid   = infoData.appid or "",
            appver  = global.L_GameEnvManager:GetAPKVersionName() or "",
        }
        strData = cjson.encode(PCStrData)
    else
        strData = global.L_NativeBridgeManager.GetLoginDataByKey and global.L_NativeBridgeManager:GetLoginDataByKey("sdkInfo") or ""
    end
    
    local jsonString = strData
    releasePrint("SendSDKInfo = " .. jsonString)
    LuaSendMsg(global.MsgType.MSG_SC_MOBILE_SDK_INFO, 0, 0, 0, 0, jsonString, string.len(jsonString))
end

function LoginProxy:SaveDeviceCode(code) --本地储存devicecode
    local userData = UserData:new("ContentFix")
    userData:setStringForKey("devicecode", code)
end

function LoginProxy:GetDeviceCode() --获取devicecode
    local userData = UserData:new("ContentFix")
    local code = userData:getStringForKey("devicecode", "")
    if code == "" or code == nil then
        code = 0
    end
    return code
end

function LoginProxy:handle_MSG_SC_CHANGE_KF(msg, msgID)
    local dataString   = msg:GetBodyStr()
    local dataSringArray = string.split(dataString or "", ";")
    local verifyValue = dataSringArray[2] 
    
    if verifyValue then
        
        local ipPortArray = string.split(dataSringArray[1], ":")
        local ip          = ipPortArray[1]
        local prot        = ipPortArray[2]
        if not prot or string.len(prot) == 0 then
            return
        end

        local function IPConnect(ip, prot)
            global.networkCtl:Connect(tostring(ip), tonumber(prot))
            releasePrint("global.MsgType.MSG_SC_CHANGE_KF connect", tostring(global.networkCtl:IsConnected()), ip, prot)
            if global.networkCtl:IsConnected() then

                local sendStr = self:GetConnectGameServerStr()
                sendStr = string.format("%s/%s",sendStr,verifyValue)

                releasePrint("global.MsgType.MSG_SC_CHANGE_KF 60002", sendStr)
                LuaSendMsg(global.MsgType.MSG_CS_RELOGIN_SERVER, 900000, os.time(), 0, 0, sendStr)

                local NetworkProxy = global.Facade:retrieveProxy( global.ProxyTable.NetworkProxy )
                NetworkProxy:SetDisconnect( true ) 
            end
        end

        -- 延迟1s连接ip
        PerformWithDelayGlobal(function()
            IPConnect(ip, prot)
        end, 1.0)

    end
end

function LoginProxy:RegisterMsgHandler()
    LoginProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_RESPONSE_SERVER_LIST,          handler(self, self.handle_MSG_SC_RESPONSE_SERVER_LIST))
    LuaRegisterMsgHandler(msgType.MSG_SC_RESPONSE_SERVER_INFO,          handler(self, self.handle_MSG_SC_RESPONSE_SERVER_INFO))
    LuaRegisterMsgHandler(msgType.MSG_SC_CREATE_ROLE_SUCCESS,           handler(self, self.handle_MSG_SC_CREATE_ROLE_SUCCESS))
    LuaRegisterMsgHandler(msgType.MSG_SC_CREATE_ROLE_FAIL,              handler(self, self.handle_MSG_SC_CREATE_ROLE_FAIL))
    LuaRegisterMsgHandler(msgType.MSG_SC_DELETE_ROLE_SUCCESS,           handler(self, self.handle_MSG_SC_DELETE_ROLE_SUCCESS))
    LuaRegisterMsgHandler(msgType.MSG_SC_DELETE_ROLE_FAIL,              handler(self, self.handle_MSG_SC_DELETE_ROLE_FAIL))
    LuaRegisterMsgHandler(msgType.MSG_SC_RESTORE_ROLE_LIST,             handler(self, self.handle_MSG_SC_RESTORE_ROLE_LIST))
    LuaRegisterMsgHandler(msgType.MSG_SC_RESTORE_ROLE,                  handler(self, self.handle_MSG_SC_RESTORE_ROLE))
    LuaRegisterMsgHandler(msgType.MSG_SC_RESPOINSE_ROLE_INFO,           handler(self, self.handle_MSG_SC_RESPOINSE_ROLE_INFO))
    LuaRegisterMsgHandler(msgType.MSG_SC_RESPOINSE_ROLE_INFO_FAIL,      handler(self, self.handle_MSG_SC_RESPOINSE_ROLE_INFO_FAIL))
    LuaRegisterMsgHandler(msgType.MSG_SC_GAMESERVER_INFO,               handler(self, self.handle_MSG_SC_GAMESERVER_INFO))
    LuaRegisterMsgHandler(msgType.MSG_SC_GAMESERVER_INFO_ERROR,         handler(self, self.handle_MSG_SC_GAMESERVER_INFO_ERROR))
    LuaRegisterMsgHandler(msgType.MSG_SC_ROLE_NAME,                     handler(self, self.handle_MSG_SC_ROLE_NAME))
    LuaRegisterMsgHandler(msgType.MSG_SC_SERVER_FORBIDDEN,              handler(self, self.handle_MSG_SC_SERVER_FORBIDDEN))
    LuaRegisterMsgHandler(msgType.MSG_SC_SERVER_FORBIDDEN_NET_ERROR,    handler(self, self.handle_MSG_SC_SERVER_FORBIDDEN_NET_ERROR))
    LuaRegisterMsgHandler(msgType.MSG_SC_RESPOINSE_CHECK_TOKEN_FAIL,    handler(self, self.handle_MSG_SC_RESPOINSE_CHECK_TOKEN_FAIL))
    LuaRegisterMsgHandler(msgType.MSG_SC_REBACK_TO_ROLE,                handler(self, self.handle_MSG_SC_REBACK_TO_ROLE))                --小退是否成功数据
    LuaRegisterMsgHandler(msgType.MSG_SC_GAME_HELLO_TIPS,               handler(self, self.handle_MSG_SC_GAME_HELLO_TIPS))
    LuaRegisterMsgHandler(msgType.MSG_SC_CHANGE_KF,                     handler(self, self.handle_MSG_SC_CHANGE_KF))    -- 通知客户端切换服务器
    LuaRegisterMsgHandler(msgType.MSG_SC_SERVER_KICKOUT,                handler(self, self.handle_MSG_SC_SERVER_KICKOUT))
end

return LoginProxy
