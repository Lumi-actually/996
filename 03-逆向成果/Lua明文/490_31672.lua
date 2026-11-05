local RemoteProxy = requireProxy("RemoteProxy")
local GameSettingProxy = class("GameSettingProxy", RemoteProxy)
GameSettingProxy.NAME = global.ProxyTable.GameSettingProxy

local cjson = require("cjson")

GameSettingProxy.syncTable = {
    [16]   = {key = "ZDLH",   job = 3},         -- 自动烈火
    [53]   = {key = "ZDKTZ",  job = 3},         -- 自动开天斩
    [54]   = {key = "ZDZR",   job = 3},         -- 自动逐日
    [118]  = {key = "ZDLYJF", job = 3},         -- 龙影剑法
    [119]  = {key = "ZDLTJF", job = 3},         -- 雷霆剑法
    [120]  = {key = "ZDZHJF", job = 3},         -- 纵横剑术
    [200]  = {key = "ZDLJ"},                    -- 自动连击
    
    [3011] = {key = "HERO_FOLLOW_ATTACK"},      -- 自动跟随主角攻击
    [3012] = {key = "HERO_ATTACK_DODGE"},       -- 英雄打怪躲避
    [41]   = {key = "BB_FOLLOW_ATTACK"},        -- 宝宝自动跟随主角攻击
}

local discard = 
{
    [global.MMO.SETTING_IDX_FRAME_RATE_TYPE_HIGH] = 1
}

local SharedEmpty    = {}
local SharedDefault  = {}

function GameSettingProxy:ctor()
    GameSettingProxy.super.ctor(self)
    
    self._data = {}
    self._config = {}

    self._pickConfig = {}           -- 组配置
    self._pickData   = {}           -- 拾取的设置
    self._pickHangUpData = {}       -- 总开关数据

    self._itemConfig = {}           -- 拾取相关的改为由服务器发 这个是默认选项

    self._bossTipsData = {}         -- Boss提醒配置
    self._bossTipsDataKey = {}      -- boss type
    self._bossTypeData = {
        "BOSS", "大BOSS", "超级BOSS"
    }

    self._rankData = {}             -- 保护数据

    self._playerNameColorData = {}  -- 玩家名字颜色配置 {[actorID] = XXX, ...}

    self._hideReportBtn = false     -- 是否隐藏举报按钮

    self._dataInited = false        -- 本地数据初始化
    self._hasServerMonsterData = false -- 是否已经接收到服务端怪物不攻击列表数据
end

function GameSettingProxy:LoadConfig()
    SL:Print("[Require game_config] ", "cfg_setup")
    self._config = SL:RequireFile("game_config/cfg_setup")
    self:readLocalData()

    -- pick config
    SL:Print("[Require game_config] ", "cfg_pick_set")
    self._pickConfig = SL:RequireFile("game_config/cfg_pick_set")

    local GameConfigMgrProxy = global.Facade:retrieveProxy(global.ProxyTable.GameConfigMgrProxy)
    local configKey = "cfg_serverItemCfg"
    local itemConfig = GameConfigMgrProxy:getConfigByKey(configKey)
    if not itemConfig then
        itemConfig = {}
    end
    self._itemConfig = itemConfig
end

function GameSettingProxy:OnPropertyInited()
    self:refSyncData()
    self:SyncDataToServer()
    self:readLocalPickData()
    self:readLocalGroupPickData()
    self:readLocalBossTipsData()
    self:readLocalBossTypeData()
    self:readLocalProtectData()
    self:readLocalPlayerNameColorData()
    self:initSomeSetting()
    global.Facade:sendNotification(global.NoticeTable.GameSettingInited)
    self._dataInited = true
    if self._needSendFilter then
        -- 后置发送
        self:RequestSendFilterAutoPickItem()
        self._needSendFilter = false
    end
end

function GameSettingProxy:OnReConnectInited()
    self:SyncDataToServer()
end

