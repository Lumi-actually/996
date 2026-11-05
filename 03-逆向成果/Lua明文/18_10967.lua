local AssetsManager = class('AssetsManager')

function AssetsManager:ctor()

    self._name              = ""
    self._remoteVer         = "xx.xx.xx"
    self._infoChecked       = false
    self._ccAssetsManagerEx = nil
    self._eventListener     = nil
    self._versionCompareHandle = nil

    self._eventDelegate     = nil
end

function AssetsManager:GetName()
    return self._name
end

function AssetsManager:Cleanup()
    if self._ccAssetsManagerEx then
        self._ccAssetsManagerEx:autorelease()
        self._ccAssetsManagerEx = nil
    end

    if self._eventListener then
        cc.Director:getInstance():getEventDispatcher():removeEventListener( self._eventListener )
        self._eventListener = nil
    end

    self._name          = ""
    self._remoteVer     = "xx.xx.xx"
    self._infoChecked   = false
    self._eventDelegate = nil
end

function AssetsManager:DownLoadRequest( name, localManifestPath, storagePath, tempManifestName, tempDirName,
                                        resUrl, manifestUrl, versionUrl, resVersion, jobs, ignoreLocal )
    if self._ccAssetsManagerEx then
        print( "wait last download finish.")
        return false
    end


    local downloadEntity = cc.AssetsManagerEx:create( localManifestPath, storagePath, true,
                                                      tempManifestName, tempDirName,
                                                      resUrl, manifestUrl, versionUrl )
    downloadEntity:retain()
    downloadEntity:setResourceVer( resVersion )
    downloadEntity:setMaxConcurrentTask( jobs )
    if self._versionCompareHandle then
        downloadEntity:setVersionCompareHandle(self._versionCompareHandle)
    end

    if ignoreLocal then
        local localManifest = downloadEntity:getLocalManifest()
        localManifest:setIgnoreLoad( true )
    end


    local listener = cc.EventListenerAssetsManagerEx:create( downloadEntity, handler( self, self.handleDownloadEvent ) )
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority( listener, 1 )

    self._eventListener     = listener
    self._ccAssetsManagerEx = downloadEntity
    self._name              = name

    downloadEntity:update()

    return true
end


----------------------------------------------------------------
function AssetsManager:setResourceVer(resVersion)
    self._ccAssetsManagerEx:setResourceVer( resVersion )
end

function AssetsManager:GetRemoteManifestVer()
    return self._remoteVer
end

function AssetsManager:SetEventDelegate( delegate )
    self._eventDelegate = delegate
end

function AssetsManager:SetVersionCompareHandle( handle )
    self._versionCompareHandle = handle
end

function AssetsManager:StartUpdate()
    if self._ccAssetsManagerEx then
        self._ccAssetsManagerEx:startUpdateManually()
    end
end

function AssetsManager:Pause()
    if self._ccAssetsManagerEx and not self._ccAssetsManagerEx:isInterrupted() then
        self._ccAssetsManagerEx:setInterruptFlag( true )
    end
end

function AssetsManager:Resume()
    if self._ccAssetsManagerEx and self._ccAssetsManagerEx:isInterrupted() then
        self._ccAssetsManagerEx:setInterruptFlag( false )
        self._ccAssetsManagerEx:startUpdateManually()
    end
end

function AssetsManager:Retry()
    if not self._ccAssetsManagerEx then
        return nil
    end

    self._ccAssetsManagerEx:downloadFailedAssets()
end


----------------------------------------------------------------
function AssetsManager:onLocalManifestError()
    releasePrint("AssetsManager error - can not find local mainfest." )

    if self._eventDelegate and self._eventDelegate.onLocalManifestError then
        self._eventDelegate:onLocalManifestError()
    end
end

function AssetsManager:onRemoteManifestError()
    releasePrint("AssetsManager error - MANIFEST download or parse failed." ) 

    if self._eventDelegate and self._eventDelegate.onRemoteManifestError then
        self._eventDelegate:onRemoteManifestError()
    end
end

function AssetsManager:onCheckVersionInfo()
    releasePrint("AssetsManager info - begin check version")

    if self._eventDelegate and self._eventDelegate.onCheckVersionInfo then
        self._eventDelegate:onCheckVersionInfo( versionSize )
    end
end

function AssetsManager:onNewVersion( versionSize )
    releasePrint("AssetsManager info - a new version was found: " .. tostring(versionSize) )
    if self._ccAssetsManagerEx then
        local manifest = self._ccAssetsManagerEx:getRemoteManifest()
        if manifest then
            self._remoteVer = manifest:getVersion()
        end
    end

    
    if self._eventDelegate and self._eventDelegate.onNewVersion then
        self._eventDelegate:onNewVersion( versionSize )
    end
end

