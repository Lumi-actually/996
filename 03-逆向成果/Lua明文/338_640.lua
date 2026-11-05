local BuffEntityAnim = require("buff/BuffEntityAnim")
local BuffEntityIce = class("BuffEntityIce", BuffEntityAnim)

function BuffEntityIce:ctor(data)
    BuffEntityIce.super.ctor(self, data)
end

function BuffEntityIce:OnEnter()
    BuffEntityIce.super.OnEnter(self)

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

function BuffEntityIce:OnExit()
    BuffEntityIce.super.OnExit(self)
end

return BuffEntityIce