function GameSettingProxy:refSyncData()
    local skillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    local skills, nSkill = skillProxy:GetConfigs()
    for i = 1, nSkill do
        local skill = skills[i]
        if skill and skill.MagicID > 1000 and (skill.job == 0 or skill.job == 3) and skillProxy:IsOnoffSkill(skill.MagicID) then        -- 自定义战士开关技能
            self.syncTable[10000 + skill.MagicID] = {key = "ZD" .. skill.MagicID, job = skill.job}
        end
    end
end

function GameSettingProxy:SyncDataToServer()
    local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local roleJob = PlayerProperty:GetRoleJob()

    -- 掉落屏蔽 "1,2,3"
    local n = 1
    local jsonData = {{key = "MSGFILTER", value = table.concat(ChatData.GetDropTypeShield(), ",")}}

    for k, v in pairs(self.syncTable) do
        if (not v.job) or (v.job == 3) or (roleJob == v.job) then
            n = n + 1
            jsonData[n] = {
                key   = v.key,
                value = CHECK_SETTING(k) == 1 and 1 or 0
            }
        end
    end

    SendTableToServer(global.MsgType.MSG_CS_GAME_SETTING_CHANGE, jsonData)
end

function GameSettingProxy:ReadData(key)
    local mainPlayerID = SL:GetValue("LOGIN_SELECT_ROLE_ID")
    local path     = "setting_UserData" .. mainPlayerID
    local userData = UserData:new(path)

    local jsonStr  = userData:getStringForKey(key, "")
    if not jsonStr or string.len(jsonStr) == 0 then
        return false
    end

    local jsonData = cjson.decode(jsonStr)
    if not jsonData then
        return false
    end 

    return jsonData
end

function GameSettingProxy:SaveData(key, data)
    local mainPlayerID = SL:GetValue("LOGIN_SELECT_ROLE_ID")
    local path     = "setting_UserData" .. mainPlayerID
    local userData = UserData:new(path)

    userData:setStringForKey(key, cjson.encode(data))
end

-- 设置
function GameSettingProxy:readLocalData()
    self._data = self:ReadData("setting") or {}
end

function GameSettingProxy:saveLocalData()
    local data = {}
    for key, value in pairs(self._data or {}) do
        if discard[tonumber(key)] ~= 1 then
            data[key] = value
        end
    end
    self:SaveData("setting", data)
end

-- boss Type
function GameSettingProxy:readLocalBossTypeData()
    self._bossTypeData = self:ReadData("bossType_setting") or {}
end

-- 延迟存储,防卡顿
function GameSettingProxy:saveLocalBossTypeData()
    if self._bossTypeStorageTimer then
        UnSchedule(self._bossTypeStorageTimer)
        self._bossTypeStorageTimer = nil
    end
    self._bossTypeStorageTimer = PerformWithDelayGlobal(function()
        self._bossTypeStorageTimer = nil
        self:SaveData("bossType_setting", self._bossTypeData)
    end, 0.01)
end

-- boss提醒
function GameSettingProxy:readLocalBossTipsData()
    local data = self:ReadData("bossTips_setting")
    if not data then
        return false
    end

    self._bossTipsSetting = true

    self._bossTipsData = data

    for i, v in ipairs(self._bossTipsData) do
        self._bossTipsDataKey[v[1]] = v
    end
end

-- 延迟存储,防卡顿
function GameSettingProxy:saveLocalBossTipsData()
    if self._bossTipStorageTimer then
        UnSchedule(self._bossTipStorageTimer)
        self._bossTipStorageTimer = nil
    end
    self._bossTipStorageTimer = PerformWithDelayGlobal(function()
        self._bossTipStorageTimer = nil
        self:SaveData("bossTips_setting", self._bossTipsData)
    end, 0.01)
end

-- 手动拾取
function GameSettingProxy:readLocalPickData()
    self._pickData = self:ReadData("pick_setting") or {}
end

