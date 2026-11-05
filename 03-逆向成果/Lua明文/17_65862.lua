local GameEnvManager = class("GameEnvManager")
local AssetsManager = requireLauncher( "res_check/assets_manager" )
local cjson = require("cjson")

local defaultChannelID = "1"
local Tags = "LauncherUpdater"
local AppOverlayTraceFile  = "overlay_trace"
cc.PRIORITY_NON_SYSTEM_MIN  = -2147483647

GameEnvManager.startPath = "res/private/start_game/"

function GameEnvManager:ctor()
    self._resVersion = "?v=1.1.1"
    self._rootDomain = ""

    self._gmName            = ""    -- gm 唯一标记
    self._iosNativeGMName   = ""    -- IOS原生下发的gm名称
    self._signkey           = ""    -- 登录、支付加密密钥
    self._gmSearchPath      = ""    -- gm 资源搜索路径
    self._gmCachePath       = ""    -- gm cache路径
    self._channelID         = nil   -- 渠道商id，类型:字符串, ANDROID:读取cID.txt文件  IOS:底层传入  WINDOWS:默认"1"
    self._modeInfoURL       = "http://list-new.dhsf.xqhuyu.com/modlist/modlist_%s.txt"

    self._modeInfoURLPlanB  = ""    -- 备选域名

    self._launcherSuffix    = nil   -- launcher 远端资源后缀
    self._modlistCustomData = {}

    self._downloader        = nil
    
    -- apk info
    self._isReview          = false     -- 是否审核服

    self.apkVersionName     = "1.1.1"
    self.apkVersionCode     = "111"
    self.apkPackageName     = "package"
    self.apkPackageShowName = ""

    self._battery           = 100
    self._netType           = 0
    self._deviceRotation    = 1    -- 刘海屏所在方向  1.刘海屏在左  3.刘海屏在右

    self._totalMemSizeInGB  = 3
    self._UDID              = "xxx"
    self._PUID              = "xxx"
    self._sData             = nil
    self._macAddress        = nil
    self._isEMU             = false
    self._isUM              = false
    self._needPermission    = false     -- 需要权限才能进游戏
    self._hasPermission     = false     -- 是否拥有权限

    -- launcher data
    self._launcherSrvID     = nil       -- 登录器 传入的服务器ID
    self._launcherWhitelist = nil       -- 登录器 传入白名单
    self._envData           = {}
    self._launchERROR       = false     -- 启动失败

    -- gm data
    self._gmLoadingData     = {}

    -- 下载失败计数
    self._downloadEasyCount = {}
    self._isGameSuspend     = false     -- 游戏正在暂停
    self._suspendCBCache    = {}        -- 暂停时的回调缓存

    -- modlist request sign
    self._modlistSignKey    = "shPUZw4ncV5oJ3Hu"
    self._modlistURLList    = {}
    self._modlistURLIndex   = 0
    self._modlistURLCount   = 0

    --强更
    self._apkUpdateInfoUrl  = nil
    self._javaVersionCode   = nil
    self._hasInstallPermission  = false --是否有应用内安装权限
    self._apkUpdateInfo     = {}
end


---------------------------------- domain ------------------------------------
function GameEnvManager:SetResVersion( ver )
    self._resVersion = ver
end

function GameEnvManager:GetResVersion()
    return self._resVersion
end


function GameEnvManager:SetRootDomain( domain )
    self._rootDomain = domain
end

function GameEnvManager:GetRootDomain()
    return self._rootDomain
end

function GameEnvManager:SetRootDomain2( domain )
    self._rootDomain2 = domain
end

function GameEnvManager:GetRootDomain2()
    return self._rootDomain2
end
---------------------------------- domain ------------------------------------

-- review server
function GameEnvManager:SetIsReview( status )
    self._isReview = status
end
function GameEnvManager:IsReview()
    return self._isReview
end

function GameEnvManager:checkReview()
    local restart = false

    -- check alpha status
    if self:IsReview() then
        releasePrint("alpha flag:in review")
        if not g_isAlpha then -- delete alpha file
            if global.L_ModuleManager:IsCurrentModuleAlphaStateExist() then
                releasePrint("alpha flag: delete !alpha flag and restart")
                global.L_ModuleManager:CleanCurrentModuleAlphaState()
                restart = true
                self:RestartGame()
            end
        end
    else
        releasePrint("alpha flag:not in review")
        if g_isAlpha then -- record alpha file
            if not global.L_ModuleManager:IsCurrentModuleAlphaStateExist() then
                releasePrint("alpha flag: record !alpha flag and restart")
                global.L_ModuleManager:StoreCurrentModuleAlphaState()
                restart = true
                self:RestartGame()
            end
        end
    end

    return restart
end

-- review server

-- apk info
function GameEnvManager:SetAPKVersionName( name )
    self.apkVersionName = name
end

function GameEnvManager:GetAPKVersionName()
    return self.apkVersionName
end

function GameEnvManager:SetAPKVersionCode(code)
    self.apkVersionCode = code
end

function GameEnvManager:GetAPKVersionCode()
    return self.apkVersionCode
end

function GameEnvManager:SetAPKPackageName( name )
    self.apkPackageName = name
end

function GameEnvManager:GetAPKPackageName()
    return self.apkPackageName
end

function GameEnvManager:SetAPKPackageShowName( name )
    self.apkPackageShowName = name
end

function GameEnvManager:GetAPKPackageShowName()
    return self.apkPackageShowName
end

function GameEnvManager:SetAPKUpdateInfoUrl( url )
    self._apkUpdateInfoUrl = url
end

function GameEnvManager:GetAPKUpdateInfoUrl()
    return self._apkUpdateInfoUrl
end

function GameEnvManager:SetJavaVersionCode(code)
    self._javaVersionCode = code
end

function GameEnvManager:GetJavaVersionCode()
    return self._javaVersionCode
end

function GameEnvManager:SetHasInstallPermission(hasInstallPermission)
    self._hasInstallPermission = hasInstallPermission
end

function GameEnvManager:GetHasInstallPermission()
    return self._hasInstallPermission
end

-- "update_content"  = "线上分包测试安卓"
-- "update_url"      = "url..."
-- "update_ver_code" = 400000054
-- "update_ver_name" = "4.5.4"
function GameEnvManager:SetAPKUpdateInfo(info)
    self._apkUpdateInfo = info
end

function GameEnvManager:GetAPKUpdateInfo()
    return self._apkUpdateInfo
end
-- apk info

-- native status
function GameEnvManager:SetBattery(battery)
    self._battery = battery
end

function GameEnvManager:GetBattery()
    return self._battery
end

function GameEnvManager:SetNetType(type)
    -- -1:未识别 0:wifi 1:2g 2:3g 3:4g
    self._netType = type
end

function GameEnvManager:GetNetType()
    return self._netType
end

function GameEnvManager:SetDeviceRotation(rotation)
    self._deviceRotation = rotation
end

function GameEnvManager:GetDeviceRotation()
    return self._deviceRotation
end

function GameEnvManager:SetTotalMemSize(memsize)
    self._totalMemSizeInGB = memsize
end

function GameEnvManager:GetTotalMemSize()
    return self._totalMemSizeInGB
end

function GameEnvManager:SetUDID(udid)
    self._UDID = udid
end

function GameEnvManager:GetUDID()
    return self._UDID
end

function GameEnvManager:SetPUID(puid)
    self._PUID = puid
end

function GameEnvManager:GetPUID()
    return self._PUID
end

function GameEnvManager:SetSData( sData )
    self._sData = sData
end

function GameEnvManager:GetSData()
    return self._sData
end

function GameEnvManager:SetMacAddress( mac )
    self._macAddress = mac
end

function GameEnvManager:GetMacAddress()
    return self._macAddress
end

function GameEnvManager:SetIsEmulator(value)
    self._isEMU = value
end
function GameEnvManager:IsEmulator()
    return self._isEMU
end

function GameEnvManager:SetIsUmeng(value)
    self._isUM = value
end

