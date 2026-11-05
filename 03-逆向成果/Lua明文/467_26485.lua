local RemoteProxy = requireProxy("RemoteProxy")
local PlayerPropertyProxy = class("PlayerPropertyProxy", RemoteProxy)
PlayerPropertyProxy.NAME  = global.ProxyTable.PlayerPropertyProxy

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

local attTypeByJob     = {
    [GUIDefine.Job.FIGHTER] = GUIDefine.AttTypeTable.Max_ATK,
    [GUIDefine.Job.WIZZARD] = GUIDefine.AttTypeTable.Max_MAT,
    [GUIDefine.Job.TAOIST]  = GUIDefine.AttTypeTable.Max_Daoshu,
}

function PlayerPropertyProxy:ctor()
    PlayerPropertyProxy.super.ctor(self)

    self._arrCurAbil = {}       -- 基础属性
    self._arrMaxAbil = {}       -- 最大属性

    self._lastArrCurAbil = {}   -- 上一次的基础属性
    self._lastArrMaxAbil = {}   -- 上一次的最大属性

    self._arrAbilIndexs  = {}   
    self._nArrAbilIndex  = {}

    self._lastAttr = {}


    self._isInited          = false
    self._isAlive           = true

    self._isRide            = 0
    self._nationID          = nil       -- 国家
    self._forbidRun         = false     -- 是否禁跑
    self._isShabakeMember   = false     -- 是否是沙巴克成员
    self._isShabakeAdmin    = false     -- 是否是沙巴克城主

    -- 外观ID
    self._feature = 
    {
        clothID      = 0,
        weaponID     = 0,
        shieldID     = 0,
        wingsID      = 0,
        hairID       = 0,
        leftWeaponID = 0,
    }

    self._canChangeMode    = {
        [global.MMO.HAM_ALL]    = true,
        [global.MMO.HAM_PEACE]  = true,
        [global.MMO.HAM_DEAR]   = true,

        [global.MMO.HAM_MASTER] = true,
        [global.MMO.HAM_GROUP]  = true,
        [global.MMO.HAM_GUILD]  = true,
        [global.MMO.HAM_SHANE]  = true,
        [global.MMO.HAM_CAMP]   = false,
        [global.MMO.HAM_NATION] = true,
    }

    self._extraComboBJRate = {}     -- 连击格子额外加暴击几率
    self._pkPoint = 0               -- PK点数
    self._showPromptPrefix = true   -- 是否显示消息提示前缀 "〖提示〗"
end

---------------------------------------------------------------------------------
-- 该消息只在进游戏时进一次
function PlayerPropertyProxy:InitProperty(arrCurAbil, arrMaxAbil)
    -- dump("初始化角色")
    self:SetArrCurAbil(arrCurAbil)
    self:SetArrMaxAbil(arrMaxAbil)

    -- init
    self:SetInited()
    global.Facade:sendNotification(global.NoticeTable.PlayerPropertyInited)

    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local jobID = self:GetRoleJob()
    -- notice native 
    local jData = {}
    local loginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local selectRole = loginProxy:GetSelectedRole()
    jData.zoneId = loginProxy:GetSelectedServerId()
    jData.zoneName = loginProxy:GetSelectedServerName()
    jData.roleId = selectRole.roleid
    jData.roleName = selectRole.name
    jData.roleCTime = selectRole.ctime or GetServerTime()
    jData.roleLevel = self:GetRoleLevel()
    jData.roleVIPLev = "0"
    jData.roleBalance = "0"
    jData.roleGuild = ""
    jData.roleCareer = self:GetRoleJobName()
    jData.roleSex = self:GetRoleSex() + 1
    jData.reinLevel = tostring(self:GetRoleReinLv())
    jData.userId = tostring(AuthProxy:GetUID())
    jData.roleJobName = self:GetRoleJobName()
    jData.roleJobId = self:GetRoleJob()
    jData.roleAtt = self:GetRoleAttByAttType(attTypeByJob[jobID] or GUIDefine.AttTypeTable.Max_ATK) or 0

    local envProxy              = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local currModule            = global.L_ModuleManager:GetCurrentModule()
    local gameID                = currModule:GetOperID()
    local channelID             = envProxy:GetChannelID()
    local npData = {
        uid = tostring(AuthProxy:GetUID()),
        userId = selectRole.roleid,
        gameVersion = gameID,
        assetVersion = channelID,
        serverId = loginProxy:GetSelectedServerId(),
        nickname = selectRole.name,
    }
    jData.extData = SL:Base64Encode(SL:JsonEncode(npData))

    -- 新增 主服id和主服name
    jData.main_servid       = loginProxy:GetMainSelectedServerId()
    jData.main_server_name  = loginProxy:GetMainSelectedServerName()

    local serviceVer        = " " .. loginProxy:GetServiceVer()
    jData.server_version    = string.gsub(serviceVer, "^%S*(.-).%d$", "%1")

    local DataTrackProxy = global.Facade:retrieveProxy(global.ProxyTable.DataTrackProxy)
    DataTrackProxy:OnEnterGame(jData)

    local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    if NativeBridgeProxy then
        NativeBridgeProxy:GN_Game_Duration_State( {isGameDuration=true} )
    end

    AuthProxy:SendLDVIPLevel()

    SLBridge:onLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED)