function GameSettingProxy:saveLocalPickData()
    if self._pickStorageTimer then
        UnSchedule(self._pickStorageTimer)
        self._pickStorageTimer = nil
    end
    self._pickStorageTimer = PerformWithDelayGlobal(function()
        self._pickStorageTimer = nil
        self:SaveData("pick_setting", self._pickData)
    end, 0.01)
end

-- 组设置
function GameSettingProxy:readLocalGroupPickData()
    self._pickHangUpData = self:ReadData("grouppick_setting") or {}
end

function GameSettingProxy:saveLocalGroupPickData()
    if self._pickGroupStorageTimer then
        UnSchedule(self._pickGroupStorageTimer)
        self._pickGroupStorageTimer = nil
    end
    self._pickGroupStorageTimer = PerformWithDelayGlobal(function()
        self._pickGroupStorageTimer = nil
        self:SaveData("grouppick_setting", self._pickHangUpData)
    end, 0.01)
end

-- 保护设置
function GameSettingProxy:readLocalProtectData()
    self._rankData = self:ReadData("RankData_setting") or {}
end

-- 延迟存储,防卡顿
function GameSettingProxy:saveLocalProtectData()
    if self._protectDataStorageTimer then
        UnSchedule(self._protectDataStorageTimer)
        self._protectDataStorageTimer = nil
    end
    self._protectDataStorageTimer = PerformWithDelayGlobal(function()
        self._protectDataStorageTimer = nil
        self:SaveData("RankData_setting", self._rankData)
    end, 0.01)
end


function GameSettingProxy:readLocalPlayerNameColorData()
    local data = self:ReadData("playerNameColor_setting")
    if not data then
        return false
    end

    self._playerNameColorData = data

    -- 以防玩家在属性初始化完成前进视野 再处理
    for actorID, colorID in pairs(self._playerNameColorData) do
        local actor = global.actorManager:GetActor(actorID)
        if actor and actor.SetSettingColorID and not actor:GetSettingColorID() then
            actor:SetSettingColorID(colorID)
            global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabelColor, actorID)
        end
    end
end

-- 延迟存储,防卡顿
function GameSettingProxy:saveLocalPlayerNameColorData()
    if self._playerNameColorStorageTimer then
        UnSchedule(self._playerNameColorStorageTimer)
        self._playerNameColorStorageTimer = nil
    end
    self._playerNameColorStorageTimer = PerformWithDelayGlobal(function()
        self._playerNameColorStorageTimer = nil
        self:SaveData("playerNameColor_setting", self._playerNameColorData)
    end, 0.01)
end

function GameSettingProxy:GetValue(id)
    id = tostring(id)

    local config = self:GetConfigByID(id)
    if not config then
        return SharedEmpty
    end

    local platform = config and config.platform or nil
    if platform ~= 0 and platform ~= 99 and platform ~= global.OperatingMode then  --判断平台
        return SharedEmpty
    end
    --挂机忽略怪物列表不走default
    if not self._data[id] and id ~= global.MMO.SETTING_IDX_IGNORE_MONSTER then
        SharedDefault[1] = config.default
        SharedDefault[2] = config.default1
        SharedDefault[3] = config.default2
        SharedDefault[4] = config.default3
        return SharedDefault
    end
    return self._data[id] 
end

function GameSettingProxy:SetValue(id, value)
    id = tostring(id)

    self._data[id] = self._data[id] or {}
    
    if type(value) == "table" then
        self._data[id] = value
    else
        local data = self._data[id]
        data[1]    = value
    end

    local numID = tonumber(id)
    if self.syncTable[numID] or self.syncTable[numID + 10000] then
        self:SyncDataToServer()
    end
    -- 发送到服务端(怪物列表不攻击列表)
    if tonumber(id) == global.MMO.SETTING_IDX_IGNORE_MONSTER then
        self:SendMonsterIgnoreListToServer()
    end

    self:saveLocalData()
end

