local RemoteProxy = requireProxy("RemoteProxy")
local HeroSkillProxy = class("HeroSkillProxy", RemoteProxy)
HeroSkillProxy.NAME = global.ProxyTable.HeroSkillProxy

local bitBytes = {
    "I1", "I1", "I1", "I1", "I1",
    "i4", "i4", "i4", "i4", "i4", "i4", "i4", "i4", 
    "i4", "i4", "i4", "i4", "i4", "i4", "i4", "i4", "i4", "i4", "i4", "i4", "i4",
    "i8", "i8", "i8", "i8", "i8", "i8",
    "C50",
}

local bitKeys = {
    "Job", "HideCDHint", "SkillType", "SpellType", "IgornAct",
    "Key", "Level", "LevelUp", "LevelUpIcon", "CurTrain", "MagicID", "EffectType", "Effect", 
    "TrainLevel1", "TrainLevel2", "TrainLevel3", "TrainLevel4", "MaxTrain1", "MaxTrain2", "MaxTrain3", "MaxTrain4", "TrainLv", "DelayTimeEX", "DelayTime", "ActionId", "LJBJRate",
    "Spell", "Power", "DefSpell", "DefPower", "DefMaxPower", "MaxPower",
    "Name"
}

local function parseOneSkillData(data)
    data.id = data.MagicID
    data.DelayTime = data.DelayTime or 0
    
    -- extension
    data.isCD = false
    data.curTime = 0
    return data
end

function HeroSkillProxy:ctor()
    HeroSkillProxy.super.ctor(self)
    
    self._data = {}
    self._configs = {}
    self._heroSkillID = nil
    self:Init()
end

function HeroSkillProxy:Init()
    self._skills           = {}          -- 所有拥有技能
    self._ngSkills         = {}          -- 所有拥有内功技能
    self._setComboSkill    = {}          -- 设置加入连击的连击技能
    self._comboSkills      = {}          -- 所有拥有的连击技能
    self._openComboNum     = 3           -- 默认开启连击设置格子数
end

function HeroSkillProxy:LoadConfig()
    SL:Print("[Require game_config] ", "cfg_magicinfo")
    self._configs = SL:RequireFile("game_config/cfg_magicinfo")
end

-- 技能配置
function HeroSkillProxy:GetConfigs()
    return self._configs
end

function HeroSkillProxy:FindConfigBySkillID(skillID)
    return self._configs[skillID]
end

function HeroSkillProxy:FindAllSkillsByJob(job)
    if not job then
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        job = PlayerProperty:GetRoleJob()
    end

    local items = {}
    local n = 0
    for i = 1, self._nums do
        local skill = self._configs[i]
        if skill and (skill.job == job or skill.job == 3 or job == 3) then
            n = n + 1
            items[n] = skill
        end
    end

    return items, n
end

-- 获取技能名字
function HeroSkillProxy:GetSkillNameByID(skillID)
    local config = self:FindConfigBySkillID(skillID)
    if not config then
        return "ERROR SKILL NAME"
    end
    return config.HeroMagicName
end

-- 获取技能Icon 圆形
function HeroSkillProxy:GetIconPathByID(skillID, isCombo)
    if skillID == 0 then
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        if PlayerInputProxy:CheckMiningAble() then
            skillID = 999
        end
    end

    local config = self:FindConfigBySkillID(skillID)
    if not config then
        local path = string.format("%s%s.jpg", global.MMO.PATH_RES_SKILL_ICON_C, "default")
        if global.FileUtilCtl:isFileExist(path) then
            return path
        end
        return string.format("%s%s.png", global.MMO.PATH_RES_SKILL_ICON_C, "default")
    end

    local data = isCombo and self:GetComboSkillByID(skillID) or self:GetSkillByID(skillID)
    if not data or not data.LevelUpIcon or data.LevelUpIcon <= 0 then
        local path = string.format("%s%s.jpg", global.MMO.PATH_RES_SKILL_ICON_C, config.icon)
        if global.FileUtilCtl:isFileExist(path) then
            return path
        end
        return string.format("%s%s.png", global.MMO.PATH_RES_SKILL_ICON_C, config.icon)
    end

    local path = string.format("%s%s_%s.jpg", global.MMO.PATH_RES_SKILL_ICON_C, config.icon, data.LevelUpIcon)
    if global.FileUtilCtl:isFileExist(path) then
        return path
    end

    return string.format("%s%s_%s.png", global.MMO.PATH_RES_SKILL_ICON_C, config.icon, data.LevelUpIcon)
