local ModuleManager = class("ModuleManager")
local AssetsManager = requireLauncher( "res_check/assets_manager" )
local Module        = requireLauncher("logic/Module")
local cjson         = require("cjson")


local Tags = "ModulePuller"
local NotAlphaFileName = "not_alpha"


function ModuleManager:ctor()
    self._currentModule  = nil
    self._launcherModule = Module.new( "mod_launcher", "launcher", global.VersionName.default )
    self:CheckModuleVersion(self._launcherModule, true)

    self._downloader = nil
    self._isVersionChanged = false

    self._referModuleID = nil
    self._modules = {}
    self._updateCount = 0
    self._imagePath = {}
end

function ModuleManager:SetReferModuleID( id )
    self._referModuleID = id
end

function ModuleManager:GetReferModuleID()
    return self._referModuleID
end

function ModuleManager:InitModules( configs )
    for idx, cfg in ipairs( configs ) do
        self._modules[idx] = Module.new( cfg.id, cfg.name, global.VersionName.default, cfg.version_suffix, cfg, cfg.subMod, cfg.severlistSign, cfg.refer )
    end
end

function ModuleManager:GetAllModules()
    return self._modules
end

function ModuleManager:GetModuleByID(id)
    for _, module in pairs(self._modules) do
        if module:GetID() == id then
            return module
        end
    end
    return nil
end

function ModuleManager:InitImagePre( configs )
    self._imagePath = configs
end

function ModuleManager:GetImagePre()
    return self._imagePath
end

function ModuleManager:RunCurrentModule()
    global.L_LoadingBarManager:CloseLayer()
    global.L_LoadingManager:CloseLayer()
    global.L_SystemTipsManager:CloseLayer()
    global.L_ModuleChooseManager:CloseLayer()
    global.L_GameLayerManager:Close()

    local main = "main.lua"

    -- clean up last require cache path
    if package.loaded[main] then
        package.loaded[main] = nil
    end
    cc.FileUtils:getInstance():purgeCachedEntries()

    require( main )
end

function ModuleManager:RegisterModuleByID( id )
    local registerModule = self:GetModuleByID(id)
    if not registerModule then
        releasePrint( "module config not existing", id )
        return false
    end

    self:RegisterModule( registerModule )

    return true
end


function ModuleManager:RegisterModule( module )
    if not module or self._currentModule == module then
        return false
    end
    
    -- check subMod
    if not module:GetCurrentSubMod() then
        return false
    end

    -- set to current module
    self._currentModule = module

    -- check module version state
    self:CheckModuleVersion( module )

    --
    self:addSubModSearchOrder(module)

    -- dev search path
    self:addDevSearchPath()

    local moduleID = module:GetID()
    local version  = module:GetVersion()
    local suffix   = module:GetSuffix()
    releasePrint( string.format("register module:[%s,%s,%s]", moduleID, version, module:GetSubModPath()) )

    local searchPaths = global.FileUtilCtl:getSearchPaths()
    dump(searchPaths, "_______________SearchPaths")

    UserData:setVersionPath( module:GetSubModPath() )

    return true
end

local function checkAndAddPath(srcPaths, addPath)
    for k, v in pairs(srcPaths) do
        if v == addPath then
            table.remove(srcPaths, k)
            break
        end
    end
    table.insert(srcPaths, 1, addPath)

    return srcPaths
end
-- 添加主体 搜索路径
function ModuleManager:addMainBodySearchPath(MainBody)
    if not MainBody then
        return false
    end

    local modulePath  = global.FileUtilCtl:getDefaultResourceRootPath() .. "mod_launcher/stab/"..MainBody
    local cachePath   = global.FileUtilCtl:getWritablePath() .. "mod_launcher/stab/"..MainBody
    
    releasePrint( "add MainBody search path:", modulePath )
    releasePrint( "add MainBody search path:", cachePath )

    local searchPaths = global.FileUtilCtl:getSearchPaths()
    checkAndAddPath(searchPaths, modulePath)
    checkAndAddPath(searchPaths, cachePath)
    global.FileUtilCtl:setSearchPaths(searchPaths)

    return true
end