function GameSettingProxy:GetConfigByID(id)
    return self._config[tonumber(id)]
end

function GameSettingProxy:GetMainOptions()
    local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local roleJob = PlayerProperty:GetRoleJob()

    local items = {}
    for i, v in pairs(self._config) do
        if v.mainpos and v.mainpos ~= "" and (v.platform == 0 or v.platform == global.OperatingMode) then
            local normalAndPress = G_GetSplitArray(v.mainpos, "&")
            local item = {}
            local has = false
            local filterJob = true
            if normalAndPress and normalAndPress[3] and normalAndPress[3] ~= "" then 
                local job  = tonumber(normalAndPress[3])
                if job and roleJob ~= job then 
                    filterJob = false
                end
            end
            --normal
            if normalAndPress and normalAndPress[1] and normalAndPress[1] ~= "" then 
                local slicesPos         = G_GetSplitArray(normalAndPress[1], "|")
                -- 移动1
                if not global.isWinPlayMode and slicesPos[1] and slicesPos[1] ~= "" then
                    local slicesPosM    = G_GetSplitArray(slicesPos[1], "#")
                    has                 = true
                    item.id             = v.id
                    item.lid            = tonumber(slicesPosM[2])
                    item.x              = tonumber(slicesPosM[3])
                    item.y              = tonumber(slicesPosM[4])
                    item.brightPath     = string.format("%s%s","private/new_setting/icon/", slicesPosM[1])
                end

                -- PC
                if global.isWinPlayMode and slicesPos[2] and slicesPos[2] ~= "" then
                    local slicesPosP    = G_GetSplitArray(slicesPos[2], "#")
                    has                 = true
                    item.id             = v.id
                    item.lid            = tonumber(slicesPosP[2])
                    item.x              = tonumber(slicesPosP[3])
                    item.y              = tonumber(slicesPosP[4])
                    item.brightPath     = string.format("%s%s","private/new_setting/icon/", slicesPosP[1])
                end
            end
            --press
            if normalAndPress and  normalAndPress[2] and normalAndPress[2] ~= "" then 
                local slicesPos         = G_GetSplitArray(normalAndPress[2], "|")
                -- 移动1
                if not global.isWinPlayMode and slicesPos[1] and slicesPos[1] ~= "" then
                    local slicesPosM    = G_GetSplitArray(slicesPos[1], "#")
                    has                 = true
                    item.id             = v.id
                    item.off_lid        = tonumber(slicesPosM[2])
                    item.off_x          = tonumber(slicesPosM[3])
                    item.off_y          = tonumber(slicesPosM[4])
                    item.normalPath = string.format("%s%s","private/new_setting/icon/", slicesPosM[1])
                end

                -- PC
                if global.isWinPlayMode and slicesPos[2] and slicesPos[2] ~= "" then
                    local slicesPosP    = G_GetSplitArray(slicesPos[2], "#")
                    has                 = true
                    item.id             = v.id
                    item.off_lid        = tonumber(slicesPosP[2])
                    item.off_x          = tonumber(slicesPosP[3])
                    item.off_y          = tonumber(slicesPosP[4])
                    item.normalPath = string.format("%s%s","private/new_setting/icon/", slicesPosP[1])
                end
            end
            if has and filterJob then 
                table.insert(items,item)
            end
        end
    end
    return items
end

--------------------------------------------------------

function GameSettingProxy:GetBossTipsValues()
    return self._bossTipsData
end

function GameSettingProxy:SetBossTipsValues(values)
    self._bossTipsData = values
    for _, v in ipairs(self._bossTipsData) do
        self._bossTipsDataKey[v[1]] = v
    end
    self:saveLocalBossTipsData()
end

function GameSettingProxy:GetBossType()
    return self._bossTypeData
end

function GameSettingProxy:SetBossType(values)
    self._bossTypeData = values
    self:saveLocalBossTypeData()
end

