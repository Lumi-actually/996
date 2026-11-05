local NativeBridgeManager = class("NativeBridgeManager")
local cjson = require("cjson")

function NativeBridgeManager:ctor()

    self._loginState = 0
    self._username   = nil
    self._password   = nil
    self._isCertification = true       --是否已经实名认证
    self._isAdult = true               --是否已经成年
    self._sdkuid     = nil             -- 原始uid，聚合那边将uid转了一下，无法正常和SDK进行其他网络通信了，加这个字段，▄█▀█●
    
    self._needAllowLaunch  = false         -- 需要SDK允许进入
    self._isAllowLaunch    = false         -- SDK是否允许进入

    -- 嫌疑数据
    self._suspectInfo    = nil

    --上一次使用的区服
    self._lastServerID   = nil;

    --是否需要buf
    self._isHasBuff        = "0"

    --移动端登录信息
    self._loginData     = {}

    -- VIP数据
    self._VipData    = nil
    self._isHaveVip  = false

    -- 从盒子启动
    self._launchByBox = false
    
    self:registerN2GMethods()
end

function NativeBridgeManager:GetLoginState()
    return self._loginState
end

function NativeBridgeManager:GetUsername()
    return self._username
end

function NativeBridgeManager:GetPassword()
    return self._password
end

function NativeBridgeManager:GetCertification()
    return self._isCertification
end

function NativeBridgeManager:SetCertification(state)
    self._isCertification = state
end

function NativeBridgeManager:GetAdult()
    return self._isAdult
end

function NativeBridgeManager:SetAdult(state)
    self._isAdult = state
end

function NativeBridgeManager:GetHasBuff()
    return self._isHasBuff
end

function NativeBridgeManager:GetLoginDataByKey(key)
    return self._loginData[key]
end

function NativeBridgeManager:SetLoginDataByKey(key,value)
    self._loginData[key] = value
end

function NativeBridgeManager:GetSdkuid(state)
    return self._sdkuid
end

function NativeBridgeManager:GetSuspectInfo()
    return self._suspectInfo
end

function NativeBridgeManager:SetSuspectInfo(info)
    self._suspectInfo = info
end

function NativeBridgeManager:IsNeedAllowLaunch()
    return self._needAllowLaunch
end

function NativeBridgeManager:SetNeedAllowLaunch(v)
    self._needAllowLaunch = v
end

function NativeBridgeManager:IsAllowLaunch()
    return self._isAllowLaunch
end

function NativeBridgeManager:SetIsAllowLaunch(v)
    self._isAllowLaunch = v
end

function NativeBridgeManager:getLastServerID()
    return self._lastServerID
end

function NativeBridgeManager:SetLastServerID(v)
    self._lastServerID = v
end

function NativeBridgeManager:SetVIPLevel(v)
    self._VipData = v
end

function NativeBridgeManager:GetVIPLevel()
    return self._VipData, self._isHaveVip
end

function NativeBridgeManager:CheckAllowLaunch()
    -- 不需要SDK同意
    if not self:IsNeedAllowLaunch() then
        return true
    end
    return self:IsNeedAllowLaunch() and self:IsAllowLaunch()
end