function GameEnvManager:IsUmeng()
    return self._isUM
end

function GameEnvManager:setNeedPermission(value)
    self._needPermission = value
end

function GameEnvManager:isNeedPermission()
    return self._needPermission
end

function GameEnvManager:setHasPermission(value)
    self._hasPermission = value
end

function GameEnvManager:isHasPermission()
    return self._hasPermission
end

-- native status

---------------------------------- gm data ------------------------------------
function GameEnvManager:SetGMLoadingData(v)
    self._gmLoadingData = v
end

function GameEnvManager:GetGMLoadingData()
    return self._gmLoadingData
end


---------------------------------- mod info ------------------------------------
function GameEnvManager:ReportError(str, callback)
    local tipsData = {
        btnType = 1,
        str = str,
        callback = callback
    }
    global.L_CommonTipsManager:OpenLayer( tipsData )
end

function GameEnvManager:SetChannelID( channel )
    self._channelID = channel
end
function GameEnvManager:GetChannelID()
    return self._channelID
end

function GameEnvManager:SetGMName(gmname)
    self._gmName = gmname
end
function GameEnvManager:GetGMName()
    return self._gmName
end

-- IOS原生下发的gm名称
function GameEnvManager:SetIosNativeGMName(gmname)
    self._iosNativeGMName = gmname
end

function GameEnvManager:GetIosNativeGMName()
    return self._iosNativeGMName
end

function GameEnvManager:SetSignkey(signkey)
    self._signkey = signkey
end
function GameEnvManager:GetSignkey()
    return self._signkey
end

function GameEnvManager:SetModInfoURL( url )
    self._modeInfoURL = url
end
function GameEnvManager:GetModInfoURL()
    return self._modeInfoURL
end

function GameEnvManager:SetModInfoURLPlanB( url )
    self._modeInfoURLPlanB = url
end
function GameEnvManager:GetModInfoURLPlanB()
    return self._modeInfoURLPlanB
end

function GameEnvManager:SetLauncherUrlSuffix( suffix )
    self._launcherSuffix = suffix
end
function GameEnvManager:GetLauncherUrlSuffix()
    return self._launcherSuffix
end

function GameEnvManager:SetGMSearchPath( path )
    self._gmSearchPath = path
end
function GameEnvManager:GetGMSearchPath()
    return self._gmSearchPath
end

function GameEnvManager:SetGMCachePath( path )
    self._gmCachePath = path
end
function GameEnvManager:GetGMCachePath()
    return self._gmCachePath
end

function GameEnvManager:SetModlistCustomData( data )
    self._modlistCustomData = data
end
function GameEnvManager:GetModlistCustomData()
    return self._modlistCustomData
end
function GameEnvManager:GetModlistCustomDataByKey(key)
    if not self._modlistCustomData then
        return nil
    end
    return self._modlistCustomData[key]
end

function GameEnvManager:GetModlistSignKey()
    return self._modlistSignKey
end

function GameEnvManager:LoadGameInfo()
    -- 启动文件异常
    if global.isWindows and not global.isDebugMode and not global.isGMMode and self._launchERROR then
        self:ReportError("启动文件异常")
        return false
    end

    -- 停止定时器
    if self._scheduleID then
        UnSchedule( self._scheduleID )
        self._scheduleID = nil
    end

    -- 向底层请求渠道号
    local count = 0
    local limit = 25
    local function callback()
        count = count + 1
        
        if global.isMobile then
            local jData    = {}
            jData.needUDID = 1
            global.L_NativeBridgeManager:GN_appLaunchNotify(jData)
        end

        -- 有渠道号
        if self:GetChannelID() and string.len(self:GetChannelID()) > 0 then
            if self._scheduleID then
                UnSchedule( self._scheduleID )
                self._scheduleID = nil
            end

            -- request modinfo list
            self:RequestModlistURL()
            return nil
        end

        if count >= limit and (nil == self:GetChannelID() or 0 == string.len(self:GetChannelID())) then
            -- 获取失败
            if self._scheduleID then
                UnSchedule( self._scheduleID )
                self._scheduleID = nil
            end

            -- 联系客服
            self:ReportError("启动环境参数异常，请退出重试！", function()
                self:LoadGameInfo()
            end)
        end
    end
    self._scheduleID = Schedule(callback, 0.2)
    callback()
end

function GameEnvManager:decodeModlistXXTEA(response)
    local fileUtil = cc.FileUtils:getInstance()
    local filePath = fileUtil:getWritablePath() .. "temp_decode"
    if fileUtil:isFileExist(filePath) then
        fileUtil:removeFile(filePath)
    end
    fileUtil:writeStringToFile(response, filePath)
    response = fileUtil:getDataFromFileEx(filePath)
    return response
end

function GameEnvManager:decodeModlist(response)
    return cjson.decode( decodeServerInfo(response) )
end

function GameEnvManager:AddModlistCacheNamePrefix(cacheName)
    return string.format("%s_%s", cacheName, self:GetChannelID())
end

function GameEnvManager:RequestModlistURL()
    -- 重新请求
    local function retry()
        self:RequestModlistURL()
    end

    -- http数据请求回调
    local function callback(success, response, url, code)
        HideLoadingBar()
        local raw_response = tostring(response)

        self._modlistURLCount = self._modlistURLCount + 1

        -- 拉取失败
        if not success then
            if self._modlistURLIndex == 0 then --主域名
                global.L_DataRePort:ReportErrorModlistURL("MODLIST_URL_REQUEST_FAILED_MAIN", "-1000", "Request main modlist URL ERROR, CODE ERROR", url, -2)
            else 
                global.L_DataRePort:ReportErrorModlistURL("MODLIST_URL_REQUEST_FAILED_PLANB", "-1000", "Request planb modlist URL ERROR, CODE ERROR", url, -2)
            end

            if self._modlistURLIndex == 0 and self._modlistURLCount >= 3 then
                self:ReportError("[modlist][URL][0]网络不给力哦！点“确认”重试。", retry)
                -- 上报至服务器
                global.L_DataRePort:ReportErrorModlistURL("MODLIST_URL_REQUEST_FAILED", "-1000", "Request modlist URL ERROR, CODE ERROR", url, code)
            else
                retry()
            end

            return nil
        end

        -- 数据异常
        if not response then
            if self._modlistURLIndex == 0 then --主域名
                global.L_DataRePort:ReportErrorModlistURL("MODLIST_URL_REQUEST_FAILED_MAIN", "-1001", "Request main modlist URL ERROR, RESPONCE ERROR", url, -1)
            else 
                global.L_DataRePort:ReportErrorModlistURL("MODLIST_URL_REQUEST_FAILED_PLANB", "-1001", "Request planb modlist URL ERROR, RESPONCE ERROR", url, -1)
            end

            if self._modlistURLIndex == 0 and self._modlistURLCount >= 3 then
                self:ReportError("[modlist][URL][1]网络不给力哦！点“确认”重试。", retry)
                -- 上报至服务器
                global.L_DataRePort:ReportErrorModlistURL("MODLIST_URL_REQUEST_FAILED", "-1001", "Request modlist URL ERROR, RESPONCE ERROR", url, code)
            else
                retry()
            end

            return nil
        end

        -- xxtea 解析
        response = self:decodeModlistXXTEA(response)

        -- json解析，检测是否解析成功
        local jsonData = self:decodeModlist(response)
        if not jsonData or not jsonData.data or #jsonData.data == 0 then
            if self._modlistURLIndex == 0 and self._modlistURLCount >= 3 then
                self:ReportError("[modlist][URL][2]远端服务器配置格式异常", retry)
                -- 上报至服务器
                global.L_DataRePort:ReportErrorModlistURL("MODLIST_URL_REQUEST_FAILED", "-1002", "Request modlist URL ERROR, JSON ERROR: " .. raw_response, url, code)
            else
                retry()
            end
            
            return nil
        end

        self._modlistURLCount = 0
        self:RespModlistURL( jsonData )
    end

    local originUrl         = (self._modlistURLIndex == 1 and self:GetModInfoURLPlanB() and self:GetModInfoURLPlanB() ~= "") and self:GetModInfoURLPlanB() or self:GetModInfoURL()
    local modInfoURL        = string.format( originUrl, self:GetChannelID() )
    modInfoURL              = modInfoURL .. "?" .. string.format("type=getaway&time=%s&sign=%s", os.time(), get_str_MD5("key="..self._modlistSignKey .. "&time="..os.time()))
    self._modlistURLIndex   = 1-self._modlistURLIndex
    -- debug
    releasePrint( "mod list URL:", modInfoURL )
    if modInfoURL and string.len(modInfoURL) > 0 then
        HTTPRequest(modInfoURL, callback)
        ShowLoadingBar()
    end
