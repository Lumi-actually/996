local DebugMediator = requireMediator("DebugMediator")
local BuffManager = class("BuffManager", DebugMediator)
BuffManager.NAME = "BuffManager"

local BuffEntityIce       = require("buff/BuffEntityIce")
local BuffEntityAnim      = require("buff/BuffEntityAnim")
local BuffEntityColor     = require("buff/BuffEntityColor")
local BuffEntityColors    = require("buff/BuffEntityColors")
local BuffEntityFreezed   = require("buff/BuffEntityFreezed")
local BuffEntityCloaking  = require("buff/BuffEntityCloaking")
local BuffEntityStoneMode = require("buff/BuffEntityStoneMode")
local BuffEntityAvatar    = require("buff/BuffEntityAvatar")
local BuffEntitySneak     = require("buff/BuffEntitySneak")
local BuffEntityHorse     = require("buff/BuffEntityHorse")
local BuffEntityPoisonTransparent = require("buff/BuffEntityPoisonTransparent")

local mmo = global.MMO
local updateBuffShareT = {}
local shareBuffTab = {}

function BuffManager:ctor()
    BuffManager.super.ctor(self, self.NAME)

    self._buffItems = {}
    self._tickItems = {}
    self._handleOnMainActBegin = {}     --潜行buff 需监听主玩家位置
end

function BuffManager:destory()
    global.Facade:removeMediator(BuffManager.NAME)
end

function BuffManager:create()
    local _this = BuffManager.new()
    global.Facade:registerMediator(_this)
    return _this
end

function BuffManager:listNotificationInterests()
    return {
        global.NoticeTable.AddBuffEntity,
        global.NoticeTable.ActorBuffPresentUpdate,
        global.NoticeTable.DropItemOutOfView,
        global.NoticeTable.ActorOutOfView,
        global.NoticeTable.RefreshActorHP,
        global.NoticeTable.RefreshBuffVisible,
        global.NoticeTable.MainPlayerActionBegan,
    }
end

function BuffManager:handleNotification(notification)
    local id = notification:getName()
    local data = notification:getBody()

    if global.NoticeTable.AddBuffEntity == id then
        self:AddBuff(data)

    elseif global.NoticeTable.ActorBuffPresentUpdate == id then
        self:OnActorBuffPresentUpdate(data)

    elseif global.NoticeTable.DropItemOutOfView == id then
        self:OnDropItemOutOfView(data)

    elseif global.NoticeTable.ActorOutOfView == id then
        self:OnActorOutOfView(data)

    elseif global.NoticeTable.RefreshActorHP == id then
        self:OnRefreshActorHP(data)

    elseif global.NoticeTable.RefreshBuffVisible == id then
        self:OnRefreshBuffVisible(data)

    elseif global.NoticeTable.MainPlayerActionBegan == id then
        self:OnMainActBeginHanlder(data)

    end
end

function BuffManager:Tick(dt)
    for actorID, items in pairs(self._buffItems) do
        for buffID, item in pairs(items) do
            if item:IsInvalid() then
                self:RmvBuff(actorID, buffID)
            end
        end
    end

    for _, items in pairs(self._tickItems) do
        for k, item in pairs(items) do
            item:Tick(dt)
        end
    end
end

local buffItemsC = {
    [mmo.BUFF_ID_COLORS]             = function(data) return BuffEntityColors.new(data)            end,
    [mmo.BUFF_ID_STONE_MODE]         = function(data) return BuffEntityStoneMode.new(data)         end,
    [mmo.BUFF_ID_POISON_TRANSPARENT] = function(data) return BuffEntityPoisonTransparent.new(data) end,
    [mmo.BUFF_ID_POISONING_RED]      = function(data) return BuffEntityColor.new(data)             end,
    [mmo.BUFF_ID_POISONING_GREEN]    = function(data) return BuffEntityColor.new(data)             end,

    [mmo.BUFF_ID_FREEZED_GRAY]       = function(data) return BuffEntityFreezed.new(data)           end,
    [mmo.BUFF_ID_CLOAKING]           = function(data) return BuffEntityCloaking.new(data)          end,
    [mmo.BUFF_ID_COLOR]              = function(data) return BuffEntityColor.new(data)             end,
    [mmo.BUFF_ID_ICE]                = function(data) return BuffEntityIce.new(data)               end,
    [mmo.BUFF_ID_THUNDER_SWORD]      = function(data) return BuffEntityColor.new(data)             end,

    [mmo.BUFF_ID_SNEAK]              = function(data) return BuffEntitySneak.new(data)             end,
    [mmo.BUFF_ID_HORSE]              = function(data) return BuffEntityHorse.new(data)             end,
    [mmo.BUFF_ID_POISONING_PURPLE]   = function(data) return BuffEntityColor.new(data)             end,

    [-1] = function(data)
        local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        return BuffProxy:IsAvatarBuff(data.buffID) and BuffEntityAvatar.new(data) or BuffEntityAnim.new(data)
    end
}

