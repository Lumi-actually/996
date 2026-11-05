local gameActorStateMoveBase = require("actor/gameActorStateMoveBase")
local gameActorStatePlayerWalk = class('gameActorStatePlayerWalk', gameActorStateMoveBase)

local isZeroPrepare = SL:GetValue("GAME_DATA","moveZeroPrepare") == 1

function gameActorStatePlayerWalk:ctor()
    self.super.ctor(self)
end

function gameActorStatePlayerWalk:GetStateID()
    return global.MMO.ACTION_WALK
end

function gameActorStatePlayerWalk:GetMoveTime(actor)
    if not G_ActorUtils.IsSmoothMove() then
        return actor:GetWalkStepTime() /actor:GetMainPlayerSpeedByAction(self:GetStateID())
    end
    return actor:GetWalkStepTime() / actor:GetWalkSpeed()
end

function gameActorStatePlayerWalk:GetMoveFrame(actor)
    if actor:GetIsMoreFullSpeedup()
        or actor:GetIsMoreSpeedRate()
        or actor:GetIsFullSpeedup()
        or actor:GetIsSpeedup() then
        return global.ConstantConfig.PlayerWalkAnimFrameCount / 2
    end
    return global.ConstantConfig.PlayerWalkAnimFrameCount
end

function gameActorStatePlayerWalk:OnEnter(actor)    
    self.super.OnEnter(self, actor)

    -- reset some data
    actor:SetAnimPrepare(0.0)
    actor:DirtyAnimFlag()
end

function gameActorStatePlayerWalk:OnExit(actor)    
    if isZeroPrepare then
        actor:SetAnimPrepare(0)
        actor:DirtyAnimFlag()
    else
        actor:SetAnimPrepare(0.1)
    end

    if SL:GetValue("GAME_DATA","gameOption_WalkOnly") ~= 1 or (actor:IsHumanoid() or actor:IsHero()) then
        actor:StopAllAnimation(6)
    end
end

return gameActorStatePlayerWalk