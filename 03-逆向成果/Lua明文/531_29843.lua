local RemoteProxy = requireProxy("RemoteProxy")
local HeroPropertyProxy = class("HeroPropertyProxy", RemoteProxy)
HeroPropertyProxy.NAME = global.ProxyTable.HeroPropertyProxy
local cjson            = require("cjson")

local shareLevelT      = {}
local shareLevelD      = {}
local shareReLevelT    = {}
local shareHMPT        = {}
local shareExpT        = {}
local shareNGT         = {}
local shareWightT      = {}
local shareNGLevelT    = {}
local shareNGExpT      = {}
local shareDZValueT    = {}
local shareAbilChangeT = {}

local shareAbilPZ      = {}

function HeroPropertyProxy:ctor()
    HeroPropertyProxy.super.ctor(self)


    self._data = {}
    self._arrCurAbil = {}       -- 基础属性
    self._arrMaxAbil = {}       -- 最大属性

    self._lastArrCurAbil = {}   -- 上一次的基础属性
    self._lastArrMaxAbil = {}   -- 上一次的最大属性

    self._arrAbilIndexs  = {}   
    self._nArrAbilIndex  = {}

    self._lastAttr = {}


    self._herologin    = false -- 英雄是否出生
    self._guardState   = false
    self._isInited     = false
    self._isAlive      = true

    self._feature =  
    {
        clothID           = 0,
        weaponID          = 0,
        shieldID          = 0,
        wingsID           = 0,
        hairID            = 0,
        leftWeaponID      = 0,
    }
    self._internalData  = {}          -- 内功数据

    self._attribute        = {}
    self._lockTargetID = nil


    ---怒气
    self._angerMax = 0  -- 最大怒气
    self._angerCur = 0  -- 当前怒气
    self._shan = false  -- 是否要闪
    self._speed = 10
    self._delayTime = 1
    -----
    self._heroID = nil

    self._loginCD = 30

    self._loginCDTime = 0

    self._lastJob = -1
end

function HeroPropertyProxy:initConfig()
    self.m_states = self:getStatesSysSet()--手机版点击快捷切换状态 战斗 跟随 休息 守护 0-3
    local localdata = self:readLocalData()
    if localdata then
        self.m_states = localdata
    end
end

function HeroPropertyProxy:getStatesSysSet()--Heroqiehuan 三个或四个
    if self._Statesysset then
        return self._Statesysset
    end
    self._Statesysset = {}
    if global.ConstantConfig and SL:GetValue("GAME_DATA","Heroqiehuan") then
        local strs = G_GetSplitArray(SL:GetValue("GAME_DATA","Heroqiehuan"), "#")
        for i, v in ipairs(strs) do
            local num = tonumber(v)
            table.insert(self._Statesysset, num and num - 1 or nil)
        end
    else
        self._Statesysset = { 0, 1, 2, 3 }
    end
    return clone(self._Statesysset)
end

function HeroPropertyProxy:setCD(cd)
    self._loginCD = cd
end

function HeroPropertyProxy:getCD(cd)
    return self._loginCDTime
end

function HeroPropertyProxy:readLocalData()
    local LoginProxy    = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local mainPlayerID = LoginProxy:GetSelectedRoleID()
    local path    = "hero_state_" .. mainPlayerID
    local key    = "setting"
    local userData = UserData:new(path)
    local jsonStr = userData:getStringForKey(key, "")

    if not jsonStr or string.len(jsonStr) == 0 then
        return false
    end

    local jsonData = cjson.decode(jsonStr)
    if not jsonData then
        return false
    end
    local set = self:getStatesSysSet()
    for i = #jsonData, 1, -1 do
        if not table.indexof(set, jsonData[i]) then
            table.remove(jsonData, i)
        end
    end
    return jsonData
end

function HeroPropertyProxy:saveLocalData(data)
    if not data then
        return false
    end
    local LoginProxy    = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local mainPlayerID = LoginProxy:GetSelectedRoleID()
    local path    = "hero_state_" .. mainPlayerID
    local key    = "setting"
    local userData = UserData:new(path)
    pcall(function()
        local jsonStr = cjson.encode(data)
        userData:setStringForKey(key, jsonStr)
    end)
    return true
end


