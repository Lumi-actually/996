local AudioMediator = class('AudioMediator', framework.Mediator)
AudioMediator.NAME  = "AudioMediator"

function AudioMediator:ctor()
    AudioMediator.super.ctor( self, self.NAME )

    self._audioEngine   = ccexp.AudioEngine

    self._musicEnable   = true
    self._effectEnable  = true

    self._musicVolume   = 0.8
    self._effectVolume  = 1

    self._entityCache   = {}
    self._musicEntityID = nil
    self._effectEntitys = {}
    self._effectCount   = 0

    self._BGMPath       = nil
    self._BGMStop		= nil

    self._finishCB      = handler(self, self.OnEffectFinishCB)
    self._fileExistCache= {}

    self:Init()
end

function AudioMediator:Init()
    local NT = global.NoticeTable
    self._noticeMaps = {
        [NT.Audio_Play]          = function (...) self:PlayAudio(...) end,
        [NT.Audio_Play_BGM]      = function (...) self:PlayBGM(...) end,
        [NT.Audio_Stop_BGM]      = function (...) self:StopBGM() end,
        [NT.Audio_Pause_BGM]     = function (...) self:PauseBGM() end,
        [NT.Audio_Resume_BGM]    = function (...) self:ResumeBGM() end,
        [NT.Audio_Play_EffectId] = function (...) self:PlayEffectByID(...) end,
        [NT.Audio_Stop_EffectId] = function (...) self:StopEffectByID(...) end,
        [NT.Audio_Pause_All]     = function (...) self:PauseAll() end,
        [NT.Audio_Resume_All]    = function (...) self:ResumeAll() end,
        [NT.Audio_Stop_All]      = function (...) self:StopAll() end,
        [NT.GameSettingInited]   = function (...) self:OnGameSettingInited() end,
        [NT.GameSettingChange]   = function (...) self:OnGameSettingChange(...) end,
        [NT.MapInfoChange]       = function (...) self:OnMapInfoChange() end
    }
end

function AudioMediator:listNotificationInterests()
    local NT = global.NoticeTable
    return {
        NT.Audio_Play,
        NT.Audio_Play_BGM,
        NT.Audio_Stop_BGM,
        NT.Audio_Pause_BGM,
        NT.Audio_Resume_BGM,
        NT.Audio_Play_EffectId,
        NT.Audio_Stop_EffectId,
        NT.Audio_Pause_All,
        NT.Audio_Resume_All,
        NT.Audio_Stop_All,
        NT.GameSettingInited,
        NT.GameSettingChange,
        NT.MapInfoChange
    }
end

function AudioMediator:handleNotification(notification)
    local noticeID = notification:getName()
    if self._noticeMaps[noticeID] then
        self._noticeMaps[noticeID](notification:getBody())
    end
end

local shareT = {}
function AudioMediator:OnMapInfoChange()
    --地图场景BGM
    shareT.type = global.MMO.SND_TYPE_BGM_MAP
    self:PlayBGM(shareT)
end

function AudioMediator:OnGameSettingInited()
    self:ChangeBGMVolume()
    self:ChangeEffectVolume()
end

function AudioMediator:OnGameSettingChange(data)
    if data.id == 27 then
        -- 背景音乐
        self:ChangeBGMVolume()
        local value = CHECK_SETTING(27) or 0
        local tips = value == 0 and GET_STRING(30053001) or string.format(GET_STRING(30053002), value or 0)
        ShowSystemChat(tips, 255, 0)
    elseif data.id == 52 then
        -- 游戏音效
        self:ChangeEffectVolume()
        local value = CHECK_SETTING(52) or 0
        local tips = value == 0 and GET_STRING(30053003) or string.format(GET_STRING(30053004), value or 0)
        ShowSystemChat(tips, 255, 0)
    end
end

function AudioMediator:ChangeBGMVolume()
    local volume        = CHECK_SETTING(27) or 0
    local enable        = volume > 0
    self._musicEnable   = enable
    self._musicVolume   = volume / 100
    self:SetBGMVolume(self._musicVolume)
end

function AudioMediator:ChangeEffectVolume()
    local volume        = CHECK_SETTING(52) or 0
    local enable        = volume > 0
    self._effectEnable  = enable
    self._effectVolume  = volume / 100
    self:SetEffectEnabled(enable)
