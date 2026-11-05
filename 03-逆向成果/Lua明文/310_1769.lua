local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterCave = class('gameActorStateMonsterCave', gameActorState)

function gameActorStateMonsterCave:ctor()
    gameActorStateMonsterCave.super.ctor(self)
end

function gameActorStateMonsterCave:Tick(dt, monster)
    if not monster.mIsArrived then
        monster.mCurrentActT = monster.mCurrentActT - dt
        if monster.mCurrentActT <= 0.00001 then
            monster:SetIsArrived(true)
            monster.mActionHandler:handleActionCompleted(monster, global.MMO.ACTION_CAVE)
        end
    end
end

function gameActorStateMonsterCave:OnEnter(monster)
    monster:DirtyAnimFlag()
    monster:SetIsArrived(false)
    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_BORN)
    monster.mActionHandler:handleActionBegin(monster, global.MMO.ACTION_CAVE, monster.mOrient, 0)
end

function gameActorStateMonsterCave:OnExit()
end

function gameActorStateMonsterCave:ChangeState(newState, monster, isTerminate)  
    if not isTerminate then
        if newState:GetStateID() ~= global.MMO.ACTION_BORN then
            return false
        end
    end

    monster.mCurrentState = newState

    return true
end

function gameActorStateMonsterCave:GetStateID()
    return global.MMO.ACTION_CAVE
end

function gameActorStateMonsterCave:OnAnimLoadCompleted(monster, animAct, elapsed)
    if animAct ~= global.MMO.ANIM_BORN then
        return false
    end

    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_BORN) - elapsed
end

return gameActorStateMonsterCave