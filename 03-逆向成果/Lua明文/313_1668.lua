local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterUnknown3 = class('gameActorStateMonsterUnknown3', gameActorState)

function gameActorStateMonsterUnknown3:ctor()
    gameActorStateMonsterUnknown3.super.ctor(self)
end

function gameActorStateMonsterUnknown3:Tick(dt, monster)
    if not monster.mIsArrived then
        monster.mCurrentActT = monster.mCurrentActT - dt
        if monster.mCurrentActT <= 0.00001 then
            monster.mIsArrived = true
            monster.mActionHandler:handleActionCompleted(monster, global.MMO.ACTION_UNKNOWN3)
        end
    end
end

function gameActorStateMonsterUnknown3:OnEnter(monster)
    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_UNKNOWN3)
    monster:SetIsArrived(false)
    monster.mActionHandler:handleActionBegin(monster, global.MMO.ACTION_UNKNOWN3, monster.mOrient, 0)
end

function gameActorStateMonsterUnknown3:OnExit(actor)
end

function gameActorStateMonsterUnknown3:ChangeState(newState, monster, isTerminate)  
    monster.mCurrentState = newState

    return true
end

function gameActorStateMonsterUnknown3:GetStateID()
    return global.MMO.ACTION_UNKNOWN3
end

function gameActorStateMonsterUnknown3:OnAnimLoadCompleted(monster, animAct, elapsed)
    if animAct ~= global.MMO.ANIM_UNKNOWN3 then
        return false
    end

    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_UNKNOWN3) - elapsed
end

return gameActorStateMonsterUnknown3