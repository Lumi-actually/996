local gameActorStateMoveBase = require("actor/gameActorStateMoveBase")
local gameActorStatePlayerAssassinSneak = class('gameActorStatePlayerAssassinSneak', gameActorStateMoveBase)

function gameActorStatePlayerAssassinSneak:ctor()
    self.super.ctor(self)
end

function gameActorStatePlayerAssassinSneak:GetStateID()
    return global.MMO.ACTION_ASSASSIN_SNEAK
end

function gameActorStatePlayerAssassinSneak:GetMoveTime(actor)
    if not G_ActorUtils.IsSmoothMove() then
        return global.MMO.DEFAULT_ASSASSIN_SNEAK_TIME /actor:GetMainPlayerSpeedByAction(self:GetStateID())
    end
    return global.MMO.DEFAULT_ASSASSIN_SNEAK_TIME / actor:GetWalkSpeed()
end

function gameActorStatePlayerAssassinSneak:GetMoveFrame(actor)
    if actor:GetIsMoreFullSpeedup()
        or actor:GetIsMoreSpeedRate()
        or actor:GetIsFullSpeedup()
        or actor:GetIsSpeedup() then
        return global.ConstantConfig.PlayerWalkAnimFrameCount / 2
    end
    return global.ConstantConfig.PlayerWalkAnimFrameCount
end

function gameActorStatePlayerAssassinSneak:OnEnter(actor)    
    self.super.OnEnter(self, actor)

    -- reset some data
    actor:SetAnimPrepare(0.0)
    actor:DirtyAnimFlag()
end

function gameActorStatePlayerAssassinSneak:OnExit(actor)    
    actor:SetAnimPrepare(0.1)

    if SL:GetValue("GAME_DATA","gameOption_WalkOnly") ~= 1 or (actor:IsHumanoid() or actor:IsHero()) then
        actor:StopAllAnimation(6)
    end
end

return gameActorStatePlayerAssassinSneak