-- 添加模块 搜索路径
function ModuleManager:addModuleSearchPath( module )
    if not module then
        return false
    end

    -- mod_fgcq/submod cache
    -- mod_fgcq/submod root
    -- [mod_fgcq/alpha cache]
    -- [mod_fgcq/alpha root]
    -- mod_fgcq/stab cache
    -- mod_fgcq/stab root
    -- [mod_launcher/alpha cache]
    -- [mod_launcher/alpha root]
    -- mod_launcher/stab cache
    -- mod_launcher/stab root

    local modulePath  = global.FileUtilCtl:getDefaultResourceRootPath() .. getNewFoldername(tostring(module:GetID())) .. "/"
    local cachePath   = global.FileUtilCtl:getWritablePath() .. getNewFoldername(tostring(module:GetID())) .. "/"
    
    releasePrint( "add search path:", modulePath )
    releasePrint( "add search path:", cachePath )

    local searchPaths = global.FileUtilCtl:getSearchPaths()
    checkAndAddPath(searchPaths, modulePath)
    checkAndAddPath(searchPaths, cachePath)
    global.FileUtilCtl:setSearchPaths(searchPaths)

    return true
end

-- 添加开发 搜索路径
function ModuleManager:addDevSearchPath()
    if not global.isWindows then
        return false
    end
    if not global.isDebugMode and not global.isGMMode then
        return false
    end

    local devPath = global.FileUtilCtl:getDefaultResourceRootPath() .. "dev"
    local searchPaths = global.FileUtilCtl:getSearchPaths()
    checkAndAddPath(searchPaths, devPath)
    global.FileUtilCtl:setSearchPaths(searchPaths)

    if not global.FileUtilCtl:isDirectoryExist(devPath) then
        global.FileUtilCtl:createDirectory(devPath)
    end

    return true
end

-- 添加模块 子版本 搜索策略
function ModuleManager:addModuleSearchOrder( module )
    if not module then
        return false
    end

    local moduleWritePath = global.FileUtilCtl:getWritablePath() .. module:GetPath()
    if not global.FileUtilCtl:isDirectoryExist( moduleWritePath ) then
        releasePrint( "create dir:", moduleWritePath )
        global.FileUtilCtl:createDirectory( moduleWritePath )
    end


    local versionOrder = module:GetVersion()
    if versionOrder and string.len( versionOrder ) > 0 then
        local baseVersionOrder = getNewFoldername(tostring(versionOrder))
        local newVersionOrder = module:GetSuffix() and string.format( "%s/%s/", baseVersionOrder, tostring(module:GetSuffix()) ) or baseVersionOrder .. "/"

        local modulePath  = global.FileUtilCtl:getDefaultResourceRootPath() .. getNewFoldername(tostring(module:GetID())) .. "/" .. newVersionOrder
        local cachePath   = global.FileUtilCtl:getWritablePath() .. getNewFoldername(tostring(module:GetID())) .. "/" .. newVersionOrder
    
        releasePrint( "add search path:", modulePath )
        releasePrint( "add search path:", cachePath )
    
        local searchPaths = global.FileUtilCtl:getSearchPaths()
        checkAndAddPath(searchPaths, modulePath)
        checkAndAddPath(searchPaths, cachePath)
        global.FileUtilCtl:setSearchPaths(searchPaths)
    end

    return true
end

-- 添加子模块 自定义文件夹搜索策略
function ModuleManager:addSubModSearchOrder(module)
    if not module then
        return false
    end
    local subMod = module:GetCurrentSubMod()
    if not subMod then
        return false
    end

    -- check & create directory
    local writePath = global.FileUtilCtl:getWritablePath() .. module:GetSubModPath()
    if not global.FileUtilCtl:isDirectoryExist( writePath ) then
        releasePrint( "create dir:", writePath )
        global.FileUtilCtl:createDirectory( writePath )
    end

    -- 
    local subModPath  = getNewFoldername(subMod:GetID()) .. "/"
    local modulePath  = global.FileUtilCtl:getDefaultResourceRootPath() .. getNewFoldername(tostring(module:GetID())) .. "/" .. subModPath
    local cachePath   = global.FileUtilCtl:getWritablePath() .. getNewFoldername(tostring(module:GetID())) .. "/" .. subModPath

    releasePrint( "add search path:", modulePath )
    releasePrint( "add search path:", cachePath )

    local searchPaths = global.FileUtilCtl:getSearchPaths()
    checkAndAddPath(searchPaths, modulePath)
    checkAndAddPath(searchPaths, cachePath)
    global.FileUtilCtl:setSearchPaths(searchPaths)

    -- gm res key
    if subMod:GetXK() and subMod:GetXK() ~= nil and LuaBridgeCtl:Inst().SetXXTEAKeyGM then
        LuaBridgeCtl:Inst():SetXXTEAKeyGM(subMod:GetXK())
    end