end

-- 属性刷新通知
function PlayerPropertyProxy:NotifyUpdateAbil(arrCurAbil, arrMaxAbil, isInit)
    -- level change
    local currlevel = self:GetRoleLevel()
    local lastlevel = self._lastArrCurAbil[GUIDefine.AttTypeTable.LEVEL]

    if lastlevel and lastlevel ~= currlevel then
        shareLevelT.last  = lastlevel
        shareLevelT.level = currlevel
        SLBridge:onLUAEvent(LUA_EVENT_LEVEL_CHANGE, shareLevelT)
        global.Facade:sendNotification(global.NoticeTable.PlayerLevelChange, shareLevelT)
        
        shareLevelD.roleLevel = tostring(currlevel)
        shareLevelD.reinLevel = 0
        local DataTrackProxy = global.Facade:retrieveProxy(global.ProxyTable.DataTrackProxy)
        DataTrackProxy:OnLevelChange(shareLevelD)
    end

    -- 转生等级是否发生变化
    local currReinLevel = self:GetRoleReinLv()
    local lastReinLevel = self._lastArrCurAbil[GUIDefine.AttTypeTable.Rein_LEVEL]
    if lastReinLevel and lastReinLevel ~= currReinLevel then
        shareReLevelT.currReinLevel = currReinLevel
        shareReLevelT.lastReinLevel = lastReinLevel
        SLBridge:onLUAEvent(LUA_EVENT_REINLEVEL_CHANGE, shareReLevelT)
        global.Facade:sendNotification(global.NoticeTable.PlayerReinLevelChange, currReinLevel)
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
        SLBridge:onLUAEvent(LUA_EVENT_HPMP_CHANGE, shareHMPT)
    end

    -- 经验
    if arrCurAbil[GUIDefine.AttTypeTable.EXP] or arrMaxAbil[GUIDefine.AttTypeTable.EXP] then
        local lastExp = self:GetLastCurAbilByID(GUIDefine.AttTypeTable.EXP) 
        local curExp  = self:GetCurAbilByID(GUIDefine.AttTypeTable.EXP)
        local changed = curExp - lastExp

        shareExpT.changed = changed
        shareExpT.currexp = curExp
        shareExpT.isInit = isInit
        SLBridge:onLUAEvent(LUA_EVENT_EXP_CHANGE, shareExpT)
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
        SL:onLUAEvent(LUA_EVENT_PLAYER_INTERNAL_FORCE_CHANGE, shareNGT)
    end

    -- 内功等级
    if arrCurAbil[GUIDefine.AttTypeTable.Internal_LEVEL] then 
        local lastInternal_level = self:GetLastCurAbilByID(GUIDefine.AttTypeTable.Internal_LEVEL) 
        local curInternal_level  = self:GetCurAbilByID(GUIDefine.AttTypeTable.Internal_LEVEL)
        if lastInternal_level ~= curInternal_level then
            shareNGLevelT.lastLevel = lastInternal_level
            shareNGLevelT.curLevel  = curInternal_level
            SLBridge:onLUAEvent(LUA_EVENT_PLAYER_INTERNAL_LEVEL_CHANGE, shareNGLevelT)
            global.Facade:sendNotification(global.NoticeTable.PlayerInternalLevelChange)
        end
        if lastInternal_level == 0 and curInternal_level > lastInternal_level then
            SLBridge:onLUAEvent(LUA_EVENT_PLAYER_LEARNED_INTERNAL)
        end
    end

    -- 内功经验
    if arrCurAbil[GUIDefine.AttTypeTable.Internal_EXP] then 
        local lastInternal_EXP = self:GetLastCurAbilByID(GUIDefine.AttTypeTable.Internal_EXP) 
        local curInternal_EXP  = self:GetCurAbilByID(GUIDefine.AttTypeTable.Internal_EXP)

        shareNGExpT.changed = curInternal_EXP - lastInternal_EXP
        SL:onLUAEvent(LUA_EVENT_PLAYER_INTERNAL_EXP_CHANGE, shareNGExpT)
    end

    -- 斗转值
    if arrCurAbil[GUIDefine.AttTypeTable.Internal_DZValue] then 
        local lastvalue = self:GetLastCurAbilByID(GUIDefine.AttTypeTable.Internal_DZValue) 
        local curvalue  = self:GetCurAbilByID(GUIDefine.AttTypeTable.Internal_DZValue)
        shareDZValueT.changed = lastvalue - curvalue
        SL:onLUAEvent(LUA_EVENT_PLAYER_INTERNAL_DZVALUE_CHANGE, shareDZValueT)
    end

    -- 背包格子
    if arrCurAbil[GUIDefine.AttTypeTable.BagMaxNum] then 
        local curvalue = self:GetCurAbilByID(GUIDefine.AttTypeTable.BagMaxNum)
        local lastValue = self:GetLastCurAbilByID(GUIDefine.AttTypeTable.BagMaxNum)
        BagData.SetMaxBag(curvalue)
        if curvalue ~= lastValue then
            SLBridge:onLUAEvent(LUA_EVENT_BAG_ITEM_LIST_REFRESH)
        end
    end

    shareAbilChangeT.arrCurAbil = arrCurAbil
    shareAbilChangeT.arrMaxAbil = arrMaxAbil
    SLBridge:onLUAEvent(LUA_EVENT_ROLE_PROPERTY_CHANGE, shareAbilChangeT)
    global.Facade:sendNotification(global.NoticeTable.PlayerPropertyChange, shareAbilChangeT)

    self:CompareAttribute()