---------------------------------------------------------------------------------
-- 属性刷新通知
function HeroPropertyProxy:NotifyUpdateAbil(arrCurAbil, arrMaxAbil, isInit)
    -- level change
    local currlevel = self:GetRoleLevel()
    local lastlevel = self._lastArrCurAbil[GUIDefine.AttTypeTable.LEVEL]
    if lastlevel and lastlevel ~= currlevel then
        shareLevelT.last  = lastlevel
        shareLevelT.level = currlevel
        SLBridge:onLUAEvent(LUA_EVENT_HERO_LEVEL_CHANGE, shareLevelT)
    end

    -- 转生等级是否发生变化
    local currReinLevel = self:GetRoleReinLv()
    local lastReinLevel = self._lastArrCurAbil[GUIDefine.AttTypeTable.Rein_LEVEL]
    if lastReinLevel and lastReinLevel ~= currReinLevel then
        shareReLevelT.currReinLevel = currReinLevel
        shareReLevelT.lastReinLevel = lastReinLevel
        SLBridge:onLUAEvent(LUA_EVENT_HERO_REINLEVEL_CHANGE, shareReLevelT)
        global.Facade:sendNotification(global.NoticeTable.PlayerReinLevelChange_Hero, currReinLevel)
    end

    -- 部分属性独立通知
    if arrCurAbil[GUIDefine.AttTypeTable.HP] or arrMaxAbil[GUIDefine.AttTypeTable.HP] or arrCurAbil[GUIDefine.AttTypeTable.MP] or arrMaxAbil[GUIDefine.AttTypeTable.MP] then
        local lastMaxHP = self:GetLastMaxAbilByID(GUIDefine.AttTypeTable.HP)
        local lastMaxMP = self:GetLastMaxAbilByID(GUIDefine.AttTypeTable.MP)

        shareHMPT.curHP = self:GetRoleCurHP()
        shareHMPT.maxHP = self:GetRoleMaxHP()
        shareHMPT.curMP = self:GetRoleCurMP()
        shareHMPT.maxMP = self:GetRoleMaxMP()


        if lastMaxHP ~= shareHMPT.maxHP then
            shareHMPT.maxHPChange = true
        end

        if lastMaxMP ~= shareHMPT.maxMP then 
            shareHMPT.maxMPChange = true
        end

        -- 血量改变
        SLBridge:onLUAEvent(LUA_EVENT_HERO_HPMP_CHANGE, shareHMPT)
    end

    -- 经验
    if arrCurAbil[GUIDefine.AttTypeTable.EXP] or arrMaxAbil[GUIDefine.AttTypeTable.EXP] then
        local lastExp = self:GetLastCurAbilByID(GUIDefine.AttTypeTable.EXP) 
        local curExp  = self:GetCurAbilByID(GUIDefine.AttTypeTable.EXP)
        local changed = curExp - lastExp

        shareExpT.changed = changed
        shareExpT.currexp = curExp
        shareExpT.isInit = isInit
        SLBridge:onLUAEvent(LUA_EVENT_HERO_EXP_CHANGE, shareExpT)
    end
        
    -- 负重
    if arrCurAbil[GUIDefine.AttTypeTable.Weight] or arrCurAbil[GUIDefine.AttTypeTable.Wear_Weight] or arrCurAbil[GUIDefine.AttTypeTable.Hand_Weight] then 
        shareWightT.weight     = self:GetCurAbilByID(GUIDefine.AttTypeTable.Weight)
        shareWightT.wearWeight = self:GetCurAbilByID(GUIDefine.AttTypeTable.Wear_Weight)
        shareWightT.handWeight = self:GetCurAbilByID(GUIDefine.AttTypeTable.Hand_Weight)
        SLBridge:onLUAEvent(LUA_EVENT_WEIGHT_CHANGE, shareWightT)
    end

    -- 内力值
    if arrCurAbil[GUIDefine.AttTypeTable.Internal_Value] or arrMaxAbil[GUIDefine.AttTypeTable.Internal_Value] then 
        local lastInternal_Value = self:GetLastCurAbilByID(GUIDefine.AttTypeTable.Internal_Value) 
        local curInternal_Value  = self:GetCurAbilByID(GUIDefine.AttTypeTable.Internal_Value)
        -- 改变值
        shareNGT.changed = lastInternal_Value - curInternal_Value
        SL:onLUAEvent(LUA_EVENT_HERO_INTERNAL_FORCE_CHANGE, shareNGT)
    end

    -- 内功等级
    if arrCurAbil[GUIDefine.AttTypeTable.Internal_LEVEL] then 
        local lastInternal_level = self:GetLastCurAbilByID(GUIDefine.AttTypeTable.Internal_LEVEL) 
        local curInternal_level  = self:GetCurAbilByID(GUIDefine.AttTypeTable.Internal_LEVEL)
        if lastInternal_level ~= curInternal_level then
            shareNGLevelT.lastLevel = lastInternal_level
            shareNGLevelT.curLevel  = curInternal_level
            SLBridge:onLUAEvent(LUA_EVENT_HERO_INTERNAL_LEVEL_CHANGE, shareNGLevelT)
            global.Facade:sendNotification(global.NoticeTable.PlayerInternalLevelChange)
        end
        if lastInternal_level == 0 and curInternal_level > lastInternal_level then
            SLBridge:onLUAEvent(LUA_EVENT_HERO_LEARNED_INTERNAL)
        end
    end

    -- 内功经验
    if arrCurAbil[GUIDefine.AttTypeTable.Internal_EXP] then 
        local lastInternal_EXP = self:GetLastCurAbilByID(GUIDefine.AttTypeTable.Internal_EXP) 
        local curInternal_EXP  = self:GetCurAbilByID(GUIDefine.AttTypeTable.Internal_EXP)

        shareNGExpT.changed = curInternal_EXP - lastInternal_EXP
        SL:onLUAEvent(LUA_EVENT_HERO_INTERNAL_EXP_CHANGE, shareNGExpT)
    end

    -- 斗转值
    if arrCurAbil[GUIDefine.AttTypeTable.Internal_DZValue] then 
        local lastvalue = self:GetLastCurAbilByID(GUIDefine.AttTypeTable.Internal_DZValue) 
        local curvalue  = self:GetCurAbilByID(GUIDefine.AttTypeTable.Internal_DZValue)

        shareDZValueT.changed = lastvalue - curvalue
        SL:onLUAEvent(LUA_EVENT_HERO_INTERNAL_DZVALUE_CHANGE, shareDZValueT)
    end

    -- 背包格子
    if arrCurAbil[GUIDefine.AttTypeTable.BagMaxNum] then 
        local curvalue = self:GetCurAbilByID(GUIDefine.AttTypeTable.BagMaxNum)
        local lastValue = self:GetLastCurAbilByID(GUIDefine.AttTypeTable.BagMaxNum)
        HeroBagData.SetMaxBag(curvalue)
        if curvalue ~= lastValue then
            SLBridge:onLUAEvent(LUA_EVENT_HERO_BAG_ITEM_LIST_REFRESH)
        end
    end

    shareAbilChangeT.arrCurAbil = arrCurAbil
    shareAbilChangeT.arrMaxAbil = arrMaxAbil
    SLBridge:onLUAEvent(LUA_EVENT_HERO_PROPERTY_CHANGE, shareAbilChangeT)

    self:CompareAttribute()
