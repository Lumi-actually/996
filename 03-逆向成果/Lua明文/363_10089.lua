local RoleEffectMediator = class('RoleEffectMediator', framework.Mediator)
RoleEffectMediator.NAME = "RoleEffectMediator"
local Queue = requireUtil("queue")

local function animCallback(anim, eventType)
    if eventType == 1 then -- end
        anim:Stop()
        anim:setVisible(false)
    end
end

local SharedPoint = {}

function RoleEffectMediator:ctor()
    RoleEffectMediator.super.ctor(self, self.NAME)

    SL:Require(UIConst.LUAFile.LUA_FILE_ROLE_EFFECT)
    self._sfxCache = {}
end

function RoleEffectMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return 
    {
        noticeTable.PlayerPropertyInited, 
        noticeTable.ReleaseMemory, 
        noticeTable.TargetChange,
        noticeTable.PlayerLevelChange, 
        noticeTable.ActorCollect, 
        noticeTable.ActorFlyIn, 
        noticeTable.ActorFlyOut,
        noticeTable.MouseMoveInActorSide, 
        noticeTable.MouseMoveOutActorSide,
        noticeTable.Layer_Monster_Belong_TargetChange, 
        noticeTable.PlayerInternalLevelChange,
        noticeTable.HeroInternalLevelChange
    }
end

function RoleEffectMediator:handleNotification(notification)
    local noticeID = notification:getName()
    local notices = global.NoticeTable
    local data = notification:getBody()

    if notices.ReleaseMemory == noticeID then
        self:OnReleaseMemory()

    elseif notices.TargetChange == noticeID then
        self:OnUpdateSelect(data)

    elseif notices.PlayerLevelChange == noticeID then
        self:OnRoleLevelUp(data)

    elseif notices.ActorCollect == noticeID then
        self:OnCollectActor(data)

    elseif notices.ActorFlyIn == noticeID then
        local stype = notification:getType()
        self:OnRoleFlyIn(data, stype)

    elseif notices.ActorFlyOut == noticeID then
        local stype = notification:getType()
        self:OnRoleFlyOut(data, stype)

    elseif notices.MouseMoveInActorSide == noticeID then
        self:OnMouseMoveInActorSide(data)

    elseif notices.MouseMoveOutActorSide == noticeID then
        self:OnMouseMoveOutActorSide(data)

    elseif notices.Layer_Monster_Belong_TargetChange == noticeID then
        self:OnUpdateSelect(data)

    elseif notices.PlayerInternalLevelChange == noticeID then
        self:OnInternalLevelUp()

    elseif notices.HeroInternalLevelChange == noticeID then
        self:OnHeroInternalLevelUp()
    end
end

function RoleEffectMediator:OnReleaseMemory()
    if self._upgradeAnim then
        self._upgradeAnim:removeFromParent()
        self._upgradeAnim:autorelease()
    end

    if self._upILvAnim then
        self._upILvAnim:removeFromParent()
        self._upILvAnim:autorelease()
    end

    if self._upHeroILvAnim then
        self._upHeroILvAnim:removeFromParent()
        self._upHeroILvAnim:autorelease()
    end

    for _, cache in pairs(self._sfxCache) do
        local cacheSize = cache:size()
        if cacheSize > 0 then
            for i = 1, cacheSize do
                local sfx = cache:pop()
                sfx:autorelease()
            end
        end
    end
end

function RoleEffectMediator:CacheAnimCallback(anim, eventType)
    if eventType == 1 then -- end
        anim:Stop()
        anim:setVisible(false)
        anim:removeFromParent()

        local sfxID = anim:getTag()
        local cache = self._sfxCache[sfxID]
        cache:push(anim)
    end
end

function RoleEffectMediator:OnRoleLevelUp(data)
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return
    end

    -- 升级音效
    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_UPGRADE
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)

    -- 升级特效
    if not self._upgradeAnim then
        self._upgradeAnim = global.FrameAnimManager:CreateSFXAnim(global.MMO.SFX_UPGRADE)
        self._upgradeAnim:retain()
        mainPlayer:GetNode():addChild(self._upgradeAnim)
        self._upgradeAnim:SetAnimEventCallback(animCallback)
    end
    self._upgradeAnim:setVisible(true)
    self._upgradeAnim:Stop()
    self._upgradeAnim:Play(0, 0, false)
end

function RoleEffectMediator:OnUpdateSelect(data)
    local targetID = data.targetID
    if targetID then
        local actor = global.actorManager:GetActor(targetID)
        if actor then
            self:OnSelectTarget(actor)
        end
    else
        self:OnClearSelect()
    end
end

-- 选择目标
function RoleEffectMediator:OnSelectTarget(actor)
    local selectRing = RoleEffect and RoleEffect.CreateSelectTargetEffect(actor:GetID())
    if selectRing then
        actor:GetNode():addChild(selectRing, -10, 10)
    end
end

function RoleEffectMediator:OnClearSelect()
end