end

-- 存储模块子版本状态
function ModuleManager:storeModuleVersionState( module, stateName )
    stateName = stateName or module:GetVersion()
    local stateFilePath = string.format( "%s%s/state_%s", global.FileUtilCtl:getWritablePath(), getNewFoldername(module:GetID()), stateName )
    releasePrint( "store module state:", stateName, stateFilePath )
    
    global.FileUtilCtl:writeStringToFile( stateName, stateFilePath )
end

-- 清理模块子版本状态
function ModuleManager:cleanModuleVersionState( module, stateName )
    stateName = stateName or module:GetVersion()
    local stateFilePath = string.format( "%s%s/state_%s", global.FileUtilCtl:getWritablePath(), getNewFoldername(module:GetID()), stateName )

    if global.FileUtilCtl:isFileExist( stateFilePath ) then
        global.FileUtilCtl:removeFile( stateFilePath )
    end
end

-- 模块子版本状态是否存在
function ModuleManager:isModuleVersionStateExist( module, stateName )
    stateName = stateName or module:GetVersion()
    local stateFilePath = string.format( "%s%s/state_%s", global.FileUtilCtl:getWritablePath(), getNewFoldername(module:GetID()), stateName )

    return global.FileUtilCtl:isFileExist( stateFilePath )
end

-- 检测各个版本状态，并切换
function ModuleManager:CheckModuleVersion( module, isLauncher )
    -- search path
    self:addModuleSearchPath( module )

    -- search order
    ---------------------- stab ----------------------
    self:SetModule2StabVersion( module, true )
    ---------------------- stab ----------------------


    ---------------------- alpha ----------------------
    local imgPath = "%s/%s/res/private/login/open_door/00.png"
    if isLauncher then
        imgPath = "%s/%s/res_launcher/private/login/open_door/00.png"
    end
    local alphaPath = string.format( imgPath, getNewFoldername(module:GetID()), getNewFoldername(global.VersionName.alpha) )
    local alphaExist = global.FileUtilCtl:isFileExist( alphaPath )
    releasePrint( "alpha exist?:", alphaPath, module:GetID(), alphaExist )
    if alphaExist then
        local launcherMod = self:GetLauncherModule()
        if launcherMod and not self:isModuleVersionStateExist( launcherMod, NotAlphaFileName ) then
            self:SetModule2AlphaVersion( module )

            -- reset to stab, only for search alpha. write to stab
            module:SetVersion( global.VersionName.stab )
        end
    end
    ---------------------- alpha ----------------------


    ---------------------- beta ----------------------
    if self:isModuleVersionStateExist( module, global.VersionName.beta ) then
        self:SetModule2BetaVersion( module )
    end
    ---------------------- beta ----------------------
end

-- 切到stab. 清理beta
function ModuleManager:SetModule2StabVersion( module, cleanup )
    if not module then
        return
    end

    local version = global.VersionName.stab
    module:SetVersion( version )
    self:addModuleSearchOrder( module )

    -- clean beta state
    if cleanup then
        self:cleanModuleVersionState( module, global.VersionName.beta )
    end
    g_isBeta = false
end

-- 切到beta.
function ModuleManager:SetModule2BetaVersion( module )
    if not module then
        return
    end

    local version = global.VersionName.beta
    module:SetVersion( version )
    self:addModuleSearchOrder( module )

    -- store beta state
    self:storeModuleVersionState( module )
    g_isBeta = true
end

-- 切到alpha
function ModuleManager:SetModule2AlphaVersion( module )
    if not module then
        return
    end

    local version = global.VersionName.alpha
    module:SetVersion( version )
    self:addModuleSearchOrder( module )

    releasePrint( "alpha flag:in alpha" )
    g_isAlpha = true