end

-- 获取技能Icon 矩形
function HeroSkillProxy:GetIconRectPathByID(skillID, isCombo)
    local config = self:FindConfigBySkillID(skillID)
    if not config then
        local path = string.format("%s%s.png", global.MMO.PATH_RES_SKILL_ICON, "default")
        if global.FileUtilCtl:isFileExist(path) then
            return path
        end
        return string.format("%s%s.jpg", global.MMO.PATH_RES_SKILL_ICON, "default")
    end

    local data = isCombo and self:GetComboSkillByID(skillID) or self:GetSkillByID(skillID)
    if not data or not data.LevelUpIcon or data.LevelUpIcon <= 0 then
        local path = string.format("%s%s.png", global.MMO.PATH_RES_SKILL_ICON, config.icon)
        if global.FileUtilCtl:isFileExist(path) then
            return path
        end
        return string.format("%s%s.jpg", global.MMO.PATH_RES_SKILL_ICON, config.icon)
    end

    local path = string.format("%s%s_%s.png", global.MMO.PATH_RES_SKILL_ICON, config.icon, data.LevelUpIcon)
    if global.FileUtilCtl:isFileExist(path) then
        return path
    end

    return string.format("%s%s_%s.jpg", global.MMO.PATH_RES_SKILL_ICON, config.icon, data.LevelUpIcon)
end

-- 技能数据
function HeroSkillProxy:GetSkills(noBasicSkill, activeOnly)
    -- 已有技能数据 param1:是否排除普攻  param2:是否只获取主动技能
    local skillMaps = {}
    local skills = {}
    local n = 0
    for _, v in pairs(self._skills) do
        if (noBasicSkill and v.MagicID == global.MMO.SKILL_INDEX_BASIC) or (activeOnly and false == self:IsActiveSkill(v.MagicID)) then
        else
            skillMaps[v.MagicID] = v
            
            n = n + 1
            skills[n] = v
        end
    end
    return skillMaps, skills, n
end

function HeroSkillProxy:IsActiveSkill(skillID)
    local config = self:FindConfigBySkillID(skillID)
    if not config then
        return false
    end
    return config.type == 1
end

-- 获取技能数据
function HeroSkillProxy:GetSkillByID(skillID)
    return self._skills[skillID]
end

function HeroSkillProxy:DelAllSkill()
    self._skills = {}
    self._heroSkillID   = nil
    self._ngSkills      = {}          
    self._setComboSkill = {}
    self._comboSkills   = {}
end

function HeroSkillProxy:GetLevel(skillID)
    -- 技能等级
    local data = self:GetSkillByID(skillID)
    if data then
        return data.Level
    end
    return -1
end

function HeroSkillProxy:AddSkill(data, bIsInit)
    --增加技能
    -- dump(data)
    if not data then
        return false
    end
    if self._skills[data.MagicID] then
        return false
    end
    if not self:FindConfigBySkillID(data.MagicID) then
        print("add skill error, skill config is nil " .. data.MagicID)
        return false
    end

    if self:isHeroSkill(data.MagicID) then
        self._heroSkillID = data.MagicID
    end

    -- 增加技能  
    self._skills[data.MagicID] = data

    SLBridge:onLUAEvent(LUA_EVENT_HERO_SKILL_ADD, data)

    -- 判断一遍合击技能是否是可以是否状态
    SLBridge:onLUAEvent(LUA_EVENT_HERO_ANGER_CHANGE, {forceRefresh = true})
end

function HeroSkillProxy:DelSkill(skillID, bIsInit)
    --删除技能
    if not skillID then
        return false
    end
    if not self._skills[skillID] then
        return false
    end

    -- 删除技能
    local data = self._skills[skillID]
    self._skills[skillID] = nil
    if self:isHeroSkill(skillID) then
        self._heroSkillID = nil
    end

    SLBridge:onLUAEvent(LUA_EVENT_HERO_SKILL_DEL, data)