-- custom buff
local customBuff = {
    [mmo.BUFF_ID_HORSE] = mmo.BUFF_ID_HORSE
}

local colorBuffMap = {
    [mmo.BUFF_ID_ICE]               = 1,   -- 冰冻
    [mmo.BUFF_ID_COLOR]             = 1,   -- 变色
    [mmo.BUFF_ID_COLORS]            = 1,   -- 换色
    [mmo.BUFF_ID_FREEZED_GRAY]      = 1,   -- 麻痹
    [mmo.BUFF_ID_POISONING_RED]     = 1,   -- 红毒
    [mmo.BUFF_ID_POISONING_GREEN]   = 1,   -- 绿毒
    [mmo.BUFF_ID_THUNDER_SWORD]     = 1,   -- 雷霆
    [mmo.BUFF_ID_POISONING_PURPLE]  = 1,   -- 紫毒
}

local ignoreBuffMap = {
    [mmo.BUFF_ID_POISON_TRANSPARENT]    = true,
    [mmo.BUFF_ID_STONE_MODE]            = true,
    [mmo.BUFF_ID_SNEAK]                 = true,
}

function BuffManager:CreateBuffItem(data)
    local buffID = data.buffID
    return (buffItemsC[buffID] or buffItemsC[-1])(data)
end

--------------------------------------------------------
function BuffManager:GetDataByUID(uid)
    local data, num = {}, 0

    if self:IsEmpty(uid) then
        return data, num
    end

    local items = self:GetItemsByActorID(uid)

    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local config, n = BuffProxy:GetConfig()
    for i = 1, n do
        local v = config[i]
        if v and items[v.ID] and v.buffshow ~= 1 then
            local item = items[v.ID]
            num = num + 1
            data[num] = {
                id      = v.ID,
                param   = item:GetData().param,
                endTime = item:GetEndTime(),
                ol      = item:GetOl()
            }
        end
    end

    return data, num
end

function BuffManager:GetCountByUID(uid)
    local _, nItem = self:GetDataByUID(uid)
    return nItem
end
--------------------------------------------------------

--------------------------------------------------------
local emptyT = {}
function BuffManager:GetItemsByActorID(actorID, isAddEmpty)
    if not self._buffItems[actorID] then
        if isAddEmpty then 
            self._buffItems[actorID] = {}
        else
            return emptyT
        end
    end
    return self._buffItems[actorID]
end

function BuffManager:GetItem(actorID, buffID)
    local items = self:GetItemsByActorID(actorID)
    return items[buffID]
end

function BuffManager:IsEmpty(actorID)
    return (not self._buffItems[actorID]) or (not next(self._buffItems[actorID]))
end
--------------------------------------------------------

--------------------------------------------------------
function BuffManager:CleanupByActorID(actorID)
    if (self:IsEmpty(actorID)) then
        return
    end

    local items = self:GetItemsByActorID(actorID)
    for _, item in pairs(items) do
        self:RmvBuff(item:GetActorID(), item:GetBuffID())
    end
end

function BuffManager:Cleanup()
    for _, items in pairs(self._buffItems) do
        for _, item in pairs(items) do
            self:CleanupByActorID(item:GetActorID())
        end
    end
    self._buffItems = {}
    self._tickItems = {}
    self._handleOnMainActBegin = {}
end
--------------------------------------------------------