function NativeBridgeManager:onRecvDataCB(sender, jsonString)
    releasePrint("RecvDataCallback:" .. tostring(jsonString))
    
    local paramJson = cjson.decode(jsonString)
    self._revcData  = paramJson
    
    if not paramJson then
        return nil
    end

    if paramJson.versionName then
        global.L_GameEnvManager:SetAPKVersionName(paramJson.versionName)
    end

    if paramJson.versionCode then 
        global.L_GameEnvManager:SetAPKVersionCode(paramJson.versionCode)
    end
    
    if paramJson.package then 
        global.L_GameEnvManager:SetAPKPackageName(paramJson.package)
    end

    if paramJson.packageName then 
        global.L_GameEnvManager:SetAPKPackageShowName(paramJson.packageName)
    end

    if paramJson.code_java then 
        global.L_GameEnvManager:SetJavaVersionCode(paramJson.code_java)
    end

    if paramJson.srvlist and string.len(paramJson.srvlist) > 0 then
        global.L_GameEnvManager:SetModInfoURL(paramJson.srvlist)
    end
    if paramJson.srvlistPlanB and string.len(paramJson.srvlistPlanB) > 0 then
        global.L_GameEnvManager:SetModInfoURLPlanB(paramJson.srvlistPlanB)
    end

    if paramJson.channelId and string.len(paramJson.channelId) > 0 then 
        global.L_GameEnvManager:SetChannelID(paramJson.channelId)
    end

    if paramJson.network then 
        global.L_GameEnvManager:SetNetType(paramJson.network) 
    end

    if paramJson.battery then
        global.L_GameEnvManager:SetBattery(paramJson.battery) 
    end

    if paramJson.totalMemSizeInByte then
        local memSize = tonumber( paramJson.totalMemSizeInByte )
        local memSizeInGB = 3
        if global.Platform == cc.PLATFORM_OS_ANDROID then
            memSizeInGB = memSize / 1048576
        else
            memSizeInGB = memSize / 1073741824
        end
        global.L_GameEnvManager:SetTotalMemSize(memSizeInGB)
    end

    if paramJson.UDID then
        global.L_GameEnvManager:SetUDID(tostring(paramJson.UDID))
    end
    
    if paramJson.PUID then
        global.L_GameEnvManager:SetPUID(tostring(paramJson.PUID))
    end

    if paramJson.isEMU then
        global.L_GameEnvManager:SetIsEmulator(paramJson.isEMU == "1")
    end

    if paramJson.isUM then
        global.L_GameEnvManager:SetIsUmeng(paramJson.isUM == "1")
    end

    if paramJson.needPermission ~= nil then
        global.L_GameEnvManager:setNeedPermission(tostring(paramJson.needPermission) == "1")
    end
    
    if paramJson.hasPermission then
        global.L_GameEnvManager:setHasPermission(tostring(paramJson.hasPermission) == "1")
    end
    
    if paramJson.needAllowLaunch then
        global.L_NativeBridgeManager:SetNeedAllowLaunch(tostring(paramJson.needAllowLaunch) == "1")
    end

    if paramJson.envData then
        local envData = cjson.decode(paramJson.envData)
        for k, v in pairs(envData) do
            global.L_GameEnvManager:SetEnvDataByKey(k, v)
        end
        global.BoxLaunchExternal = true --盒子启动的外部游戏包
    end

    if paramJson.launchByBox then
        self._launchByBox = paramJson.launchByBox
    end
    
    -- 推广员标识，IOS原生下发数据
    if global.isIOS then
        local gmValue = tostring(paramJson.gm)
        if gmValue ~= "nil" and string.len(gmValue) > 0 then
            global.L_GameEnvManager:SetIosNativeGMName(gmValue)
        end
    end

    releasePrint( "_totalMemSizeInGB:" .. tostring(global.L_GameEnvManager:GetTotalMemSize()))
    releasePrint("isEmulator:", global.L_GameEnvManager:IsEmulator())


    -- check by app code
    if not self._launchByBox then
        -- 盒子启动时，不处理覆盖安装的删除
        global.L_GameEnvManager:CheckAppOverlayTrace()
    end

    -- root dir
    global.L_GameEnvManager:CheckRootDir()
end

function NativeBridgeManager:onSDKLoginCB(sender, jsonString)
    HideLoadingBar()

    -- debug
    releasePrint("SDKLoginCallback:" .. tostring(jsonString))

    local paramJson = cjson.decode(jsonString)
    local state = paramJson.state -- 1: success, 0:failed

    -- login state
    self._loginState = tonumber(state)

    if state and tonumber(state) == 1 then
        if paramJson.userName and paramJson.sessionId then
            releasePrint("paramJson.sdata: " .. tostring(paramJson.sdata))
            if paramJson.sdata ~= nil then
                global.L_GameEnvManager:SetSData(paramJson.sdata)
            end

            self._username = paramJson.userName
            self._password = paramJson.sessionId
        end

        for k, v in pairs(paramJson) do
            self:SetLoginDataByKey(k, v)
        end

        if global.L_ModuleChooseManager.OnLoginSuccessResp then
            global.L_ModuleChooseManager:OnLoginSuccessResp()
        end

        if paramJson.isCertification ~= nil and paramJson.isAdult ~= nil then
            self._isCertification = paramJson.isCertification
            self._isAdult = paramJson.isAdult

            releasePrint("self._isCertification = ",self._isCertification,"self._isAdult = ",self._isAdult)
        end

        if paramJson.sdkuid ~= nil and paramJson.sdkuid ~= "" then
            self._sdkuid = paramJson.sdkuid
        end

        self:GN_getVIPLevel()
    end