end

function PlayerPropertyProxy:InitAbilID(v, n)
    self._arrAbilIndexs = v
    self._nArrAbilIndex = n 
end

function PlayerPropertyProxy:SetArrCurAbil(v)
    self._arrCurAbil = v
end

function PlayerPropertyProxy:SetCurAbilByID(i, v)
    self._arrCurAbil[i] = v
end

function PlayerPropertyProxy:GetCurAbilByID(i)
    return self._arrCurAbil[i] or 0
end

function PlayerPropertyProxy:UpdateArrCurAbil(data)
    for i = 1, self._nArrAbilIndex do
        local k = self._arrAbilIndexs[i]
        local v = data[k]
        self:SetCurAbilByID(k, v)
    end
end

function PlayerPropertyProxy:GetArrCurAbil()
    return self._arrCurAbil
end

function PlayerPropertyProxy:SetArrMaxAbil(v)
    self._arrMaxAbil = v
end

function PlayerPropertyProxy:SetMaxAbilByID(i, v)
    self._arrMaxAbil[i] = v
end

function PlayerPropertyProxy:GetMaxAbilByID(i)
    return self._arrMaxAbil[i] or 0
end

function PlayerPropertyProxy:UpdateArrMaxAbil(data)
    for i = 1, self._nArrAbilIndex do
        local k = self._arrAbilIndexs[i]
        local v = data[k]
        self:SetMaxAbilByID(k, v)
    end
end

function PlayerPropertyProxy:GetArrMaxAbil()
    return self._arrMaxAbil
end

function PlayerPropertyProxy:GetLastCurAbilByID(i)
    return self._lastArrCurAbil[i] or 0
end

function PlayerPropertyProxy:SetLastCurAbilByID(i, v)
    self._lastArrCurAbil[i] = v
end

function PlayerPropertyProxy:UpdateLastArrCurAbil(data)
    for i = 1, self._nArrAbilIndex do
        local k = self._arrAbilIndexs[i]
        local v = data[k]
        self:SetLastCurAbilByID(k, v)
    end
end

function PlayerPropertyProxy:GetLastMaxAbilByID(i)
    return self._lastArrMaxAbil[i] or 0
end

function PlayerPropertyProxy:SetLastMaxAbilByID(i, v)
    self._lastArrMaxAbil[i] = v
end

