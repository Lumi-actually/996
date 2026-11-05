local BuffEntityAnim = require("buff/BuffEntityAnim")
local BuffEntityColor = class("BuffEntityColor", BuffEntityAnim)

local colors = {4, 249, 132, 6, 244, 11, 255}

function BuffEntityColor:ctor(data)
    BuffEntityColor.super.ctor(self, data)

    self._time  = 0
    self._index = 1
end

function BuffEntityColor:OnEnter()
    BuffEntityColor.super.OnEnter(self)

    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        self:disable()
        return false
    end
    actor:UnBright()
    
    self._time  = 0
    self._index = 1
end

function BuffEntityColor:OnExit()
    BuffEntityColor.super.OnExit(self)

    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return false
    end

    local color = global.BuffManager:CheckBuffColor(self._actorID)
    self:setActorColor(color)
end

function BuffEntityColor:Tick(dt)
    if self._time <= 0 then
        local colorID = colors[self._index]
        local color = global.BuffManager:CheckBuffColor(self._actorID, colorID)
        self:setActorColor(color)

        self._index = self._index + 1
        self._index = self._index > #colors and 1 or self._index
        self._time  = 2
    end
    self._time = self._time - dt

    BuffEntityColor.super.Tick(self, dt)
end

function BuffEntityColor:setActorColor(color)
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return false
    end

    local anim  = actor:GetAnimation()
    if anim then
        anim:setColor(color)
    end

    if actor.GetAnimationShield then
        anim = actor:GetAnimationShield()
        if anim then
            anim:setColor(color)
        end
    end

    if actor.GetAnimationWings then
        anim = actor:GetAnimationWings()
        if anim then
            anim:setColor(color)
        end
    end

    if actor.GetAnimationMount then
        anim = actor:GetAnimationMount()
        if anim then
            anim:setColor(color)
        end
    end

    if actor.GetAnimationHair then
        anim = actor:GetAnimationHair()
        if anim then
            anim:setColor(color)
        end
    end

    if actor.GetAnimationWeapon then
        anim = actor:GetAnimationWeapon()
        if anim then
            anim:setColor(color)
        end
    end

    if actor.GetAnimationMonster then
        anim = actor:GetAnimationMonster()
        if anim then
            anim:setColor(color)
        end
    end

    if actor.GetAnimationMonsterCloth then
        anim = actor:GetAnimationMonsterCloth()
        if anim then
            anim:setColor(color)
        end
    end
end

return BuffEntityColor
