local BuffEntityAnim = require("buff/BuffEntityAnim")
local BuffEntityFreezed = class("BuffEntityFreezed", BuffEntityAnim)

function BuffEntityFreezed:ctor(data)
    BuffEntityFreezed.super.ctor(self, data)
end

function BuffEntityFreezed:OnEnter()
    BuffEntityFreezed.super.OnEnter(self)

    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        self:disable()
        return false
    end

    if not (actor:IsPlayer() or actor:IsMonster()) then
        self:disable()
        return false
    end

end

function BuffEntityFreezed:OnExit()
    BuffEntityFreezed.super.OnExit(self)
end

function BuffEntityFreezed:IsAllowAnimUpdate()
    return true
end


return BuffEntityFreezed
