local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterBorn = class('gameActorStateMonsterBorn', gameActorState)

function gameActorStateMonsterBorn:ctor()
    gameActorStateMonsterBorn.super.ctor(self)
end

function gameActorStateMonsterBorn:Tick(dt, monster)
    if not monster.mIsArrived and not monster:GetStoneMode() then
        monster.mCurrentActT = monster.mCurrentActT - dt
        if monster.mCurrentActT <= 0.00001 then
            monster:SetIsArrived(true)
            monster.mActionHandler:handleActionCompleted(monster, global.MMO.ACTION_BORN)
        end
    end
end

function gameActorStateMonsterBorn:OnEnter(monster)
    monster:DirtyAnimFlag()
    monster:SetIsArrived(false)
    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_BORN)
    monster.mActionHandler:handleActionBegin(monster, global.MMO.ACTION_BORN, monster.mOrient, 0)
end

function gameActorStateMonsterBorn:OnExit(actor)
end

function gameActorStateMonsterBorn:ChangeState(newState, monster, isTerminate)  
    monster.mCurrentState = newState
    return true
end

function gameActorStateMonsterBorn:GetStateID()
    return global.MMO.ACTION_BORN
end

function gameActorStateMonsterBorn:OnAnimLoadCompleted(monster, animAct, elapsed)
    if animAct ~= global.MMO.ANIM_BORN then
        return false
    end

    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_BORN) - elapsed
end

return gameActorStateMonsterBorn