--------------------------------------------------------
function BuffManager:AddBuff(data)
    -- print("buff began, actorID: " .. data.actorID .. "  buffID:" .. data.buffID)
    local actorID = data.actorID
    local buffID = data.buffID
    local param = data.param
    local ol    = data.ol

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    -- empty
    if self:IsEmpty(actorID) then
        self._buffItems[actorID] = {}
        self._tickItems[actorID] = {}
    end

    -- exist, update it
    if self:GetItem(actorID, buffID) then
        self:UpdateBuff(data)
        return
    end

    local items = self:GetItemsByActorID(actorID, true)
    local item    = self:CreateBuffItem(data)
    items[buffID] = item
    item:OnEnter()

    shareBuffTab.actorID = actorID
    shareBuffTab.buffID = buffID
    SLBridge:onLUAEvent(LUA_EVENT_ACTOR_ENTER_BUFF, shareBuffTab)

    if item:IsAuto() then
        self._tickItems[actorID] = self._tickItems[actorID] or {}
        self._tickItems[actorID][buffID] = item
    end

    updateBuffShareT.actorID = actorID
    updateBuffShareT.buffID  = buffID
    updateBuffShareT.type    = 1

    -- 主玩家Buff同步
    if actorID == global.gamePlayerController:GetMainPlayerID() then
        local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        BuffProxy:AddBuffItem({
            id    = buffID,
            param = param,
            ol    = ol
        })

        SLBridge:onLUAEvent(LUA_EVENT_MAINPLAYER_BUFF_UPDATE, updateBuffShareT)
    end

    -- 主玩家英雄buff提示
    if actor:IsHero() and actor:GetMasterID() == global.gamePlayerController:GetMainPlayerID() then
        local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        BuffProxy:AddBuffItem({
            id    = buffID,
            param = param,
            ol    = ol
        }, true)
    end

    -- notice
    SLBridge:onLUAEvent(LUA_EVENT_BUFF_UPDATE, updateBuffShareT)

    return true
end

function BuffManager:UpdateBuff(data)
    local actorID = data.actorID
    local buffID = data.buffID
    local param = data.param
    local ol    = data.ol  -- buff 层级

    if (self:IsEmpty(actorID)) then
        return false
    end

    local item = self:GetItem(actorID, buffID)
    if item then
        item:UpdateParam(param)
        item:UpdateOl(ol)
        item:UpdatePresent()

        shareBuffTab.actorID = actorID
        shareBuffTab.buffID = buffID
        SLBridge:onLUAEvent(LUA_EVENT_ACTOR_UPDATE_BUFF_PRESENT, shareBuffTab)
    end

    updateBuffShareT.actorID = actorID
    updateBuffShareT.buffID  = buffID
    updateBuffShareT.type    = 2

    -- 主玩家Buff同步
    if actorID == global.gamePlayerController:GetMainPlayerID() then
        local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        BuffProxy:UpdateBuffItem({
            id    = buffID,
            param = param,
            ol    = ol
        })

        SLBridge:onLUAEvent(LUA_EVENT_MAINPLAYER_BUFF_UPDATE, updateBuffShareT)
    end

    -- notice
    SLBridge:onLUAEvent(LUA_EVENT_BUFF_UPDATE, updateBuffShareT)
end

function BuffManager:RmvBuff(actorID, buffID)
    -- print("buff ended, actorID: " .. actorID .. "  buffID:" .. buffID)
    -- not exist
    if (self:IsEmpty(actorID)) then
        return false
    end

    -- do exist & delete it
    local items = self:GetItemsByActorID(actorID)
    local item = items[buffID]
    if item then
        self._tickItems[actorID] = self._tickItems[actorID] or {}
        self._tickItems[actorID][buffID] = nil

        items[buffID] = nil
        item:OnExit()

        shareBuffTab.actorID = actorID
        shareBuffTab.buffID = buffID
        SLBridge:onLUAEvent(LUA_EVENT_ACTOR_EXIT_BUFF, shareBuffTab)
    end

    if self:IsEmpty(actorID) then
        self._buffItems[actorID] = nil
        self._tickItems[actorID] = nil
    end

    updateBuffShareT.actorID = actorID
    updateBuffShareT.buffID  = buffID
    updateBuffShareT.type    = 0

    -- 主玩家Buff同步
    if actorID == global.gamePlayerController:GetMainPlayerID() then
        local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        BuffProxy:RmvBuffItem({ id = buffID })

        SLBridge:onLUAEvent(LUA_EVENT_MAINPLAYER_BUFF_UPDATE, updateBuffShareT)
    end

    -- notice
    SLBridge:onLUAEvent(LUA_EVENT_BUFF_UPDATE, updateBuffShareT)

    return true
end
--------------------------------------------------------