function AssetsManager:onAlreadyUpToDate()
    releasePrint("AssetsManager info - already up to date" )
    if self._ccAssetsManagerEx then
        local manifest = self._ccAssetsManagerEx:getRemoteManifest()
        if manifest then
            self._remoteVer = manifest:getVersion()
        end
    end

    if self._eventDelegate and self._eventDelegate.onAlreadyUpToDate then
        self._eventDelegate:onAlreadyUpToDate()
    end
end

function AssetsManager:onUpdatePercent( percent, percentSize )
    if self._ccAssetsManagerEx and percent > 0 then
        if self._ccAssetsManagerEx.percent ~= percent then
            self._ccAssetsManagerEx.percent = percent
            releasePrint("AssetsManager info - percent:" .. tostring(percent) )

            if self._eventDelegate and self._eventDelegate.onUpdatePercent then
                self._eventDelegate:onUpdatePercent( percent, self._ccAssetsManagerEx:getTotalDiffFileSize() )
            end
        end
    end
    if self._ccAssetsManagerEx and percentSize > 0 then
        if self._ccAssetsManagerEx.percentSize ~= percentSize then
            self._ccAssetsManagerEx.percentSize = percentSize
            releasePrint("AssetsManager info - percentSize:" .. tostring(percentSize) )

            if self._eventDelegate and self._eventDelegate.onUpdatePercentSize then
                self._eventDelegate:onUpdatePercentSize( math.min(percentSize, 100), self._ccAssetsManagerEx:getTotalDiffFileSize() )
            end
        end
    end
end

function AssetsManager:onAssetError( assetID, msg )
    releasePrint("AssetsManager error - ERROR_UPDATING ", assetID, ", ", msg)        

    if self._eventDelegate and self._eventDelegate.onAssetError then
        self._eventDelegate:onAssetError( assetID, msg )
    end
end

function AssetsManager:onDownloadFinished()
    releasePrint("AssetsManager info - update finished")

    if self._ccAssetsManagerEx then
        local manifest = self._ccAssetsManagerEx:getLocalManifest()
        if manifest then
            self._remoteVer = manifest:getVersion()
        end
    end

    if self._eventDelegate and self._eventDelegate.onDownloadFinished then
        self._eventDelegate:onDownloadFinished()
    end
end

function AssetsManager:onDownloadFailed()
    releasePrint("AssetsManager error - update failed")

    if self._eventDelegate and self._eventDelegate.onDownloadFailed then
        self._eventDelegate:onDownloadFailed()
    end
end

function AssetsManager:handleDownloadEvent( event )
    if not self._ccAssetsManagerEx then
        return nil
    end


    local eventCode = event:getEventCode()
    if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST then
        if global.Director:isValid() then
            self:onLocalManifestError()
        else
            local function func()
                self:onLocalManifestError()
            end
            PerformWithDelayGlobal( func, 0.5 )
        end

  elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST or 
         eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_PARSE_MANIFEST then
        if global.Director:isValid() then
            self:onRemoteManifestError()
        else
            local function func()
                self:onRemoteManifestError()
            end
            PerformWithDelayGlobal( func, 0.5 )
        end

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then
        if self._ccAssetsManagerEx:getState() == 8 then
            local versionSize = self._ccAssetsManagerEx:getTotalDiffFileSize()
            if global.Director:isValid() then
                self:onNewVersion( versionSize )
            else
                local function func()
                    self:onNewVersion( versionSize )
                end
                PerformWithDelayGlobal( func, 0.5 )
            end
        end

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE then
        if global.Director:isValid() then
            self:onAlreadyUpToDate()
        else
            local function func()
                self:onAlreadyUpToDate()
            end
            PerformWithDelayGlobal( func, 0.5 )
        end

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION then
        if global.Director:isValid() then
            if not self._infoChecked then
                self._infoChecked = true
                self:onCheckVersionInfo()
            else
                local percentFile = math.ceil( event:getPercentByFile() )
                local percentSize = math.ceil( event:getPercent() )
                self:onUpdatePercent( percentFile, percentSize )
            end
        end

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
        if global.Director:isValid() then
            self:onDownloadFinished()
        else
            local function func()
                self:onDownloadFinished()
            end
            PerformWithDelayGlobal( func, 0.5 )
        end

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then      
        if global.Director:isValid() then
            self:onDownloadFailed()
        else
            local function func()
                self:onDownloadFailed()
            end
            PerformWithDelayGlobal( func, 0.5 )
        end

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then      
        local assetID = event:getAssetId()
        local msg = string.format( "%s, code:%s", tostring(event:getMessage()), tostring(eventCode) )
        if global.Director:isValid() then
            self:onAssetError( assetID, msg )
        else
            local function func()
                self:onAssetError( assetID, msg )
            end
            PerformWithDelayGlobal( func, 0.5 )
        end

    end
end


return AssetsManager
