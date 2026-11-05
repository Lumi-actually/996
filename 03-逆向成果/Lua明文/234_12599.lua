local DebugMediator = requireMediator("DebugMediator")
local actorRefreshController = class("actorRefreshController", DebugMediator)
actorRefreshController.NAME = "actorRefreshController"

local optionsUtils = requireUtil("optionsUtils")

local REFRESH_TYPE_HUDLABEL      = 1
local REFRESH_TYPE_HUDTITLE      = 2
local REFRESH_TYPE_FEATURE       = 3
local REFRESH_TYPE_HUDBAR        = 4
local REFRESH_TYPE_DIRTY_FEATURE = 5
local REFRESH_TYPE_HUDLABELCOLOR = 6

function actorRefreshController:ctor()
    actorRefreshController.super.ctor(self)

    self._createCache = {}
    self._refreshCache = {}

    self._npcCreateCache = {}
    self._npcRefreshCache = {}
end

function actorRefreshController:destory()
    global.Facade:removeMediator(actorRefreshController.NAME)
end

function actorRefreshController:create()
    local _this = actorRefreshController.new()
    global.Facade:registerMediator(_this)
    return _this
end

function actorRefreshController:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return 
    {
        noticeTable.ActorOutOfView,
        noticeTable.DropItemOutOfView,
        noticeTable.ActorEffectOutOfView,
        noticeTable.DelayRefreshHUDLabel,
        noticeTable.DelayRefreshHUDLabelColor,
        noticeTable.DelayRefreshHUDTitle,
        noticeTable.DelayActorFeatureChange,
        noticeTable.DelayDirtyFeature,
        noticeTable.DelayCreateHUDBar,
    }
end

function actorRefreshController:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()

    if noticeTable.ActorOutOfView == noticeID then
        self:OnActorOutOfView(data)

    elseif noticeTable.DropItemOutOfView == noticeID then
        self:OnDropItemOutOfView(data)

    elseif noticeTable.ActorEffectOutOfView == noticeID then
        self:OnActorEffectOutOfView(data)
        
    elseif noticeTable.DelayRefreshHUDLabel == noticeID then
        self:OnDelayRefreshHUDLabel(data)

    elseif noticeTable.DelayRefreshHUDLabelColor == noticeID then
        self:OnDelayRefreshHUDLabelColor(data)
        
    elseif noticeTable.DelayRefreshHUDTitle == noticeID then
        self:OnDelayRefreshHUDTitle(data)

    elseif noticeTable.DelayActorFeatureChange == noticeID then
        self:OnDelayActorFeatureChange(data)

    elseif noticeTable.DelayDirtyFeature == noticeID then
        self:OnDelayDirtyFeature(data)

    elseif noticeTable.DelayCreateHUDBar == noticeID then
        self:OnDelayCreateHUDBar(data)

    end
end

function actorRefreshController:Cleanup()
    self._createCache = {}
    self._refreshCache = {}

    self._npcCreateCache = {}
    self._npcRefreshCache = {}
end

function actorRefreshController:CleanupByActorID(actorID)
    self._createCache[actorID] = nil
    self._refreshCache[actorID] = nil

    self._npcCreateCache[actorID] = nil
    self._npcRefreshCache[actorID] = nil
end

function actorRefreshController:Tick()
    local n = 0
    for i = 1, 3 do
        n = n + self:NextCreate(self._npcCreateCache)
        self:NextRefresh(self._npcRefreshCache)
    end

    for i = n+1, 3 do
        self:NextCreate(self._createCache)
        self:NextRefresh(self._refreshCache)
    end
end

function actorRefreshController:NextCreate(caches)
    local actorID = next(caches)
    if not actorID then
        return 0
    end
    local cache = caches[actorID]

    -- hud bar
    if cache[REFRESH_TYPE_HUDBAR] then
        self:OnCreateHUDBar(actorID)
    end

    -- feature
    if cache[REFRESH_TYPE_FEATURE] then
        global.Facade:sendNotification( global.NoticeTable.ActorFeatureChange, actorID)
    end

    -- feature
    if cache[REFRESH_TYPE_DIRTY_FEATURE] then
        self:DirtyFeature(actorID)
    end

    -- cleanup
    caches[actorID] = nil

    return 1
end