end

function HeroPropertyProxy:GetHeroActor()
    local actor = global.actorManager:GetActor(self:GetRoleUID())
    return actor
end

function HeroPropertyProxy:IsInited()
    return self._isInited
end

function HeroPropertyProxy:SetInited()
    self._isInited = true
end

-- 主角名字
function HeroPropertyProxy:GetName()
    return self._name or ""
end

function HeroPropertyProxy:SetName(name)
    self._name = name
end

function HeroPropertyProxy:GetPKMode()
    return self._pkMode or global.MMO.HAM_ALL
end

function HeroPropertyProxy:SetPKMode(pkmode)
    self._pkMode = pkmode
end

function HeroPropertyProxy:SetHeroNameColor(color)
    self._nameColor = color
end

function HeroPropertyProxy:GetHeroNameColor()
    return self._nameColor or 255
end

-- 等级
function HeroPropertyProxy:GetRoleLevel()
    return self:GetCurAbilByID(GUIDefine.AttTypeTable.LEVEL) or 0
end

-- 职业
function HeroPropertyProxy:GetRoleJob()
    return self._job or GUIDefine.Job.FIGHTER
end
function HeroPropertyProxy:SetRoleJob(job)
    local lastJob = self:GetRoleJob()
    self._job = job
    if lastJob ~= job then
        SLBridge:onLUAEvent(LUA_EVENT_HERO_JOB_CHANGE, job)
    end
