local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterUnknown1 = class('gameActorStateMonsterUnknown1', gameActorState)

function gameActorStateMonsterUnknown1:ctor()
    gameActorStateMonsterUnknown1.super.ctor(self)
end

function gameActorStateMonsterUnknown1:Tick(dt, monster)
    if not monster.mIsArrived then
        monster.mCurrentActT = monster.mCurrentActT - dt
        if monster.mCurrentActT <= 0.00001 then
            monster.mIsArrived = true
            monster.mActionHandler:handleActionCompleted(monster, global.MMO.ACTION_UNKNOWN1)
        end
    end
end

function gameActorStateMonsterUnknown1:OnEnter(monster)
    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_UNKNOWN1)
    monster:SetIsArrived(false)
    monster.mActionHandler:handleActionBegin(monster, global.MMO.ACTION_UNKNOWN1, monster.mOrient, 0)
end

function gameActorStateMonsterUnknown1:OnExit(actor)
end

function gameActorStateMonsterUnknown1:ChangeState(newState, monster, isTerminate)  
    monster.mCurrentState = newState

    return true
end

function gameActorStateMonsterUnknown1:GetStateID()
    return global.MMO.ACTION_UNKNOWN1
end

function gameActorStateMonsterUnknown1:OnAnimLoadCompleted(monster, animAct, elapsed)
    if animAct ~= global.MMO.ANIM_UNKNOWN1 then
        return false
    end

    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_UNKNOWN1) - elapsed
end

return gameActorStateMonsterUnknown1