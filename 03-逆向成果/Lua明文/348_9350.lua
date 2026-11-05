local BuffEntityAnim = require("buff/BuffEntityAnim")
local BuffEntityHorse = class("BuffEntitySneak", BuffEntityAnim)
local optionsUtils = requireUtil("optionsUtils")

function BuffEntityHorse:ctor(data)
    BuffEntityHorse.super.ctor(self,data)

    self._feature            = data.param and data.param.feature 
    self._bindMainHorseActor = nil

    self._autoRemove         = true     -- 设置了自动移除才走Tick
end

function BuffEntityHorse:Tick(dt)
    -- BuffEntityHorse.super.Tick(self, dt)         -- 不走super的Tick，防止被invalid

    if self:IsInvalid() then
        return false
    end
    
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if mainPlayer and self._bindMainHorseActor then
        local mainPosX, mainPosY            = mainPlayer:getPositionX(), mainPlayer:getPositionY()
        local bindHorsePosX, bindHorsePosY  = self._bindMainHorseActor:getPositionX(), self._bindMainHorseActor:getPositionY()
        if mainPosX ~= bindHorsePosX or mainPosY ~= bindHorsePosY then
            mainPlayer:setPosition(bindHorsePosX, bindHorsePosY)
        end
        if mainPlayer:GetMapX() ~= self._bindMainHorseActor:GetMapX() or mainPlayer:GetMapY() ~= self._bindMainHorseActor:GetMapY() then
            global.actorManager:SetActorMapXY( mainPlayer, self._bindMainHorseActor:GetMapX(), self._bindMainHorseActor:GetMapY() )
            global.Facade:sendNotification(global.NoticeTable.SceneFollowMainPlayer)
        end
    end
end

function BuffEntityHorse:UpdateParam(data)
    if not data then
        data = {}
    end
    if data.isExit then
        self._feature = {}
        self:disable()
        return
    end

    if self:IsInvalid() then
        self._isInvalid = false
    end

    self._feature = data.feature
    BuffEntityHorse.super.UpdateParam(self, data.param or data)

    local actor = global.actorManager:GetActor(self._actorID)
    if actor then
        self:HorseActor()
    end
end

function BuffEntityHorse:OnEnter()
    BuffEntityHorse.super.OnEnter(self)

    self:HorseActor()

    -- 通知上马
    SLBridge:onLUAEvent(LUA_EVENT_HORSE_UP, {actorID = self._actorID})
end

function BuffEntityHorse:HorseActor()
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor or not actor:IsPlayer() then
        return false
    end

    if actor:GetID() == actor:GetValueByKey(global.MMO.HORSE_MAIN) then
        self:MainHorseActor( actor )
    elseif actor:GetID() == actor:GetValueByKey(global.MMO.HORSE_COPILOT) then
        self:CopilotHorseActor( actor )
    end
end

