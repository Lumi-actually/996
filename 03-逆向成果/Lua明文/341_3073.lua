local BuffEntityAnim = require("buff/BuffEntityAnim")
local BuffEntityColor = class("BuffEntityColor", BuffEntityAnim)

function BuffEntityColor:ctor(data)
    BuffEntityColor.super.ctor(self, data)
end

function BuffEntityColor:OnEnter()
    BuffEntityColor.super.OnEnter(self)
    
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        self:disable()
        return false
    end

    actor:UnBright()

    local color = global.BuffManager:CheckBuffColor(self._actorID)
    self:SetActorColor( actor,color )
end

function BuffEntityColor:OnExit()
    BuffEntityColor.super.OnExit(self)

    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return false
    end

    local color = global.BuffManager:CheckBuffColor(self._actorID)
    self:SetActorColor( actor,color )
end

function BuffEntityColor:UpdatePresent()
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return false
    end

    local color = global.BuffManager:CheckBuffColor(self._actorID)
    self:SetActorColor( actor,color )
end

function BuffEntityColor:SetActorColor( actor,color )
    local anim = actor:GetAnimation()
    if anim then
        self:ShaderNormal(anim)
        anim:setColor(color)
    end
    
    if actor.GetAnimationShield then
        anim = actor:GetAnimationShield()
        if anim then
            self:ShaderNormal(anim)
            anim:setColor(color)
        end
    end

    if actor.GetAnimationWings then
        anim = actor:GetAnimationWings()
        if anim then
            self:ShaderNormal(anim)
            anim:setColor(color)
        end
    end

    if actor.GetAnimationMount then
        anim = actor:GetAnimationMount()
        if anim then
            self:ShaderNormal(anim)
            anim:setColor(color)
        end
    end

    if actor.GetAnimationHair then
        anim = actor:GetAnimationHair()
        if anim then
            self:ShaderNormal(anim)
            anim:setColor(color)
        end
    end

    if actor.GetAnimationWeapon then
        anim = actor:GetAnimationWeapon()
        if anim then
            self:ShaderNormal(anim)
            anim:setColor(color)
        end
    end

    if actor.GetAnimationMonster then
        anim = actor:GetAnimationMonster()
        if anim then
            self:ShaderNormal(anim)
            anim:setColor(color)
        end
    end

    if actor.GetAnimationMonsterCloth then
        anim = actor:GetAnimationMonsterCloth()
        if anim then
            self:ShaderNormal(anim)
            anim:setColor(color)
        end
    end
end

function BuffEntityColor:ShaderNormal(node)
    if not node then
        return
    end

    if self._buffID ~= global.MMO.BUFF_ID_THUNDER_SWORD then
        return
    end

    local p = global.GLProgramCache:getGLProgram("ShaderPositionTextureColor_noMVP")
    node:setGLProgram(p)
end

return BuffEntityColor
