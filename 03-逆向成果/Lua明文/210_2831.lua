local BaseLayer = requireLayerUI("BaseLayer")
local LoginVersionLayer = class("LoginVersionLayer", BaseLayer)

function LoginVersionLayer:ctor()
    LoginVersionLayer.super.ctor(self)
end

function LoginVersionLayer.create()
    local node = LoginVersionLayer.new()
    if node:Init() then
        return node
    else
        return nil
    end
end

function LoginVersionLayer:Init()
    self._root = CreateExport("login/login_version.lua")
    if not self._root then
        return false
    end
    self:addChild(self._root)

    self._textVersion = self._root:getChildByName("Text_version")
    self._textVersion:setPositionX(100)
    self._textVersion:setFontSize(16) 

    local visibleSize = global.Director:getVisibleSize()
    self._textGMAssetsVer = ccui.Text:create()
    self._root:addChild(self._textGMAssetsVer)
    self._textGMAssetsVer:setFontName(global.MMO.PATH_FONT2)
    self._textGMAssetsVer:setFontSize(16)
    self._textGMAssetsVer:setTextColor({r = 255, g = 228, b = 199})
    self._textGMAssetsVer:setAnchorPoint(cc.p(0, 0.5))
    self._textGMAssetsVer:setPosition(cc.p(100, visibleSize.height - 30))


    self:UpdateVersion(true)
    return true
end

function LoginVersionLayer:UpdateVersion(isInit)
    if not global.L_ModuleManager or not global.L_ModuleManager:GetCurrentModule() then
        self._textVersion:setString("")
        return
    end


    -- 原始版本号
    local currModule = global.L_ModuleManager:GetCurrentModule()
    local originVer = currModule:GetOriginVersion()
    local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)

    -- 热更版本号
    local manifestVer = currModule:GetRemoteVersion()

    -- 渠道号
    local channelID = envProxy:GetChannelID() or ""
    local appVersion = global.LuaBridgeCtl:GetModulesSwitch(global.MMO.Modules_Index_Cpp_Version)
    self._textVersion:setString(string.format("%s (%s/%s)(appV/%s)", channelID, originVer, manifestVer, appVersion))

    -- 自定义资源
    local currentSubMod = currModule:GetCurrentSubMod()
    local versionStr = currentSubMod.GetRemoteVersion and currentSubMod:GetRemoteVersion() or ""
    self._textGMAssetsVer:setString(versionStr)

    -- 后台设置的内容
    local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local moduleVer = envProxy:GetCustomDataByKey("moduleVer")
    if moduleVer then
        self._textVersion:setString(moduleVer)
    end

    -- 后台设置的内容
    local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local moduleVer = envProxy:GetCustomDataByKey("moduleVer")
    if moduleVer then
        self._textGMAssetsVer:setString(moduleVer)
    end
end

return LoginVersionLayer