end

function ModuleManager:IsCurrentModuleAlphaStateExist()
    local module = self._currentModule or self._launcherModule
    if not module then
        return false
    end

    return self:isModuleVersionStateExist( module, NotAlphaFileName )
end

function ModuleManager:CleanCurrentModuleAlphaState()
    local module = self._currentModule or self._launcherModule
    if not module then
        return
    end

    return self:cleanModuleVersionState( module, NotAlphaFileName )
end

function ModuleManager:StoreCurrentModuleAlphaState()
    local module = self._currentModule or self._launcherModule
    if not module then
        return
    end

    self:storeModuleVersionState( module, NotAlphaFileName )
end


function ModuleManager:GetCurrentModule()
    return self._currentModule
end

function ModuleManager:GetCurrentModuleID()
    if not self._currentModule then
        return ""
    end

    return self._currentModule:GetID()
end

function ModuleManager:GetCurrentModuleVersion()
    if not self._currentModule then
        return global.VersionName.default
    end

    return self._currentModule:GetVersion()
end

function ModuleManager:GetCurrentModulePath()
    if not self._currentModule then
        return ""
    end

    return self._currentModule:GetPath()
end


function ModuleManager:GetLauncherModule()
    return self._launcherModule
end

function ModuleManager:GetLauncherModuleID()
    if not self._launcherModule then
        return ""
    end

    return self._launcherModule:GetID()
end

function ModuleManager:GetLauncherModuleVersion()
    if not self._launcherModule then
        return global.VersionName.default
    end

    return self._launcherModule:GetVersion()
end

function ModuleManager:GetLauncherModulePath()
    if not self._launcherModule then
        return ""
    end

    return self._launcherModule:GetPath()
end

function ModuleManager:GetAllGameID()
    local items = {}
    for _, module in pairs(self._modules) do
        local subMods = module:GetSubMods()
        for _, subMod in ipairs(subMods) do
            table.insert(items, subMod:GetOperID())
        end
    end
    return items
end

---------------------------------- hot update ------------------------------------
function ModuleManager:ReportError(str, callback)
    local tipsData = {
        btnType = 1,
        str = str,
        callback = callback
    }
    global.L_CommonTipsManager:OpenLayer( tipsData )
end
function ModuleManager:CleanupDownloader()
    if self._downloader then
        self._downloader:Cleanup()
        self._downloader = nil
    end
end

function ModuleManager:handleUpdateFinished()
    -- don't need restart
    self:handleAlreadyUpToDate()
end

function ModuleManager:handleAlreadyUpToDate()
    -- record remote manifest ver
    if self._downloader and self:GetCurrentModule() then
        local version = self._downloader:GetRemoteManifestVer()
        self:GetCurrentModule():SetRemoteVersion( version )
    end

    self:CleanupDownloader()

    global.L_HotUpdateGMAssets:CheckUpdate()
end

