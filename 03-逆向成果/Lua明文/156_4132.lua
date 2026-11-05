local ModBridgeController = class('ModBridgeController', framework.Mediator)
ModBridgeController.NAME = "ModBridgeController"

local cjson = require("cjson")

function ModBridgeController:ctor()
    ModBridgeController.super.ctor(self, self.NAME)

    self._uploadData = {}
end

function ModBridgeController:GN_selectGameMod(data)
end

function ModBridgeController:GN_onSelectServer(data)
    if global.isDebugMode then
        return nil
    end
    if not data then
        return nil
    end

    self._uploadData.user_id            = data.userId
    self._uploadData.server_id          = data.zoneId
    self._uploadData.server_name        = data.zoneName

    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:uploadData(1, self._uploadData)
end

function ModBridgeController:GN_onNewRole(data)
    if global.isDebugMode then
        return nil
    end
    if not data then
        return nil
    end

    self._uploadData.server_id          = data.zoneId
    self._uploadData.server_name        = data.zoneName
    self._uploadData.role_id            = data.roleId
    self._uploadData.role_name          = data.roleName
    self._uploadData.role_level         = data.roleLevel
    self._uploadData.role_create_time   = data.roleCTime
    self._uploadData.rein_level         = data.reinLevel

    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    if AuthProxy:IsQQChannel() then
        AuthProxy:uploadDataQQGame(2,self._uploadData)
        AuthProxy:uploadDataQQGame(6,self._uploadData) 
    else
        AuthProxy:uploadData(2, self._uploadData)
        AuthProxy:uploadBoxData(2, self._uploadData)
    end
end

function ModBridgeController:GN_onEnterGame(data)
    if global.isDebugMode then
        return nil
    end
    if not data then
        return nil
    end

    self._uploadData.server_id          = data.zoneId
    self._uploadData.server_name        = data.zoneName
    self._uploadData.role_id            = data.roleId
    self._uploadData.role_name          = data.roleName
    self._uploadData.role_level         = data.roleLevel
    self._uploadData.role_create_time   = data.roleCTime
    self._uploadData.role_career        = data.roleCareer
    self._uploadData.role_sex           = data.roleSex
    self._uploadData.rein_level         = data.reinLevel

    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    if AuthProxy:IsQQChannel() then
        AuthProxy:uploadDataQQGame(3,self._uploadData) 
    else
        AuthProxy:uploadData(3, self._uploadData)
    end
end

function ModBridgeController:GN_onLevelChanged(data)
    if global.isDebugMode then
        return nil
    end
    if not data then
        return nil
    end

    self._uploadData.role_level         = data.roleLevel
    self._uploadData.rein_level         = data.reinLevel

    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:uploadData(4, self._uploadData)
end

function ModBridgeController:GN_onQuestIDChanged(data)
end

function ModBridgeController:GN_buyItemWithYB(data)
end

function ModBridgeController:GN_kefu()
    if global.Platform == cc.PLATFORM_OS_ANDROID or global.isOHOS then
        local propertyProxy = global.Facade:retrieveProxy( global.ProxyTable.PlayerPropertyProxy )
        local loginProxy    = global.Facade:retrieveProxy( global.ProxyTable.LoginProxy )
        local AuthProxy     = global.Facade:retrieveProxy( global.ProxyTable.AuthProxy )
        local jData = {}
        jData.userId        = tostring( AuthProxy:GetUID() )
        jData.serverId      = loginProxy:GetSelectedServerId()
        jData.roleId        = global.gamePlayerController:GetMainPlayerID()
        jData.roleName      = loginProxy:GetSelectedRoleName()
        local jsonString    = jData and cjson.encode(jData) or ""
        local methodName    = "GN_kefu"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
    end
end

return ModBridgeController
