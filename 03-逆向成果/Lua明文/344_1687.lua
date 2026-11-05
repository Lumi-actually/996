local BuffEntityAnim = require("buff/BuffEntityAnim")
local BuffEntityCloaking = class("BuffEntityCloaking", BuffEntityAnim)

function BuffEntityCloaking:ctor(data)
    BuffEntityCloaking.super.ctor(self, data)

    self._buffEffHide = tonumber(global.ConstantConfig.disBuffHideEffect) == 1 --不显示隐身效果
end

function BuffEntityCloaking:OnEnter()
    BuffEntityCloaking.super.OnEnter(self)

    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        self:disable()
        return false
    end

    -- net player only
    if not (actor:IsPlayer() or actor:IsMonster()) then
        self:disable()
        return false
    end

    if self._buffEffHide and actor:IsPlayer() then
        return false
    end

    actor:SetCloaking(true, 2)
end

function BuffEntityCloaking:OnExit()
    BuffEntityCloaking.super.OnExit(self)

    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return nil
    end

    -- net player only
    if not (actor:IsPlayer() or actor:IsMonster()) then
        return false
    end

    if self._buffEffHide and actor:IsPlayer() then
        return false
    end

    actor:SetCloaking(false, 2)
end

function BuffEntityCloaking:UpdatePresent()
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return false
    end

    -- net player only
    if not (actor:IsPlayer() or actor:IsMonster()) then
        return false
    end

    if self._buffEffHide and actor:IsPlayer() then
        return false
    end

    actor:SetCloaking(true, 2)
end

return BuffEntityCloaking