function ModuleManager:CheckModuleLocalStorage()
    if global.L_GameEnvManager:IsReview() then
        self:handleAlreadyUpToDate()
        return false
    end
    
    if self._downloader then
        releasePrint( "pulling module!!" )
        return false
    end

    local module = self:GetCurrentModule()
    if not module then
        releasePrint( "can not find current module!!" )
        return false
    end


    -- check version, stab or beta?
    self._isVersionChanged = self:checkVersion()


    -- check local storage is existing
    local moduleGameEnv     = module:GetGameEnv()
    local modulePath        = module:GetPath()
    local moduleID          = module:GetID()
    local localManifestName = module:GetManifestFileName()
    local isExist           = global.FileUtilCtl:isFileExist( localManifestName )

    -- check resurl, it will be break on mobile.
    if (not moduleGameEnv:GetResDownloadUrl() or string.len(moduleGameEnv:GetResDownloadUrl()) == 0) 
        and (not moduleGameEnv:GetResDownloadUrl2() or string.len(moduleGameEnv:GetResDownloadUrl2()) == 0) then
        self:ReportError("远程资源路径未发现！", function()
            global.L_NativeBridgeManager:GN_accountLogout()
            global.L_GameEnvManager:RestartGame()
        end)
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


    local localVersionName  = module:GetVersionFileName()
    local localManifestName = module:GetManifestFileName()
    local serverChannel     = moduleGameEnv:GetSelectedServerUrlSuffix()
    local storagePath       = cc.FileUtils:getInstance():getWritablePath() .. modulePath
    local tempManifestName  = "project.manifest.temp"
    local tempDirName       = "/_temp"
    local rootDomain        = self._updateCount == 0 and moduleGameEnv:GetResDownloadUrl() or moduleGameEnv:GetResDownloadUrl2()
    local resUrl            = string.format("%s%s", rootDomain, tostring(module:GetRemotePath(serverChannel)))
    local manifestUrl       = resUrl .. localManifestName
    local versionUrl        = resUrl .. localVersionName
    local resVersion        = moduleGameEnv:GetResVersion()
    local jobs              = 2
    local ignoreLocal       = not isExist


    -- verbose
    releasePrint( "-------------------------------------------------------------" )
    releasePrint( "pull module:", moduleID )
    releasePrint( manifestUrl )
    releasePrint( versionUrl )
    releasePrint( resVersion )
    releasePrint( "ignore local:" .. tostring(ignoreLocal) )
    releasePrint( "local storage path:" .. tostring(storagePath) )
    releasePrint( "-------------------------------------------------------------" )


    -- request download
    local ret = downloader:DownLoadRequest( "module_pull", localManifestName, storagePath, tempManifestName, tempDirName,
                                            resUrl, manifestUrl, versionUrl, resVersion, jobs, ignoreLocal )

    if not ret then
        downloader:Cleanup()
        return false
    end

    self._downloader = downloader
    local url2 = moduleGameEnv:GetResDownloadUrl2()
    if self._updateCount == 0 and url2 and string.len(url2) > 0 then 
        self._moduleUpdateSchedule = PerformWithDelayGlobal(function ()
            self._moduleUpdateSchedule = nil
            self._updateCount = self._updateCount + 1
            self:CleanupDownloader()
            self:CheckModuleLocalStorage()
        end
        , 10)
    else
        self._moduleUpdateSchedule = PerformWithDelayGlobal(function ()
            self._moduleUpdateSchedule = nil
            -- 触发重新下载
            local module = self:GetCurrentModule()
            local moduleID = self:GetCurrentModuleID()
            local tips = "?"
            local logs = "?"
            if module then
                tips = string.format("%s(%s)", module:GetVersion(), module:GetGameEnv():GetSelectedServerUrlSuffix())
                logs = module:GetID() .. ":" .. module:GetGameEnv():GetResDownloadUrl()
            end

            local errorString = string.format("[%s][%s]远程清单访问超时!\n点击下方\"确认\"重试", tostring(moduleID), tostring(tips))

            RecordBuglyLogIm( Tags, logs )
            ReportBuglyError( Tags, errorString )

            local function callback()
                self._updateCount = 0
                self:CleanupDownloader()
                self:CheckModuleLocalStorage()
            end
            self:ReportError(errorString, callback)
        end
        , 10) 
    end
    return true
end

function ModuleManager:onLocalManifestError()
    self:CleanupDownloaderSchedule()
    self:CleanupDownloader()

    local module = self:GetCurrentModule()
    local moduleGameEnv     = module:GetGameEnv()
    local url2 = moduleGameEnv:GetResDownloadUrl2()

    if self._updateCount == 0 and url2 and string.len(url2) > 0 then 
        self._updateCount = self._updateCount + 1
        self:CheckModuleLocalStorage()
    else
        local module = self:GetCurrentModule()
        local moduleID = self:GetCurrentModuleID()
        local tips = "?"
        local logs = "?"
        if module then
            tips = module:GetID()
            logs = module:GetID() .. ":" .. module:GetGameEnv():GetResDownloadUrl()
        end

        local errorString = string.format("[%s][%s]本地清单异常!\n点击下方\"确认\"重试", tostring(moduleID), tostring(tips))

        RecordBuglyLogIm( Tags, logs )
        ReportBuglyError( Tags, errorString )

        local function callback()
            self._updateCount = 0
            self:CheckModuleLocalStorage()
        end
        self:ReportError(errorString, callback)
    end
end

