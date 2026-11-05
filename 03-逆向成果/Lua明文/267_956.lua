local gameActorStateMoveBase = require("actor/gameActorStateMoveBase")
local gameActorStatePlayerRideRun = class('gameActorStatePlayerRideRun', gameActorStateMoveBase)

function gameActorStatePlayerRideRun:ctor()
    self.super.ctor(self)
end

function gameActorStatePlayerRideRun:GetStateID()
    return global.MMO.ACTION_RIDE_RUN
end

function gameActorStatePlayerRideRun:GetMoveTime(actor)
    if not G_ActorUtils.IsSmoothMove() then
        return actor:GetRunStepTime() /actor:GetMainPlayerSpeedByAction(self:GetStateID())
    end
    return actor:GetRunStepTime() / actor:GetRunSpeed()
end

function gameActorStatePlayerRideRun:OnEnter(actor)    
    self.super.OnEnter(self, actor)

    -- reset some data
    actor:SetAnimPrepare(0.0)
    actor:DirtyAnimFlag()
end

function gameActorStatePlayerRideRun:OnExit(actor)
    actor:SetAnimPrepare(0.05)
    actor:StopAllAnimation(6)
end

return gameActorStatePlayerRideRun