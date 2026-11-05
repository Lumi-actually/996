local gameActorStateMoveBase = require("actor/gameActorStateMoveBase")
local gameActorStateMonsterWalk = class('gameActorStateMonsterWalk', gameActorStateMoveBase)

local mMin = math.min

function gameActorStateMonsterWalk:ctor()
    self.super.ctor(self)
end

function gameActorStateMonsterWalk:GetStateID() 
    return global.MMO.ACTION_WALK
end

function gameActorStateMonsterWalk:GetMoveTime(actor)
    local animTime = global.FrameAnimManager:GetAnimTotalDuration(actor:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_WALK)
    return mMin(animTime, actor:GetWalkStepTime() / actor:GetWalkSpeed())
end

function gameActorStateMonsterWalk:OnAnimLoadCompleted(monster, animAct, elapsed)
    if animAct ~= global.MMO.ANIM_WALK then
        return false
    end

    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_WALK) - elapsed
end

return gameActorStateMonsterWalk