--------------------------------------------------------
function BuffManager:handleBuffInit(netPkg)
    local actorID = netPkg:GetP0Str()
    -- 没有BUFF
    local buffData = netPkg:GetBodyValues({"i4", "i8", "i2", "i4"}, {"id", "param", "ol", "p1"})
    if not buffData and self:IsEmpty(actorID) then  -- 进出跨服初始化来刷新Buff
        return nil
    end

    buffData = buffData or {}

    local added = {}
    local removed = {}
    local changed = {}

    local items = {}
    if not self:IsEmpty(actorID) then
        items = self:GetItemsByActorID(actorID)
    end

    -- check added & changed
    for _, v in pairs(buffData) do
        if (not items[v.id]) then
            added[v.id] = v
        else
            changed[v.id] = v
        end
    end

    -- check removed
    local tmp = {}
    for _, v in pairs(buffData) do
        tmp[v.id] = 1
    end
    for _, v in pairs(items) do
        if not tmp[v:GetBuffID()] and not customBuff[v:GetBuffID()] then
            table.insert(removed, v:GetBuffID())
        end
    end

    for _, v in pairs(changed) do
        self:AddBuff({ actorID = actorID, buffID = v.id, param = v.param, ol = v.ol, replaceId = v.p1 })
    end
    for _, v in pairs(added) do
        self:AddBuff({ actorID = actorID, buffID = v.id, param = v.param, ol = v.ol, replaceId = v.p1 })
    end
    for _, v in pairs(removed) do
        self:RmvBuff(actorID, v)
    end
end

function BuffManager:handleBuffAdd(netPkg)
    local headBuffer = netPkg:GetHeadLuaBuffer()
    local userId = headBuffer:ReadInt64Str()
    local buffID = headBuffer:ReadInt()
    local param = headBuffer:ReadInt()
    local ol = headBuffer:ReadInt()
    local replaceId = headBuffer:ReadInt()--替换buffid特效  魔法盾需要显示其它的特效
    local exParam = headBuffer:ReadInt()

    -- 新增/更新
    self:AddBuff({actorID = userId, buffID = buffID, param = param, ol = ol, replaceId = replaceId, exParam = exParam})

    -- print("----------------------BUFF add", buffID, param, userId)
end

function BuffManager:handleBuffRmv(netPkg)
    local headBuffer = netPkg:GetHeadLuaBuffer()
    local userId = headBuffer:ReadInt64Str()
    local buffID = headBuffer:ReadInt()

    -- 
    self:RmvBuff(userId, buffID)

    -- 
    -- print("----------------------BUFF rmv", buffID, userId)
end
--------------------------------------------------------

--------------------------------------------------------
function BuffManager:OnActorBuffPresentUpdate(actorID)
    -- 更新buff表现，外观改变需要更新buff表现....
    if self:IsEmpty(actorID) then
        return
    end

    local items = self:GetItemsByActorID(actorID)
    for _, v in pairs(items) do
        v:UpdatePresent()
        shareBuffTab.actorID = actorID
        shareBuffTab.buffID = v:GetBuffID()
        SLBridge:onLUAEvent(LUA_EVENT_ACTOR_UPDATE_BUFF_PRESENT, shareBuffTab)
    end
end

function BuffManager:UpdateBuffSfxDir(actorID)
    if self:IsEmpty(actorID) then
        return
    end
    
    local items = self:GetItemsByActorID(actorID)
    for _, v in pairs(items) do
        v:UpdateSfxDir()
    end
end

function BuffManager:setPosition(actorID, x, y)
    -- 更新buff表现，外观改变需要更新buff表现....
    if self:IsEmpty(actorID) then
        return
    end

    local items = self:GetItemsByActorID(actorID)
    for _, v in pairs(items) do
        v:setPosition(x, y)
    end
end

function BuffManager:OnRefreshActorHP(data)
    if not data.isDamage then
        return
    end
    if self:IsEmpty(data.actorID) then
        return
    end
    local items = self:GetItemsByActorID(data.actorID)
    for _, v in pairs(items) do
        v:OnActorStuck()
    end
end

function BuffManager:OnDropItemOutOfView(actorID)
    self:CleanupByActorID(actorID)
end

function BuffManager:OnActorOutOfView(actorID)
    self:CleanupByActorID(actorID)
end

function BuffManager:OnRefreshBuffVisible(actor)
    if actor and (actor:IsDeath() or actor:IsDie()) then
        local isShow = CHECK_SETTING(global.MMO.SETTING_IDX_HIDE_MONSTER_BODY) ~= 1
        self:UpdateBuffItemVisible(actor:GetID(), isShow)
    end
end

--------------------------------------------------------
function BuffManager:IsAllowAnimUpdate(actorID)
    if self:IsEmpty(actorID) then
        return true
    end

    local items = self:GetItemsByActorID(actorID)
    for _, v in pairs(items) do
        if not v:IsAllowAnimUpdate() then
            return false
        end
    end
    return true