end

function AudioMediator:PauseAll()
    self._audioEngine:pauseAll()
end

function AudioMediator:ResumeAll()
    self._audioEngine:resumeAll()
end

function AudioMediator:StopAll()
    self._BGMStop = true
    self._BGMPath = nil
    self._musicEntityID = nil
    self._audioEngine:stopAll()

    for audioID, entity in pairs(self._effectEntitys) do
        self:RecycleEntity(entity)
    end
    self._effectEntitys = {}
    self:ClearAudioCount()
end

function AudioMediator:PlayByPath(path, isLoop, volume)
    if not path or path == "" or not volume then
        return nil
    end

    if not self:IsFileExist(path) then
        global.ResDownloader:download(
            path,
            function(isOK)
                if isOK then
                    self:OnDownloadComplete(path)
                end
            end
        )
        return nil
    end

    local audioID = self._audioEngine:play2d(path, isLoop, volume)
    if audioID == cc.AUDIO_INVAILD_ID then
        return nil
    end

    return audioID
end

function AudioMediator:SetVolumeByID(audioID, volume)
    if audioID then
        self._audioEngine:setVolume(audioID, volume)
    end
end

function AudioMediator:PlayAudio(data)
    local AudioProxy = global.Facade:retrieveProxy(global.ProxyTable.AudioProxy)
    local id, delayTime, id2, delayTime2 = AudioProxy:getAudioId(data)
    if not id then
        return
    end

    local config = AudioProxy:GetConfig(id)
    if not config or not config.file or config.file == "" then
        return
    end

    local audioType = data.type
    local filePath = config.file
    local isLoop = data.isLoop and data.isLoop or false

    -- 播放
    if delayTime and delayTime > 0 then
        PerformWithDelayGlobal(
            function()
                self:PlayEffect(filePath, isLoop, audioType)
            end,
            delayTime
        )
    else
        self:PlayEffect(filePath, isLoop, audioType)
    end

    -- 两个音效
    if id2 then
        local config = AudioProxy:GetConfig(id2)
        if config and config.file then
            local audioType = data.type
            local filePath = config.file
            if delayTime2 and delayTime2 > 0 then
                PerformWithDelayGlobal(
                    function()
                        self:PlayEffect(filePath, isLoop, audioType)
                    end,
                    delayTime2
                )
            else
                self:PlayEffect(filePath, isLoop, audioType)
            end
        end
    end
end

function AudioMediator:PlayBGM(data, isLoop)
    local AudioProxy = global.Facade:retrieveProxy(global.ProxyTable.AudioProxy)
    local path = data.path or AudioProxy:getBGMPath(data)

    if not path or path == "" then
        self:StopBGM()
        return
    end
    if not data.path and path ~= nil and path == self._BGMPath then
        return
    end

    if not self._musicEnable or not path or path == "" then
        return
    end

    self:PlayBGMByPath(path)
end

function AudioMediator:PlayBGMByPath(path)
    if not path then
        return nil
    end

    -- stop last bgm
    self:StopBGM()
    self._BGMStop = false
    self._BGMPath = path
    local audioID = self:PlayByPath(path, true, self._musicVolume)
    self._musicEntityID = audioID
end

function AudioMediator:StopBGM()
    if self._musicEntityID then
        local bgID = self._musicEntityID
        PerformWithDelayGlobal(function ()
            self._audioEngine:stop(bgID)
        end, 0.1)
        
        self._musicEntityID = nil
        self._BGMStop		= true
        self._BGMPath       = nil
    end
end

function AudioMediator:PauseBGM()
   if self._musicEntityID then
        local bgID = self._musicEntityID
        PerformWithDelayGlobal(function()
            self._audioEngine:pause(bgID)
        end, 0.1)
    end 
end

function AudioMediator:ResumeBGM()
   if self._musicEntityID then
        local bgID = self._musicEntityID
        PerformWithDelayGlobal(function()
            self._audioEngine:resume(bgID)
        end, 0.1)
    end 
end

function AudioMediator:StopEffectByPath(path)
    for _, entity in pairs(self._effectEntitys) do
        if path == entity.path then
            self:StopEffect(entity.id)
            break
        end
    end
end