function ModuleManager:onRemoteManifestError()
    self:CleanupDownloaderSchedule()
    self:CleanupDownloader()

    local module = self:GetCurrentModule()
    local moduleGameEnv     = module:GetGameEnv()
    local url2 = moduleGameEnv:GetResDownloadUrl2()
    if self._updateCount == 0 and url2 and string.len(url2) > 0 then 
        self._updateCount = self._updateCount + 1
        self:CheckModuleLocalStorage()
    else
        -- 触发重新下载
        local module = self:GetCurrentModule()
        local moduleID = self:GetCurrentModuleID()
        local tips = "?"
        local logs = "?"
        if module then
            tips = string.format("%s(%s)", module:GetVersion(), module:GetGameEnv():GetSelectedServerUrlSuffix())
            logs = module:GetID() .. ":" .. module:GetGameEnv():GetResDownloadUrl()
        end

        local errorString = string.format("[%s][%s]远程清单异常!\n点击下方\"确认\"重试", tostring(moduleID), tostring(tips))

        RecordBuglyLogIm( Tags, logs )
        ReportBuglyError( Tags, errorString )

        local function callback()
            self._updateCount = 0
            self:CheckModuleLocalStorage()
        end
        self:ReportError(errorString, callback)
    end
end

function ModuleManager:onCheckVersionInfo()
    self:CleanupDownloaderSchedule()

    global.L_LoadingManager:OpenLayer({isCheckVersion=true, delay=true})
end

function ModuleManager:onNewVersion( versionSize )
    RecordBuglyLogIm( Tags, "New Version Found:" .. tostring( versionSize / (1024 * 1024) ) )
    self:CleanupDownloaderSchedule()

    global.L_LoadingManager:CloseLayer()
    global.L_LoadingManager:OpenLayer({isCheckVersion=true})

    -- start update
    local function startUpdate()
        global.L_LoadingManager:CloseLayer()
        global.L_LoadingManager:OpenLayer({isDetails=true})
        global.L_LoadingPlayManager:OpenLayer()

        local scheduler = cc.Director:getInstance():getScheduler()
        local handle = nil
        handle = scheduler:scheduleScriptFunc(
            function()
                scheduler:unscheduleScriptEntry(handle)

                if self._downloader then
                    self._downloader:StartUpdate()
                end
            end,
            1/60,
            false
        )

        -- 资源开始加载  进入登录页  上报自定义事件
        local moduleGameEnv = global.L_ModuleManager:GetCurrentModule():GetGameEnv()
        local selSerInfo    = moduleGameEnv:GetSelectedServer()
        local server_id     = selSerInfo and selSerInfo.serverId
        local server_name   = selSerInfo and selSerInfo.serverName

        local dataParam = {
            event = {
                time = os.time(), name = "startLoading", type = "track"
            },
            properities = {
                servid = tostring(server_id), server_name = tostring(server_name)
            }
        }

        local main_servid  = selSerInfo and selSerInfo.mainServerId
        local main_server_name = selSerInfo and selSerInfo.mainServerName

        dataParam.properities.main_servid = main_servid and tostring(main_servid) or tostring(server_id)
        dataParam.properities.main_server_name = main_server_name and tostring(main_server_name) or tostring(server_name)

        local userId = global.L_GameEnvManager:GetEnvDataByKey("user_id") or global.L_GameEnvManager:GetEnvDataByKey("uid")
        if userId and userId ~= "" then
            dataParam.user = {id = userId}
        end

        global.L_DataRePort:SendRePortData( dataParam )
    end

    -- 根据配置决定更新确认提醒
    local currentModule = self:GetCurrentModule()
    if not currentModule then
        startUpdate()
        return
    end
    local modGameEnv = currentModule:GetGameEnv()
    if not modGameEnv then
        startUpdate()
        return
    end

    -- 根据网络类型决定是否需要手动确认更新
    local netType   = global.L_GameEnvManager:GetNetType()
    local limitSize = 0
    if netType == 0 then
        limitSize = tonumber(modGameEnv:GetCustomDataByKey("hotSizeWifi")) or 20
    else
        limitSize = tonumber(modGameEnv:GetCustomDataByKey("hotSize4G")) or 10
    end
    if (versionSize > limitSize*1024*1024) then
        local tipsData = {
            btnType  = 1,
            str      = string.format("检测到版本，大小%.2fM，建议在WIFI环境下\n更新，点击确认开始下载", versionSize / (1024 * 1024)),
            callback = startUpdate
        }
        global.L_CommonTipsManager:OpenLayer(tipsData)
    else
        startUpdate()
    end