function GameSettingProxy:getNeedTipsMonsterData(name)
    return self._bossTipsDataKey[name]
end

function CHECK_SETTING_BOSSTIPS(name)
    if not name then 
        return 
    end
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    return GameSettingProxy:getNeedTipsMonsterData(name)
end

function GameSettingProxy:GetPickConfig()
    return self._pickConfig
end

-- 拾取组设置
function GameSettingProxy:GetPickGroupValue(id)
    -- 掉落显示#手动拾取#挂机捡取#极品拾取
    return self._pickHangUpData[tostring(id)] or {1, 1, 1, 0}
end

--拾取设置
function GameSettingProxy:GetPickValue(id)
    id = tostring(id)
    -- 组类别#掉落显示#手动拾取#挂机捡取#极品拾取
    local set = {}
    if not self._pickData[id] then
        local find = false
        for i, v in ipairs(self._itemConfig) do -- 服务器的为默认配置 道具表控制是否可以 设置
            if v.Index == tonumber(id) then
                find = true
                set =  {v.ShowName or 1, v.AutoPick or 1, v.HideMode or 1, 0}
                break
            end
        end
        if not find then
            set =  {1, 1, 1, 0}
        end
    else
        set = clone(self._pickData[id])
    end
    
    set[1] = set[1]  or 1
    set[2] = set[2]  or 1
    set[3] = set[3]  or 1
    set[4] = set[4]  or 0
    local config  = self:GetPickCanSet(id) -- 不能勾选的当不能拾取
    for i,v in ipairs(config) do
        if v == 0 then
            set[i] = 0
        end
    end
    
    return set
end

-- 道具表 配置能否勾选
function GameSettingProxy:GetPickCanSet(id)
    id = tostring(id)
    -- 组类别#掉落显示#手动拾取#挂机捡取#极品拾取
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    local itemConfig = ItemConfigProxy:GetItemDataByIndex(tonumber(id))

    -- 先读道具表
    if itemConfig.pickset and string.len(itemConfig.pickset) > 0 then
        local slices = G_GetSplitArray(tostring(itemConfig.pickset), "#")
        local value  = {tonumber(slices[2]) or 0, tonumber(slices[3]) or 0, tonumber(slices[4]) or 0, tonumber(slices[5]) or 0}
        return value
    end

    return {1, 1, 1, 1}
end

function GameSettingProxy:GetGroupIdByIndex(Index)
    local id = tonumber(Index)
    -- 组类别#掉落显示#手动拾取#挂机捡取#极品拾取
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    local itemConfig = ItemConfigProxy:GetItemDataByIndex(id)

    -- 先读道具表
    if itemConfig and itemConfig.pickset and string.len(itemConfig.pickset) > 0 then
        local slices = G_GetSplitArray(tostring(itemConfig.pickset), "#")
        return slices[1]
    end

    return nil
end

function GameSettingProxy:SetPickValue(id, value)
    self._pickData[tostring(id)] = value
    self:saveLocalPickData()
end

function GameSettingProxy:SetPickGroupValue(id, value)
    self._pickHangUpData[tostring(id)] = value
    self:saveLocalGroupPickData()
end

-- 某些排序的设置 
function GameSettingProxy:getRankData(id)
    if not id then 
        return {}
    end

    id = tostring(id)
    local config = self:GetConfigByID(id)
    if not config then
        return {indexs = {} ,time = 1000,oriStr = ""}
    end

    if self._rankData[id] then
        local oriStr = self._rankData[id].oriStr
        local indexs = config.indexs
        if indexs and indexs ~= ""  and  oriStr ~= indexs then --发现之前的配置跟现在不一样  清除之前的排序数据
            self:setRankData(id,{indexs = {} ,time = 1000,oriStr = config.indexs})
        else
            return self._rankData[id]
        end
    end
    
    if not config.indexs then 
        config.indexs = ""
    end 

    if not config.time then 
        config.time = 1000
    end

    self._rankData[id] = {indexs = {} ,time = 1000,oriStr = config.indexs}
    self._rankData[id].time = config.default2 or config.time
    if id == tostring(global.MMO.SETTING_IDX_AUTO_GROUPSKILL) or id == tostring(global.MMO.SETTING_IDX_AUTO_SIMPSKILL) then  
    else
        local indexs =  G_GetSplitArray(config.indexs,"#")
        for i,index in ipairs(indexs) do
            table.insert(self._rankData[id].indexs, tonumber(index))
        end
    end

    return self._rankData[id]