end

-- 职业名字
function HeroPropertyProxy:GetRoleJobName()
    return GUIFunction:GetJobNameByID(self:GetRoleJob())
end

-- 性别
function HeroPropertyProxy:GetRoleSex()
    return self._sex or GUIDefine.DEFAULT_SEX
end
function HeroPropertyProxy:SetRoleSex(sex)
    local lastSex = self:GetRoleSex()
    self._sex = sex
    if lastSex ~= sex then
        SLBridge:onLUAEvent(LUA_EVENT_HERO_SEX_CHANGE)
    end
end

function HeroPropertyProxy:SetRoleProperty(data)
    self:SetRoleJob(data.Job)
    self:SetRoleSex(data.Sex)
end

-- uid
function HeroPropertyProxy:GetRoleUID()
    return self._heroID
end

-- 转生
function HeroPropertyProxy:GetRoleReinLv()
    return self:GetCurAbilByID(GUIDefine.AttTypeTable.Rein_LEVEL)
end

-- hp
function HeroPropertyProxy:GetRoleCurHP()
    return self._arrCurAbil[GUIDefine.AttTypeTable.HP] or 0
end

function HeroPropertyProxy:GetRoleMaxHP()
    return self._arrMaxAbil[GUIDefine.AttTypeTable.HP] or 1
end

function HeroPropertyProxy:GetRoleHPPercent()
    return self:GetRoleCurHP() / self:GetRoleMaxHP() * 100
end

-- mp
function HeroPropertyProxy:GetRoleCurMP()
    return self._arrCurAbil[GUIDefine.AttTypeTable.MP] or 0
end

function HeroPropertyProxy:GetRoleMaxMP()
    return self._arrMaxAbil[GUIDefine.AttTypeTable.MP] or 1
end

function HeroPropertyProxy:GetRoleMPPercent()
    return self:GetRoleCurMP() / self:GetRoleMaxMP() * 100
end

-- 经验值
function HeroPropertyProxy:GetCurrExp() 
    return self:GetCurAbilByID(GUIDefine.AttTypeTable.EXP)
end

function HeroPropertyProxy:GetNeedExp()  
    return self:GetMaxAbilByID(GUIDefine.AttTypeTable.EXP)
end

function HeroPropertyProxy:GetInternalDZValue()  
    return self:GetMaxAbilByID(GUIDefine.AttTypeTable.Internal_DZValue)
end

function HeroPropertyProxy:GetRoleEXPPercent()
    return self:GetCurrExp() / self:GetNeedExp() * 100
end

function HeroPropertyProxy:GetRoleAttByAttType(attId)
    return self._arrCurAbil[attId] or 0
end

-- 获取外观
function HeroPropertyProxy:GetFeature()
    return self._feature
end

function HeroPropertyProxy:SetAlive(alive)
    self._isAlive = alive
    if alive then
        SL:onLUAEvent(LUA_EVENT_HERO_REVIVE)
    else
        SL:onLUAEvent(LUA_EVENT_HERO_DIE)
    end
end

function HeroPropertyProxy:IsAlive()
    return self._isAlive 
end

function HeroPropertyProxy:GetNeedExp()  
    return self:GetMaxAbilByID(GUIDefine.AttTypeTable.EXP)
end

function HeroPropertyProxy:SetFeature(feature)
    self._feature.clothID = feature.clothID
    self._feature.weaponID = feature.weaponID
    self._feature.shieldID = feature.shieldID
    self._feature.wingsID = feature.wingsID
    self._feature.hairID = feature.hairID
    self._feature.leftWeaponID = feature.leftWeaponID
end

--0-2来回切换
function HeroPropertyProxy:RequestChangeHeroMode(state)
    if state then
    else
        state = self:getHeroState()
        state = state + 1
        state = state > 2 and 0 or state
    end
    
    self:setHeroState(state)
    LuaSendMsg(global.MsgType.MSG_CS_HERO_ATTACK_MODE, state)
end

function HeroPropertyProxy:setStates(states)
    self.m_states = states
    self:saveLocalData(self.m_states)
end

--当前开启的状态
function HeroPropertyProxy:getStates()
    return self.m_states or {}
end