end

-- 是否中毒
function BuffManager:IsPoisoning(actorID)
    if self:IsEmpty(actorID) then
        return false
    end

    local items = self:GetItemsByActorID(actorID)
    for _, v in pairs(items) do
        if v:GetBuffID() == mmo.BUFF_ID_POISONING_RED or v:GetBuffID() == mmo.BUFF_ID_POISONING_GREEN then
            return true
        end
    end
    return false
end

-- 是否中红毒
function BuffManager:IsPoisoningRed(actorID)
    return self:IsHaveOneBuff(actorID, mmo.BUFF_ID_POISONING_RED)
end

-- 是否中绿毒
function BuffManager:IsPoisoningGreen(actorID)
    return self:IsHaveOneBuff(actorID, mmo.BUFF_ID_POISONING_GREEN)
end

-- 是否有护盾
function BuffManager:IsHaveShield(actorID)
    return self:IsHaveOneBuff(actorID, mmo.BUFF_ID_MAGIC_SHIELD)
end

-- 是否麻痹
function BuffManager:IsFreezed(actorID)
    return self:IsHaveOneBuff(actorID, mmo.BUFF_ID_FREEZED_GRAY)
end

-- 神圣战甲术
function BuffManager:IsHaveAngelShield(actorID)
    return self:IsHaveOneBuff(actorID, mmo.BUFF_ID_ANGEL_SHIELD)
end

-- 是否有幽灵盾
function BuffManager:IsHaveGhostShield(actorID)
    return self:IsHaveOneBuff(actorID, mmo.BUFF_ID_GHOST_SHIELD)
end

-- 是否某个buff
function BuffManager:IsHaveOneBuff(actorID, buffID)
    if self:IsEmpty(actorID) then
        return false
    end

    local items = self:GetItemsByActorID(actorID)
    for _, v in pairs(items) do
        if v:GetBuffID() == buffID then
            return true
        end
    end
    return false
end

-- 自动释放该技能是否有该buff
function BuffManager:CheckAutoBuffBySkillID(actorID, skillID)
    if self:IsEmpty(actorID) then
        return false
    end

    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local skillBuff = BuffProxy:GetNoSkillAuto(skillID)
    if not skillBuff then
        return false
    end

    local items = self:GetItemsByActorID(actorID)
    for _, v in pairs(items) do
        local buffID = v:GetBuffID()
        if skillBuff[buffID] then
            return buffID
        end
    end

    return false
end

-- 释放该技能是否有该buff
function BuffManager:CheckLaunchBuffBySkillID(actorID, skillID)
    if self:IsEmpty(actorID) then
        return false
    end

    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local skillBuff = BuffProxy:GetNoSkillLaunch(skillID)
    if not skillBuff then
        return false
    end

    local items = self:GetItemsByActorID(actorID)
    for _, v in pairs(items) do
        local buffID = v:GetBuffID()
        if skillBuff[buffID] then
            return buffID
        end
    end

    return false
end

function BuffManager:IsInColorBuff(actorID)
    -- 是否在变色buff
    if self:IsEmpty(actorID) then
        return false
    end

    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local items = self:GetItemsByActorID(actorID)
    for _, v in pairs(items) do
        local buffID = v:GetBuffID()
        if colorBuffMap[buffID] or BuffProxy:GetBuffColorByID(buffID) then
            return true
        end
    end

    return false
end

local ColorCache = {}
-- changeColorID: 循环变色buff 当前颜色ID
function BuffManager:CheckBuffColor(actorID, changeColorID)
    -- 是否某个buff
    local color = cc.Color3B.WHITE
    if self:IsEmpty(actorID) then
        return color
    end

    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local items = self:GetItemsByActorID(actorID)
    local buffColorList = {}
    for _, v in pairs(items) do
        local buffColorOrder = BuffProxy:GetBuffColorOrderByID(v:GetBuffID())
        if v:GetBuffID() == mmo.BUFF_ID_COLOR then
            if not ColorCache[v:GetParam()] then
                ColorCache[v:GetParam()] = GET_COLOR_BYID_C3B(v:GetParam())
            end
            local buffColor = ColorCache[v:GetParam()]
            table.insert(buffColorList, {color = buffColor, colorOrder = buffColorOrder})
        elseif v:GetBuffID() == mmo.BUFF_ID_COLORS and changeColorID then
            if not ColorCache[changeColorID] then
                ColorCache[changeColorID] = GET_COLOR_BYID_C3B(changeColorID)
            end
            local buffColor = ColorCache[changeColorID]
            table.insert(buffColorList, {color = buffColor, colorOrder = buffColorOrder})
        elseif not ignoreBuffMap[v:GetBuffID()] then
            local buffColor = BuffProxy:GetBuffColorByID(v:GetBuffID())
            if buffColor then
                table.insert(buffColorList, {color = buffColor, colorOrder = buffColorOrder})
            end
        end
    end

    table.sort(buffColorList, function(a, b)
        return a.colorOrder > b.colorOrder
    end)

    if buffColorList and buffColorList[1] and buffColorList[1].color then
        color = buffColorList[1].color
    end

    return color