end

function NativeBridgeManager:onHasBuff(sender, jsonString)
    -- debug
    releasePrint("LogoutCallback:" .. tostring(jsonString))
    local paramJson = cjson.decode(jsonString)
    local buff = paramJson.buff -- 1: 有buf, 0:无buf
    self._isHasBuff = buff
end

function NativeBridgeManager:onLogoutCB(sender, jsonString)
    -- debug
    releasePrint("LogoutCallback:" .. tostring(jsonString))

    global.L_GameEnvManager:RestartGame()
end

function NativeBridgeManager:onOverlayInstallationCB(sender, jsonString)
end

function NativeBridgeManager:onMacAddressCB(sender, jsonString)
    local paramJson = cjson.decode(jsonString)
    if paramJson.wifi_mac and string.len(paramJson.wifi_mac) > 0 then
        global.L_GameEnvManager:SetMacAddress(tostring(paramJson.wifi_mac))
    end
end

function NativeBridgeManager:onNativeStatusChangedCB(sender, jsonString)
    releasePrint("NativeStatusChanged 1111:" .. tostring(jsonString))

    local paramJson = cjson.decode(jsonString)
    local networkDesc = {[-1] = "unknown", [0] = "wifi", [1] = "2g", [2] = "3g", [3] = "4g"}
    releasePrint("NativeStatusChanged, network:" .. networkDesc[paramJson.network] .. ",battery:" .. paramJson.battery)

    global.L_GameEnvManager:SetNetType(paramJson.network)
    global.L_GameEnvManager:SetBattery(paramJson.battery)
end

function NativeBridgeManager:onDeviceRotationChanged(sender, jsonString)
    releasePrint("onDeviceRotationChanged 1111:" .. tostring(jsonString))

    local paramJson = cjson.decode(jsonString)
    releasePrint("onDeviceRotationChanged, deviceRotation:" .. paramJson.deviceRotation)

    global.L_GameEnvManager:SetDeviceRotation(paramJson.deviceRotation)

    if global.Facade then
        global.Facade:sendNotification(global.NoticeTable.DeviceRotationChanged)
    end
end

function NativeBridgeManager:NG_AllowLaunchGame(sender, jsonString)
    releasePrint("NG_canEnterGame 1111:" .. tostring(jsonString))

    local paramJson = cjson.decode(jsonString)
    releasePrint("NG_canEnterGame,:" .. paramJson.isAllowLaunch)

    global.L_NativeBridgeManager:SetIsAllowLaunch(tostring(paramJson.isAllowLaunch) == "1")
end

function NativeBridgeManager:NG_RealNameInfo(sender, jsonString)
    releasePrint("NG_RealNameInfo 1111:" .. tostring(jsonString))

    local paramJson = cjson.decode(jsonString)
    releasePrint("NG_RealNameInfo,:" .. paramJson.RealNameStatus)
    self._isCertification = true
    local status = paramJson and paramJson.RealNameStatus and tostring(paramJson.RealNameStatus)
    self._isAdult = status == "2"
    if global.Facade then
        global.Facade:sendNotification(global.NoticeTable.RealNameInfo,{status =status})
    end
end

function NativeBridgeManager:NG_SuspectInfo(sender, jsonString)
    local paramJson = cjson.decode(jsonString)
    if  paramJson.suspectInfo then
        self:SetSuspectInfo(paramJson.suspectInfo)
        -- releasePrint("paramJson.suspectInfo = "..paramJson.suspectInfo)
        global.Facade:sendNotification(global.NoticeTable.SuspectInfo,{info = paramJson.suspectInfo,type = 2})
    end
end

function NativeBridgeManager:NG_HeartInfo(sender, jsonString)
    local paramJson = cjson.decode(jsonString)
    if paramJson.heartInfo then
        if global.Facade then
            global.Facade:sendNotification(global.NoticeTable.SuspectInfo,{info = paramJson.heartInfo,type = 1})
        end
    end
    
end

function NativeBridgeManager:NG_AppInfo(sender, jsonString)
    local paramJson = cjson.decode(jsonString)
    if global.Facade then
        global.Facade:sendNotification(global.NoticeTable.SuspectInfo,{info = paramJson.appInfo,type = 3})
    end
end

