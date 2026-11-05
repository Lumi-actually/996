local BuffEntity = require("buff/BuffEntity")
local BuffEntityAnim = class("BuffEntityAnim", BuffEntity)
local SharedPoint = {}

function BuffEntityAnim:ctor(data)
    BuffEntityAnim.super.ctor(self, data)

    self._rootNodeB   = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_SKILL_BEHIND)
    self._rootNodeF   = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_SKILL)
    self._sceneAnims  = {}

    local BuffProxy   = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    self._sfxOffset   = BuffProxy:GetSfxOffset(self._buffID)
    self._sfxSpeed    = BuffProxy:GetSfxSpeed(self._buffID)
    self._unOffset    = nil
    self._horseOffset = cc.p(0,0)
end

function BuffEntityAnim:OnEnter()
    BuffEntityAnim.super.OnEnter(self)

    self:setVisible( true )
    self:updatePosition()
end

function BuffEntityAnim:OnExit()
    BuffEntityAnim.super.OnExit(self)

    self:HideAnim()
    self:HideAnimStuck()
end

function BuffEntityAnim:ShowAnim()
    local buffid = self._buffID
    if self._data.replaceId and self._data.replaceId > 0 then
        buffid = self._data.replaceId
    end

    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local sfxConfig = BuffProxy:GetBuffSfxByID(buffid)
    if sfxConfig then
        if sfxConfig.front then
            local sfxID  = sfxConfig.front.sfxID
            local loop   = sfxConfig.front.loop
            local is8dir = sfxConfig.front.is8dir
            local dirfollow = sfxConfig.front.dirfollow
            self._unOffset = sfxConfig.front.unOffset
            self:addBuffSfx(sfxID, true, loop, is8dir, dirfollow)
        end
        
        if sfxConfig.behind then
            local sfxID  = sfxConfig.behind.sfxID
            local loop   = sfxConfig.behind.loop
            local is8dir = sfxConfig.behind.is8dir
            local dirfollow = sfxConfig.behind.dirfollow
            self:addBuffSfx(sfxID, false, loop, is8dir, dirfollow)
        end
    end
end

function BuffEntityAnim:HideAnim()
    local buffid = self._buffID
    if self._data.replaceId and self._data.replaceId > 0 then
        buffid = self._data.replaceId
    end

    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local sfxConfig = BuffProxy:GetBuffSfxByID(buffid)
    if sfxConfig then
        if sfxConfig.front then
            local sfxID = sfxConfig.front.sfxID
            self:removeBuffSfx(sfxID)
        end
        
        if sfxConfig.behind then
            local sfxID = sfxConfig.behind.sfxID
            self:removeBuffSfx(sfxID)
        end
    end
end

function BuffEntityAnim:IsShowStuckAnim()
    local buffid = self._buffID
    if self._data.replaceId and self._data.replaceId > 0 then
        buffid = self._data.replaceId
    end
    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local sfxConfig = BuffProxy:GetBuffSfxByID(buffid)
    local hasSfx = false
    if sfxConfig then
        if sfxConfig.front_stuck and sfxConfig.front_stuck.sfxID and sfxConfig.front_stuck.sfxID ~= 0 then
            hasSfx = true
        end
        
        if sfxConfig.behind_stuck and sfxConfig.behind_stuck.sfxID and sfxConfig.behind_stuck.sfxID ~= 0 then
            hasSfx = true
        end
    end
    return hasSfx
end

function BuffEntityAnim:ShowAnimStuck()
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return nil
    end

    local buffid = self._buffID
    if self._data.replaceId and self._data.replaceId > 0 then
        buffid = self._data.replaceId
    end

    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local sfxConfig = BuffProxy:GetBuffSfxByID(buffid)
    if sfxConfig then
        local falg = false
        local function callback()

            if self:IsInvalid() then
                return
            end

            if falg then
                return
            end
            falg = true
            self:HideAnimStuck()
            self:ShowAnim()
        end

        if sfxConfig.front_stuck then
            local sfxID  = sfxConfig.front_stuck.sfxID
            local loop   = sfxConfig.front_stuck.loop
            local is8dir = sfxConfig.front_stuck.is8dir
            local dirfollow = sfxConfig.front_stuck.dirfollow
            self:addBuffSfx(sfxID, true, loop, is8dir, dirfollow, callback)
        end
        
        if sfxConfig.behind_stuck then
            local sfxID  = sfxConfig.behind_stuck.sfxID
            local loop   = sfxConfig.behind_stuck.loop
            local is8dir = sfxConfig.behind_stuck.is8dir
            local dirfollow = sfxConfig.behind_stuck.dirfollow
            self:addBuffSfx(sfxID, false, loop, is8dir, dirfollow, callback)
        end
    end
end

function BuffEntityAnim:HideAnimStuck()
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return nil
    end

    local buffid = self._buffID
    if self._data.replaceId and self._data.replaceId > 0 then
        buffid = self._data.replaceId
    end
    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local sfxConfig = BuffProxy:GetBuffSfxByID(buffid)
    if sfxConfig then
        if sfxConfig.front_stuck then
            local sfxID = sfxConfig.front_stuck.sfxID
            self:removeBuffSfx(sfxID)
        end
        
        if sfxConfig.behind_stuck then
            local sfxID = sfxConfig.behind_stuck.sfxID
            self:removeBuffSfx(sfxID)
        end
    end