end

function HeroSkillProxy:UpdateSkillData(data)
    -- 更新技能数据
    if not data then
        return
    end
    if not data.skillID then
        return nil
    end
    local skill = self:GetSkillByID(data.skillID)
    if not skill then
        return nil
    end

    -- 更新技能属性
    for k, v in pairs(data) do
        skill[k] = v
    end

    SLBridge:onLUAEvent(LUA_EVENT_HERO_SKILL_UPDATE, skill)
end

function HeroSkillProxy:GetSkillTrainData(skillID)
    -- 技能等级>3的全部特殊处理下
    local maxStr = "-"
    if not skillID or not self._skills[skillID] then
        return maxStr
    end
    if skillID == global.MMO.SKILL_INDEX_BASIC then
        return maxStr
    end
    local skillData     = self._skills[skillID]
    local isBaseSkill   = skillData.Level <= 3
    local skillLevel    = skillData.Level
    local maxSkillLevel = skillData.TrainLv
    if isBaseSkill and skillLevel >= maxSkillLevel then
        return maxStr
    end
    local skillMaxTrain = {
        [0] = skillData.MaxTrain1,
        [1] = skillData.MaxTrain2,
        [2] = skillData.MaxTrain3,
        [3] = skillData.MaxTrain4
    }
    local curTrain = skillData.CurTrain or 0
    local maxTrain = (isBaseSkill and skillMaxTrain[skillLevel] or skillData.MaxTrain1) or 0
    local str = curTrain >= maxTrain and maxStr or string.format(GET_STRING(1053), curTrain, maxTrain)
    return str
end

--是否使用技能书 通过书名
function HeroSkillProxy:CheckAbleToUseBookByName(bookname)
    local skills, nSkills = self:FindAllSkillsByJob()
    local skillID = nil

    for i = 1, nSkills do
        local skill = skills[i]
        if skill and skill.magicName == bookname then
            skillID = skill.MagicID
            break
        end
    end

    if not skillID then
        return false
    end

    -- 已学习
    if self:IsLearned(skillID) then
        return false
    end

    return true
end

-- 是否已经学习
function HeroSkillProxy:IsLearned(skillID)
    local skillData = self:GetSkillByID(skillID)
    return skillData and true or false
end

-- MP 是否满足
function HeroSkillProxy:IsEnoughMana(skillID)
    local skill = self:GetSkillByID(skillID)
    if not skill then
        return false
    end
    if not skill.Spell or not skill.DefSpell then
        -- 没有告诉我是否耗蓝
        return true
    end

    local propertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local currMP = propertyProxy:GetRoleCurMP()
    return currMP and currMP >= (skill.Spell + skill.DefSpell)
end

-- skill key
function HeroSkillProxy:GetSkillKey(skillID)
    if not skillID then
        return nil
    end
    local skill = self:GetSkillByID(skillID)
    if not skill then
        return nil
    end
    return skill.Key
end

function HeroSkillProxy:SetSkillKey(skillID, key)
    if not skillID then
        return nil
    end
    local skill = self:GetSkillByID(skillID)
    if not skill then
        return nil
    end
    skill.Key  = key
    self:sendMCMessage(skillID, key, 0)
end

-- skill 开关
function HeroSkillProxy:GetNGSkillOnOff(skillID, skillType)
    if not skillID then
        return nil
    end
    local skill = self:GetNGSkillData(skillID, skillType)
    if not skill then
        return nil
    end
    return skill.Key
end

function HeroSkillProxy:SetNGSkillOnOff(skillID, skillType, key)
    if not skillID then
        return nil
    end
    local skill = self:GetNGSkillData(skillID, skillType)
    if not skill then
        return nil
    end
    skill.Key  = key
    self:sendMCMessage(skillID, key, 1, skillType)
end