end

function GameSettingProxy:setRankData(id,value)
    self._rankData[tostring(id)] = value
    self:saveLocalProtectData()
end

-- 玩家名字颜色数据
function GameSettingProxy:GetPlayerNameColorValues()
    return self._playerNameColorData
end

function GameSettingProxy:GetPlayerNameColorValueByActorID(actorID)
    if not actorID then
        return nil
    end
    if not self._playerNameColorData or not next(self._playerNameColorData) then
        return nil
    end
    return self._playerNameColorData[actorID]
end

function GameSettingProxy:SetPlayerNameColorValues(values)
    local lastActorIDList = table.keys(self._playerNameColorData)

    self._playerNameColorData = {}
    local actorIDList = table.keys(values)
    for i = 1, #actorIDList do
        local actorID = actorIDList[i]
        local colorID = values[actorID]
        self._playerNameColorData[actorID] = colorID
        local actor = global.actorManager:GetActor(actorID)
        if actor and actor.SetSettingColorID then           -- 更新颜色
            local lastColorID = actor:GetSettingColorID()
            if colorID ~= lastColorID then
                actor:SetSettingColorID(colorID)
                global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabelColor, actorID)
            end
        end
    end
    --
    self:saveLocalPlayerNameColorData()


    -- 清除玩家名字颜色显示
    if lastActorIDList and next(lastActorIDList) then
        for i = 1, #lastActorIDList do
            local actorID = lastActorIDList[i]
            if not self._playerNameColorData[actorID] then  -- 删除颜色
                local actor = global.actorManager:GetActor(actorID)
                if actor and actor.SetSettingColorID then
                    actor:SetSettingColorID(nil)
                    global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabelColor, actorID)
                end
            end
        end
    end

end

