local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterDie = class('gameActorStateMonsterDie', gameActorState)

function gameActorStateMonsterDie:ctor()
    gameActorStateMonsterDie.super.ctor(self)
end

function gameActorStateMonsterDie:Tick(dt, monster)
    if not monster.mIsArrived then
        monster.mCurrentActT = monster.mCurrentActT - dt
        if monster.mCurrentActT <= 0.00001 then
            monster.mIsArrived  = true
            monster.mActionHandler:handleActionCompleted(monster, global.MMO.ACTION_DIE)
        end
    end
end

function gameActorStateMonsterDie:OnEnter(monster)
    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_DIE)
    monster:SetIsArrived(false)
    monster.mActionHandler:handleActionBegin(monster, global.MMO.ACTION_DIE, monster.mOrient, 0)
end

function gameActorStateMonsterDie:OnExit(actor)
end

function gameActorStateMonsterDie:ChangeState(newState, monster, isTerminate)   
    if not isTerminate then
        if newState:GetStateID() ~= global.MMO.ACTION_IDLE and newState:GetStateID() ~= global.MMO.ACTION_DEATH and newState:GetStateID() ~= global.MMO.ACTION_BORN then
            return false
        end
    end

    monster.mCurrentState = newState

    return true
end

function gameActorStateMonsterDie:GetStateID()
    return global.MMO.ACTION_DIE
end

function gameActorStateMonsterDie:OnAnimLoadCompleted(monster, animAct, elapsed)
    if animAct ~= global.MMO.ANIM_DIE then
        return false
    end

    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_DIE) - elapsed
end

return gameActorStateMonsterDie