end

function ModuleManager:onAlreadyUpToDate()
    self:CleanupDownloaderSchedule()
    RecordBuglyLogIm( Tags, "Already Up To Date")

    self:handleAlreadyUpToDate()
end

function ModuleManager:onUpdatePercent( percent )
    releasePrint(Tags, "onUpdatePercentFile", percent)
    self:CleanupDownloaderSchedule()
    -- global.L_LoadingManager:UpdatePercent(percent)
end

function ModuleManager:onUpdatePercentSize(percentSize, totalSize)
    releasePrint(Tags, "onUpdatePercentSize", percentSize)
    self:CleanupDownloaderSchedule()
    global.L_LoadingManager:UpdatePercent(percentSize, totalSize)
end

function ModuleManager:onAssetError( assetID, msg )
    self:CleanupDownloaderSchedule()
    RecordBuglyLogIm( Tags, "Asset Error! " .. tostring( assetID ) )
end

function ModuleManager:onDownloadFinished()
    RecordBuglyLogIm( Tags, "Update Finished" )
    self:CleanupDownloaderSchedule()

    self:handleUpdateFinished()

    -- 资源加载完成  进入登录页  上报自定义事件
    local moduleGameEnv = global.L_ModuleManager:GetCurrentModule():GetGameEnv()
    local selSerInfo    = moduleGameEnv:GetSelectedServer()
    local server_id     = selSerInfo and selSerInfo.serverId
    local server_name   = selSerInfo and selSerInfo.serverName

    local dataParam = {
        event = {
            time = os.time(), name = "finishLoading", type = "track"
        },
        properities = {
            servid = tostring(server_id), server_name = tostring(server_name)
        }
    }

    local main_servid  = selSerInfo and selSerInfo.mainServerId
    local main_server_name = selSerInfo and selSerInfo.mainServerName
    
    dataParam.properities.main_servid = main_servid and tostring(main_servid) or tostring(server_id)
    dataParam.properities.main_server_name = main_server_name and tostring(main_server_name) or tostring(server_name)

    local userId = global.L_GameEnvManager:GetEnvDataByKey("user_id") or global.L_GameEnvManager:GetEnvDataByKey("uid")
    if userId and userId ~= "" then
        dataParam.user = {id = userId}
    end

    global.L_DataRePort:SendRePortData( dataParam )
end

function ModuleManager:onDownloadFailed()
    RecordBuglyLogIm( Tags, "Update Failed!" )
    self:CleanupDownloaderSchedule()

    if self._downloader then
        self._downloader:Retry()
    end
end


-- check beta or stab
function ModuleManager:checkVersion()
    local currentModule = self:GetCurrentModule()
    if not currentModule then
        return false
    end

    local selectServer  = currentModule:GetGameEnv():GetSelectedServer()
    local verStr        = currentModule:GetVersion()
    if verStr ~= selectServer.stab then
        if selectServer.stab == global.VersionName.beta then
            global.L_ModuleManager:SetModule2BetaVersion( currentModule )
        else  
            global.L_ModuleManager:SetModule2StabVersion( currentModule, true )
        end
 
        return true
    else
        return false
    end

    return false
end


function ModuleManager:onChangeVersion()
    local function callback( aType, custom )
        global.L_NativeBridgeManager:GN_accountLogout()
        global.L_GameEnvManager:RestartGame()
    end

    local tipsData = {
        btnType = 1,
        str = "当前客户端版本不一致，进入该服需要重启客户端<br>是否重启并进入该服？",
        callback = callback
    }
    global.L_CommonTipsManager:OpenLayer( tipsData )
end

function ModuleManager:CleanupDownloaderSchedule()
    if self._moduleUpdateSchedule then 
        global.Scheduler:unscheduleScriptEntry(self._moduleUpdateSchedule)
        self._moduleUpdateSchedule = nil
    end
end
---------------------------------- hot update ------------------------------------

return ModuleManager
