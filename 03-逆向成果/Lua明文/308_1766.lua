local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterDeath = class('gameActorStateMonsterDeath', gameActorState)

function gameActorStateMonsterDeath:ctor()
    gameActorStateMonsterDeath.super.ctor(self)
end

function gameActorStateMonsterDeath:Tick(dt, monster)
    if not monster.mIsArrived then
        monster.mCurrentActT = monster.mCurrentActT - dt
        if monster.mCurrentActT <= 0.00001 then
            monster.mIsArrived  = true
            monster.mActionHandler:handleActionCompleted(monster, global.MMO.ACTION_DEATH )
        end
    end
end

function gameActorStateMonsterDeath:OnEnter(monster)
    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_DEATH )
    monster:SetIsArrived(false)
    monster.mActionHandler:handleActionBegin(monster, global.MMO.ACTION_DEATH, monster.mOrient, 0 )
end

function gameActorStateMonsterDeath:OnExit(actor)
end

function gameActorStateMonsterDeath:ChangeState(newState, monster, isTerminate)   
    if not isTerminate then
        if newState:GetStateID() ~= global.MMO.ACTION_IDLE then
            return false
        end
    end

    monster.mCurrentState = newState

    return true
end

function gameActorStateMonsterDeath:GetStateID()
    return global.MMO.ACTION_DEATH
end

function gameActorStateMonsterDeath:OnAnimLoadCompleted(monster, animAct, elapsed)
    if animAct ~= global.MMO.ANIM_DEATH then
        return false
    end

    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_DEATH) - elapsed
end

return gameActorStateMonsterDeath