end

function GameEnvManager:RespModlistURL(jsonData)
    local data = jsonData.data
    self._modlistURLList = data

    self:RequestModInfo()
end

function GameEnvManager:GetModlistCachePath()
    local fileUtil = cc.FileUtils:getInstance()
    local filename = self:AddModlistCacheNamePrefix("ResModlist.txt")
    local filePath = fileUtil:getWritablePath() .. filename
    return filePath
end

function GameEnvManager:CleanupLocalModlist()
    local fileUtil = cc.FileUtils:getInstance()

    local filePath = self:GetModlistCachePath()
    if fileUtil:isFileExist(filePath) then
        fileUtil:removeFile(filePath)
    end
end

function GameEnvManager:GetLocalRuntime()
    local fileUtil = cc.FileUtils:getInstance()

    local filePath = self:GetModlistCachePath()
    if not fileUtil:isFileExist(filePath) then
        return ""
    end
    local response = fileUtil:getDataFromFileEx(filePath)
    local jsonData = self:decodeModlist(response)
    if not jsonData then
        return ""
    end
    if not jsonData.runtime then
        return ""
    end
    return "runtime=" .. jsonData.runtime
end

function GameEnvManager:RequestModInfo()
    -- 重新请求, 需要请求地址
    local function errorRetry()
        self:RequestModlistURL()
    end

    -- 重新请求
    local function retry()
        self:RequestModInfo()
    end

    -- 数据异常
    if #self._modlistURLList == 0 then
        self:ReportError("[modlist][0]网络不给力哦！点“确认”重试。", errorRetry)
        -- 上报至服务器
        global.L_DataRePort:ReportErrorModlistURL("MODLIST_INFO_REQUEST_FAILED", "-2000", "Request modlist INFO ERROR, URL ERROR", "empty", 0)
        return
    end

    -- http数据请求回调
    local function callback(success, response, url, code)
        HideLoadingBar()

        -- 拉取失败
        if not success then
            if #self._modlistURLList == 0 then
                self:ReportError("[modlist][1]网络不给力哦！点“确认”重试。", errorRetry)
                -- 上报至服务器
                global.L_DataRePort:ReportErrorModlistURL("MODLIST_INFO_REQUEST_FAILED", "-2001", "Request modlist INFO ERROR, CODE ERROR", url, code)
            else
                retry()
            end

            return nil
        end

        -- 数据异常
        if not response then
            if #self._modlistURLList == 0 then
                self:ReportError("[modlist][2]网络不给力哦！点“确认”重试。", errorRetry)
                -- 上报至服务器
                global.L_DataRePort:ReportErrorModlistURL("MODLIST_INFO_REQUEST_FAILED", "-2002", "Request modlist INFO ERROR, RESPONSE ERROR", url, code)
            else
                retry()
            end

            return nil
        end

        -- xxtea 解析
        response = self:decodeModlistXXTEA(response)

        -- json解析，检测是否解析成功
        local jsonData = self:decodeModlist(response)
        if not jsonData then
            if #self._modlistURLList == 0 then
                self:CleanupLocalModlist()
                self:ReportError("[modlist][3]远端服务器配置格式异常", errorRetry)
                -- 上报至服务器
                global.L_DataRePort:ReportErrorModlistURL("MODLIST_INFO_REQUEST_FAILED", "-2003", "Request modlist INFO ERROR, JSON ERROR", url, code)
            else
                retry()
            end
            
            return nil
        end

        -- 本地是否是最新的
        local fileUtil = cc.FileUtils:getInstance()
        local filePath = ""
        if jsonData.latestData then
            -- 读取本地，json解析
            filePath = self:GetModlistCachePath()
            response = fileUtil:getDataFromFileEx(filePath)
            jsonData = self:decodeModlist(response)
        else
            -- 不是最新，保存内容至本地，无需再次解析json
            filePath = self:GetModlistCachePath()
            if fileUtil:isFileExist(filePath) then
                fileUtil:removeFile(filePath)
            end
            fileUtil:writeStringToFile(response, filePath)
        end

        -- json解析，检测是否解析成功
        if not jsonData then
            if #self._modlistURLList == 0 then
                self:CleanupLocalModlist()
                self:ReportError("[modlist][4]远端服务器配置格式异常", errorRetry)
                -- 上报至服务器
                global.L_DataRePort:ReportErrorModlistURL("MODLIST_INFO_REQUEST_FAILED", "-2004", "Request modlist INFO ERROR, JSON ERROR", url, code)
            else
                retry()
            end
            
            return nil
        end

        self:parseModList( jsonData )
    end

    local randomIdx     = math.random(1, #self._modlistURLList)
    local modlistURL    = table.remove(self._modlistURLList, randomIdx)
    local modInfoURL    = string.format( modlistURL, self:GetChannelID() )
    local modInfoData   = modInfoURL
    modInfoData         = string.gsub(modInfoData, "http://", "")
    modInfoData         = string.gsub(modInfoData, "https://", "")
    modInfoData         = string.gsub(modInfoData, "/gsl/auth/mod_list_auth", "")
    modInfoData         = string.gsub(modInfoData, "/gsl/main", "")
    local s             = string.find(modInfoData, "/")
    modInfoData         = string.sub(modInfoData, s+1, string.len(modInfoData))
    local signKey       = self:GetModlistSignKey()
    local timestamp     = os.time()
    local sign          = get_str_MD5("data=" .. modInfoData .. "&key=" .. signKey .. "&time="..timestamp)
    -- modInfoURL          = modInfoURL .. "?" .. self:GetLocalRuntime()
    modInfoURL          = modInfoURL .. string.format("?time=%s&sign=%s", timestamp, sign)
    -- debug
    releasePrint( "mod info URL:", modInfoURL )
    if modInfoURL and string.len(modInfoURL) > 0 then
        HTTPRequest(modInfoURL, callback)
        ShowLoadingBar()
    end
end

function GameEnvManager:parseModList(jsonData)
    dump(jsonData)

    -- 根据modlist中 platformId 更新本地的 channelID
    if jsonData.platformId and tostring(jsonData.platformId) ~= "" then
        self:SetChannelID(tostring(jsonData.platformId))
    end

    -- native notice
    global.L_NativeBridgeManager:GN_LoadModlistFinish()

    -- apk强更版本检查
    if jsonData.apkVerUrl then
        local url = {}
        url.apkVerUrl = jsonData.apkVerUrl .. jsonData.resVer
        global.L_NativeBridgeManager:GN_checkApkUpdate(url)
    end
    
    -- apk强更版本检查 根据包名
    if jsonData.apkNameVerUrl and global.isAndroid then
        local packageName = self:GetAPKPackageName()
        local apkVerUrl = string.format("%s%s.json?v=%s",jsonData.apkNameVerUrl, packageName, os.time())  
        self:SetAPKUpdateInfoUrl(apkVerUrl)
    end

    if jsonData.refer then
        global.L_ModuleManager:SetReferModuleID(jsonData.refer)
    end

    if jsonData.customData then
        self:SetModlistCustomData(jsonData.customData)
    end

    if jsonData.modData then
        local modData = jsonData.modData[1]
        if modData and modData.operid and self:NeedChangeRes(modData.operid) then 
            local launcher_ex = "mainBody"
            global.L_ModuleManager:addMainBodySearchPath(launcher_ex)
            global.L_ModuleChooseManager:CloseLayer()
            global.L_ModuleChooseManager:OpenLayer()
        end
        global.L_ModuleManager:InitModules(jsonData.modData)
    end

    if jsonData.resVer then
        self:SetResVersion(jsonData.resVer)
    end

    if jsonData.loadingimg then
        self:SetGMLoadingData(jsonData.loadingimg)

        if jsonData.loadingimg.bar_carousel then
            global.L_ModuleManager:InitImagePre(jsonData.loadingimg.bar_carousel)
        end 
    end

    -- 审核服检测
    local reviewVersion = jsonData.reviewVersion
    local versionCode   = self:GetAPKVersionCode()
    if versionCode and reviewVersion then
        versionCode = tostring(versionCode)
        reviewVersion = tostring(reviewVersion)
        local reviewTable = string.split(reviewVersion, ",")
        for _, version in ipairs(reviewTable) do
            if versionCode == version then
                self:SetIsReview(true)
                break
            end
        end
    end

    if self:checkReview() then
        -- restart
        return 
    end

    -- 安卓/ios 分平台读取
    local resURL        = jsonData.resURL
    local resURL_win    = jsonData.resURL_win
    local resURL_ios    = jsonData.resURL_ios
    local resURL_ad     = jsonData.resURL_ad
    resURL_ios          = (resURL_ios and resURL_ios ~= "") and resURL_ios or resURL
    resURL_ad           = (resURL_ad and resURL_ad ~= "") and resURL_ad or resURL
    resURL_win          = (resURL_win and resURL_win ~= "") and resURL_win or resURL_ad
    --备份cdn
    local resURL2        = jsonData.resURL2
    local resURL_win2    = jsonData.resURL_win2
    local resURL_ios2    = jsonData.resURL_ios2
    local resURL_ad2     = jsonData.resURL_ad2
    resURL_ios2          = (resURL_ios2 and resURL_ios2 ~= "") and resURL_ios2 or resURL2
    resURL_ad2           = (resURL_ad2 and resURL_ad2 ~= "") and resURL_ad2 or resURL2
    resURL_win2          = (resURL_win2 and resURL_win2 ~= "") and resURL_win2 or resURL_ad2

    if global.isWindows then
        resURL          = resURL_win
        resURL2         = resURL_win2
    elseif global.isAndroid or global.isOHOS then
        resURL          = resURL_ad
        resURL2         = resURL_ad2
    elseif global.isIOS then
        resURL          = resURL_ios
        resURL2         = resURL_ios2
    end
    if (resURL and string.len(resURL) > 0) or (resURL2 and string.len(resURL2) > 0) then
        self._updateCount = 0
        self:SetRootDomain(resURL)
        self:SetRootDomain2(resURL2)
        self:SetLauncherUrlSuffix(jsonData.urlsuffix)

        if not self:IsReview() then
            self:CheckUpdate()
        else
            self:handleAlreadyUpToDate()
        end
    else
        self:ReportError("远程资源路径未发现！")
    end

    -- 新安装包地址
    self:CheckNewPackage(jsonData.currpackage)
end
---------------------------------- mod info ------------------------------------


---------------------------------- hot update ------------------------------------
function GameEnvManager:CleanupDownloader()
    if self._downloader then
        self._downloader:Cleanup()
        self._downloader = nil
    end
end

function GameEnvManager:CleanupDownloaderSchedule()
    if self._launcherUpdateSchedule then 
        global.Scheduler:unscheduleScriptEntry(self._launcherUpdateSchedule)
        self._launcherUpdateSchedule = nil
    end
end

function GameEnvManager:handleUpdateFinished()
    self:CleanupDownloader()
    self:CleanupDownloaderSchedule()

    local restartMode = nil
    if global.Platform == cc.PLATFORM_OS_ANDROID then
        local checkNativeFiles  = {
            "libMyGame.so.new",
        }
        local fileUtil  = cc.FileUtils:getInstance()
        local writePath = fileUtil:getWritablePath()
        for _, value in ipairs( checkNativeFiles ) do
            if fileUtil:isFileExist( value ) then
                restartMode = "code"
                break
            end
        end
    end
    self:RestartGame( restartMode )
end

function GameEnvManager:handleAlreadyUpToDate()
    global.L_LoadingManager:CloseLayer()

    self:CleanupDownloader()
    self:CleanupDownloaderSchedule()
    
    global.L_ModuleChooseManager:OnAlreadyUpToDate()

    -- native notice
    global.L_NativeBridgeManager:GN_LoadLauncherModeFinish()

    -- YD
    global.L_NativeBridgeManager:GN_requestInitYD(self:GetModlistCustomData())

    -- SDK login
    global.L_NativeBridgeManager:GN_accountLogin()

    -- download loading img
    local loadingData = global.L_GameEnvManager:GetGMLoadingData()
    if loadingData and loadingData.bg_name and loadingData.bg_url then
        global.L_GameEnvManager:downloadResEasy(loadingData.bg_url, loadingData.bg_name, function(isOK, filename)
            releasePrint("download", isOK, loadingData.bg_url, loadingData.bg_name)
        end)
    end
    if loadingData and loadingData.bar_bg_name and loadingData.bar_bg_url then
        global.L_GameEnvManager:downloadResEasy(loadingData.bar_bg_url, loadingData.bar_bg_name, function(isOK, filename)
            releasePrint("download", isOK, loadingData.bar_bg_url, loadingData.bar_bg_name)
        end)
    end
    if loadingData and loadingData.bar_name and loadingData.bar_url then
        global.L_GameEnvManager:downloadResEasy(loadingData.bar_url, loadingData.bar_name, function(isOK, filename)
            releasePrint("download", isOK, loadingData.bar_url, loadingData.bar_name)
        end)
    end

    --获取pc端的versiconCode
    if global.isWindows then
        if Win32BridgeCtl and Win32BridgeCtl.Inst and Win32BridgeCtl:Inst().GetPcVersionCode then
            self.apkVersionCode = Win32BridgeCtl:Inst():GetPcVersionCode()
        end
        releasePrint("pc VersionCode = "..self.apkVersionCode)
    end
end

function GameEnvManager:CheckUpdate()
    local module = global.L_ModuleManager:GetLauncherModule()
    if not module then
        releasePrint( "can not find launcher module!!" )
        return false
    end

    if self._downloader then
        releasePrint("Launcher pulling!!!")
        return false
    end

    local function versionCompare(str1, str2)
        if str1 == "999.1.1" then
            -- 内网测试版本
            return 1
        end
        if str1 ~= str2 then
            return -1
        end
        return 1
    end
    local downloader = AssetsManager:new()
    downloader:SetEventDelegate( self )
    downloader:SetVersionCompareHandle(versionCompare)


    local modulePath        = module:GetPath()
    local moduleID          = module:GetID()
    local localVersionName  = module:GetVersionFileName()
    local localManifestName = module:GetManifestFileName()
    local storagePath       = cc.FileUtils:getInstance():getWritablePath() .. modulePath
    local tempManifestName  = "project.manifest.temp"
    local tempDirName       = "/_temp"
    local rootDomain        = self._updateCount == 0 and self:GetRootDomain() or self:GetRootDomain2()
    local resUrl            = string.format( "%s%s", rootDomain, tostring(module:GetRemotePath(self:GetLauncherUrlSuffix())) )
    local manifestUrl       = resUrl .. localManifestName
    local versionUrl        = resUrl .. localVersionName
    local resVersion        = self:GetResVersion()
    local jobs              = 2
    local ignoreLocal       = not global.FileUtilCtl:isFileExist( localManifestName )



    -- verbose
    releasePrint( "-------------------------------------------------------------" )
    releasePrint( "pull module:", moduleID )
    releasePrint( manifestUrl )
    releasePrint( versionUrl )
    releasePrint( "ignore local:" .. tostring(ignoreLocal) )
    releasePrint( "local storage path:" .. tostring(storagePath) )
    releasePrint( "-------------------------------------------------------------" )


    -- request download
    local ret = downloader:DownLoadRequest( "launcher_update", localManifestName, storagePath, tempManifestName, tempDirName,
                                            resUrl, manifestUrl, versionUrl, resVersion, jobs, ignoreLocal )

    if not ret then
        downloader:Cleanup()
        return false
    end

    self._downloader = downloader
    
    if self._updateCount == 0 and self:GetRootDomain2() and string.len(self:GetRootDomain2()) > 0 then 
        self._launcherUpdateSchedule = PerformWithDelayGlobal(function ()
            self._launcherUpdateSchedule = nil
            self._updateCount = self._updateCount + 1
            self:CleanupDownloader()
            self:CheckUpdate()
        end, 10)
    else
        self._launcherUpdateSchedule = PerformWithDelayGlobal(function ()
            self._launcherUpdateSchedule = nil
            -- 触发重新下载
            local moduleID = global.L_ModuleManager:GetLauncherModuleID()
            local moduleVersion = self:GetLauncherUrlSuffix()
            local errorString = string.format("[%s][%s]远程清单访问超时!\n点击下方\"确认\"重试", tostring(moduleID), tostring(moduleVersion))
            local function callback()
                self._updateCount = 0
                self:CleanupDownloader()
                self:CheckUpdate()
            end
            self:ReportError(errorString, callback)
        end, 10)
    end
    return true
end


function GameEnvManager:onLocalManifestError()
    RecordBuglyLogIm( Tags, "Local Manifest Error!" )

    self:CleanupDownloader()
    self:CleanupDownloaderSchedule()
    if self._updateCount == 0 and self:GetRootDomain2() and string.len(self:GetRootDomain2()) > 0  then 
        self._updateCount = self._updateCount + 1
        self:CheckUpdate()
    else
        -- 触发重新下载
        local moduleID = global.L_ModuleManager:GetLauncherModuleID()
        local moduleVersion = self:GetLauncherUrlSuffix()
        local errorString = string.format("[%s][%s]远程清单异常!\n点击下方\"确认\"重试", tostring(moduleID), tostring(moduleVersion))

        local function callback()
            self._updateCount = 0
            self:CheckUpdate()
        end
        self:ReportError(errorString, callback)
    end
    
end

function GameEnvManager:onRemoteManifestError()
    RecordBuglyLogIm( Tags, "Remote Manifest Error!" )

    self:CleanupDownloader()
    self:CleanupDownloaderSchedule()
    if self._updateCount == 0 and self:GetRootDomain2() and string.len(self:GetRootDomain2()) > 0  then 
        self._updateCount = self._updateCount + 1
        self:CheckUpdate()
    else
        -- 触发重新下载
        local moduleID = global.L_ModuleManager:GetLauncherModuleID()
        local moduleVersion = self:GetLauncherUrlSuffix()
        local errorString = string.format("[%s][%s]远程清单异常!\n点击下方\"确认\"重试", tostring(moduleID), tostring(moduleVersion))

        local function callback()
            self._updateCount = 0
            self:CheckUpdate()
        end
        self:ReportError(errorString, callback)
    end
end

function GameEnvManager:onCheckVersionInfo()
    self:CleanupDownloaderSchedule()
    global.L_LoadingManager:OpenLayer({isCheckVersion=true, delay=true})
end

function GameEnvManager:onNewVersion( versionSize )
    self:CleanupDownloaderSchedule()
    local sizeInMB = versionSize / (1024 * 1024)
    RecordBuglyLogIm( Tags, "New Version Found:" .. tostring( sizeInMB ) )

    global.L_LoadingManager:CloseLayer()
    global.L_LoadingManager:OpenLayer({isCheckVersion=true})

    if self._downloader then
        global.L_LoadingManager:CloseLayer()
        global.L_LoadingManager:OpenLayer()
        self._downloader:StartUpdate()
    end
end

function GameEnvManager:onAlreadyUpToDate()
    RecordBuglyLogIm( Tags, "Already Up To Date")
    self:CleanupDownloaderSchedule()

    local launcherModule = global.L_ModuleManager:GetLauncherModule()
    if self._downloader and launcherModule then
        local version = self._downloader:GetRemoteManifestVer()
        launcherModule:SetRemoteVersion( version )
    end
    self:handleAlreadyUpToDate()
end

function GameEnvManager:onUpdatePercent( percent )
    self:CleanupDownloaderSchedule()
    global.L_LoadingManager:UpdatePercent(percent)
end

function GameEnvManager:onAssetError( assetID, msg )
    self:CleanupDownloaderSchedule()
    RecordBuglyLogIm( Tags, "Asset Error! " .. tostring( assetID ) )
end

function GameEnvManager:onDownloadFinished()
    RecordBuglyLogIm( Tags, "Update Finished" )
    self:CleanupDownloaderSchedule()

    self:handleUpdateFinished()

    global.L_LoadingManager:CloseLayer()
end

function GameEnvManager:onDownloadFailed()
    RecordBuglyLogIm( Tags, "Update Failed!" )
    self:CleanupDownloaderSchedule()

    if self._downloader then
        self._downloader:Retry()
    end
end
---------------------------------- hot update ------------------------------------

function GameEnvManager:RestartGame( mode )
    global.L_LoadingBarManager:CloseLayer()
    global.L_ModuleChooseManager:CloseLayer()
    global.L_GameLayerManager:Close()
    -- cleanup user data
    UserData:Cleanup()
    UserData:setVersionPath("")


    local director = cc.Director:getInstance()
    local texCache = director:getTextureCache()

    -- clearAsyncCallback
    texCache:unbindAllImageAsync()

    -- clear cocos2d cache, issue: release res maybe crash.
    director:purgeCachedData()
    -- clear cocos2d event
    director:getEventDispatcher():removeAllEventListeners()
    -- clear cocos2d scheduler, but system scheduler( ActionManager )
    director:getScheduler():unscheduleAllWithMinPriority( cc.PRIORITY_NON_SYSTEM_MIN )
    -- clear cocos2d action
    director:getActionManager():removeAllActions()
    -- clear cocos2d audio
    cc.SimpleAudioEngine:destroyInstance()
    ccexp.AudioEngine:uncacheAll()
    -- ccexp.AudioEngine:endToLua()
    -- destroy glProgram
    cc.GLProgramCache:destroyInstance()


    -- reset downloader
    httpDownloader:Inst():reset()


    -- record log
    local platform = cc.Application:getInstance():getTargetPlatform()
    if platform == cc.PLATFORM_OS_ANDROID then
        if nil ~= mode then
            local jData = {}
            jData.restartMode = mode
            global.L_NativeBridgeManager:GN_restartGame(jData)
        else 
            buglyLog( 0, "restart game", "Restart Lua VM!" )         
        end
    end

    releasePrint( "Restart Launcher completed" )
    releasePrint( "Restart Lua VM!" )    

    -- restart luaVM
    LuaBridgeCtl:Inst():CreateNewState()
end


---------------------------------- overlay install ------------------------------------
function GameEnvManager:CheckAppOverlayTrace()
    local lastAppVerCode = tonumber( self:readAppOverlayTrace() )
    local currAppVerCode = tonumber( self:GetAPKVersionCode() )

    if currAppVerCode and lastAppVerCode and currAppVerCode > lastAppVerCode then
        self:onAppOverlay()
        self:writeAppOverlayTrace( currAppVerCode )
        self:RestartGame()
    end
end

function GameEnvManager:readAppOverlayTrace()
    local fileUtil   = cc.FileUtils:getInstance()
    local writePath  = fileUtil:getWritablePath()
    local filePath   = writePath .. AppOverlayTraceFile
    local appVerCode = tonumber( self:GetAPKVersionCode() )

    if not fileUtil:isFileExist( filePath ) then
        self:writeAppOverlayTrace( appVerCode )
        return appVerCode
    end

    local fileContent = fileUtil:getDataFromFile( filePath ) 
    local tmpCode = tonumber( fileContent )
    if nil == tmpCode then
        self:writeAppOverlayTrace( appVerCode )
        return appVerCode
    else
        appVerCode = tmpCode
    end

    return appVerCode
end

function GameEnvManager:writeAppOverlayTrace( appVerCode )
    local fileUtil   = cc.FileUtils:getInstance()
    local writePath  = fileUtil:getWritablePath()
    local filePath   = writePath .. AppOverlayTraceFile

    fileUtil:writeStringToFile( tostring( appVerCode ), filePath )
end

function GameEnvManager:onAppOverlay()
    --  处理盒子覆盖安装清理launcher导致进入游戏黑屏的问题
    if global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin") == 1 then
        release_print("box not clear launcher1")
        return nil
    end
    
    local removeDirs  = {}
    local removeFiles = {}

    if( cc.PLATFORM_OS_IPHONE == global.Platform ) or ( cc.PLATFORM_OS_IPAD == global.Platform ) then
        removeDirs = { 
            "mod_launcher",
            "mod_fgcq",
        }

        removeFiles = {
        }
    else
        removeDirs = { 
            "mod_launcher",
            "mod_fgcq",
        }

        removeFiles = {
            "libMyGame.so",
        }
    end


    local fileUtil = cc.FileUtils:getInstance()
    local writePath = fileUtil:getWritablePath()

    -- remove dirs
    for _, value in ipairs( removeDirs ) do
        -- debug
        releasePrint( "remove dir:" .. writePath .. value )
        fileUtil:removeDirectory( writePath .. value )
    end

    -- remove files
    for _, value in ipairs( removeFiles ) do
        -- debug
        releasePrint( "remove file:" .. writePath .. value )
        fileUtil:removeFile( writePath .. value )
    end
end
---------------------------------- overlay install ------------------------------------

function GameEnvManager:CheckRootDir()
    local fileUtil = cc.FileUtils:getInstance()
    local writePath = fileUtil:getWritablePath()
    
    local checkDirs = {
        writePath,
    }

    for _, value in ipairs( checkDirs ) do
        if not fileUtil:isDirectoryExist( value ) then
            releasePrint( "create root dir:", value )
            fileUtil:createDirectory( value )
        end
    end


    if global.isIOS then
        -- check ios root dir
        local iosRootDir = fileUtil:getWritablePath() .. "/files/"
        if not fileUtil:isDirectoryExist(iosRootDir) then
            releasePrint("create ios root dir")
            fileUtil:createDirectory(iosRootDir)
        end
    end
end

function GameEnvManager:CheckNewPackage(packageData)
    if not packageData or not packageData.url or not packageData.currVersion then
        return
    end

    local versionCode   = tonumber(self:GetAPKVersionCode())
    local currVersion   = tonumber(packageData.currVersion)
    local tips          = packageData.tips or "检测到新版本，请点击\"确认\"前往下载"
    local url           = packageData.url

    release_print("CheckNewPackage", currVersion, versionCode, url)

    -- 版本号合法
    if not currVersion or not versionCode then
        return
    end
    -- 版本已经是最新
    if versionCode >= currVersion then
        return
    end

    local tipsData = {
        btnType = 1,
        str = tips,
        callback = function()
            cc.Application:getInstance():openURL(url)
            self:RestartGame()
        end
    }
    global.L_CommonTipsManager:OpenLayer( tipsData )
end

---------------------------------- game env ------------------------------------
function GameEnvManager:SetEnvData(data)
    self._envData = data
end

function GameEnvManager:GetEnvData()
    return self._envData
end

function GameEnvManager:SetEnvDataByKey(key, value)
    self._envData[key] = value
end

function GameEnvManager:GetEnvDataByKey(key)
    return self._envData[key]
end

function GameEnvManager:SetLauncherSrvID(srvid)
    self._launcherSrvID = srvid
end

function GameEnvManager:GetLauncherSrvID(srvid)
    return self._launcherSrvID
end

function GameEnvManager:SetLauncherWhitelist(whitelist)
    self._launcherWhitelist = whitelist
end

function GameEnvManager:GetLauncherWhitelist()
    return self._launcherWhitelist
end

-- 加载开关配置 switchConfig.json
function GameEnvManager:LoadSwitchConfig()
    local fileUtil  = cc.FileUtils:getInstance()
    local filename  = "switchConfig.json"
    local isExist   = fileUtil:isFileExist(filename)
    if not isExist then
        return
    end
    -- 是否有内容
    local jsonStr   = nil
    if fileUtil:isFileExist(filename) then
        jsonStr     = fileUtil:getDataFromFileEx(filename)
    elseif fileUtil:isFileExist(filenameT) then
        jsonStr     = fileUtil:getDataFromFileEx(filenameT)
    end
    if not jsonStr or jsonStr == "" then
        return nil
    end

    -- 是否是json
    local jsonData  = cjson.decode(jsonStr)
    if not jsonData then
        return nil
    end

    -- 保存
    for k,v in pairs(jsonData) do
        self._envData[k] = v
    end

    if jsonData["showLanguage"] then
        loadLanguageConfig( jsonData["showLanguage"] )
    end
end

function GameEnvManager:LoadGameEnv()
    local fileUtil  = cc.FileUtils:getInstance()
    local filename  = "env.json"
    local filenameT = "env.json.tmp"
    local isExist   = fileUtil:isFileExist(filename) or fileUtil:isFileExist(filenameT)

    -- 是否存在
    if not isExist then
        if global.isDebugMode or global.isGMMode then
            -- 开发模式下，给默认渠道号
            self:SetChannelID(defaultChannelID)
            self:SetGMName("1")
            global.CURRENT_OPERMODE = global.OPERMODE_MOBILE
        end
        return nil
    end

    -- 是否有内容
    local jsonStr   = nil
    if fileUtil:isFileExist(filename) then
        jsonStr     = fileUtil:getDataFromFileEx(filename)
    elseif fileUtil:isFileExist(filenameT) then
        jsonStr     = fileUtil:getDataFromFileEx(filenameT)
    end
    if not jsonStr or jsonStr == "" then
        self._launchERROR = true
        return nil
    end

    -- 是否是json
    local jsonData  = cjson.decode(jsonStr)
    if not jsonData then
        self._launchERROR = true
        return nil
    end

    -- 存储
    for k,v in pairs(jsonData) do
        self._envData[k] = v
    end

    -- 開發模式/GM模式
    if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS and (global.isDebugMode or global.isGMMode) then
        -- 操作模式
        local oper_mode         = tonumber(jsonData.oper_mode) or 2
        global.CURRENT_OPERMODE = oper_mode
    end

    -- 分辨率
    if global.CURRENT_OPERMODE == global.OPERMODE_WINDOWS then
        -- 竖版
        local isPortrait = tonumber(jsonData.isPortrait) == 1
        if isPortrait then
            global.IS_PORTRAIT = true
        end
        local defaultReslution  = isPortrait and "640x980" or "1024x768"
        local resolution        = jsonData.resolution or defaultReslution
        if isPortrait then
            resolution          = defaultReslution
        end
        local slices            = string.split(resolution, "x")
        local resolutionWidth   = tonumber(slices[1]) or 1024
        local resolutionHeight  = tonumber(slices[2]) or 768

        global.DesignSize_Win   = {width = resolutionWidth, height = resolutionHeight}
        global.DeviceSize_Win   = {width = resolutionWidth, height = resolutionHeight}
        releasePrint(global.DeviceSize_Win.width, global.DeviceSize_Win.height)
    end

    -- modlist
    if jsonData.modlist and string.len(jsonData.modlist) > 0 then
        self:SetModInfoURL(jsonData.modlist)
    end
    if jsonData.modlistPlanB and string.len(jsonData.modlistPlanB) > 0 then
        self:SetModInfoURLPlanB(jsonData.modlistPlanB)
    end

    -- 渠道ID
    self:SetChannelID(jsonData.channel)

    -- 推广员标识 先查找IOS平台是否下发gm
    local gmName = jsonData.gm
    local iosNativeGMName = self:GetIosNativeGMName()
    if global.isIOS and iosNativeGMName and string.len(iosNativeGMName) > 0 then
        gmName = iosNativeGMName
    end
    self:SetGMName(gmName)

    -- signkey
    self:SetSignkey(jsonData.signkey)

    -- server id
    if jsonData.serverId and string.len(jsonData.serverId) > 0 then
        self:SetLauncherSrvID(jsonData.serverId)
    end

    -- whitelist
    if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
        if jsonData.whitelist and string.len(jsonData.whitelist) > 0 then
            self:SetLauncherWhitelist(tonumber(jsonData.whitelist) == 1)
        end
    end
    
    -- gm res search path
    if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
        if jsonData.gmRes and string.len(jsonData.gmRes) > 0 then
            self:SetGMSearchPath(jsonData.gmRes)

            -- 新增GM资源搜索目录
            local rootPath      = global.FileUtilCtl:getDefaultResourceRootPath()
            local gmCachePath   = rootPath .. "gm_cache/" .. self:GetGMSearchPath() .. "/"
            self:SetGMCachePath(gmCachePath)
            global.FileUtilCtl:addSearchPath(gmCachePath)
        end
    end

    -- 映射功能只在windows生效
    if global.isWindows then
        global.FileUtilCtl:setFilenameLookupDictionary({})
    end

    self:LoadSwitchConfig()
end

function GameEnvManager:NeedChangeRes(gameid)
    gameid = tostring(gameid)
    local gameids = {"202624"}
    for i,v in ipairs(gameids) do
        if v == gameid then 
            releasePrint("NeedChangeRes ")
            return true
        end
    end
    return false
end

function GameEnvManager:SetGameEnvDataByKey(key, value)
    -- windows only
    local showResolution = global.L_GameEnvManager:GetEnvDataByKey("showResolution")
    if global.isDebugMode or global.isGMMode or showResolution then
        if type(key) ~= "string" then
            print("STRING ONLY")
            return nil
        end
    
        local module = global.L_ModuleManager:GetLauncherModule()
        if not module then
            releasePrint( "can not find launcher module!!" )
            return false
        end
    
        local fileUtil          = cc.FileUtils:getInstance()
        local storagePath       = cc.FileUtils:getInstance():getDefaultResourceRootPath() .. "env.json"
    
        local jsonData          = {}
        local jsonStr           = fileUtil:getDataFromFileEx("env.json")
        if not jsonStr or jsonStr == "" or jsonStr == "env.json" then
            jsonData            = {}
        else
            jsonData            = cjson.decode(jsonStr)
        end
        jsonData                = jsonData or {}
        jsonData[key]           = value
        jsonData["channel"]     = self:GetChannelID()
        jsonData["gm"]          = self:GetGMName() or "21"
    
        local jsonStr           = cjson.encode(jsonData)
        fileUtil:writeStringToFile(jsonStr, storagePath)
    end
end

function GameEnvManager:SetGamePreEnvDataByKey(key, value)
    local showResolution = global.L_GameEnvManager:GetEnvDataByKey("showResolution")
    if global.isDebugMode or global.isGMMode or showResolution then
        if type(key) ~= "string" then
            print("STRING ONLY")
            return nil
        end
    
        local module = global.L_ModuleManager:GetLauncherModule()
        if not module then
            releasePrint( "can not find launcher module!!" )
            return false
        end
    
        local fileUtil          = cc.FileUtils:getInstance()
        local storagePath       = cc.FileUtils:getInstance():getDefaultResourceRootPath() .. "preenv.json"
        if fileUtil:isFileExist(storagePath) then
            local jsonData          = {}
            local jsonStr           = fileUtil:getDataFromFileEx("preenv.json")
            if not jsonStr or jsonStr == "" or jsonStr == "preenv.json" then
                jsonData            = {}
            else
                jsonData            = cjson.decode(jsonStr)
            end
            jsonData                = jsonData or {}
            jsonData[key]           = value
            
            local jsonStr           = cjson.encode(jsonData)
            fileUtil:writeStringToFile(jsonStr, storagePath)
        end
    end
end

function GameEnvManager:downloadResEasy(resUrl, filename, downloadCB)
    -- check param
    if not resUrl or string.len(resUrl) == 0 then
        downloadCB(false, filename)
        return
    end

    -- check param
    if not filename or string.len(filename) == 0 then
        downloadCB(false, filename)
        return
    end

    local directoryPath = global.FileUtilCtl:getWritablePath()
    local filePath      = directoryPath .. filename
    print("filePath", filePath, global.FileUtilCtl:isFileExist(filePath) )

    -- remove cache
    local textureCache  = global.Director:getTextureCache()
    if textureCache:getTextureForKey(filePath) then
        textureCache:removeTextureForKey(filePath)
    end

    -- is exist
    if global.FileUtilCtl:isFileExist(filePath) then
        downloadCB(true, filename)
        return
    end

    local downloader    = httpDownloader:Inst()
    downloader:AsyncDownloadEasy(resUrl, filePath,
    function(isOK)
            print("downloadRes isOK", isOK)
            -- 下载成功了
            if isOK then
                if self._isGameSuspend then
                    table.insert(self._suspendCBCache, function()
                        downloadCB(isOK, filename)
                    end)
                else
                    downloadCB(isOK, filename)
                end
                
                return
            end
        
            -- 下载失败了
            -- 重试 3 次
            self._downloadEasyCount[filename] = self._downloadEasyCount[filename] or 0
            self._downloadEasyCount[filename] = self._downloadEasyCount[filename] + 1
            if self._downloadEasyCount[filename] <= 3 then
                global.L_GameEnvManager:downloadResEasy(resUrl, filename, downloadCB)
            end
        end,
        0
    )
end

function GameEnvManager:StartGame()
    if not global.L_GameLayerManager._uiNode then
        self:LoadGameInfo()
        return
    end

    local filepath  = self.startPath
    local viewSize  = global.Director:getVisibleSize()
    local SplashTime        = 1.0
    local SplashFadeInTime  = 0.6
    local SplashFadeOutTime = 0.8

    local layer = cc.Layer:create()
    global.L_GameLayerManager._uiNode:addChild(layer, 999)

    -- swallow
    local layout = ccui.Layout:create()
    layer:addChild(layout)
    layout:setBackGroundColor(cc.c3b(0, 0, 0))
    layout:setBackGroundColorType(1)
    layout:setBackGroundColorOpacity(255)
    layout:setContentSize({width = viewSize.width, height = viewSize.height})
    layout:setTouchEnabled(true)

    ----------------------------------------
    ----------------------------------------
    ----------------------------------------
    local function finishCB()
        -- native notice
        global.L_NativeBridgeManager:GN_LoadGameInfo()

        layer:removeFromParent()
        self:LoadGameInfo()
    end

    -- 闪屏
    local function startSplash()
        -- played
        if LuaBridgeCtl:Inst():GetModulesSwitch(8) == 1 then
            finishCB()
            return
        end
        LuaBridgeCtl:Inst():SetModulesSwitch(8, 1)
        

        local items = {}
        local index = 0
        while true do
            local filename = filepath .. string.format("%02d.png", index)
            if not global.FileUtilCtl:isFileExist(filename) then
                break
            end
            table.insert(items, filename)
            index = index + 1
        end

        -- 
        local function showSplashAuto()
            if #items <= 0 then
                finishCB()
                return
            end

            local filename = table.remove(items, 1)
            local image    = ccui.ImageView:create()
            image:loadTexture( filename )
            image:setPosition( viewSize.width * 0.5, viewSize.height * 0.5 )
            image:setAnchorPoint( 0.5, 0.5 )
            layer:addChild( image, 999 )

            image:setOpacity( 0 )
            image:runAction( cc.Sequence:create( 
                cc.FadeIn:create( SplashFadeInTime ),
                cc.DelayTime:create( SplashTime ),
                cc.FadeTo:create( SplashFadeOutTime, 20 ),
                cc.CallFunc:create(function()
                    showSplashAuto()
                end),
                cc.RemoveSelf:create()
            ) )

            -- remove texture cache
            global.TextureCache:removeTextureForKey( filename )
        end

        showSplashAuto()
    end

    startSplash()
end

function GameEnvManager:OnGameSuspend()
    release_print("function GameEnvManager:OnGameSuspend()")

    self._isGameSuspend = true
end

function GameEnvManager:OnGameResumed()
    release_print("function GameEnvManager:OnGameResumed()")

    self._isGameSuspend = false

    -- 所有暂停期间的回调处理
    for i, v in ipairs(self._suspendCBCache) do
        v()
    end
    self._suspendCBCache = {}
end

function GameEnvManager:OnSizeChanged(width, height)
    local frameFactor   = width / height
    local designPolicy  = cc.ResolutionPolicy.FIXED_HEIGHT
    if frameFactor > 1.8 then       -- 17:9 = 1.889
        designPolicy = cc.ResolutionPolicy.FIXED_HEIGHT
    else                            -- 16:9 = 1.778
        designPolicy = cc.ResolutionPolicy.FIXED_WIDTH
    end

    local glview = cc.Director:getInstance():getOpenGLView()
    glview:setFrameSize(width, height)
    local width = global.DesignSize_Win.width
    local height = global.DesignSize_Win.height
    if global.isWindows and width > global.DeviceWith_Win or height > global.DeviceHeight_Win then
        width = global.DeviceWith_Win
        height = global.DeviceHeight_Win
    end
    glview:setDesignResolutionSize(width, height, designPolicy)
    self:RestartGame()
end

function GameEnvManager:OnScreenSizeChanged(width, height)
    if self._framesizeOriWidth == width and self._framesizeOriHeight == height then
        return 
    end 

    if self._framesizeOriWidth == height and self._framesizeOriHeight == width then
        return 
    end 
    
    self:OnSizeChanged(width, height)
end
-------------------------------------------------------------
function GameEnvManager:launch()
    local glview = cc.Director:getInstance():getOpenGLView()
    local framesize = glview:getFrameSize()
    self._framesizeOriWidth  = framesize.width
    self._framesizeOriHeight = framesize.height

    -- stateMgr, for pause & resume
    gameStateMgr:Inst():RegisterLuaHandler( function( appState, p1, p2)
        if 0 == appState then
            self:OnGameSuspend()
    
        elseif 1 == appState then
            self:OnGameResumed()
        elseif 2 == appState then 
            self:OnScreenSizeChanged(p1, p2)
        end
    end )
    
    local function loadGame()
        -- load game env
        global.L_GameEnvManager:LoadGameEnv()
        global.L_DataRePort:Init()
        --------------------------------------------
        local glview = cc.Director:getInstance():getOpenGLView()
        local frameSize     = cc.Director:getInstance():getOpenGLView():getFrameSize()
        if frameSize.width < frameSize.height then --竖屏
            global.IS_PORTRAIT = true
            local w = global.DesignSize_Oth.width 
            global.DesignSize_Oth.width  = global.DesignSize_Oth.height
            global.DesignSize_Oth.height = w
        end
        local frameFactor   = frameSize.width / frameSize.height
        local designPolicy  = cc.ResolutionPolicy.FIXED_HEIGHT
        if frameFactor > 1.8 then       -- 17:9 = 1.889
            designPolicy = cc.ResolutionPolicy.FIXED_HEIGHT
        else                            -- 16:9 = 1.778
            designPolicy = cc.ResolutionPolicy.FIXED_WIDTH
        end
    
        if cc.PLATFORM_OS_WINDOWS == cc.Application:getInstance():getTargetPlatform() then
            -- 自适应屏幕
            local monitorWidth = 0
            local monitorHeight = 0
            if getWindowWidth and getWindowHeight then
                monitorWidth = getWindowWidth()
                monitorHeight = getWindowHeight()
            end
            if monitorWidth ~= 0 and monitorHeight ~= 0 then
                global.DeviceSize_Win.width = math.min(global.DeviceSize_Win.width, (monitorWidth-20))
                global.DeviceSize_Win.height = math.min(global.DeviceSize_Win.height, (monitorHeight-100))

                if monitorWidth > 1920 or monitorHeight > 1080 then
                    global.WINIS4K = true
                end
            end
            
            release_print(global.DeviceSize_Win.width, global.DeviceSize_Win.height)
            glview:setFrameSize(global.DeviceSize_Win.width, global.DeviceSize_Win.height)
    
            local width = global.DesignSize_Win.width
            local height = global.DesignSize_Win.height
            if width > global.DeviceWith_Win or height > global.DeviceHeight_Win then
                width = global.DeviceWith_Win
                height = global.DeviceHeight_Win
            end
            glview:setDesignResolutionSize(width, height, designPolicy)
            -- glview:setFrameZoomFactor( global.DeviceZoom_Win )
        else
            glview:setDesignResolutionSize(global.DesignSize_Oth.width, global.DesignSize_Oth.height, designPolicy)
        end
        --------------------------------------------
        ----------ttfScale-----
        --c++版本大于等于1
        if LuaBridgeCtl:Inst():GetModulesSwitch(global.Modules_Index_Cpp_Version) >= global.CPP_VERSION_LABEL_TTF then 
            if cc.PLATFORM_OS_WINDOWS ~= cc.Application:getInstance():getTargetPlatform() then
                local frameSize  = glview:getFrameSize()
                local DesignSize = glview:getDesignResolutionSize()
                local ttfscale   = 1
                if designPolicy == cc.ResolutionPolicy.FIXED_HEIGHT then 
                    ttfscale = frameSize.height / DesignSize.height
                elseif designPolicy == cc.ResolutionPolicy.FIXED_WIDTH then 
                    ttfscale = frameSize.width / DesignSize.width
                end
                if cc.Label.setTTFAliasTexParameters then 
                    cc.Label:setTTFAliasTexParameters(true)
                end
                if cc.Label.setTTFScaleFactor then 
                    cc.Label:setTTFScaleFactor(ttfscale)
                end
            end
        end
        --------------------------------------------
        -- 游戏名
        local viewName = global.L_GameEnvManager:GetEnvDataByKey("viewName")
        if cc.PLATFORM_OS_WINDOWS == cc.Application:getInstance():getTargetPlatform() then
            glview:setViewName(viewName or "")
        end
    
        -- init game layer
        global.L_GameLayerManager:Init()
    
        -- init system tips
        global.L_SystemTipsManager:OpenLayer()
    
        -- open module choose layer
        global.L_ModuleChooseManager:OpenLayer()
    
        -- native notice
        global.L_NativeBridgeManager:GN_LaunchGame()

        -- load game info && request mod info list
        global.L_GameEnvManager:StartGame()
    end


    -------------------------------------------------
    -- 是否能进入，需要权限且拥有权限
    local function checkPermission()
        if global.isWindows then
            return true
        end
        if global.L_NativeBridgeManager._revcData and not self:isNeedPermission() then
            return true
        end
        if self:isNeedPermission() and self:isHasPermission() then
            return true
        end
        return false
    end

    -- 尝试进入游戏
    local function checkLoad()
        if checkPermission() then
            loadGame()
            return
        end

        self._launchScheduleID = Schedule(function()
            if checkPermission() then
                loadGame()

                -- 停止定时器
                if self._launchScheduleID then
                    UnSchedule(self._launchScheduleID)
                    self._launchScheduleID = nil 
                end
            else
                local jData    = {}
                jData.needUDID = 1
                global.L_NativeBridgeManager:GN_appLaunchNotify(jData)
            end
        end, 1/60)
    end

    checkLoad()

    if global.L_GameEnvManager:GetEnvDataByKey("pc_close_secoend_tips") == 1 then
        global.L_NativeBridgeManager:GN_IsCan_Windown_Close_State({state=0})
    end
end

return GameEnvManager