function PlayerPropertyProxy:UpdateLastArrMaxAbil(data)
    for i = 1, self._nArrAbilIndex do
        local k = self._arrAbilIndexs[i]
        local v = data[k]
        self:SetLastMaxAbilByID(k, v)
    end
end

-- 获取国家id
function PlayerPropertyProxy:GetNationID()
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return nil
    end

    local nationid = mainPlayer:GetNationID()
    if nationid and nationid > 0 then
        return nationid
    end
    return nil
end

-- 判断是否加入了国家
function PlayerPropertyProxy:IsJoinNation()
    local nationid = self:GetNationID()
    if nationid and nationid > 0 then
        return true
    end
    return false
end

function PlayerPropertyProxy:IsInited()
    return self._isInited
end

function PlayerPropertyProxy:SetInited()
    self._isInited = true
end

-- 角色是否活着
function PlayerPropertyProxy:IsAlive()
    return self._isAlive
end

function PlayerPropertyProxy:SetAlive(alive)
    self._isAlive = alive

    if alive then
        global.Facade:sendNotification(global.NoticeTable.MainPlayerRevive)
        SLBridge:onLUAEvent(LUA_EVENT_MAIN_PLAYER_REVIVE)
    else
        global.Facade:sendNotification(global.NoticeTable.MainPlayerDie)
        SLBridge:onLUAEvent(LUA_EVENT_MAIN_PLAYER_DIE)
    end
end

-- uid
function PlayerPropertyProxy:GetRoleUID()
    return global.gamePlayerController:GetMainPlayerID()
end

-- 等级
function PlayerPropertyProxy:GetRoleLevel()
    return self:GetCurAbilByID(GUIDefine.AttTypeTable.LEVEL) or 0
end

-- 主角名字
function PlayerPropertyProxy:GetName()
    return self._name or ""
end
function PlayerPropertyProxy:SetName(name)
    self._name = name
end

-- name color
function PlayerPropertyProxy:SetMainPlayerNameColor(color)
    self._nameColor = color
    SL:onLUAEvent(LUA_EVENT_PLAYER_FRAME_NAME_RRFRESH)
end
function PlayerPropertyProxy:GetMainPlayerNameColor()
    return self._nameColor or 255
end

-- 职业
function PlayerPropertyProxy:GetRoleJob()
    return self._job or GUIDefine.Job.FIGHTER
end
function PlayerPropertyProxy:SetRoleJob(job)
    local lastJob = self:GetRoleJob()
    self._job = job
    if lastJob ~= job then
        SLBridge:onLUAEvent(LUA_EVENT_PLAYER_JOB_CHANGE, job)
    end
end

-- 职业名字
function PlayerPropertyProxy:GetRoleJobName()
    return GUIFunction:GetJobNameByID(self:GetRoleJob())
end

-- 性别
function PlayerPropertyProxy:GetRoleSex()
    return self._sex or GUIDefine.DEFAULT_SEX
end
function PlayerPropertyProxy:SetRoleSex(sex)
    local lastSex = self:GetRoleSex()
    self._sex = sex
    if lastSex ~= sex then
        SLBridge:onLUAEvent(LUA_EVENT_PLAYER_SEX_CHANGE)
    end
end

function PlayerPropertyProxy:SetRoleProperty(data)
    self:SetRoleJob(data.Job)
    self:SetRoleSex(data.Sex)
end

-- 转生
function PlayerPropertyProxy:GetRoleReinLv()
    return self:GetCurAbilByID(GUIDefine.AttTypeTable.Rein_LEVEL)
end

-- 外观
function PlayerPropertyProxy:GetFeature() 
    return self._feature
end

function PlayerPropertyProxy:SetFeature(feature) 
    self._feature.clothID  = feature.clothID
    self._feature.weaponID = feature.weaponID
    self._feature.shieldID = feature.shieldID
    self._feature.wingsID  = feature.wingsID
    self._feature.hairID   = feature.hairID
    self._feature.leftWeaponID = feature.leftWeaponID
end

-- PK模式
function PlayerPropertyProxy:GetPKMode()
    return self._pkMode or global.MMO.HAM_ALL
end
function PlayerPropertyProxy:SetPKMode(pkmode)
    self._pkMode = pkmode
end
function PlayerPropertyProxy:IsShowCurMode(pkmode)
    if pkmode >= 100 then   -- 自定义攻击模式
        return true
    end
    return self._canChangeMode[pkmode]
