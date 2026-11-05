local HotUpdateGMAssets = class('HotUpdateGMAssets')
HotUpdateGMAssets.NAME = "HotUpdateGMAssets"
local AssetsManager = requireLauncher( "res_check/assets_manager" )

local Tags = "HotUpdateGMAssets"

function HotUpdateGMAssets:ctor()
    self._downloader = nil
    self._updateCount = 0
end

function HotUpdateGMAssets:CleanupDownloader()
    if self._downloader then
        self._downloader:Cleanup()
        self._downloader = nil
    end
end

function HotUpdateGMAssets:handleAlreadyUpToDate()
    if self._downloader and global.L_ModuleManager:GetCurrentModule() and global.L_ModuleManager:GetCurrentModule():GetCurrentSubMod() then
        local currentSubMod = global.L_ModuleManager:GetCurrentModule():GetCurrentSubMod()
        local version = self._downloader:GetRemoteManifestVer()
        currentSubMod:SetRemoteVersion( version )
    end
    
    global.L_LoadingManager:CloseLayer()
    
    global.L_LoadingPlayManager:CloseLayer()

    self:CleanupDownloader()

    global.L_ModuleManager:RunCurrentModule()
end

function HotUpdateGMAssets:CheckUpdate()
    if global.L_GameEnvManager:IsReview() then
        self:handleAlreadyUpToDate()
        return
    end

    if not global.L_ModuleManager and not global.L_ModuleManager:GetCurrentModule() then
        releasePrint("can not find current module!!")
        return
    end

    -- GM Init Res URL
    local module            = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv     = module:GetGameEnv()
    if (not moduleGameEnv:GetGMResURL() or string.len(moduleGameEnv:GetGMResURL()) == 0) 
    and (not moduleGameEnv:GetGMResURL2() or string.len(moduleGameEnv:GetGMResURL2()) == 0) then
        releasePrint("can not find GMResURL !!")
        self:handleAlreadyUpToDate()
        return
    end
    if not moduleGameEnv:GetGMResVer() or string.len(moduleGameEnv:GetGMResVer()) == 0 then
        releasePrint("can not find GMResVer !!")
        self:handleAlreadyUpToDate()
        return
    end

    -- new downloader
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
    downloader:SetEventDelegate(self)
    downloader:SetVersionCompareHandle(versionCompare)

    local fileUtil          = cc.FileUtils:getInstance()
    local writablePath      = fileUtil:getWritablePath()
    local module            = global.L_ModuleManager:GetCurrentModule()
    local modulePath        = module:GetSubModPath()
    local moduleGameEnv     = module:GetGameEnv()
    local storagePath       = writablePath .. modulePath

    local localManifestName = "gm_assets_project.manifest"
    local localVersionName  = "gm_assets_version.manifest"

    local tempManifestName  = "gm_assets_project.manifest.temp"
    local tempDirName       = "/_gm_assets_temp"
    local resUrl            = string.format("%s",self._updateCount == 0 and moduleGameEnv:GetGMResURL() or moduleGameEnv:GetGMResURL2())
    local gmurlsuffix       = moduleGameEnv:GetSelectedServerGmurlsuffix()
    if gmurlsuffix and gmurlsuffix ~= "" then
        resUrl = resUrl  .. gmurlsuffix .. "/"
    end
    local resVersionOri     = moduleGameEnv:GetGMInitResVer()
    local manifestUrl       = resUrl .. localManifestName
    local versionUrl        = resUrl .. localVersionName
    local jobs              = 1
    local ignoreLocal       = true

    local subMod        = module:GetCurrentSubMod()
    local subModInfo    = subMod:GetSubModInfo()
    local gameid        = subMod:GetOperID()
    local xk            = subMod:GetXK()
    local channelID     = global.L_GameEnvManager:GetChannelID() or 1

    local sign  = GetCdnSign(gameid, global.modListSrvTime, xk or "")
    local param = string.format("gameId=%s&time=%s&sign=%s&channelID=%s", gameid, global.modListSrvTime, sign, channelID)
    local resVersion  = string.format("%s&%s", resVersionOri, param)

    -- verbose
    releasePrint( "-------------------------------------------------------------" )
    releasePrint( "pull gm_assets:" )
    releasePrint( manifestUrl )
    releasePrint( versionUrl )
    releasePrint( resVersion )
    releasePrint( "ignore local:" .. tostring(ignoreLocal) )
    releasePrint( "local storage path:" .. tostring(storagePath) )
    releasePrint( "-------------------------------------------------------------" )

    -- request download
    local ret = downloader:DownLoadRequest( "gm_assets", localManifestName, storagePath, tempManifestName, tempDirName,
                                            resUrl, manifestUrl, versionUrl, resVersion, jobs, ignoreLocal)

    if not ret then
        downloader:Cleanup()
        releasePrint("GMRES Hotupdate ERR DownLoadRequest failed!!")
        self:handleAlreadyUpToDate()
        return
    end

    self._downloader = downloader

    local url2 = moduleGameEnv:GetGMResURL2()
    if self._updateCount == 0 and url2 and string.len(url2) > 0 then 
        self._gmResUpdateSchedule = PerformWithDelayGlobal(function ()
            self._gmResUpdateSchedule = nil
            self._updateCount = self._updateCount + 1
            self:CleanupDownloader()
            self:CheckUpdate()
        end, 10)
    else
        self._gmResUpdateSchedule = PerformWithDelayGlobal(function ()
            self._gmResUpdateSchedule = nil
            self:handleAlreadyUpToDate()
        end, 10)
    end
