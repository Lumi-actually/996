local DebugProxy = requireProxy("DebugProxy")
local DataTrackProxy = class("DataTrackProxy", DebugProxy)
DataTrackProxy.NAME = global.ProxyTable.DataTrackProxy

local cjson = require("cjson")

function DataTrackProxy:ctor()
    DataTrackProxy.super.ctor(self)
end

-------------------------------------------------------------
--- 登录返回UserID
function DataTrackProxy:OnResponseLoginUserID(userID)
    -- Data recording
    if global.isMobile then
        local LoginProxy    = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        local serverID      = LoginProxy:GetSelectedServerId()
        local jsonData      = {}
        jsonData.userID     = userID
        jsonData.srvID      = serverID
        global.L_NativeBridgeManager:GN_onUserIDUpdated(jsonData)
    end
end

-------------------------------------------------------------
--- 上报userID至Bugly
function DataTrackProxy:RecordBuglyLoginUserData()
    if global.isAndroid then
        -- account|serverID|channel
        -- record login user data
        local envProxy      = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
        local AuthProxy     = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        local LoginProxy    = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        local channelID     = envProxy:GetChannelID()
        local account       = AuthProxy:GetUID()
        local serverID      = LoginProxy:GetSelectedServerId()
        local userValue     = string.format("%s|%s|%s", tostring(account), tostring(serverID), tostring(channelID))
        buglyAddUserValue("LoginUserAccountData", userValue)
    end
end

-------------------------------------------------------------
--- 角色信息返回
function DataTrackProxy:OnRoleInfo(jsonData)
    if global.isMobile then
        global.L_NativeBridgeManager:GN_onSelectServer(jsonData)
    end

    -- QQ大厅上报
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    if AuthProxy:IsQQChannel() then
        local uploadData = {}
        uploadData.user_id            = jsonData.userId
        uploadData.server_id          = jsonData.zoneId
        uploadData.server_name        = jsonData.zoneName
        AuthProxy:uploadDataQQGame(5, uploadData) 
    end
end

-------------------------------------------------------------
--- 创角
function DataTrackProxy:OnCreateRole(jsonData)
    -- 上报至 安卓层
    global.L_NativeBridgeManager:GN_onNewRole(jsonData)

    --需要接入pc端的sdk
    if global.L_GameEnvManager:GetEnvDataByKey("isPcSdk") then
        local jsonString = cjson.encode(jsonData)
        local methodName = "GN_onNewRole"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
    end

    -- 996数据上报
    local DataRePortProxy = global.Facade:retrieveProxy( global.ProxyTable.DataRePortProxy )
    DataRePortProxy:CreateRole(jsonData)

    --直播红包+飘屏群 上报需求  
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:RequestUpLoadCreateRole(jsonData)

end

-------------------------------------------------------------
--- 进入游戏
function DataTrackProxy:OnEnterGame(jsonData)
    global.L_NativeBridgeManager:GN_onEnterGame(jsonData)

    --需要接入pc端的sdk
    local isPcSdk = global.L_GameEnvManager:GetEnvDataByKey("isPcSdk")
    if isPcSdk or global.isWindows then
        local jsonString = cjson.encode(jsonData)
        local methodName = "GN_onEnterGame"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
    end

    -- 数据上报  进入游戏
    local DataRePortProxy = global.Facade:retrieveProxy( global.ProxyTable.DataRePortProxy )
    DataRePortProxy:GameLogin(jsonData)
end

-------------------------------------------------------------
--- 等级改变
function DataTrackProxy:OnLevelChange(jsonData)
    global.L_NativeBridgeManager:GN_onLevelChanged(jsonData)

    --需要接入pc端的sdk
    if global.L_GameEnvManager:GetEnvDataByKey("isPcSdk") then
        local jsonString = cjson.encode(jsonData)
        local methodName = "GN_onLevelChanged"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
    end
end

-- 扩展参数变化
function DataTrackProxy:OnExpandInfoChanage()
    
    local AutoProxy         = global.Facade:retrieveProxy( global.ProxyTable.AutoProxy )
    local MapProxy          = global.Facade:retrieveProxy( global.ProxyTable.MapProxy )
    local isAfk             = 0
    local mapId             = MapProxy and MapProxy:GetMapID() or ""
    if AutoProxy and AutoProxy:IsAFKState() then
        isAfk = 1
    end


    local infoData = {
        map_id = mapId,
        is_afk = isAfk
    }
    local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    NativeBridgeProxy:GN_SetExpandInfo(infoData)
end

return DataTrackProxy