function GameSettingProxy:initSomeSetting()
    -- 忽略怪物 
    local value = GET_SETTING(global.MMO.SETTING_IDX_IGNORE_MONSTER)
    if not (value and (type(value) == "table")) then 
        local config = self:GetConfigByID(global.MMO.SETTING_IDX_IGNORE_MONSTER) 
        if config and config.names then 
            local names = G_GetSplitArray(config.names,"#")
            local t = {}
            for i,name in ipairs(names) do
                t[name] = 1
            end
            CHANGE_SETTING(global.MMO.SETTING_IDX_IGNORE_MONSTER, {t})
        end
    end

    -- boss提醒 
    local values = self:GetBossTipsValues()
    if not (values and #values>0) and not self._bossTipsSetting then 
        local config = self:GetConfigByID(global.MMO.SETTING_IDX_BOSS_TIPS) 
        if config and config.names then 
            local names = G_GetSplitArray(config.names,"#")
            local t = {}
            for i,name in ipairs(names) do
                table.insert(t,{name,1,"BOSS"})
            end
            self:SetBossTipsValues(t)
        end
    end

    local protect = 
    {    
        --人物   
        global.MMO.SETTING_IDX_HP_PROTECT1          , -- hp保护1
        global.MMO.SETTING_IDX_HP_PROTECT2          , -- hp保护2
        global.MMO.SETTING_IDX_HP_PROTECT3          , -- hp保护3
        global.MMO.SETTING_IDX_HP_PROTECT4          , -- hp保护4
        global.MMO.SETTING_IDX_MP_PROTECT1          , -- mp保护1
        global.MMO.SETTING_IDX_MP_PROTECT2          , -- mp保护2
        global.MMO.SETTING_IDX_MP_PROTECT3          , -- mp保护3
        global.MMO.SETTING_IDX_MP_PROTECT4          , -- mp保护4
        --hero
        global.MMO.SETTING_IDX_HERO_HP_PROTECT1     , -- hp保护1
        global.MMO.SETTING_IDX_HERO_HP_PROTECT2     , -- hp保护2
        global.MMO.SETTING_IDX_HERO_HP_PROTECT3     , -- hp保护3
        global.MMO.SETTING_IDX_HERO_HP_PROTECT4     , -- hp保护4
        global.MMO.SETTING_IDX_HERO_MP_PROTECT1     , -- mp保护1
        global.MMO.SETTING_IDX_HERO_MP_PROTECT2     , -- mp保护2
        global.MMO.SETTING_IDX_HERO_MP_PROTECT3     , -- mp保护3
        global.MMO.SETTING_IDX_HERO_MP_PROTECT4     , -- mp保护4
        --红名保护
        global.MMO.SETTING_IDX_PK_PROTECT           , --红名保护
    }
    for i,id in ipairs(protect) do
        local values = self:getRankData(id)
        local config =  self:GetConfigByID(id)
        local minTime = config and config.time or 1000
        if values and values.time and values.time < minTime then 
            values.time = minTime
        end
        self:setRankData(id,values)
    end

    self:SetFireEffectOpactiy()
end

function CHECK_GROUPSETTING_PICK(id)
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    return GameSettingProxy:GetPickGroupValue(id)
end

function CHANGE_GROUPSETTING_PICK(id, value)
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    GameSettingProxy:SetPickGroupValue(id, value)
end

function CHECK_SETTING_PICK(id)
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    return GameSettingProxy:GetPickValue(id)
end

function CHANGE_SETTING_PICK(id, value)
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    GameSettingProxy:SetPickValue(id, value)

    global.Facade:sendNotification(global.NoticeTable.GamePickSettingChange)
end

-- 检测掉落物显示
function CHECK_ITEM_DROP_SHOW(id)
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    local value = GameSettingProxy:GetPickValue(id)
    local groupid = GameSettingProxy:GetGroupIdByIndex(id)
    local groupOK = true
    if groupid then
        local groupvalue = GameSettingProxy:GetPickGroupValue(groupid)
        groupOK =  groupvalue[1] == 1
    end 
    return value[1] == 1 and groupOK
end

-- 检测手动拾取
function CHECK_ITEM_PICK(id)
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    local value = GameSettingProxy:GetPickValue(id)
    local groupid = GameSettingProxy:GetGroupIdByIndex(id)
    local groupOK = true
    if groupid then
        local groupvalue = GameSettingProxy:GetPickGroupValue(groupid)
        groupOK =  groupvalue[2] == 1
    end 
    return value[2] == 1 and groupOK
end

-- 检测自动拾取
function CHECK_ITEM_AUTO_PICK(id)
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    local value = GameSettingProxy:GetPickValue(id)
    local groupid = GameSettingProxy:GetGroupIdByIndex(id)
    local groupOK = true
    if groupid then
        local groupvalue = GameSettingProxy:GetPickGroupValue(groupid)
        groupOK =  groupvalue[3] == 1
    end 
    return value[3] == 1 and groupOK
end

-- 检测是否开启极品拾取
function CHECK_ITEM_QUALITY_PICK(id)
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    local value = GameSettingProxy:GetPickValue(id)
    local groupid = GameSettingProxy:GetGroupIdByIndex(id)
    local groupOK = true
    if groupid then
        local groupvalue = GameSettingProxy:GetPickGroupValue(groupid)
        groupOK =  groupvalue[4] == 1
    end 
    return value[4] == 1 and groupOK
end

function CHECK_ITEM_PICK_CANSET(id)
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    local value = GameSettingProxy:GetPickCanSet(id)
    return value
end

function GameSettingProxy:RequestSendFilterAutoPickItem()
    if not self._dataInited then
        self._needSendFilter = true
        return
    end
    local idxStr = ""
    local idxList = {}
    for id, v in pairs(self._pickData) do
        if v and v[3] == 0 then
            table.insert(idxList, id)
        end
    end
    for i, v in ipairs(self._itemConfig) do     -- 服务器的为默认配置
        if v.Index and not self._pickData[tostring(v.Index)] then
            if v.AutoPick and v.AutoPick == 0 then
                table.insert(idxList, v.Index)
            end
        end
    end
    if #idxList > 0 then
        idxStr = table.concat(idxList, ",")
    end
    LuaSendMsg(global.MsgType.MSG_CS_FILTER_PICKUP_ITEM, 0, 0, 0, 0, idxStr, string.len(idxStr))
end

function GameSettingProxy:RegisterMsgHandler()
    GameSettingProxy.super.RegisterMsgHandler(self)
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_SERVER_SAVE_MONSTER, handler(self, self.HandleServerSaveMonster))
end