function RoleEffectMediator:OnCollectActor(data)
    local actor = data.actor
    local sfxID = data.sfxID
    if not actor then
        return
    end

    local actorAnim = actor:GetAnimation()
    if not actorAnim then
        return nil
    end

    local anim = global.FrameAnimManager:CreateSFXAnim(sfxID)
    local rect = actorAnim:GetBoundingBox()
    anim:setPosition(0, rect.height)
    anim:Play(0, 0, true)
    actor:GetNode():addChild(anim)
end

function RoleEffectMediator:createSfx( sfxID )
    if not self._sfxCache[sfxID] then
        self._sfxCache[sfxID] = Queue.new()
    end
    local cache = self._sfxCache[sfxID]

    local sfx = nil
    if cache:empty() then
        sfx = global.FrameAnimManager:CreateSFXAnim( sfxID )
        sfx:setTag( sfxID )
        sfx:retain()
    else
        sfx = cache:pop()
    end

    return sfx
end

function RoleEffectMediator:OnRoleFlyIn(data, stype)
    local parent = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_ACTOR_SFX_FRONT)
    local wX, wY = global.sceneManager:MapPos2WorldPos(data.x, data.y, true)
    SharedPoint.x = wX
    SharedPoint.y = wY
    SharedPoint.x = SharedPoint.x + global.MMO.PLAYER_AVATAR_OFFSET.x
    SharedPoint.y = SharedPoint.y + global.MMO.PLAYER_AVATAR_OFFSET.y

    local sfxID = stype > 1 and stype
    if not sfxID then
        sfxID = stype == 1 and global.MMO.SFX_FLY_IN_2 or global.MMO.SFX_FLY_IN
    end
    local anim = self:createSfx(sfxID)
    anim:setVisible(true)
    anim:Play(0, 0, true)
    anim:SetAnimEventCallback(handler(self, self.CacheAnimCallback))
    anim:setPosition(SharedPoint)
    parent:addChild(anim)
end

function RoleEffectMediator:OnRoleFlyOut(actor, stype)
    if not actor then
        return
    end

    local parent = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_ACTOR_SFX_FRONT)
    SharedPoint.x = actor:getPositionX()
    SharedPoint.y = actor:getPositionY()
    SharedPoint.x = SharedPoint.x + global.MMO.PLAYER_AVATAR_OFFSET.x
    SharedPoint.y = SharedPoint.y + global.MMO.PLAYER_AVATAR_OFFSET.y

    local sfxID = stype > 1 and stype
    if not sfxID then
        sfxID = stype == 1 and global.MMO.SFX_FLY_OUT_2 or global.MMO.SFX_FLY_OUT
    end
    local anim = self:createSfx(sfxID)
    anim:setVisible(true)
    anim:Play(0, 0, true)
    anim:SetAnimEventCallback(handler(self, self.CacheAnimCallback))
    anim:setPosition(SharedPoint)
    parent:addChild(anim)
end

function RoleEffectMediator:OnMouseMoveInActorSide(actorID)
    if actorID == global.gamePlayerController:GetMainPlayerID() then
        return
    end
    if global.BuffManager:IsInColorBuff(actorID) then
        return
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return
    end

    actor:Bright()

    if actor:IsNPC() then
        SetCustomCursor(global.MMO.CURSOR_TYPE_NPC)
    else
        SetCustomCursor(global.MMO.CURSOR_TYPE_PK)
    end
end

function RoleEffectMediator:OnMouseMoveOutActorSide(actorID)
    if actorID == global.gamePlayerController:GetMainPlayerID() then
        return
    end
    if global.BuffManager:IsInColorBuff(actorID) then
        return
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return
    end

    actor:UnBright()

    SetCustomCursor(global.MMO.CURSOR_TYPE_NORMAL)
end

function RoleEffectMediator:OnInternalLevelUp()
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return
    end

    -- 音效
    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_UPGRADE
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)

    -- 特效
    if not self._upILvAnim then
        self._upILvAnim = global.FrameAnimManager:CreateSFXAnim(global.MMO.SFX_INTERNAL_LV_UP)
        self._upILvAnim:retain()
        mainPlayer:GetNode():addChild(self._upILvAnim)

        self._upILvAnim:SetAnimEventCallback(animCallback)
    end

    self._upILvAnim:setVisible(true)
    self._upILvAnim:Stop()
    self._upILvAnim:Play(0, 0, false)
end

function RoleEffectMediator:OnHeroInternalLevelUp()
    local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    local heroActorID = HeroPropertyProxy:GetRoleUID()
    local heroActor = global.actorManager:GetActor(heroActorID)
    if not heroActor then
        return
    end

    -- 音效
    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_UPGRADE
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)

    -- 特效
    if not self._upHeroILvAnim then
        self._upHeroILvAnim = global.FrameAnimManager:CreateSFXAnim(global.MMO.SFX_INTERNAL_LV_UP)
        self._upHeroILvAnim:retain()
        heroActor:GetNode():addChild(self._upHeroILvAnim)
        self._upHeroILvAnim:SetAnimEventCallback(animCallback)
    end
    self._upHeroILvAnim:setVisible(true)
    self._upHeroILvAnim:Stop()
    self._upHeroILvAnim:Play(0, 0, false)
end

return RoleEffectMediator
