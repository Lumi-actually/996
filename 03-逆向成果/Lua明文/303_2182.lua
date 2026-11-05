local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterAttack = class('gameActorStateMonsterAttack', gameActorState)

function gameActorStateMonsterAttack:ctor()
    gameActorStateMonsterAttack.super.ctor(self)
end

function gameActorStateMonsterAttack:Tick(dt, monster)
    if not monster.mIsArrived then
        monster.mCurrentActT = monster.mCurrentActT - dt
        if monster.mCurrentActT <= 0.00001 then
            monster:SetIsArrived(true)
            monster.mActionHandler:handleActionCompleted(monster, global.MMO.ACTION_ATTACK)
        end
    end
end

function gameActorStateMonsterAttack:OnEnter(monster)
    local animTime = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_ATTACK)
    --怪物攻速 默认用帧动画速度  要是快于帧速度 就加速
    if monster:GetAttackSpeed() > 1 then 
        monster.mCurrentActT = animTime / monster:GetAttackSpeed()
    else
        monster.mCurrentActT = animTime
    end
    monster:SetIsArrived(false)  
    monster.mActionHandler:handleActionBegin(monster, global.MMO.ACTION_ATTACK, monster.mOrient, 0)
end

function gameActorStateMonsterAttack:OnExit(actor)
    actor:StopAllAnimation()
    actor:DirtyAnimFlag() 
end

function gameActorStateMonsterAttack:ChangeState(newState, monster, isTerminate)   
    monster.mCurrentState = newState

    return true
end

function gameActorStateMonsterAttack:GetStateID()
    return global.MMO.ACTION_ATTACK
end

function gameActorStateMonsterAttack:OnAnimLoadCompleted(monster, animAct, elapsed)
    if animAct ~= global.MMO.ANIM_ATTACK then
        return false
    end

    local animTime = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_ATTACK) - elapsed
    --怪物攻速 默认用帧动画速度  要是快于帧速度 就加速
    if monster:GetAttackSpeed() > 1 then 
        monster.mCurrentActT = animTime / monster:GetAttackSpeed()
    else
        monster.mCurrentActT = animTime
    end
end

return gameActorStateMonsterAttack