function actorRefreshController:NextRefresh(caches)
    local actorID = next(caches)
    if not actorID then
        return nil
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then 
        caches[actorID] = nil
        return 
    end
    local refresh = caches[actorID]

    -- hud label
    if refresh[REFRESH_TYPE_HUDLABEL] then
        optionsUtils:InitHUDVisibleValue(actor, global.MMO.HUD_NAMELabel_VISIBLE)
        optionsUtils:InitHUDVisibleValue(actor, global.MMO.HUD_GUILDLabel_VISIBLE)
        optionsUtils:InitHUDVisibleValue(actor, global.MMO.HUD_TITLELabel_VISIBLE)

        global.Facade:sendNotification(global.NoticeTable.RefreshHUDLabel, actorID)
        global.Facade:sendNotification(global.NoticeTable.RefreshActorNameColor, actorID)
        -- hud label color
    elseif refresh[REFRESH_TYPE_HUDLABELCOLOR] then 
        global.Facade:sendNotification(global.NoticeTable.RefreshActorNameColor, actorID)
    end

    -- hud title
    if refresh[REFRESH_TYPE_HUDTITLE] then
        optionsUtils:InitHUDVisibleValue(actor, global.MMO.HUD_TITLE_VISIBLE)

        global.Facade:sendNotification(global.NoticeTable.RefreshHUDTitle, actorID)
    end

    -- cleanup
    caches[actorID] = nil
end

function actorRefreshController:OnActorOutOfView(actorID)
    if not actorID then
        return nil
    end

    self:CleanupByActorID(actorID)
end

function actorRefreshController:OnDropItemOutOfView(actorID)
    if not actorID then
        return nil
    end

    self:CleanupByActorID(actorID)
end

function actorRefreshController:OnActorEffectOutOfView(actorID)
    if not actorID then
        return nil
    end

    self:CleanupByActorID(actorID)
end

function actorRefreshController:OnDelayRefreshHUDLabel(data)
    local actorID = data
    if not actorID then
        return nil
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end
    local caches = actor:IsNPC() and self._npcRefreshCache or self._refreshCache

    caches[actorID] = caches[actorID] or {}
    caches[actorID][REFRESH_TYPE_HUDLABEL] = true
end

function actorRefreshController:OnDelayRefreshHUDLabelColor(actorID)
    if not actorID then
        return nil
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end
    local caches = actor:IsNPC() and self._npcRefreshCache or self._refreshCache

    caches[actorID] = caches[actorID] or {}
    caches[actorID][REFRESH_TYPE_HUDLABELCOLOR] = true
end

function actorRefreshController:OnDelayRefreshHUDTitle(actorID)
    if not actorID then
        return nil
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    local caches = actor:IsNPC() and self._npcRefreshCache or self._refreshCache
    caches[actorID] = caches[actorID] or {}
    caches[actorID][REFRESH_TYPE_HUDTITLE] = true
end

function actorRefreshController:OnDelayActorFeatureChange(actorID)
    if not actorID  then
        return nil
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    local caches = actor:IsNPC() and self._npcCreateCache or self._createCache
    caches[actorID] = caches[actorID] or {}
    caches[actorID][REFRESH_TYPE_FEATURE] = true
end

function actorRefreshController:OnDelayCreateHUDBar(actorID)
    if not actorID  then
        return nil
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    local caches = actor:IsNPC() and self._npcCreateCache or self._createCache
    caches[actorID] = caches[actorID] or {}
    caches[actorID][REFRESH_TYPE_HUDBAR] = true
end

