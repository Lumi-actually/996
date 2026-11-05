local BuffEntityAnim = require("buff/BuffEntityAnim")
local BuffEntitySneak = class("BuffEntitySneak", BuffEntityAnim)
local optionsUtils = requireUtil("optionsUtils")
local checkSneakTempP1 = cc.p(0, 0)
local checkSneakTempP2 = cc.p(0, 0)

function BuffEntitySneak:ctor(data)
    BuffEntitySneak.super.ctor(self, data)
    
    self._isSneak = false --潜行状态
    self._range   = 2     --范围内显示
end

function BuffEntitySneak:OnEnter()
    BuffEntitySneak.super.OnEnter(self)

    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return false
    end

    actor:SetKeyValue(global.MMO.ACT_SNEAK, true)

    local isSneak = self:CheckSneak()
    if self._isSneak ~= isSneak then
        self._isSneak = isSneak
        if isSneak then
            self:SneakActor()
        else
            self:UnSneakActor()
        end
    end

    global.BuffManager:AddHandleOnMainActBegin(self._actorID, handler(self, self.OnMainPlayerHandle))
end

function BuffEntitySneak:OnExit()
    BuffEntitySneak.super.OnExit(self)

    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return false
    end

    actor:SetKeyValue(global.MMO.ACT_SNEAK, false)

    self:UnSneakActor()

    global.BuffManager:RemoveHandleOnMainActBegin(self._actorID)
end

function BuffEntitySneak:CheckSneak()
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return false
    end

    if actor:IsPlayer() and actor:IsMainPlayer() then
        return false
    end

    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return false
    end

    checkSneakTempP1.x = mainPlayer:GetMapX()
    checkSneakTempP1.y = mainPlayer:GetMapY()
    checkSneakTempP2.x = actor:GetMapX()
    checkSneakTempP2.y = actor:GetMapY()
    
    if cc.pGetDistance(checkSneakTempP2, checkSneakTempP1) > self._range then
        return true
    end
    return false
end

function BuffEntitySneak:OnMainPlayerHandle(actor, act)
    local isSneak = self:CheckSneak()
    if self._isSneak ~= isSneak then
        self._isSneak = isSneak
        if isSneak then
            self:SneakActor()
        else
            self:UnSneakActor()
        end
    end
end

function BuffEntitySneak:SneakActor()
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return false
    end

    if not actor:IsPlayer() then
        return false
    end

    -- 判断目标是否是潜行者，如果是，就清理目标
    local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    if PlayerInputProxy:GetTargetID() == self._actorID then
        PlayerInputProxy:ClearTarget()
    end

    actor:SetKeyValue(global.MMO.HUD_SNEAK, true)
    actor:GetNode():setVisible(false)
    
    -- Hp、Mp
    optionsUtils:RefreshHUDHMpLabelVisible(actor)
    -- 血条
    optionsUtils:CheckHUDHpBarVisible(actor)
    -- 蓝条
    optionsUtils:CheckHUDMpBarVisible(actor)
    -- 内功条
    optionsUtils:CheckHUDNGBarVisible(actor)
    -- 人名、行会、称号、顶戴
    optionsUtils:RefreshLabelVisible(actor)

    optionsUtils:RefreshPlayerVisible(actor)
    optionsUtils:RefreshPlayerBVisible(actor)

    -- 身上的特效
    global.ActorEffectManager:RefreshActorEffectVisible(self._actorID, false)

    -- 身上的buff特效
    global.BuffManager:UpdateBuffItemVisible(self._actorID, false)

    -- 刷新附近
    SLBridge:onLUAEvent(LUA_EVENT_MAIN_NEAR_REFRESH, {actorID = self._actorID})
end

function BuffEntitySneak:UnSneakActor()
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return false
    end

    if not actor:IsPlayer() then
        return false
    end

    actor:SetKeyValue(global.MMO.HUD_SNEAK, false)
    actor:GetNode():setVisible(true)
    actor:DirtyAnimFlag()

    -- 清理选中目标
    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    if inputProxy:GetTargetID() == self._actorID then
        inputProxy:ClearTarget()
    end

    -- Hp、Mp
    optionsUtils:RefreshHUDHMpLabelVisible(actor)
    -- 血条
    optionsUtils:CheckHUDHpBarVisible(actor)
    -- 蓝条
    optionsUtils:CheckHUDMpBarVisible(actor)
    -- 内功条
    optionsUtils:CheckHUDNGBarVisible(actor)
    -- 人名、行会、称号、顶戴
    optionsUtils:RefreshLabelVisible(actor)

    optionsUtils:RefreshPlayerVisible(actor)
    optionsUtils:RefreshPlayerBVisible(actor)

    -- 身上的特效
    global.ActorEffectManager:RefreshActorEffectVisible(self._actorID, true)

    -- 身上的buff特效
    global.BuffManager:UpdateBuffItemVisible(self._actorID, true)

    -- 刷新附近
    SLBridge:onLUAEvent(LUA_EVENT_MAIN_NEAR_REFRESH, {actorID = self._actorID})
end

function BuffEntitySneak:setPosition(x, y)
    BuffEntitySneak.super.setPosition(self, x, y)

    local isSneak = self:CheckSneak()
    if self._isSneak ~= isSneak then
        self._isSneak = isSneak
        if isSneak then
            self:SneakActor()
        else
            self:UnSneakActor()
        end
    end
end

return BuffEntitySneak