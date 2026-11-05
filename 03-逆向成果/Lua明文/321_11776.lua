local monsterManager = class('gameActorMonster')

function monsterManager:ctor()
    self.mMonstersInCurrViewFieldMap = {}
    self.mMonstersInCurrViewField = {}
    self.mMonstersIndexMap = {}
    self.mMonsterCount = 0

    self._config = {}
    self._monAttackConfig = {}
    self:LoadConfig()
end

function monsterManager:destory()
end

function monsterManager:create()
    local _this = monsterManager.new()
    return _this
end

function monsterManager:LoadConfig()
    local config = {}
    local filePath = "scripts/game_config/cfg_monster.lua"
    if SL:IsFileExist(filePath) then
        SL:Print("[Require game_config] ", "cfg_monster")
        config = SL:RequireFile(filePath)
    end
    if config and next(config) then
        for i, data in pairs(config) do
            if data.effectid and string.len(data.effectid) > 0 then
                local icons = {}
                local paramList = G_GetSplitArray(data.effectid, "&")
                for i, params in ipairs(paramList) do
                    if string.len(params) > 0 then
                        local data = G_GetSplitArray(params, "#")
                        if tonumber(data[1]) then
                            local pos = i - 1
                            icons[pos] = {}
                            icons[pos].Id = pos
                            icons[pos].effType = 1
                            icons[pos].effSrc = tonumber(data[1]) or 0
                            icons[pos].X = tonumber(data[2]) or 0
                            icons[pos].iY = tonumber(data[3]) or 0
                            icons[pos].height = tonumber(data[4]) or 0 -- 自动补全空白位置0,1(0=掉 1=不掉) 无效  大于1 当长度 自动排序忽视Y
                            icons[pos].after = tonumber(data[5]) or 0 -- 增加播放在怪物前面和后面参数
                        end
                    end
                end
                if next(icons) then
                    data.effectList = icons
                end
            end

            if data.Hide and string.len(data.Hide) > 0 then
                local params        = G_GetSplitArray(data.Hide,"#")
                data.noShowName     = tonumber(params[1])
                data.noShowHPBar    = tonumber(params[2])
            end
        end
        self._config = config
    end

    local monattackConfig = {}
    local filePath = "scripts/game_config/cfg_monattack.lua"
    if SL:IsFileExist(filePath) then
        SL:Print("[Require game_config] ", "cfg_monattack")
        monattackConfig = SL:RequireFile(filePath)
    end

    for _act,_attck_cfg in pairs(monattackConfig or {}) do
        local array = string.split(_attck_cfg.attck_models or "", "#")
        if array[2] and tonumber(array[2]) and tonumber(_act) then
            self._monAttackConfig[tonumber(_act)] = {
                monsterDir    = tonumber(array[1]) or 0,
                monsterEff1   = tonumber(array[2]),
                monsterEff2   = tonumber(array[3]),
                monsterEff3   = tonumber(array[4]),
            }
        end
    end
end

function monsterManager:ReloadConfig()
    self._config = {}
    self._monAttackConfig = {}
    self:LoadConfig()
end

function monsterManager:GetMonAttackByAct( act )
    return self._monAttackConfig[act]
end

function monsterManager:GetConfigById(typeIndex)
    if not next(self._config) or not typeIndex then
        return nil
    end
    return self._config[typeIndex]
end

function monsterManager:GetTypeById(typeIndex)
    local data = self:GetConfigById(typeIndex)
    if not data then
        return nil
    end
    return data.Type
end

function monsterManager:GetBigIconIDById(typeIndex)
    local data = self:GetConfigById(typeIndex)
    if not data then
        return nil
    end
    return data.nBigTips
end

function monsterManager:GetHudIconsById(typeIndex)
    local data = self:GetConfigById(typeIndex)
    if not data then
        return nil
    end
    return data.effectList
end

function monsterManager:GetHideNameById(typeIndex)
    local data = self:GetConfigById(typeIndex)
    if not data then
        return nil
    end
    return data.noShowName
end

function monsterManager:GetHideHPBarById(typeIndex)
    local data = self:GetConfigById(typeIndex)
    if not data then
        return nil
    end
    return data.noShowHPBar
end

function monsterManager:Cleanup()
    self.mMonstersInCurrViewFieldMap = {}
    self.mMonstersInCurrViewField = {}
    self.mMonstersIndexMap = {}
    self.mMonsterCount = 0
end

function monsterManager:GetMonsterCount()
    return self.mMonsterCount
end

function monsterManager:AddMonster(monster)
    if not monster then
        return false
    end

    local monsterID = monster:GetID()

    if self.mMonstersInCurrViewFieldMap[monsterID] then
        return false
    end

    self.mMonsterCount = self.mMonsterCount + 1

    local n = self.mMonsterCount

    self.mMonstersIndexMap[monsterID] = n

    self.mMonstersInCurrViewField[n] = monster

    self.mMonstersInCurrViewFieldMap[monsterID] = monster
end

function monsterManager:RmvMonster(monsterID)
    local monster = self.mMonstersInCurrViewFieldMap[monsterID]

    if not monster then
        return false
    end

    self.mMonstersInCurrViewFieldMap[monsterID] = nil

    local index = self.mMonstersIndexMap[monsterID]

    if index == self.mMonsterCount then
        self.mMonstersInCurrViewField[index] = nil
    else
        -- last index --> index
        local lastActor = self.mMonstersInCurrViewField[self.mMonsterCount]
        self.mMonstersInCurrViewField[index] = lastActor
        self.mMonstersIndexMap[lastActor:GetID()] = index

        -- reset last value
        self.mMonstersInCurrViewField[self.mMonsterCount] = nil
    end

    self.mMonstersIndexMap[monsterID] = nil
    self.mMonsterCount = self.mMonsterCount - 1
