local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterUnknown2 = class('gameActorStateMonsterUnknown2', gameActorState)

function gameActorStateMonsterUnknown2:ctor()
    gameActorStateMonsterUnknown2.super.ctor(self)
end

function gameActorStateMonsterUnknown2:Tick(dt, monster)
    if not monster.mIsArrived then
        monster.mCurrentActT = monster.mCurrentActT - dt
        if monster.mCurrentActT <= 0.00001 then
            monster.mIsArrived = true
            monster.mActionHandler:handleActionCompleted(monster, global.MMO.ACTION_UNKNOWN2)
        end
    end
end

function gameActorStateMonsterUnknown2:OnEnter(monster)
    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_UNKNOWN2)
    monster:SetIsArrived(false)
    monster.mActionHandler:handleActionBegin(monster, global.MMO.ACTION_UNKNOWN2, monster.mOrient, 0)
end

function gameActorStateMonsterUnknown2:OnExit(actor)
end

function gameActorStateMonsterUnknown2:ChangeState(newState, monster, isTerminate)  
    monster.mCurrentState = newState

    return true
end

function gameActorStateMonsterUnknown2:GetStateID()
    return global.MMO.ACTION_UNKNOWN2
end

function gameActorStateMonsterUnknown2:OnAnimLoadCompleted(monster, animAct, elapsed)
    if animAct ~= global.MMO.ANIM_UNKNOWN2 then
        return false
    end

    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_UNKNOWN2) - elapsed
end

return gameActorStateMonsterUnknown2