end

-- 是否显示消息提示前缀
function PlayerPropertyProxy:SetPromptPrefixShow(value)
    self._showPromptPrefix = value
end

function PlayerPropertyProxy:GetPromptPrefixShow()
    return self._showPromptPrefix
end

function PlayerPropertyProxy:RequestChangePKMode(state)
    if not self:IsShowCurMode(state) then
        global.Facade:sendNotification(global.NoticeTable.SystemTips, GET_STRING(30023010))
        return
    end
    LuaSendMsg(global.MsgType.MSG_CS_REQUEST_PK_STATE, state)
end

function PlayerPropertyProxy:handle_MSG_SC_PLAYER_PK_STATE(msg)
    local header    = msg:GetHeader()
    local pkMode    = header.recog
    local errorCode = header.param1

    if errorCode == -1 then
        global.Facade:sendNotification(global.NoticeTable.SystemTips, GET_STRING(30023010))
        return
    end

    self:SetPKMode(pkMode)
    SLBridge:onLUAEvent(LUA_EVENT_PKMODE_CHANGE, pkMode)
end

-- hp
function PlayerPropertyProxy:GetRoleCurHP()
    return self._arrCurAbil[GUIDefine.AttTypeTable.HP] or 0
end

function PlayerPropertyProxy:GetRoleMaxHP()
    return self._arrMaxAbil[GUIDefine.AttTypeTable.HP] or 1
end

function PlayerPropertyProxy:GetRoleHPPercent()
    return self:GetRoleCurHP() / self:GetRoleMaxHP() * 100
end

-- mp
function PlayerPropertyProxy:GetRoleCurMP()
    return self._arrCurAbil[GUIDefine.AttTypeTable.MP] or 0
end

function PlayerPropertyProxy:GetRoleMaxMP()
    return self._arrMaxAbil[GUIDefine.AttTypeTable.MP] or 1
end

function PlayerPropertyProxy:GetRoleMPPercent()
    return self:GetRoleCurMP() / self:GetRoleMaxMP() * 100
end

-- 经验值
function PlayerPropertyProxy:GetCurrExp() 
    return self:GetCurAbilByID(GUIDefine.AttTypeTable.EXP)
end

function PlayerPropertyProxy:GetNeedExp()  
    return self:GetMaxAbilByID(GUIDefine.AttTypeTable.EXP)
end

function PlayerPropertyProxy:GetRoleAttByAttType(attId)
    return self._arrCurAbil[attId] or 0
end

function PlayerPropertyProxy:GetRoleAttrByType(attId)
    if not attId then
        return clone(self._arrCurAbil)
    end
    return self._arrCurAbil[attId] or 0
end

-- combo skill
function PlayerPropertyProxy:SetComboExtraBJRate(value, index)
    self._extraComboBJRate[index] = value
end
function PlayerPropertyProxy:GetComboExtraBJRate(index)
    if index then
        return self._extraComboBJRate[index]
    end
    return self._extraComboBJRate
end

-- 人物最大等级
function PlayerPropertyProxy:SetMaxLevel(value)
    self._maxLevel = value
end

function PlayerPropertyProxy:GetMaxLevel()
    return self._maxLevel
end

function PlayerPropertyProxy:IsShabakeMember()
    return self._isShabakeMember == true
end

function PlayerPropertyProxy:IsShabakeAdmin()
    return self._isShabakeAdmin == true
end

function PlayerPropertyProxy:CompareAttribute()
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
        global.Facade:sendNotification(global.NoticeTable.PlayerAttribute_Change, diffAttr)
    end

    self._lastAttr = attrItems
end

function PlayerPropertyProxy:handle_MSG_SC_PLAYER_CANCHANGE_MODE(msg)
    local canMode = msg:GetP0()
    for i = global.MMO.HAM_ALL, global.MMO.HAM_CAMP do
        self._canChangeMode[i] = bit.band(bit.rshift(canMode, i), 1) == 1 
    end
end

function PlayerPropertyProxy:IsForbidRun()
    return self._forbidRun
end

function PlayerPropertyProxy:IsCanRevive()
    return self._canRevive
end

function PlayerPropertyProxy:GetPKPoint()
    return self._pkPoint or 0
end

function PlayerPropertyProxy:handle_MSG_SC_PLAYER_RELIVE_STATE(msg)
    self._canRevive = msg:GetP0() == 1
    SLBridge:onLUAEvent(LUA_EVENT_CANREVIVE_STATUS_CHANGE, self._canRevive)