--锁定对象
function HeroPropertyProxy:RequestLockTarget(targetID, x, y, isPlayer)
    self._tempID = targetID
    releasePrint("----------RequestLockTarget--------------------", targetID, x, y, isPlayer)
    LuaSendMsg(global.MsgType.MSG_CS_LOCKTARGET_HERO, x, y, isPlayer and 1 or 0, 0, targetID)
end

--守护位置 -- mappos
function HeroPropertyProxy:RequestTargetXY(x, y)
    LuaSendMsg(global.MsgType.MSG_CS_LOCKTARGET_HERO, x, y)
end

function HeroPropertyProxy:CancelLock()
    LuaSendMsg(global.MsgType.MSG_CS_LOCKTARGET_CANCEL_HERO)
end

--守护按钮点击
function HeroPropertyProxy:setGuardBtnState(guard)
    if guard then
        global.Facade:sendNotification(global.NoticeTable.SystemTips, GET_STRING(600000266))
    end
    self._guardState = guard
end

function HeroPropertyProxy:getGuardBtnState()
    return self._guardState
end

function HeroPropertyProxy:CompareAttribute()
    -- 五秒内不播放
    if not self._abilChangeNotice then 
        PerformWithDelayGlobal(function() self._abilChangeNotice = true end, 5)
    end

    local AttrConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.AttrConfigProxy)
    local AttrType, nAttrType = AttrConfigProxy:GetAttTypes()

    local isInvalid = true
    local attrItems = {}
    for i = 1, nAttrType do
        local attID = AttrType[i]
        local config = AttrConfigProxy:GetAttConfigByAttId(attID)
        if config and not GUIDefineEx.NoHintAtts[attID] then
            local attrValue = 0
            if attID == 1 then
                attrValue = self:GetRoleMaxHP()
            elseif attID == 2 then
                attrValue = self:GetRoleMaxMP()
            else
                attrValue = self:GetRoleAttByAttType(attID)
            end
    
            attrItems[attID] = attrValue
            if attrValue > 0 then
                isInvalid = false
            end
        end
    end

    -- invalid
    if isInvalid then
        return nil
    end

    -- init
    if not next(self._lastAttr) then
        self._lastAttr = attrItems
        return nil
    end

    local mfloor = math.floor
    local diffAttr = {}
    local n = 0

    for i = 1, nAttrType do
        local attID = AttrType[i]
        local v = attID and attrItems[attID]
        if v then
            local diff = mfloor(v - (self._lastAttr[attID] or 0))
            if diff >= 1 then
                n = n + 1 
                diffAttr[n] = {id = attID, value = diff}
            end
        end
    end

    if n > 0 and self._abilChangeNotice then
        local isShowAbilNotice = tonumber(SL:GetValue("GAME_DATA", "isShowAttributeTips")) ~= 0
        if isShowAbilNotice then
            shareAbilPZ.attributes = diffAttr
            shareAbilPZ.attr_type  = 0
            SLBridge:onLUAEvent(LUA_EVENT_NOTICE_ATTRIBUTE, shareAbilPZ)
        end
        global.Facade:sendNotification(global.NoticeTable.PlayerAttribute_Change_Hero, diffAttr)
    end

    self._lastAttr = attrItems
end

function HeroPropertyProxy:InitAbilID(v, n)
    self._arrAbilIndexs = v
    self._nArrAbilIndex = n 
end

function HeroPropertyProxy:SetArrCurAbil(v)
    self._arrCurAbil = v
end

function HeroPropertyProxy:SetArrMaxAbil(v)
    self._arrMaxAbil = v
end

function HeroPropertyProxy:GetLastCurAbilByID(i)
    return self._lastArrCurAbil[i] or 0
end

function HeroPropertyProxy:SetLastCurAbilByID(i, v)
    self._lastArrCurAbil[i] = v
end

function HeroPropertyProxy:UpdateLastArrCurAbil(data)
    for i = 1, self._nArrAbilIndex do
        local k = self._arrAbilIndexs[i]
        local v = data[k]
        self:SetLastCurAbilByID(k, v)
    end
end

function HeroPropertyProxy:GetLastMaxAbilByID(i)
    return self._lastArrMaxAbil[i] or 0
end

function HeroPropertyProxy:SetLastMaxAbilByID(i, v)
    self._lastArrMaxAbil[i] = v
end

function HeroPropertyProxy:UpdateLastArrMaxAbil(data)
    for i = 1, self._nArrAbilIndex do
        local k = self._arrAbilIndexs[i]
        local v = data[k]
        self:SetLastMaxAbilByID(k, v)
    end