--key 0 开启 1关闭
--type 0英雄 1内功 2连击
--skillType 0=人物技能, 1=英雄技能 2=人物怒内功技能  3=英雄怒内功技能  4=人物静内功技能  5=英雄静内功技能   6=人物连击技能 7=英雄连击技能
function HeroSkillProxy:sendMCMessage(skillID, key, type, ngType)
    local skillType = 0
    if type == 0 then
        skillType = 1
    elseif type == 1 and ngType then
        skillType = ngType
    end
    LuaSendMsg(global.MsgType.MSG_CS_PLAYER_ONOFF_SKILL_HERO, skillID, key, skillType, 0)
end

function HeroSkillProxy:RespPlayerSkillDataHero(netPkg)
    local data = netPkg:GetBodyValues(bitBytes, bitKeys) or {}
    for i=1, #data do
        local skill = parseOneSkillData(data[i])
        --  人物连击技能
        if skill.SkillType == 7 then
            -- LJBJRate 连击暴击几率
            self._comboSkills[skill.MagicID] = skill
            SLBridge:onLUAEvent(LUA_EVENT_HERO_COMBO_SKILL_ADD, skill)
        else
            self:AddSkill(skill, true)
        end
    end
end

function HeroSkillProxy:RespPlayerAddSkillHero(netPkg)
    local data = netPkg:GetBodyValues2(bitBytes, bitKeys) or {}
    local skill = parseOneSkillData(data)

    -- 英雄连击技能
    if skill.SkillType == 7 then
        self._comboSkills[skill.MagicID] = skill
        SLBridge:onLUAEvent(LUA_EVENT_HERO_COMBO_SKILL_ADD, skill)
    else
        self:AddSkill(skill, false)
    end
end

-- 删除技能
function HeroSkillProxy:RespPlayerDelSkillHero(netPkg)
    local skillID, skillType = netPkg:GetHeadValues({"i4", "i4"})

    -- 英雄连击技能
    if skillType == 7 then
        local data = self._comboSkills[skillID]
        if data then
            self._comboSkills[skillID] = nil
            SLBridge:onLUAEvent(LUA_EVENT_HERO_COMBO_SKILL_DEL, data)
        end
    else
        self:DelSkill(skillID)
    end
end

function HeroSkillProxy:RespPlayerUpdateSkillHero(netPkg)
    -- 技能ID、技能等级、强化等级、熟练度、强化图标、技能类型、连击技能爆率
    local headers = {netPkg:GetHeadValues({"i4", "i4", "i4", "i4", "i4", "i4", "i4"})}

    local data = {
        skillID     = headers[1], 
        Level       = headers[2], 
        LevelUp     = headers[3], 
        CurTrain    = headers[4], 
        LevelUpIcon = headers[5],
        LJBJRate    = headers[7] 
    }

    local skillType = headers[6]
    if skillType == 7 then
        -- 人物连击
        self:UpdateComboSkillData(data)
    elseif skillType == 2 or skillType == 4 then
        -- 人物内功
        self:UpdateNGSkillData(data, skillType)
    else
        self:UpdateSkillData(data)
    end
end

-- 是否拥有英雄技能 返回技能id
function HeroSkillProxy:haveHeroSkill()
    return self._heroSkillID
end

-- 是否是英雄技能 返回技能id  60-65
function HeroSkillProxy:isHeroSkill(skillID)
    local skillbegin = 60
    local res = false
    for i = 0,5 do
        if skillbegin + i == skillID then
            res = skillID
            break
        end
    end
    return res
end

--------------------------- 内功技能 ----------------------------------
function HeroSkillProxy:GetNGSkills()
    return self._ngSkills
end

function HeroSkillProxy:GetNGSkillsList()
    local list = {}
    for _, data in pairs(self._ngSkills) do
        for i, skill in pairs(data) do
            table.insert(list, skill)
        end
    end
    table.sort(list, function(a, b)
        if a.MagicID ~= b.MagicID then
            return a.MagicID < b.MagicID
        end
        return a.SkillType < b.SkillType
    end)
    return list
end

function HeroSkillProxy:GetNGSkillData(skillID, skillType)
    return self._ngSkills[skillType] and self._ngSkills[skillType][skillID]
end

-- skillType 3=英雄怒内功技能 5=英雄静内功技能
function HeroSkillProxy:GetNGSkillName(skillID, skillType)
    local config = self:FindConfigBySkillID(skillID)
    if not config then
        return "ERROR SKILL NAME"
    end
    if skillType == 3 then
        return config.nMagicName
    elseif skillType == 5 then
        return config.jMagicName
    end