function BuffEntityHorse:UpdateFeature(actor, feature)
    if not actor then
        return false
    end

    if not feature then
        feature = {}
    end
    local mountID        = feature.mountID
    local mountEff       = feature.mountEff
    local mountCloth     = feature.mountCloth
    local hairID         = feature.hairID or actor:GetAppearByID(global.MMO.P_F_HAIR)
    -- 如果是双人马
    local copilotHorseSex = nil
    if actor:IsPlayer() and actor:IsDoubleHorse() then
        copilotHorseSex = actor:GetSexID()
    end
    if actor:GetValueByKey(global.MMO.HORSE_COPILOT) then
        -- 主驾
        local actorID = actor:GetValueByKey(global.MMO.HORSE_MAIN)
        local mainHorseActor = actorID and global.actorManager:GetActor(actorID) or nil
        if mainHorseActor then
            mountID = mountID > 0 and (mountID + mainHorseActor:GetSexID() + 1) or mountID
            mountEff = mountEff > 0 and (mountEff + mainHorseActor:GetSexID() + 1) or mountEff
            mountCloth = mountCloth > 0 and (mountCloth + mainHorseActor:GetSexID() + 1) or mountCloth
        end
        
        --副驾的性别
        local copilotHorseActor = global.actorManager:GetActor(actor:GetValueByKey(global.MMO.HORSE_COPILOT))
        if copilotHorseActor then
            copilotHorseSex = copilotHorseActor:GetSexID()            
        end
    elseif feature.isDown then --如果是下马
        if not actor:GetValueByKey(global.MMO.HORSE_MAIN) then
            copilotHorseSex = nil
            mountID = nil
            mountEff = nil
            mountCloth = nil
        else
            mountID = mountID > 0 and (mountID - actor:GetSexID() - 1) or mountID
            mountEff = mountEff > 0 and (mountEff - actor:GetSexID() - 1) or mountEff
            mountCloth = mountCloth > 0 and (mountCloth - actor:GetSexID() - 1) or mountCloth
        end
    end

    actor:SetKeyValue(global.MMO.HORSE_SEX, copilotHorseSex)

    actor:SetAppearByID(global.MMO.P_F_MONSTER, mountID or 0) 
    actor:SetAppearByID(global.MMO.P_F_MONSTER_EFF, mountEff or 0)
    actor:SetAppearByID(global.MMO.P_F_MONSTER_CLOTH, mountCloth or 0)
    actor:SetAppearByID(global.MMO.P_F_HAIR, hairID)

    global.Facade:sendNotification( global.NoticeTable.DelayActorFeatureChange, actor:GetID())
end

-- 主驾
function BuffEntityHorse:MainHorseActor( actor )
    actor:GetNode():setVisible(true)

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

    -- 刷新名字
    global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabel, actor:GetID())

    -- 调整hud位置
    global.HUDManager:SetHorseOffset(actor:GetID(), ActorHud.HUD_OFFSET and ActorHud.HUD_OFFSET.HORSE or global.MMO.HUD_OFFSET_HORSE)
    global.HUDManager:SetHorseOffsetLabel(actor:GetID(), ActorHud.HUD_OFFSET and ActorHud.HUD_OFFSET.HORSE_LABEL or global.MMO.HUD_OFFSET_HORSE_LABEL)
    local hudTop = actor:GetHUDTop()
    local actorpos = actor:getPosition()
    global.HUDManager:setPosition(actor:GetID(), actorpos.x, actorpos.y + hudTop)

    self:UpdateFeature(actor, self._feature)
end

-- 副驾
function BuffEntityHorse:CopilotHorseActor( actor )
    
    if actor:IsMainPlayer() then
        local mainHorseID = actor:GetValueByKey(global.MMO.HORSE_MAIN)
        if mainHorseID then
            self._bindMainHorseActor = global.actorManager:GetActor(mainHorseID)
        end
    end

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

    -- 刷新名字
    global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabel, actor:GetID())
end

function BuffEntityHorse:UnHorseActor()
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor or not actor:IsPlayer() then
        local mainPlayer = global.gamePlayerController:GetMainPlayer()
        if self._actorID ~= mainPlayer:GetValueByKey(global.MMO.HORSE_MAIN) then
            return false
        end
        actor = mainPlayer
        self._actorID = mainPlayer:GetID()
    end

    actor:GetNode():setVisible(true)
    actor:DirtyAnimFlag()

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

    -- 刷新名字
    global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabel, actor:GetID())

    -- 调整hud位置
    global.HUDManager:SetHorseOffset(actor:GetID())
    global.HUDManager:SetHorseOffsetLabel(actor:GetID())
    local hudTop = actor:GetHUDTop()
    local actorpos = actor:getPosition()
    global.HUDManager:setPosition(actor:GetID(), actorpos.x, actorpos.y + hudTop)

    self:UpdateFeature(actor, self._feature)
end

function BuffEntityHorse:OnExit()
    BuffEntityHorse.super.OnExit(self)

    self:UnHorseActor()

    -- 通知下马
    SLBridge:onLUAEvent(LUA_EVENT_HORSE_DOWN, {actorID = self._actorID})
end

return BuffEntityHorse