end

function HeroPropertyProxy:SetMaxAbilByID(i, v)
    self._arrMaxAbil[i] = v
end

function HeroPropertyProxy:GetMaxAbilByID(i)
    return self._arrMaxAbil[i] or 0
end

function HeroPropertyProxy:UpdateArrCurAbil(data)
    for i = 1, self._nArrAbilIndex do
        local k = self._arrAbilIndexs[i]
        local v = data[k]
        self:SetCurAbilByID(k, v)
    end
end

function HeroPropertyProxy:UpdateArrMaxAbil(data)
    for i = 1, self._nArrAbilIndex do
        local k = self._arrAbilIndexs[i]
        local v = data[k]
        self:SetMaxAbilByID(k, v)
    end
end

function HeroPropertyProxy:SetCurAbilByID(i, v)
    self._arrCurAbil[i] = v
end

function HeroPropertyProxy:GetCurAbilByID(i)
    return self._arrCurAbil[i] or 0
end

function HeroPropertyProxy:GetArrCurAbil()
    return self._arrCurAbil
end

function HeroPropertyProxy:InitProperty(arrCurAbil, arrMaxAbil)
    self:SetArrCurAbil(arrCurAbil)
    self:SetArrMaxAbil(arrMaxAbil)
    -- init
    self:SetInited()
    SLBridge:onLUAEvent(LUA_EVENT_HERO_ROLE_PROPERTY_INITED)
end

-- 获取英雄忠诚度
function HeroPropertyProxy:GetHeroLuck()
    return self._HeroLuck or 1000
end

-- 设置英雄忠诚度
function HeroPropertyProxy:SetHeroLuck(luck)
    if not luck then
        return false
    end

    if luck == self:GetHeroLuck() then
        return false
    end

    self._HeroLuck = luck

    SLBridge:onLUAEvent(LUA_EVENT_HERO_LOYAL_CHANGE)
end

function HeroPropertyProxy:GetIsMakeHero()
    return self._MakeHero or false
end

function HeroPropertyProxy:SetMakeHero(MakeHero)
    self._MakeHero = MakeHero
    SLBridge:onLUAEvent(LUA_EVENT_HERO_CALL_BUTTON_SHOW, MakeHero)
end

-- 召唤英雄或收起
function HeroPropertyProxy:RequestHeroInOrOut()
    LuaSendMsg(global.MsgType.MSG_CS_HERO, 0, 0, 0, 0, 0, 0)
end

-- 角色名字  名字颜色ID
function HeroPropertyProxy:handle_MSG_SC_PLAYER_NAMEANDID_HERO(msg)
    local msgLen = msg:GetDataLength()
    local msgHdr = msg:GetHeader()
    if msgLen <= 0 then
        return
    end

    local dataString = msg:GetBodyStr()
    local strs = G_GetSplitArray(dataString, "&")
    self:SetName(strs[1])

    self:SetHeroNameColor(msgHdr.param1)
    SL:onLUAEvent(LUA_EVENT_HERO_FRAME_NAME_RRFRESH)
end

-- 请求合击
function HeroPropertyProxy:ReqJointAttack()
    LuaSendMsg(global.MsgType.MSG_CS_JOINTATTACK_HERO, 0, 0, 0, 0, 0, 0)
end

function HeroPropertyProxy:getShan()
    return self._shan
end

function HeroPropertyProxy:getMaxAnger()
    return self._angerMax
end
-- 获取当前怒气
function HeroPropertyProxy:getCurAnger()
    return self._angerCur
end

function HeroPropertyProxy:getDelayTime()
    return self._delayTime
end
function HeroPropertyProxy:getSpeed()
    return self._speed
end

-- 英雄怒气值
function HeroPropertyProxy:handle_MSG_SC_ANGER_HERO(msg)
    local msgHdr = msg:GetHeader()
    local max = msgHdr.recog or 0
    local cur = msgHdr.param1 or 0
    local s = msgHdr.param2 or 0
    self._angerMax = max
    self._angerCur = cur
    self._shan = s == 1
    self._delayTime = msgHdr.param3 or 1

    local msgLen = msg:GetDataLength()
    if msgLen > 0 then
        local dataString = msg:GetBodyStr()
        self._speed = tonumber(dataString) or 10
    end

    SLBridge:onLUAEvent(LUA_EVENT_HERO_ANGER_CHANGE)