end

function HeroSkillProxy:GetNGSkillDesc(skillID, skillType)
    local config = self:FindConfigBySkillID(skillID)
    if not config then
        return "ERROR SKILL DESC"
    end
    if skillType == 3 then
        return config.nDesc
    elseif skillType == 5 then
        return config.jDesc
    end
end

-- 获取内功技能Icon 矩形
function HeroSkillProxy:GetNGIconRectPath(skillID, skillType)
    local config = self:FindConfigBySkillID(skillID)
    if not config then
        local path = string.format("%s%s.png", global.MMO.PATH_RES_SKILL_ICON, "default")
        if global.FileUtilCtl:isFileExist(path) then
            return path
        end
        return string.format("%s%s.jpg", global.MMO.PATH_RES_SKILL_ICON, "default")
    end

    local data = self:GetNGSkillData(skillID, skillType)
    local icon = nil 
    if skillType == 3 then  -- 怒
        icon = config.nIcon
    elseif skillType == 5 then  -- 静
        icon = config.jIcon
    end
    icon = icon or config.icon
    if not data or not data.LevelUpIcon or data.LevelUpIcon <= 0 then
        
        local path = string.format("%s%s.png", global.MMO.PATH_RES_SKILL_ICON, icon)
        if global.FileUtilCtl:isFileExist(path) then
            return path
        end
        return string.format("%s%s.jpg", global.MMO.PATH_RES_SKILL_ICON, icon)
    end

    local path = string.format("%s%s_%s.png", global.MMO.PATH_RES_SKILL_ICON, icon, data.LevelUpIcon)
    if global.FileUtilCtl:isFileExist(path) then
        return path
    end

    return string.format("%s%s_%s.jpg", global.MMO.PATH_RES_SKILL_ICON, icon, data.LevelUpIcon)
end

function HeroSkillProxy:GetNGSkillTrainData(skillID, skillType)
    -- 技能等级>3的全部特殊处理下
    local maxStr = "-"
    if not skillID or not self._ngSkills[skillType] or not self._ngSkills[skillType][skillID] then
        return maxStr
    end
    if skillID == global.MMO.SKILL_INDEX_BASIC then
        return maxStr
    end
    local skillData     = self._ngSkills[skillType][skillID]
    local isBaseSkill   = skillData.Level <= 3
    local skillLevel    = skillData.Level
    local maxSkillLevel = skillData.TrainLv
    if skillLevel >= maxSkillLevel then
        return maxStr
    end
    local skillMaxTrain = {
        [0] = skillData.MaxTrain1,
        [1] = skillData.MaxTrain2,
        [2] = skillData.MaxTrain3,
        [3] = skillData.MaxTrain4
    }
    local curTrain = skillData.CurTrain or 0
    local maxTrain = (isBaseSkill and skillMaxTrain[skillLevel] or skillData.MaxTrain1) or 0
    return curTrain >= maxTrain and maxStr or string.format(GET_STRING(1053), curTrain, maxTrain)
end

-- 更新技能数据
function HeroSkillProxy:UpdateNGSkillData(data, skillType)
    if not data then
        return
    end
    if not data.skillID then
        return nil
    end
    local skill = self:GetNGSkillData(data.skillID, skillType)
    if not skill then
        return nil
    end

    -- 更新技能属性
    for k, v in pairs(data) do
        skill[k] = v
    end
    SLBridge:onLUAEvent(LUA_EVENT_HERO_INTERNAL_SKILL_UPDATE, skill)
end

function HeroSkillProxy:RespHeroNGSkillData(netPkg)
    local data = netPkg:GetBodyValues(bitBytes, bitKeys) or {}
    for i=1, #data do
        local skill = parseOneSkillData(data[i])
        self._ngSkills[skill.SkillType] = self._ngSkills[skill.SkillType] or {}
        self._ngSkills[skill.SkillType][skill.MagicID] = skill
    end
end

