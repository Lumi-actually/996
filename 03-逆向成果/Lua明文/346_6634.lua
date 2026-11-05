local BuffEntityAnim = require("buff/BuffEntityAnim")
local BuffEntityAvatar = class("BuffEntityAvatar",BuffEntityAnim)

function BuffEntityAvatar:ctor(data)
    BuffEntityAvatar.super.ctor(self,data)

    local BuffProxy     = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    self._cfgColor      = BuffProxy:GetBuffColorByID( self._buffID )
    self._cfgSacle      = BuffProxy:GetBuffScaleByID( self._buffID )
    self._cfgAvatar     = BuffProxy:GetBuffAvatarByID( self._buffID )
end

function BuffEntityAvatar:OnEnter()
    BuffEntityAvatar.super.OnEnter(self)
    self:FeatureActor()
end

function BuffEntityAvatar:OnExit()
    BuffEntityAvatar.super.OnExit(self)
    self:UnFeatureActor()
end

function BuffEntityAvatar:updatePosition()
    BuffEntityAvatar.super.updatePosition(self)
end

function BuffEntityAvatar:FeatureActor()
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return
    end

    if self._cfgAvatar then
        if actor:IsMonster() and self._cfgAvatar.avatarType == 1 and self._cfgAvatar.avatarID then
            self._originClothID = actor:GetAnimationID()
            actor:SetAppearByID(global.MMO.P_F_CLOTH, self._cfgAvatar.avatarID)
            actor:DirtyFeature()
        elseif actor:IsPlayer() and not actor:GetHorseMasterID() and not actor:IsHoreseCopilot() then
            if global.BuffManager:CheckRmvBuffAvatar(actor:GetID(), self._cfgAvatar) then
                actor:SetAppearByID(global.MMO.P_F_MONSTER, 0)
                actor:UpdateMonster(0)
            end
            actor:SetAppearByID(global.MMO.P_F_MONSTER, self._cfgAvatar.avatarID)
            actor:DirtyFeature()
        end
    end

    self._cfgColor = global.BuffManager:CheckBuffColorByID(self._actorID, self._buffID)
    self._cfgSacle = global.BuffManager:CheckBuffScale(self._actorID, self._buffID)
    self:OnRefreshFeature(self._cfgColor, self._cfgSacle)
end

function BuffEntityAvatar:UnFeatureActor()
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return
    end

    local cfgAvatar = global.BuffManager:CheckBuffAvatar(self._actorID, self._buffID)
    if actor:IsMonster() then
        if cfgAvatar and cfgAvatar.avatarType == 1 and cfgAvatar.avatarID then
            actor:SetAppearByID(global.MMO.P_F_CLOTH, cfgAvatar.avatarID)
            actor:DirtyFeature()
        elseif self._originClothID then
            actor:SetAppearByID(global.MMO.P_F_CLOTH, self._originClothID)
            actor:DirtyFeature()
            self._originClothID = nil
        end
    elseif actor:IsPlayer() and not actor:GetHorseMasterID() and not actor:IsHoreseCopilot() then
        local id = cfgAvatar and cfgAvatar.avatarID
        if not cfgAvatar or global.BuffManager:CheckRmvBuffAvatar(actor:GetID(), cfgAvatar) then
            actor:SetAppearByID(global.MMO.P_F_MONSTER, 0)
            actor:UpdateMonster(0)
        end
        if id and id > 0 then
            actor:SetAppearByID(global.MMO.P_F_MONSTER, id)
            actor:DirtyFeature()
        end
    end

    self._cfgColor = global.BuffManager:CheckBuffColorByID(self._actorID, self._buffID)
    self._cfgSacle = global.BuffManager:CheckBuffScale(self._actorID, self._buffID)
    self:OnRefreshFeature(self._cfgColor, self._cfgSacle, true)
end

local glp = global.GLProgramCache:getGLProgram("ShaderPositionTextureColor_noMVP")
local function featureColor(anim, color)
    if not color then
        return
    end
    anim:setGLProgram(glp)
    anim:setColor(color)
end
local function featureScale(anim, scale)
    if not scale then
        return
    end
    local aScale = anim:getScale()
    if aScale == scale then
        return
    end
    anim:setScale(scale)
    local avatarOffset = global.MMO.PLAYER_AVATAR_OFFSET
    local offx = (scale - aScale) * avatarOffset.x
    local offy = (scale - aScale) * avatarOffset.y
    local pos = anim:getTurePosition()
    anim:setPosition(pos.x + offx, pos.y + offy)
end
local function featureShader(anim, color, scale)
    featureColor(anim, color)
    featureScale(anim, scale)
end
function BuffEntityAvatar:OnRefreshFeature(color, scale, isUnFeat)
    if not color and not scale then
        return
    end

    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return
    end

    if actor:IsPlayer() and (actor:GetHorseMasterID() or actor:IsHoreseCopilot()) then
        scale = 1
    end

    local anim = actor:GetAnimation()
    if anim then
        featureShader(anim, color, scale)
    end

    if actor.GetAnimationShield then
        anim = actor:GetAnimationShield()
        if anim then
            featureShader(anim, color, scale)
        end
    end

    if actor.GetAnimationShieldEff then
        anim = actor:GetAnimationShieldEff()
        if anim then
            featureShader(anim)
        end
    end

    if actor.GetAnimationWings then
        anim = actor:GetAnimationWings()
        if anim then
            featureShader(anim, color, scale)
        end
    end

    if actor.GetAnimationMount then
        anim = actor:GetAnimationMount()
        if anim then
            featureShader(anim, color, scale)
        end
    end

    if actor.GetAnimationHair then
        anim = actor:GetAnimationHair()
        if anim then
            featureShader(anim, color, scale)
        end
    end

    if actor.GetAnimationWeapon then
        anim = actor:GetAnimationWeapon()
        if anim then
            featureShader(anim, color, scale)
        end
    end

    if actor.GetAnimationWeaponEff then
        anim = actor:GetAnimationWeaponEff()
        if anim then
            featureShader(anim)
        end
    end

    if actor.GetAnimationLeftWeapon then
        anim = actor:GetAnimationLeftWeapon()
        if anim then
            featureShader(anim)
        end
    end

    if actor.GetAnimationLeftWeaponEff then
        anim = actor:GetAnimationLeftWeaponEff()
        if anim then
            featureShader(anim)
        end
    end

    if actor.GetAnimationMonster then
        anim = actor:GetAnimationMonster()
        if anim then
            featureShader(anim, color, scale)
        end
    end
end

function BuffEntityAvatar:UpdatePresent()
    self._cfgColor = global.BuffManager:CheckBuffColorByID(self._actorID, self._buffID)
    self:OnRefreshFeature(self._cfgColor, self._cfgSacle)
end

return BuffEntityAvatar
