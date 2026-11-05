local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterChangeShape = class('gameActorStateMonsterChangeShape', gameActorState)

function gameActorStateMonsterChangeShape:ctor()
    gameActorStateMonsterChangeShape.super.ctor(self)
end

function gameActorStateMonsterChangeShape:Tick(dt, monster)
    if not monster.mIsArrived then
        monster.mCurrentActT = monster.mCurrentActT - dt
        if monster.mCurrentActT <= 0.00001  then
            monster.mIsArrived = true
            monster.mActionHandler:handleActionCompleted(monster, global.MMO.ACTION_CHANGESHAPE)
        end
    end
end

function gameActorStateMonsterChangeShape:OnEnter(monster)
    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_CHANGESHAPE)
    monster:SetIsArrived(false)
    monster.mActionHandler:handleActionBegin(monster, global.MMO.ACTION_CHANGESHAPE, monster.mOrient, 0)
end

function gameActorStateMonsterChangeShape:OnExit(actor)
end

function gameActorStateMonsterChangeShape:ChangeState(newState, monster)  
    monster.mCurrentState = newState
    return true
end

function gameActorStateMonsterChangeShape:GetStateID()
    return global.MMO.ACTION_CHANGESHAPE
end

function gameActorStateMonsterChangeShape:OnAnimLoadCompleted(monster, animAct, elapsed)
    if animAct ~= global.MMO.ANIM_CHANGESHAPE then
        return false
    end

    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_CHANGESHAPE) - elapsed
end

return gameActorStateMonsterChangeShape