function AudioMediator:StopEffectByType(type)
    for _, entity in pairs(self._effectEntitys) do
        if type == entity.type then
            self:StopEffect(entity.id)
            break
        end
    end
end

function AudioMediator:StopEffectByID(id)
    local AudioProxy = global.Facade:retrieveProxy(global.ProxyTable.AudioProxy)
    local config = AudioProxy:GetConfig(id)
    if not config or not config.file then
        return
    end
    local path = config.file
    self:StopEffectByPath(path)
end

function AudioMediator:PlayEffectByID(data)
    local id, isLoop, type, times = data.id, data.loop, data.type, data.times
    local path = nil
    local AudioProxy = global.Facade:retrieveProxy(global.ProxyTable.AudioProxy)
    local config = AudioProxy:GetConfig(id)
    if not config or not config.file then
        return
    end

    path = config.file
    type = type or global.MMO.SUD_TYPE_NORMAL
    isLoop = isLoop or false
    self:StopEffectByType(global.MMO.SUD_TYPE_NORMAL)
    self:PlayEffect(path, isLoop, type, times)
end

function AudioMediator:PlayEffect(path, isLoop, type, times)
    if not self._effectEnable then
        return
    end

    if not self:CheckEffectCount() then
        return
    end

    if times and times > 0 then
        isLoop = false
    end

    local audioID = self:PlayByPath(path, isLoop, self._effectVolume)
    if audioID then
        local entity = self:AllocEntity()
        entity.id = audioID
        entity.path = path
        entity.type = type
        entity.times = times
        self._effectEntitys[entity.id] = entity
        self._audioEngine:setFinishCallback(entity.id, self._finishCB)
        self:OnAudioPlay(type)
    end
end

function AudioMediator:SetEffectEnabled(enable)
    self._effectEnable = enable

    if not enable then
        self:StopAllEffects()
    end
end

function AudioMediator:StopAllEffects()
    for audioID, entity in pairs(self._effectEntitys) do
        self:StopEffect(audioID)
    end

    self._effectEntitys = {}
    self:ClearAudioCount()
end

function AudioMediator:StopEffect(audioID)
    local entity = self._effectEntitys[audioID]
    if entity then
        self:OnAudioStop(entity)
        self._audioEngine:stop(entity.id)
        self:RecycleEntity(entity)
        self._effectEntitys[audioID] = nil
    end
end

function AudioMediator:SetBGMVolume(value)
    self._musicVolume = value

    if self._musicEntityID then
        self:SetVolumeByID(self._musicEntityID, self._musicVolume)
    end
end

function AudioMediator:CheckEffectCount()
    return self._effectCount <= 10
end

function AudioMediator:OnAudioPlay(type)
    self:AddEffectCount()
end

function AudioMediator:OnAudioStop(eneity)
    if not eneity then
        return
    end

    self:DecEffectCount()
end

function AudioMediator:ClearAudioCount()
    self._effectCount = 0
end

function AudioMediator:AddEffectCount()
    self._effectCount = self._effectCount + 1
end

function AudioMediator:DecEffectCount()
    self._effectCount = self._effectCount - 1
end

function AudioMediator:OnEffectFinishCB(audioID, path)
    local entity = self._effectEntitys[audioID]
    if entity then
        local replayPath  = entity.path
        local replayType  = entity.type
        local replayTimes = entity.times

        self:OnAudioStop(entity)
        self:RecycleEntity(entity)
        self._effectEntitys[audioID] = nil

        if replayTimes and replayTimes > 1 then
            self:PlayEffect(replayPath, false, replayType, replayTimes - 1)
        end
    end
end

function AudioMediator:AllocEntity()
    local entity = table.remove(self._entityCache) or {}
    return entity
end

function AudioMediator:RecycleEntity(entity)
    table.insert(self._entityCache, entity)
end

function AudioMediator:OnDownloadComplete(filePath)
    -- 标记已存在
    self._fileExistCache[filePath] = true

    -- 背景音乐下载成功时立即播放
    if self._BGMPath == filePath and not self._BGMStop then
        self:PlayBGMByPath(filePath)
    end
end

function AudioMediator:IsFileExist(filePath)
    if self._fileExistCache[filePath] == nil then
        self._fileExistCache[filePath] = global.FileUtilCtl:isFileExist(filePath)
    end
    return self._fileExistCache[filePath]
end

return AudioMediator