end

function PlayerPropertyProxy:handle_MSG_SC_NORUNONLYMSG(msg)
    self._forbidRun = msg:GetP1() > 0
end

function PlayerPropertyProxy:handle_MSG_SC_SENDKILLMONEXPEFF(msg)
    local header = msg:GetHeader()
    local msgLen = msg:GetDataLength()
    local dataString = msg:GetBodyStr()
    local actorID = dataString
    local effectID = header.param1
    EXPFly(actorID,effectID)
end

-- 功能是否应该移动至ItemManagerProxy
function PlayerPropertyProxy:handle_MSG_SC_PLAYER_ITEM_REMOVE(msg)
    local sliceStr = msg:GetBodyStr()
    local tag = msg:GetP0()  -- 1: 爆出时删除装备
    local MakeIndexList = {}
    local itemList = G_GetSplitArray(sliceStr, "/")
    for k,v in ipairs(itemList) do
        table.insert(MakeIndexList, v)
    end
    local ItemManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemManagerProxy)
    ItemManagerProxy:RemoveItems(MakeIndexList, tag)
end

function PlayerPropertyProxy:handle_MSG_SC_PLAY_MAGICBALL_EFFECT(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return false
    end
    jsonData.scale = jsonData.n9
    SLBridge:onLUAEvent(LUA_EVENT_PLAY_MAGICBALL_EFFECT, jsonData)
end

-- PK值改变后推送，最快每秒推送一次
function PlayerPropertyProxy:handle_MSG_SC_UPDATE_PLAYER_PKPOINT(msg)
    local value = msg:GetP0()
    self._pkPoint = value
    SLBridge:onLUAEvent(LUA_EVENT_PKPOINT_CHANGE)
end

function PlayerPropertyProxy:handle_MSG_SC_UPDATE_DIYATTR_TITLE(msg)
    local value = msg:GetBodyStr()
    if value and string.len(value) > 0 then
        local arrays = {}
        local showList = string.split(value, "|")
        for _, str in ipairs(showList) do
            if str and string.len(str) > 0 then
                local param = string.split(str, "#")
                local type = tonumber(param[1])
                if type then
                    arrays[type] = {}
                    arrays[type].name = string.len(param[2] or "") > 0 and param[2] or nil
                    arrays[type].color = param[3] and tonumber(param[3])
                end
            end
        end
        GUIDefineEx.TipsDiyAttrTypeTitle = arrays
    end
end

function PlayerPropertyProxy:onRegister()
    PlayerPropertyProxy.super.onRegister(self)
end

function PlayerPropertyProxy:RegisterMsgHandler()
    PlayerPropertyProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_RELIVE_STATE,    handler(self, self.handle_MSG_SC_PLAYER_RELIVE_STATE))         -- 是否可复活状态
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_PK_STATE,        handler(self, self.handle_MSG_SC_PLAYER_PK_STATE))             -- 角色PK状态
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_ITEM_REMOVE,     handler(self, self.handle_MSG_SC_PLAYER_ITEM_REMOVE))
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAY_MAGICBALL_EFFECT,  handler(self, self.handle_MSG_SC_PLAY_MAGICBALL_EFFECT))       -- 播放魔血球特效
    LuaRegisterMsgHandler(msgType.MSG_SC_NORUNONLYMSG,           handler(self, self.handle_MSG_SC_NORUNONLYMSG))
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_CANCHANGE_MODE,  handler(self, self.handle_MSG_SC_PLAYER_CANCHANGE_MODE))       -- 可改变攻击模式 
    LuaRegisterMsgHandler(msgType.MSG_SC_SENDKILLMONEXPEFF,      handler(self, self.handle_MSG_SC_SENDKILLMONEXPEFF))           -- 飘经验特效
    LuaRegisterMsgHandler(msgType.MSG_SC_UPDATE_PLAYER_PKPOINT,  handler(self, self.handle_MSG_SC_UPDATE_PLAYER_PKPOINT))       -- 刷新PK点数
    LuaRegisterMsgHandler(msgType.MSG_SC_UPDATE_DIYATTR_TITLE,   handler(self, self.handle_MSG_SC_UPDATE_DIYATTR_TITLE))        -- 更新自定义属性标题
end

return PlayerPropertyProxy