function actorRefreshController:OnCreateHUDBar(actorID)
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return false
    end

    -- HUD for actor  
    local hpSpriteID = global.MMO.HP_SPRITE_ID
    if actor:IsPlayer() and actor:IsMainPlayer() and SL:GetValue("GAME_DATA", "hight_main_player_hp") == 1 then
        hpSpriteID = global.MMO.HP_MAIN_SPRITE_ID
    end
    local hpBgParam = ActorHud.GetHUDHPSpriteParam and ActorHud.GetHUDHPSpriteParam(actorID, true) or {}
    local hpBorder  = global.HUDManager:CreateHUDBar(actorID, global.MMO.HUD_SPRITE_HP_BG, hpBgParam.offset or global.MMO.HUD_OFFSET_BG_1,  hpBgParam.id or global.MMO.HP_BG_SPRITE_ID)
    local hpParam   = ActorHud.GetHUDHPSpriteParam and ActorHud.GetHUDHPSpriteParam(actorID) or {}
    local hpBar     = global.HUDManager:CreateHUDBar(actorID, global.MMO.HUD_SPRITE_HP, hpParam.offset or global.MMO.HUD_OFFSET_1, hpParam.id or hpSpriteID)
    actor.mHUDUI[global.MMO.HUDHPUI_BAR]    = hpBar
    actor.mHUDUI[global.MMO.HUDHPUI_BORDER] = hpBorder
    local HP      = actor:GetHP()
    local maxHP   = actor:GetMaxHP()

    local percent = nil
    if ActorHud.GetHUDHPBarPer then
        percent = ActorHud.GetHUDHPBarPer(actor:GetID())
    end
    if not percent then
        percent = HP / maxHP
        if global.ConstantConfig.showFewHp == 1 and not actor:GetValueByKey(global.MMO.HUD_BAR_SHOW_FULL_HP) then
            local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
            local heroActor  = HeroPropertyProxy:GetHeroActor()
            local mainPlayer = global.gamePlayerController:GetMainPlayer()
            if actor ~= heroActor and actor ~= mainPlayer then 
                percent = 1
            end
        end
    end

    global.HUDManager:SetHUDBarPercent( hpBar, percent )

    -- HUD MP for actor
    local mpBgParam = ActorHud.GetHUDMPSpriteParam and ActorHud.GetHUDMPSpriteParam(actorID, true) or {}
    local mpBorder  = global.HUDManager:CreateHUDBar(actorID, global.MMO.HUD_SPRITE_MP_BG, mpBgParam.offset or global.MMO.HUD_OFFSET_BG_2, mpBgParam.id or global.MMO.HP_BG_SPRITE_ID)
    local mpParam   = ActorHud.GetHUDMPSpriteParam and ActorHud.GetHUDMPSpriteParam(actorID) or {}
    local mpBar     = global.HUDManager:CreateHUDBar(actorID, global.MMO.HUD_SPRITE_MP, mpParam.offset or global.MMO.HUD_OFFSET_2, mpParam.id or global.MMO.MP_SPRITE_ID)
    actor.mHUDUI[global.MMO.HUDMPUI_BAR]    = mpBar
    actor.mHUDUI[global.MMO.HUDMPUI_BORDER] = mpBorder
    local MP      = actor:GetMP()
    local maxMP   = actor:GetMaxMP()
    local percent = MP / maxMP
    if ActorHud.GetHUDMPBarPer then
        percent = ActorHud.GetHUDMPBarPer(actor:GetID()) or percent
    end
    global.HUDManager:SetHUDBarPercent( mpBar, percent )

    -- HUD NG for actor
    local ngBgParam = ActorHud.GetHUDNGSpriteParam and ActorHud.GetHUDNGSpriteParam(actorID, true) or {}
    local ngBorder  = global.HUDManager:CreateHUDBar(actorID, global.MMO.HUD_SPRITE_NG_BG, ngBgParam.offset or global.MMO.HUD_OFFSET_BG_3, ngBgParam.id or global.MMO.HP_BG_SPRITE_ID)
    local ngParam   = ActorHud.GetHUDNGSpriteParam and ActorHud.GetHUDNGSpriteParam(actorID) or {}
    local ngBar     = global.HUDManager:CreateHUDBar(actorID, global.MMO.HUD_SPRITE_NG, ngParam.offset or global.MMO.HUD_OFFSET_3, ngParam.id or global.MMO.NG_SPRITE_ID)
    actor.mHUDUI[global.MMO.HUDNGUI_BAR]    = ngBar
    actor.mHUDUI[global.MMO.HUDNGUI_BORDER] = ngBorder

    local force     = actor:GetInternal()
    local maxForce  = actor:GetMaxInternal()
    local percent   = maxForce == 0 and 0 or (force / maxForce)
    if ActorHud.GetHUDNGBarPer then
        percent = ActorHud.GetHUDNGBarPer(actor:GetID()) or percent
    end
    global.HUDManager:SetHUDBarPercent( ngBar, percent )

    -- 刷新坐标
    local position = actor:getPosition()
    actor:setPosition(position.x, position.y)

    global.Facade:sendNotification(global.NoticeTable.RefreshActorSceneOptions, actor)
end

function actorRefreshController:OnDelayDirtyFeature(actorID)
    if not actorID then
        return nil
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    local caches = actor:IsNPC() and self._npcCreateCache or self._createCache
    caches[actorID] = caches[actorID] or {}
    caches[actorID][REFRESH_TYPE_DIRTY_FEATURE] = true
end

function actorRefreshController:DirtyFeature(actorID)
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    actor:DirtyFeature()
end

return actorRefreshController