end

function monsterManager:GetAllMonsterInCurrViewField()
    return self.mMonstersInCurrViewField, self.mMonsterCount
end

function monsterManager:FindAllMonsterIDInCurrViewField(noPetOfMainPlayer, noPetOfNetPlayer)
    if nil == noPetOfMainPlayer then
        noPetOfMainPlayer = false
    end

    if nil == noPetOfNetPlayer then
        noPetOfNetPlayer = true
    end

    local playerID = global.gamePlayerController:GetMainPlayerID()
    local recvVec = {}
    local num = 0

    for i = 1, self.mMonsterCount do
        local m = self.mMonstersInCurrViewField[i]
        if m then
            if (noPetOfMainPlayer and playerID == m:GetMasterID()) or (noPetOfNetPlayer and m:IsHaveMaster()) then
            else
                num = num + 1
                recvVec[num] = m:GetID()
            end
        end
    end

    return recvVec, num
end

function monsterManager:FindAllMonsterInCurrViewField(noPetOfMainPlayer, noPetOfNetPlayer)
    if nil == noPetOfMainPlayer then
        noPetOfMainPlayer = false
    end

    if nil == noPetOfNetPlayer then
        noPetOfNetPlayer = true
    end

    local playerID = global.gamePlayerController:GetMainPlayerID()
    local recvVec = {}
    local num = 0

    for i = 1, self.mMonsterCount do
        local m = self.mMonstersInCurrViewField[i]
        if m then
            if (noPetOfMainPlayer and playerID == m:GetMasterID()) or (noPetOfNetPlayer and m:IsHaveMaster()) then
            else
                num = num + 1
                recvVec[num] = m
            end
        end
    end

    return recvVec, num
end

function monsterManager:FindMonsterInCurrViewFieldByTypeIndex(typeIndex, noPetOfMainPlayer, noPetOfNetPlayer)
    if nil == noPetOfMainPlayer then
        noPetOfMainPlayer = false
    end

    if nil == noPetOfNetPlayer then
        noPetOfNetPlayer = true
    end

    local playerID = global.gamePlayerController:GetMainPlayerID()
    local recvVec = {}
    local num = 0

    for i = 1, self.mMonsterCount do
        local m = self.mMonstersInCurrViewField[i]
        if m and m:GetTypeIndex() == typeIndex then
            if (noPetOfMainPlayer and playerID == m:GetMasterID()) or (noPetOfNetPlayer and m:IsHaveMaster()) then
            else
                num = num + 1
                recvVec[num] = m
            end
        end
    end

    return recvVec, num
end

function monsterManager:FindMonsterInCurrViewFieldByTypeIndexTable(typeIndexTable, noPetOfMainPlayer, noPetOfNetPlayer)
    if nil == noPetOfMainPlayer then
        noPetOfMainPlayer = false
    end

    if nil == noPetOfNetPlayer then
        noPetOfNetPlayer = true
    end

    local playerID = global.gamePlayerController:GetMainPlayerID()
    local recvVec = {}
    local num = 0

    for i = 1, self.mMonsterCount do
        local m = self.mMonstersInCurrViewField[i]
        if m then
            for _, typeIndex in pairs(typeIndexTable) do
                if m:GetTypeIndex() == typeIndex then
                    if (noPetOfMainPlayer and playerID == m:GetMasterID()) or (noPetOfNetPlayer and m:IsHaveMaster()) then
                    else
                        num = num + 1
                        recvVec[num] = m
                    end
                end
            end
        end
    end

    return recvVec, num
end

function monsterManager:FindMonsterInCurrViewFieldByRace(race)
    local recvVec = {}
    local num = 0

    for i = 1, self.mMonsterCount do
        local m = self.mMonstersInCurrViewField[i]
        if m and m:GetRace() == race then
            num = num + 1
            recvVec[num] = m
        end
    end

    return recvVec, num
end

function monsterManager:FindMonsterIDInCurrViewFieldByRace(race)
    local recvVec = {}
    local num = 0

    for i = 1, self.mMonsterCount do
        local m = self.mMonstersInCurrViewField[i]
        if m and m:GetRace() == race then
            num = num + 1
            recvVec[num] = m:GetID()
        end
    end

    return recvVec, num
end

function monsterManager:FindMonsterIDInCurrViewFieldByTypeIndex(param, noPetOfMainPlayer, noPetOfNetPlayer)
    if nil == noPetOfMainPlayer then
        noPetOfMainPlayer = false
    end

    if nil == noPetOfNetPlayer then
        noPetOfNetPlayer = true
    end

    local playerID = global.gamePlayerController:GetMainPlayerID()
    local recvVec = {}
    local num = 0

    if type(param) == "number" then
        for i = 1, self.mMonsterCount do
            local m = self.mMonstersInCurrViewField[i]
            if m and m:GetTypeIndex() == param then
                if (noPetOfMainPlayer and playerID == m:GetMasterID()) or (noPetOfNetPlayer and m:IsHaveMaster()) then
                else
                    num = num + 1
                    recvVec[num] = m:GetID()
                end
            end
        end
    elseif type(param) == "table" then
        for i = 1, self.mMonsterCount do
            local m = self.mMonstersInCurrViewField[i]
            if m then
                for j = 1, #param do
                    local typeIndex = param[j]
                    if m:GetTypeIndex() == typeIndex then
                        if (noPetOfMainPlayer and playerID == m:GetMasterID()) or (noPetOfNetPlayer and m:IsHaveMaster()) then
                        else
                            num = num + 1
                            recvVec[num] = m:GetID()
                        end
                    end
                end
            end
        end
    end

    return recvVec, num
end

return monsterManager