end

-- 通过buff id获取buff color
function BuffManager:CheckBuffColorByID(actorID, buffID)
    if not self:IsHaveOneBuff(buffID) then
        return self:CheckBuffColor(actorID)
    end

    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.Buff)
    local buffColor = BuffProxy:GetBuffColorByID(buffID)
    if buffColor then
        return buffColor
    end

    return self:CheckBuffColor(actorID)
end

function BuffManager:CheckBuffAvatar(actorID, buffID)
    -- 是否某个buff
    if self:IsEmpty(actorID) then
        return nil
    end

    -- 骑马
    local actor = global.actorManager:GetActor(actorID)
    if actor and actor:IsPlayer() and (actor:GetHorseMasterID() or actor:IsHoreseCopilot()) then
        return {
            avatarType = 1,
            avatarID = actor:GetAppearByID(global.MMO.P_F_MONSTER)
        }
    end

    local ret = nil
    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local items = self:GetItemsByActorID(actorID)
    for _, v in pairs(items) do
        local avatar = BuffProxy:GetBuffAvatarByID(v:GetBuffID())
        if avatar then
            ret = avatar
        end
        if v:GetBuffID() == buffID then
            break
        end
    end
    return ret
end

function BuffManager:CheckBuffScale(actorID, buffID)
    -- 是否没有buff
    if self:IsEmpty(actorID) then
        return 1
    end

    local ret = 1
    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local items = self:GetItemsByActorID(actorID)
    for _, v in pairs(items) do
        local scale = BuffProxy:GetBuffScaleByID(v:GetBuffID())
        if scale then
            ret = scale
        end
        if v:GetBuffID() == buffID then
            break
        end
    end
    return ret
end

-- 检测变形类型是否要删除，人物 -> 怪物 / 怪物 -> 人物是时需要
function BuffManager:CheckRmvBuffAvatar(actorID, avatar)
    if not actorID or not avatar then
        return false
    end

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return false
    end

    local sex = nil
    if avatar.avatarType == 0 then
        sex = avatar.avatarSex or actor:GetSexID()
    end
    local oldSex = actor:GetValueByKey(global.MMO.BUFF_PLAYER_AVATAR_SEX)
    actor:SetKeyValue(global.MMO.BUFF_PLAYER_AVATAR_SEX,sex)
    if (not oldSex and sex) or (not sex and oldSex) then
        return true
    end
    return false
end

function BuffManager:AddHandleOnMainActBegin(actorid,func)
    if not actorid then
        return
    end
    self._handleOnMainActBegin[actorid] = func
end

function BuffManager:RemoveHandleOnMainActBegin(actorid,func)
    if not actorid then
        return
    end
    self._handleOnMainActBegin[actorid] = nil
end

function BuffManager:OnMainActBeginHanlder(act)
    for k,v in pairs(self._handleOnMainActBegin) do
        v(act)
    end
end

function BuffManager:UpdateBuffItemVisible(actorID, allVisible)
    if allVisible == nil then
        -- 检测是不是副驾的玩家   副驾玩家的buff特效都不显示出来
        allVisible = true
        local actor = global.actorManager:GetActor(actorID)
        if actor and actor:IsPlayer() and actor:IsHoreseCopilot() then
            allVisible = false
        end
    end
    local visible = allVisible == true
    local items = self:GetItemsByActorID(actorID)
    for _, _item in pairs(items) do
        _item:setVisible(visible)
        _item:updatePosition()
    end
end

function BuffManager.OnUnloaded()
    BuffManager.super.OnUnloaded()
    global.BuffManager = nil
    global.Facade:removeMediator(BuffManager.NAME)
end

function BuffManager.Onloaded()
    BuffManager.super.Onloaded()
    local mediator = BuffManager.new()
    global.Facade:registerMediator(mediator)
    global.BuffManager = mediator
end

return BuffManager