end

-- 获取英雄状态0 攻击  1 跟随 2 休息
function HeroPropertyProxy:getHeroState()
    return self._state or 0
end
function HeroPropertyProxy:setHeroState(state)
    self._state = state
end
-- 获取英雄守护状态0   1 
function HeroPropertyProxy:getHeroGuardState()
    return self._guard or 0
end

-- 获取英雄锁定状态0   1 
function HeroPropertyProxy:getHeroLockState()
    return self._target or 0
end
function HeroPropertyProxy:setLockID(ID)
    self._lockTargetID = ID
end
function HeroPropertyProxy:getLockID()
    return self._lockTargetID
end

-- 英雄状态
function HeroPropertyProxy:handle_MSG_SC_PLAYER_STATE_HERO(msg)
    local msgHdr = msg:GetHeader()
    local state  = msgHdr.recog or 0
    local guard  = msgHdr.param1 or 0
    local target = msgHdr.param2 or 0
    self._state  = state  -- 状态
    self._guard  = guard  -- 守护
    self._target = target -- 锁定
    if target == 1 and self._tempID then
        self:setLockID(self._tempID)
        self._tempID = nil
        SL:onLUAEvent(LUA_EVENT_HERO_LOCK_CHANGE)
    elseif target == 0 then
        self:setLockID(nil)
        SL:onLUAEvent(LUA_EVENT_HERO_LOCK_CHANGE)
    end
end

-- 英雄开关
function HeroPropertyProxy:IsHeroOpen()
    local res = false
    if global.ConstantConfig and tonumber(SL:GetValue("GAME_DATA","syshero")) == 1 then
        res = true
    end
    return res
end

-- 英雄出生
function HeroPropertyProxy:handle_MSG_SC_HEROLOGIN(msg)
    local msgLen = msg:GetDataLength()
    local msgHdr = msg:GetHeader()
    if msgLen < 1 then
        return false
    end

    local dataString = msg:GetBodyStr()
    local ids = G_GetSplitArray(dataString, "&")

    local playerID = ids[1]
    local heroID   = ids[2]

    local animID = 98
    local anim   = global.FrameAnimManager:CreateSFXAnim(animID)
    local srcX   = msgHdr.param1
    local srcY   = msgHdr.param2

    local wX, wY = global.sceneManager:MapPos2WorldPos(srcX, srcY)
    local root = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_ACTOR_SFX_FRONT)
    root:addChild(anim)
    anim:setPosition(wX, wY)
    anim:setLocalZOrder(animID)
    anim:Play(0, 0, true)
    anim:SetAnimEventCallback(function(sender) sender:removeFromParent() end)

    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_FLY_IN_HERO
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
    
    if playerID == global.gamePlayerController:GetMainPlayerID() then
        self._heroID = heroID
        self._herologin = true
        SL:onLUAEvent(LUA_EVENT_HERO_LOCK_CHANGE)
        SL:onLUAEvent(LUA_EVENT_HERO_LOGIN)
        SLBridge:onLUAEvent(LUA_EVENT_HERO_LOGIN_OROUT, true)
    end
end

--英雄退出
function HeroPropertyProxy:handle_MSG_SC_HEROLOGOUT(msg)
    local msgLen = msg:GetDataLength()
    local msgHdr = msg:GetHeader()
    if msgLen < 1 then
        return false
    end
    local dataString = msg:GetBodyStr()
    local ids = G_GetSplitArray(dataString, "&")
    local playerID = ids[1]
    local heroID   = ids[2]

    local animID = 99
    local anim   = global.FrameAnimManager:CreateSFXAnim(animID)
    local srcX   = msgHdr.param1
    local srcY   = msgHdr.param2

    local wX, wY = global.sceneManager:MapPos2WorldPos(srcX, srcY)
    local root = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_ACTOR_SFX_FRONT)
    root:addChild(anim)
    anim:setPosition(wX, wY)
    anim:setLocalZOrder(animID)
    anim:Play(0, 0, true)
    anim:SetAnimEventCallback(function (sender) sender:removeFromParent() end)

    -- 如果是自己的英雄
    if playerID == global.gamePlayerController:GetMainPlayerID() then
        self:NoticeOut()
    end

    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_FLY_OUT_HERO
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
end