end

function BuffEntityAnim:addBuffSfx(sfxID, front, loop, is8dir, dirfollow, callback)
    if not sfxID then
        return nil
    end
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return nil
    end

    if (actor:IsDeath() or actor:IsDie()) and CHECK_SETTING(global.MMO.SETTING_IDX_HIDE_MONSTER_BODY) == 1 then
        return
    end

    -- create sfx
    if nil == self._sceneAnims[sfxID] and not actor:GetValueByKey(global.MMO.HUD_SNEAK) then
        local dir = (dirfollow or is8dir) and actor:GetDirection() or 0
        local sfx  = global.FrameAnimManager:CreateSFXAnim(sfxID)
        sfx:SetGlobalElapseEnable(loop == 0)
        local root = front and self._rootNodeF or self._rootNodeB
        root:addChild(sfx, sfxID)
        local visible = CHECK_SETTING(global.MMO.SETTING_IDX_EFFECT_SHOW) ~= 1
        sfx:setVisible(visible)
        sfx:Play(0, dir, true, self._sfxSpeed)
        self._sceneAnims[sfxID] = sfx
        sfx._dirfollow_ = dirfollow

        local count = 0
        local function overCB()

            if self:IsInvalid() then
                return
            end

            if loop > 0 then
                count = count + 1
                if loop == count then
                    sfx:Stop()
                    self:removeBuffSfx(sfxID)
                end
            end
            
            if callback then
                callback()
            end
        end
        sfx:SetAnimEventCallback(overCB)
    end

    self:setPosition(actor:getPositionX(), actor:getPositionY())
end

function BuffEntityAnim:removeBuffSfx(sfxID)
    if not sfxID then
        return nil
    end
    
    if self._sceneAnims[sfxID] then
        self._sceneAnims[sfxID]:removeFromParent()
        self._sceneAnims[sfxID] = nil
    end
end

function BuffEntityAnim:OnActorStuck()
    if not self:IsShowStuckAnim() then
        return false
    end
    self:HideAnim()
    self:HideAnimStuck()

    self:ShowAnimStuck()
    return true
end

function BuffEntityAnim:setPosition(x, y)
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return nil
    end

    local horseOffset = self._horseOffset or cc.p(0,0)
    for animID, anim in pairs(self._sceneAnims) do
        SharedPoint.x = x
        SharedPoint.y = y
        if actor:IsDropItem() then
            SharedPoint.x = SharedPoint.x + horseOffset.x + self._sfxOffset.x
            SharedPoint.y = SharedPoint.y + horseOffset.y + self._sfxOffset.y
            local notOffset = self._unOffset and self._unOffset == 1
            if notOffset then
                SharedPoint.x = SharedPoint.x + global.MMO.PLAYER_AVATAR_OFFSET.x
                SharedPoint.y = SharedPoint.y + global.MMO.PLAYER_AVATAR_OFFSET.y
            end
            anim:setPosition(SharedPoint)
        else
            SharedPoint.x = SharedPoint.x + horseOffset.x + self._sfxOffset.x + global.MMO.PLAYER_AVATAR_OFFSET.x
            SharedPoint.y = SharedPoint.y + horseOffset.y + self._sfxOffset.y + global.MMO.PLAYER_AVATAR_OFFSET.y
            anim:setPosition(SharedPoint)
        end
    end
end

function BuffEntityAnim:setVisible(visible)
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return
    end

    if actor:IsPlayer() and actor:IsHoreseCopilot() then
        self:HideAnim()
        return
    end

    if actor:IsPlayer() and actor:GetHorseMasterID() and global.actorManager:GetActor(actor:GetHorseMasterID()) then
        local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        if not BuffProxy:IsHorseShow(self._buffID) then
            self:HideAnim()
            return
        end
    end

    -- 潜行
    if visible and actor:GetValueByKey(global.MMO.HUD_SNEAK) then
        visible = false
    end

    if visible then
        self:ShowAnim()
    else
        self:HideAnim()
    end
end

function BuffEntityAnim:updatePosition()
    local actor = global.actorManager:GetActor(self._actorID)
    if actor and self._buffID == global.MMO.BUFF_ID_MAGIC_SHIELD then
        -- 检测是不是副驾的玩家   副驾玩家的buff特效都不显示出来
        self._horseOffset.y = 0
        if actor and actor:IsPlayer() and actor:GetHorseMasterID() then
            self._horseOffset.y = 10
        end
        local pX = actor.mPositionX
        local pY = actor.mPositionY
        self:setPosition(pX, pY)
    elseif actor and actor:IsPlayer() and actor:GetHorseMasterID() and global.actorManager:GetActor(actor:GetHorseMasterID()) then
        local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        self._horseOffset = BuffProxy:GetHorseOffset(self._buffID)
        local pX = actor.mPositionX
        local pY = actor.mPositionY
        self:setPosition(pX, pY)
    end
end

function BuffEntityAnim:UpdateSfxDir()
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return false
    end

    if not actor.GetDirection then
        return false
    end

    for _, sfx in pairs(self._sceneAnims) do
        if sfx and sfx._dirfollow_ then
            sfx:Stop()
            sfx:Play(0, actor:GetDirection(), true, self._sfxSpeed)
        end
    end
end

return BuffEntityAnim