function GameSettingProxy:SendMonsterIgnoreListToServer()
    local value = SL:GetValue("SETTING_ENABLED", (SLDefine.SETTINGID.SETTING_IDX_IGNORE_MONSTER))
    if value and type(value) == "table" then
        local monsterList = {}
        monsterList.id = global.MMO.SETTING_IDX_IGNORE_MONSTER
        monsterList.value = value
        local monsterStr = cjson.encode(monsterList)
        LuaSendMsg(global.MsgType.MSG_CS_SERVER_SAVE_MONSTER, 0, 0, 0, 0, monsterStr, string.len(monsterStr))
    end
end

function GameSettingProxy:HandleServerSaveMonster(msg)
    local header = msg:GetHeader()
    local len    = msg:GetDataLength()
    if len <= 0 then
        return false
    end
    local jsonData  = ParseRawMsgToJson(msg)
    if jsonData and jsonData.id == global.MMO.SETTING_IDX_IGNORE_MONSTER then
        CHANGE_SETTING(global.MMO.SETTING_IDX_IGNORE_MONSTER, {jsonData.value})
        self._hasServerMonsterData = true
    end
end

function CHECK_SETTING(id)
    local data   = GET_SETTING(id)
    local enable = data[1]
    return enable
end

function GET_SETTING(id)
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    return GameSettingProxy:GetValue(id)
end


local effectSet = {
    [SLDefine.SETTINGID.SETTING_IDX_FIRE_OPACITY] = 1
}

function CHANGE_SETTING(id, values)
    local data = GET_SETTING(id)
    for i = 1, 4 do
        if data and data[i] then
            values[i] = values[i] or data[i]
        end
    end
    
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    GameSettingProxy:SetValue(id, values)

    if effectSet[id] then
        GameSettingProxy:SetFireEffectOpactiy()
    end

    global.Facade:sendNotification(global.NoticeTable.GameSettingChange, {id = id, value = values})

    SLBridge:onLUAEvent(LUA_EVENT_SETTING_CHANGE, {id = id, values = values})
end

------------------------------------------------------
-- 举报
function GameSettingProxy:IsHideReportBtn()
    return self._hideReportBtn
end

function GameSettingProxy:SetHideReportBtn(state)
    self._hideReportBtn = state
end
------------------------------------------------------

------------------------------------------------------
-- 火墙透明度
function GameSettingProxy:SetFireEffectOpactiy()
    local values  = SL:GetValue("SETTING_VALUE", SLDefine.SETTINGID.SETTING_IDX_FIRE_OPACITY)
    local percent = (values and values[2]) and values[2] or 100
    self._fireEffectPercent = math.floor(percent / 100 * 255)
end

function GameSettingProxy:GetFireEffectOpactiy()
    return self._fireEffectPercent or 255
end
------------------------------------------------------

return GameSettingProxy