-- 英雄退出 或尸体消失 或主角死亡
function HeroPropertyProxy:NoticeOut()
    -- 隐藏英雄怒气
    SLBridge:onLUAEvent(LUA_EVENT_HERO_ANGER_CHANGE)
    SLBridge:onLUAEvent(LUA_EVENT_HERO_LOCK_CHANGE)

    self._loginCDTime = self._loginCD
    if self.ScheduleID1 then
        UnSchedule(self.ScheduleID1)
    end

    self.ScheduleID1 = Schedule(function()
        self._loginCDTime = self._loginCDTime - 1
        if self._loginCDTime <= 0 then
            self._loginCDTime = 0
            UnSchedule(self.ScheduleID1)
            self.ScheduleID1 = nil
        end
    end, 1)

    local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
    HeroSkillProxy:DelAllSkill()

    self._guardState = false
    self._isInited   = false
    self._isAlive    = true

    self._herologin  = false

    self._feature    =    
    {
        clothID      = 0,
        weaponID     = 0,
        shieldID     = 0,
        wingsID      = 0,
        fireID       = 0,
        hairID       = 0,
        leftWeaponID = 0,
    }

    self._attribute = {}
    self._lockTargetID = nil

    self._angerMax = 0      -- 最大怒气
    self._angerCur = 0      -- 当前怒气
    self._shan     = false  -- 是否要闪
    self._speed    = 10
    self._delayTime = 1

    self._heroID = nil

    self:SetHeroNameColor(255)

    SLBridge:onLUAEvent(LUA_EVENT_HERO_LOGOUT)
    SLBridge:onLUAEvent(LUA_EVENT_HERO_LOGIN_OROUT, false)
end

function HeroPropertyProxy:handle_MSG_SC_PLAYER_RELIVE_STATE(msg)
    local header = msg:GetHeader()
    self._canRevive = header.param1 == 1
end

function HeroPropertyProxy:handle_MSG_SC_HERO_DIE(msg)
    self:SetAlive(false)
end

function HeroPropertyProxy:hander_MSG_SC_HERO_AbilEx(msg)
    local jsonData = msg:GetJsonData()
    if not jsonData then
        return
    end

    dump(jsonData, "--hander_MSG_SC_HERO_AbilEx--")
    -- 英雄按钮是否显示
    self:SetMakeHero(jsonData.Hero == 1)

    -- 英雄忠诚度
    self:SetHeroLuck(jsonData.Heroloyal)

    -- 英雄首饰盒是否开启
    HeroEquipData.SetBestRingsOpenState(jsonData.HeroBox == 1)
end

function HeroPropertyProxy:HeroIsLogin()
    return self._herologin
end

function HeroPropertyProxy:IsCanRevive()
    return self._canRevive
end

function HeroPropertyProxy:onRegister()
    HeroPropertyProxy.super.onRegister(self)
end

function HeroPropertyProxy:RegisterMsgHandler()
    HeroPropertyProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_NAMEANDID_HERO, handler(self, self.handle_MSG_SC_PLAYER_NAMEANDID_HERO))        -- 角色名字  名字颜色ID
    LuaRegisterMsgHandler(msgType.MSG_SC_ANGER_HERO,            handler(self, self.handle_MSG_SC_ANGER_HERO))                   -- 英雄怒气
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_STATE_HERO,     handler(self, self.handle_MSG_SC_PLAYER_STATE_HERO))
    LuaRegisterMsgHandler(msgType.MSG_SC_HEROLOGIN,             handler(self, self.handle_MSG_SC_HEROLOGIN))                    -- 英雄出生
    LuaRegisterMsgHandler(msgType.MSG_SC_HEROLOGOUT,            handler(self, self.handle_MSG_SC_HEROLOGOUT))                   -- 英雄退出
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_RELIVE_STATE,   handler(self, self.handle_MSG_SC_PLAYER_RELIVE_STATE))          -- 是否可复活状态(角色的地方也有监听，不是bug)
    LuaRegisterMsgHandler(msgType.MSG_SC_HERO_DIE,              handler(self, self.handle_MSG_SC_HERO_DIE))                     -- 英雄死亡
    LuaRegisterMsgHandler(msgType.MSG_SC_HERO_AbilEx,           handler(self, self.hander_MSG_SC_HERO_AbilEx))                  -- 英雄额外属性
end

return HeroPropertyProxy