function HeroSkillProxy:RespHeroAddNGSkill(netPkg)
    local data = netPkg:GetBodyValues2(bitBytes, bitKeys) or {}

    local skill = parseOneSkillData(data)
    self._ngSkills[skill.SkillType] = self._ngSkills[skill.SkillType] or {}
    self._ngSkills[skill.SkillType][skill.MagicID] = skill
    SLBridge:onLUAEvent(LUA_EVENT_HERO_INTERNAL_SKILL_ADD, skill)
end

-- 删除技能
function HeroSkillProxy:RespHeroDelNGSkill(netPkg)
    local skillID, skillType = netPkg:GetHeadValues({"i4", "i4"})

    if not self._ngSkills[skillType] then
        return false
    end

    local data = self._ngSkills[skillType][skillID]
    if not data then
        return false
    end
    
    self._ngSkills[skillType][skillID] = nil
    SLBridge:onLUAEvent(LUA_EVENT_HERO_INTERNAL_SKILL_DEL, data)
end

--------------------------- 连击技能 ----------------------------------
function HeroSkillProxy:haveSetComboSkill()
    return self._setComboSkill
end

function HeroSkillProxy:SetComboSkill(idx, skillID)
    self._setComboSkill[idx] = skillID
end

function HeroSkillProxy:GetComboSkills()
    return self._comboSkills
end

-- 获取技能数据
function HeroSkillProxy:GetComboSkillByID(skillID)
    return self._comboSkills[skillID]
end

function HeroSkillProxy:GetComboSkillTrainData(skillID)
    -- 技能等级>3的全部特殊处理下
    local maxStr = "-"
    if not skillID or not self._comboSkills[skillID] then
        return maxStr
    end
    local skillData     = self._comboSkills[skillID]
    local isBaseSkill   = skillData.Level <= 3
    local skillLevel    = skillData.Level
    local maxSkillLevel = skillData.TrainLv
    if skillLevel >= maxSkillLevel then
        return maxStr
    end
    local skillMaxTrain = {
        [0] = skillData.MaxTrain1,
        [1] = skillData.MaxTrain2,
        [2] = skillData.MaxTrain3,
        [3] = skillData.MaxTrain4
    }
    local curTrain = skillData.CurTrain or 0
    local maxTrain = (isBaseSkill and skillMaxTrain[skillLevel] or skillData.MaxTrain1) or 0
    return curTrain >= maxTrain and maxStr or string.format(GET_STRING(1053), curTrain, maxTrain)
end

function HeroSkillProxy:SetComboOpenNum(openNum)
    self._openComboNum = openNum
end

function HeroSkillProxy:GetComboOpenNum()
    return self._openComboNum
end

-- 更新技能数据
function HeroSkillProxy:UpdateComboSkillData(data)
    if not data then
        return
    end
    if not data.skillID then
        return nil
    end
    local skill = self:GetComboSkillByID(data.skillID)
    if not skill then
        return nil
    end

    -- 更新技能属性
    for k, v in pairs(data) do
        skill[k] = v
    end
    SLBridge:onLUAEvent(LUA_EVENT_HERO_COMBO_SKILL_UPDATE, skill)
end

--------------------------------------------------------------------------

function HeroSkillProxy:RegisterMsgHandler()
    HeroSkillProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_SKILL_DATA_HERO, handler(self, self.RespPlayerSkillDataHero))        -- 已学技能 信息
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_ADD_SKILL_HERO,  handler(self, self.RespPlayerAddSkillHero))         -- 新增技能
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_DEL_SKILL_HERO,  handler(self, self.RespPlayerDelSkillHero))         -- 删除技能
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_UP_SKILL_HERO,   handler(self, self.RespPlayerUpdateSkillHero))      -- 技能数据更新

    LuaRegisterMsgHandler(msgType.MSG_SC_HERO_NG_SKILL_DATA,     handler(self, self.RespHeroNGSkillData))            -- 内功技能
    LuaRegisterMsgHandler(msgType.MSG_SC_HERO_ADD_NG_SKILL,      handler(self, self.RespHeroAddNGSkill))
    LuaRegisterMsgHandler(msgType.MSG_SC_HERO_DEL_NG_SKILL,      handler(self, self.RespHeroDelNGSkill))
end

return HeroSkillProxy