end

function HotUpdateGMAssets:onLocalManifestError()
    self:CleanupDownloaderSchedule()
    releasePrint(Tags, "Local Manifest Error!")

    local module            = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv     = module:GetGameEnv()
    local url2 = moduleGameEnv:GetGMResURL2()
    if self._updateCount == 0 and url2 and string.len(url2) > 0 then
        self:CleanupDownloader()
        self._updateCount = self._updateCount + 1
        self:CheckUpdate()
    else
        -- skip
        self:handleAlreadyUpToDate()
    end
end

function HotUpdateGMAssets:onRemoteManifestError()
    self:CleanupDownloaderSchedule()
    releasePrint(Tags, "Remote Manifest Error!")

    local module            = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv     = module:GetGameEnv()
    local url2 = moduleGameEnv:GetGMResURL2()
    if self._updateCount == 0 and url2 and string.len(url2) > 0 then
        self:CleanupDownloader()
        self._updateCount = self._updateCount + 1
        self:CheckUpdate()
    else
        -- skip
        self:handleAlreadyUpToDate()
    end
end

function HotUpdateGMAssets:onCheckVersionInfo()
    self:CleanupDownloaderSchedule()
    releasePrint(Tags, "onCheckVersionInfo")
end

function HotUpdateGMAssets:onNewVersion(versionSize)
    self:CleanupDownloaderSchedule()
    self:CleanupTipsSchedule()

    local sizeInMB = versionSize / (1024 * 1024)
    releasePrint(Tags, "New Version Found:" .. tostring(sizeInMB))

    global.L_LoadingManager:CloseLayer()
    global.L_LoadingManager:OpenLayer({loadingType=2, isDetails=true})

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

    local moduleGameEnv = global.L_ModuleManager:GetCurrentModule():GetGameEnv()
    local selSerInfo    = moduleGameEnv:GetSelectedServer()
    local server_id     = selSerInfo and selSerInfo.serverId
    local server_name   = selSerInfo and selSerInfo.serverName

    local dataParam = {
        event = {
            time = os.time(), name = "startLoading2", type = "track"
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

    self._waitTime = 5
    local currentModule = global.L_ModuleManager:GetCurrentModule()
    if currentModule then
        local modGameEnv = currentModule:GetGameEnv()
        if modGameEnv then 
            local time = modGameEnv:GetCustomDataByKey("updateWaitTime") 
            time = time and tonumber(time) 
            if time and time > 0 then
                self._waitTime = time
            end
        end
    end
    self._checkTipsScheduleID = scheduler:scheduleScriptFunc(
        function()
            self:CleanupTipsSchedule()
            
            self:ShowCloudTipsView()
        end,
        self._waitTime,
        false
    )
end

function HotUpdateGMAssets:CleanupTipsSchedule()
    if self._checkTipsScheduleID then
        local scheduler = cc.Director:getInstance():getScheduler()
        scheduler:unscheduleScriptEntry(self._checkTipsScheduleID)
        self._checkTipsScheduleID = nil
    end
end

function HotUpdateGMAssets:ShowCloudTipsView()
    local updateWaitTips = "点击这里，一键体验烈火云手机！"
    local followFloatDismiss = false
    local currentModule = global.L_ModuleManager:GetCurrentModule()
    if currentModule then
        local modGameEnv = currentModule:GetGameEnv()
        if modGameEnv then 
            local str = modGameEnv:GetCustomDataByKey("updateWaitTips") 
            if str and string.len(str) > 0 then
                updateWaitTips = str
            end
            local isFollowFloatDismiss = modGameEnv:GetCustomDataByKey("isFollowFloatDismiss") 
            followFloatDismiss = isFollowFloatDismiss == 1 or isFollowFloatDismiss == "1"
        end
    end

    local data = {
        tipsStr = updateWaitTips,
        isFollowFloatDismiss = followFloatDismiss
    }
    global.L_NativeBridgeManager:GN_showTipsView(data)
end

function HotUpdateGMAssets:onAlreadyUpToDate()
    releasePrint(Tags, "Already Up To Date")
    self:CleanupDownloaderSchedule()

    self:handleAlreadyUpToDate()
end

function HotUpdateGMAssets:onUpdatePercent(percentFile)
    self:CleanupDownloaderSchedule()
    releasePrint(Tags, "onUpdatePercent", percentFile)
    
    -- global.L_LoadingManager:UpdatePercent(percentFile)
end

function HotUpdateGMAssets:onUpdatePercentSize(percentSize, totalSize)
    self:CleanupDownloaderSchedule()
    releasePrint(Tags, "onUpdatePercentSize", percentSize)

    global.L_LoadingManager:UpdatePercent(percentSize, totalSize)
end

function HotUpdateGMAssets:onAssetError(assetID, msg)
    self:CleanupDownloaderSchedule()
    self:CleanupTipsSchedule()
    releasePrint(Tags, "Asset Error! " .. tostring(assetID))
    global.L_SystemTipsManager:ShowTips("ASSET ERROR " .. tostring(assetID))
end

function HotUpdateGMAssets:onDownloadFinished()
    releasePrint(Tags, "DownloadFinished!")
    self:CleanupDownloaderSchedule()
    self:CleanupTipsSchedule()
    
    local moduleGameEnv = global.L_ModuleManager:GetCurrentModule():GetGameEnv()
    local selSerInfo    = moduleGameEnv:GetSelectedServer()
    local server_id     = selSerInfo and selSerInfo.serverId
    local server_name   = selSerInfo and selSerInfo.serverName

    local dataParam = {
        event = {
            time = os.time(), name = "finishLoading2", type = "track"
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

    self:handleAlreadyUpToDate()
end

function HotUpdateGMAssets:onDownloadFailed()
    releasePrint(Tags, "DownloadFailed!")
    self:CleanupDownloaderSchedule()
    self:CleanupTipsSchedule()

    if self._downloader then
        self._downloader:Retry()
    end
end

function HotUpdateGMAssets:CleanupDownloaderSchedule()
    if self._gmResUpdateSchedule then 
        global.Scheduler:unscheduleScriptEntry(self._gmResUpdateSchedule)
        self._gmResUpdateSchedule = nil
    end
end
return HotUpdateGMAssets