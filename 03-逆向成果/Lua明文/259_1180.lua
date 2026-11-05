local gameActorStateMoveBase = require("actor/gameActorStateMoveBase")
local gameActorStatePlayerRun = class('gameActorStatePlayerRun', gameActorStateMoveBase)

local isZeroPrepare = SL:GetValue("GAME_DATA","moveZeroPrepare") == 1

function gameActorStatePlayerRun:ctor()
    self.super.ctor(self)
end

function gameActorStatePlayerRun:GetStateID()
    return global.MMO.ACTION_RUN
end

function gameActorStatePlayerRun:GetMoveTime(actor)
    if not G_ActorUtils.IsSmoothMove() then
        return actor:GetRunStepTime() /actor:GetMainPlayerSpeedByAction(self:GetStateID())
    end
    return actor:GetRunStepTime() / actor:GetRunSpeed()
end

function gameActorStatePlayerRun:OnEnter(actor)    
    self.super.OnEnter(self, actor)

    -- reset some data
    actor:SetAnimPrepare(0.0)
    actor:DirtyAnimFlag()
end

function gameActorStatePlayerRun:OnExit(actor)
    if isZeroPrepare then
        actor:SetAnimPrepare(0)
        actor:DirtyAnimFlag()
    else
        actor:SetAnimPrepare(0.1)
    end

    if not actor:GetValueByKey(global.MMO.IS_RUN_ONE) then
        actor:StopAllAnimation(6)
    end
end

return gameActorStatePlayerRun