function NativeBridgeManager:NG_LastServerInfo(sender, jsonString)
    
    local paramJson = cjson.decode(jsonString)
    self:SetLastServerID(paramJson.lastServerID)
    releasePrint("lastserverid = "..self:getLastServerID())

    if global.L_ModuleChooseManager then
        global.L_ModuleChooseManager:OnLastSelectServerResp()
    end
end

function NativeBridgeManager:NG_SelectGameAndRestart(sender, envString)
    if global.L_ModuleChooseManager then
        global.L_ModuleChooseManager:WriteEnvAndRestart(envString)
    end
end

function NativeBridgeManager:NG_VIPLevel(sender, jsonString)
    releasePrint("NG_VIPLevel = "..jsonString)
    local paramJson = cjson.decode(jsonString)
    self._isHaveVip = true
    self:SetVIPLevel(paramJson)
end

function NativeBridgeManager:NG_SceneSizeChange(sender,jsonString)
    local paramJson = cjson.decode(jsonString)
    if not paramJson then
        return
    end

    releasePrint("=====================NG_SceneSizeChange jsonString： ", jsonString)
    if global.Facade then
        global.Facade:sendNotification( global.NoticeTable.Scene_Size_Change, paramJson)
        return
    end

    global.L_GameEnvManager:OnSizeChanged(paramJson.width, paramJson.height)
end


function NativeBridgeManager:NG_onCubeMessageCallback(sender,jsonString)
    -- body
    if not jsonString or jsonString == "" then
        return
    end
    local paramJson = cjson.decode(jsonString)
    if not paramJson then
        return
    end

    if paramJson.header == "init" then
        -- 初始化完成检测判断是否是聚合
        global.L_DataRePort:OpenJuheMode()
    elseif paramJson.header == "deviceinfo_changed" then
        global.L_DataRePort:SetDeviceInfo(cjson.decode(paramJson.payload))
        global.L_DataRePort:SendLoginEvent()
        releasePrint("=====================NG_onCubeMessageCallback deviceinfo_changed: ", jsonString)
    end
    releasePrint("=====================NG_onCubeMessageCallback jsonString： ", jsonString)
end

function NativeBridgeManager:registerN2GMethods()
    local nativeBridgeCtl = NativeBridgeCtl:Inst()
    
    -- remove last selector
    nativeBridgeCtl:removeSelectorsInGroup("recvDataForInit")
    nativeBridgeCtl:removeSelectorsInGroup("SDKLoginResponse")
    nativeBridgeCtl:removeSelectorsInGroup("AccountOperator")
    nativeBridgeCtl:removeSelectorsInGroup("OverlayInstallation")
    nativeBridgeCtl:removeSelectorsInGroup("WifiMacRecord")
    nativeBridgeCtl:removeSelectorsInGroup("NativeStatus")
    nativeBridgeCtl:removeSelectorsInGroup("DeviceRotation")
    nativeBridgeCtl:removeSelectorsInGroup("AllowLaunchGame")
    nativeBridgeCtl:removeSelectorsInGroup("RealNameInfo")
    nativeBridgeCtl:removeSelectorsInGroup("LastServerInfo")
    nativeBridgeCtl:removeSelectorsInGroup("SDKHasBuff")
    nativeBridgeCtl:removeSelectorsInGroup("GameList")
    nativeBridgeCtl:removeSelectorsInGroup("VIPLevel")
    nativeBridgeCtl:removeSelectorsInGroup("sceneSizeChange")
    nativeBridgeCtl:removeSelectorsInGroup("CubeSDKRePort")

    -- register recv data callback
    nativeBridgeCtl:addNativeSelector("recvDataForInit", "NG_recvData", handler(self, self.onRecvDataCB), nil)

    -- register SDK callback
    nativeBridgeCtl:addNativeSelector("SDKLoginResponse", "NG_SDKLoginCB", handler(self, self.onSDKLoginCB), nil)

    -- register recv data callback
    nativeBridgeCtl:addNativeSelector("AccountOperator", "NG_Logout", handler(self, self.onLogoutCB), nil)

    -- register recv data callback
    nativeBridgeCtl:addNativeSelector("OverlayInstallation", "NG_OverlayInstallation", handler(self, self.onOverlayInstallationCB), nil)
    
    -- register mac address callback
    nativeBridgeCtl:addNativeSelector("WifiMacRecord", "NG_WifiMacRecv", handler(self, self.onMacAddressCB), nil)

    -- register native status changing callback
    nativeBridgeCtl:addNativeSelector("NativeStatus", "NG_NativeStatusChanged", handler(self, self.onNativeStatusChangedCB), nil)
    
    -- register device rotation changing callback
    nativeBridgeCtl:addNativeSelector("DeviceRotation", "NG_DeviceRotationChanged", handler(self, self.onDeviceRotationChanged), nil)

    -- register AllowLaunchGame
    nativeBridgeCtl:addNativeSelector("AllowLaunchGame", "NG_AllowLaunchGame", handler(self, self.NG_AllowLaunchGame), nil)

    -- register RealNameInfo
    nativeBridgeCtl:addNativeSelector("RealNameInfo", "NG_RealNameInfo", handler(self, self.NG_RealNameInfo), nil)

    -- 网易盾嫌疑数据
    nativeBridgeCtl:addNativeSelector("SuspectInfo", "NG_SuspectInfo", handler(self, self.NG_SuspectInfo), nil)
    -- 网易盾心跳数据
    nativeBridgeCtl:addNativeSelector("HeartInfo", "NG_HeartInfo", handler(self, self.NG_HeartInfo), nil)
    -- 网易盾环境风险信息
    nativeBridgeCtl:addNativeSelector("HeartInfo", "NG_AppInfo", handler(self, self.NG_AppInfo), nil)

    nativeBridgeCtl:addNativeSelector("LastServerInfo", "NG_LastServerInfo", handler(self, self.NG_LastServerInfo), nil)

    -- register SDK hasBuf callback
    nativeBridgeCtl:addNativeSelector("SDKHasBuff", "NG_HasBuff", handler(self, self.onHasBuff), nil)

    -- box  gamelist
    nativeBridgeCtl:addNativeSelector("GameList", "NG_SelectGameAndRestart", handler(self, self.NG_SelectGameAndRestart), nil)

    -- 雷电vip
    nativeBridgeCtl:addNativeSelector("VIPLevel", "NG_VIPLevel", handler(self, self.NG_VIPLevel), nil)

    -- 小屏、全屏切换
    nativeBridgeCtl:addNativeSelector("sceneSizeChange","NG_SceneSizeChange", handler(self, self.NG_SceneSizeChange), nil)

    -- c++ 上报
    nativeBridgeCtl:addNativeSelector("CubeSDKRePort","NG_onCubeMessageCallback", handler(self, self.NG_onCubeMessageCallback), nil)

    -- notice native
    self:GN_initNativeFunc()
end

function NativeBridgeManager:GN_appLaunchNotify(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_appLaunchNotify"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

function NativeBridgeManager:GN_initNativeFunc(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_initNativeFunc"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

function NativeBridgeManager:GN_selectGameMod(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_selectGameMod"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)

    elseif cc.PLATFORM_OS_WINDOWS == global.Platform then
        -- upload data windows
        if global.modBridgeController then
            global.modBridgeController:GN_selectGameMod(data)
        end
    end
end

function NativeBridgeManager:GN_accountLogin(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_accountLogin"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

function NativeBridgeManager:GN_accountLogout(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_accountLogout"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

function NativeBridgeManager:GN_onCallOF(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_onCallOF"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

function NativeBridgeManager:GN_onUserIDUpdated(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_onUserIDUpdated"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

function NativeBridgeManager:GN_checkApkUpdate(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_checkApkUpdate"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

function NativeBridgeManager:GN_onSelectServer(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_onSelectServer"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)

    elseif cc.PLATFORM_OS_WINDOWS == global.Platform then
        -- upload data windows
        if global.modBridgeController then
            global.modBridgeController:GN_onSelectServer(data)
        end
    end
end

function NativeBridgeManager:GN_onNewRole(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_onNewRole"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)

    elseif cc.PLATFORM_OS_WINDOWS == global.Platform then
        -- upload data windows
        if global.modBridgeController then
            global.modBridgeController:GN_onNewRole(data)
        end
    end
end

function NativeBridgeManager:GN_onEnterGame(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_onEnterGame"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)

    elseif cc.PLATFORM_OS_WINDOWS == global.Platform then
        -- upload data windows
        if global.modBridgeController then
            global.modBridgeController:GN_onEnterGame(data)
        end
    end
end

function NativeBridgeManager:GN_onLevelChanged(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_onLevelChanged"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)

    elseif cc.PLATFORM_OS_WINDOWS == global.Platform then
        -- upload data windows
        if global.modBridgeController then
            global.modBridgeController:GN_onLevelChanged(data)
        end
    end
end

function NativeBridgeManager:GN_onQuestIDChanged(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_onQuestIDChanged"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)

    elseif cc.PLATFORM_OS_WINDOWS == global.Platform then
        -- upload data windows
        if global.modBridgeController then
            global.modBridgeController:GN_onQuestIDChanged(data)
        end
    end
end

function NativeBridgeManager:GN_buyItemWithYB(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_buyItemWithYB"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)

    elseif cc.PLATFORM_OS_WINDOWS == global.Platform then
        -- upload data windows
        if global.modBridgeController then
            global.modBridgeController:GN_buyItemWithYB(data)
        end
    end
end

function NativeBridgeManager:GN_restartGame(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        if nil ~= data then
            local jsonString = (data and cjson.encode(data))
            local methodName = "GN_restartGame"
            NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
            local printJson = jsonString and jsonString or ""
            releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
        end
    end
end

function NativeBridgeManager:GN_setClipboardText(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = data and cjson.encode({content = data}) or ""
        local methodName = "GN_setClipboardText"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 友盟 进入游戏
function NativeBridgeManager:GN_umengUploadEnterGame(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_umengUploadEnterGame"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    elseif cc.PLATFORM_OS_WINDOWS == global.Platform then
        data = data or {}
        data.actionType = "2"
        self:PCNoticeRequest("GN_onActionGame",data)
    end
end

-- 友盟 支付
function NativeBridgeManager:GN_umengUploadPay(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_umengUploadPay"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 友盟 创角
function NativeBridgeManager:GN_umengUploadNewRole(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_umengUploadNewRole"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    elseif cc.PLATFORM_OS_WINDOWS == global.Platform then
        data = data or {}
        data.actionType = "1"
        self:PCNoticeRequest("GN_onActionGame",data)
    end
end

-- 友盟 升级
function NativeBridgeManager:GN_umengUploadLevelChanged(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_umengUploadLevelChanged"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 友盟 注册
function NativeBridgeManager:GN_umengUploadRegister(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_umengUploadRegister"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 友盟 发起充值
function NativeBridgeManager:GN_umengSubmitPay(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_umengSubmitPay"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 友盟 充值成功
function NativeBridgeManager:GN_umengFinishPay(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_umengFinishPay"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 打开qq
function NativeBridgeManager:GN_startQQ(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_startQQ"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 加qq
function NativeBridgeManager:GN_joinQQ(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_joinQQ"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 加入qq群
function NativeBridgeManager:GN_joinQQGroup(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_joinQQGroup"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 打开wx
function NativeBridgeManager:GN_startWX(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_startWX"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 加入wx公众号
function NativeBridgeManager:GN_joinWXGroup(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_joinWXGroup"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 盒子 返回盒子
function NativeBridgeManager:GN_finishGame(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_finishGame"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 盒子 区服大厅
function NativeBridgeManager:GN_GameList(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_GameList"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 请求启动游戏
function NativeBridgeManager:GN_requestAllowLaunch(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_requestAllowLaunch"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    elseif cc.PLATFORM_OS_WINDOWS == global.Platform then
        self:PCNoticeRequest("GN_onPlayGame",data or {})
    end
end

-- 请求实名
function NativeBridgeManager:GN_requestRealName(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_requestRealName"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 请求获取嫌疑数据
function NativeBridgeManager:GN_requestSuspectInfo(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_requestSuspectInfo"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 初始化易盾外挂sdk
function NativeBridgeManager:GN_requestInitYD(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_requestInitYD"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        release_print("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 上报心跳
function NativeBridgeManager:GN_requestHeartBeat( data )
    if cc.PLATFORM_OS_WINDOWS == global.Platform then
        self:PCNoticeRequest( "GN_onHeartbeat",data or {} )
    end
end

-- 获取平台VIP等级
function NativeBridgeManager:GN_getVIPLevel( data )
    if cc.PLATFORM_OS_ANDROID == global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_getVIPLevel"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

function NativeBridgeManager:PCCheckMedthodName(methodName)
    if not methodName or cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        return false
    end

    if sdkUtil and sdkUtil["getInstance"] and sdkUtil[methodName] then
        return true
    end
    return false
end

function NativeBridgeManager:PCNoticeRequest(methodName,data)
    local ret = nil
    if self:PCCheckMedthodName(methodName) then
        local jsonString = ""
        local obj = sdkUtil:getInstance()
        if obj and obj[methodName] then
            if data and type(data) == "table" then
                local jsonString = (data and cjson.encode(data)) or ""
                ret = obj[methodName](obj,jsonString)
            else
                ret = obj[methodName](obj)
            end
            
            release_print("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. jsonString)
        end
    end
    return ret
end

-- 实名检测返回
function PC_GN_checkRealNameCB( jsonStr )
    if cc.PLATFORM_OS_WINDOWS == global.Platform then
        local jsonData = cjson.decode( jsonStr or "")

        local methodName = "PC_GN_checkRealNameCB"
        local printJson = jsonStr and jsonStr or ""
        release_print("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)

        if jsonData and next(jsonData) and tonumber(jsonData.result) == 0 then
            -- 退出游戏
            cc.Director:getInstance():endToLua()
            return
        end
        global.L_ModuleChooseManager:LaunchModule()
        
    else
        
        global.L_ModuleChooseManager:LaunchModule()
    end
end

-- 注销账号
function NativeBridgeManager:GN_deleteAccount(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = data and cjson.encode(data) or ""
        local methodName = "GN_deleteAccount"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        release_print("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 被顶号
function NativeBridgeManager:GN_otherClientLogin(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = ""
        local methodName = "GN_otherClientLogin"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        release_print("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 云手机发送信息
function NativeBridgeManager:GN_sendCloudLoginMes(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_sendCloudLoginMes"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 自定义数据上报
function NativeBridgeManager:GN_customRePortData(data)
    if PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_customRePortData"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- PC关闭按钮状态
-- @param data table {state=1: 能关闭(默认)， 0: 不能关闭}
function NativeBridgeManager:GN_IsCan_Windown_Close_State( data )
    if cc.PLATFORM_OS_WINDOWS == global.Platform then
        local jsonString = data and cjson.encode(data) or ""
        local methodName = "GN_IsCan_Windown_Close_State"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. jsonString)
    end
end

-- 游戏开始启动
function NativeBridgeManager:GN_LaunchGame( data )
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_LaunchGame"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 加载游戏必要的信息
function NativeBridgeManager:GN_LoadGameInfo( data )
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_LoadGameInfo"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- modlist加载完成
function NativeBridgeManager:GN_LoadModlistFinish( data )
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_LoadModlistFinish"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- modlist加载完成
function NativeBridgeManager:GN_LoadLauncherModeFinish( data )
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_LoadLauncherModeFinish"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 上报游戏相关信息到移动端
function NativeBridgeManager:GN_SendGameInfo( data )
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_SendGameInfo"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 上报游戏异常日志以及网络诊断日志到sdk
function NativeBridgeManager:GN_SendGameNetWorkLog( data )
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_SendGameNetWorkLog"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 云手机悬浮框tips
function NativeBridgeManager:GN_showTipsView( data )
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_showTipsView"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 发送数据到云手机sdk
function NativeBridgeManager:GN_sendDataToSDK( data )
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_sendDataToSDK"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. printJson)
    end
end

-- 多版本通知sdk
function NativeBridgeManager:GN_SDKinit( data )
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_SDKinit"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName)
    end
end

-- 初始化c++上报
function NativeBridgeManager:GN_InitClientCube( data )
    if cc.PLATFORM_OS_WINDOWS == global.Platform then
        local jsonString = data and cjson.encode(data) or ""
        local methodName = "GN_InitClientCube"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName)
    end
end

-- 上报数据 c++
function NativeBridgeManager:GN_SendLogGroupCube( data )
    if cc.PLATFORM_OS_WINDOWS == global.Platform then
        local jsonString = data and cjson.encode(data) or ""
        local methodName = "GN_SendLogGroupCube"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName)
    end
end

-- 聚合SDK模块
function NativeBridgeManager:GN_OpenJuheMode( data )
    if cc.PLATFORM_OS_WINDOWS == global.Platform then
        local jsonString = data and cjson.encode(data) or ""
        local methodName = "GN_OpenJuheMode"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName)
    end
end

-- 多版本更改boxid相关数据
function NativeBridgeManager:GN_UpdateDeviceInfo(data)
    if cc.PLATFORM_OS_WINDOWS == global.Platform then
        local jsonString = data and cjson.encode(data) or ""
        local methodName = "GN_UpdateDeviceInfo"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        local printJson = jsonString and jsonString or ""
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName)
    end
end

return NativeBridgeManager
