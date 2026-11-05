local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterSkill = class('gameActorStateMonsterSkill', gameActorState)

function gameActorStateMonsterSkill:ctor()
    gameActorStateMonsterSkill.super.ctor(self)
end

function gameActorStateMonsterSkill:Tick(dt, monster)    
    if not monster.mIsArrived then
        monster.mCurrentActT = monster.mCurrentActT - dt
        if monster.mCurrentActT <= 0.00001  then
            monster.mIsArrived  = true
            monster.mActionHandler:handleActionCompleted(monster, global.MMO.ACTION_SKILL)
        end
    end
end

function gameActorStateMonsterSkill:OnEnter(monster)    
    local animTime = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_SKILL)
    --怪物施法 默认用帧动画速度  要是快于帧速度 就加速 
    if monster:GetMagicAnimSpeed() > 1 then 
        monster.mCurrentActT = animTime / monster:GetMagicAnimSpeed()
    else
        monster.mCurrentActT = animTime
    end
    monster:SetIsArrived(false)  
    monster.mActionHandler:handleActionBegin(monster, global.MMO.ACTION_SKILL, monster.mOrient, 0)
end

function gameActorStateMonsterSkill:OnExit(actor)    
end

function gameActorStateMonsterSkill:ChangeState(newState, monster, isTerminate)   
    monster.mCurrentState = newState

    return true
end

function gameActorStateMonsterSkill:GetStateID()    
    return global.MMO.ACTION_SKILL
end

function gameActorStateMonsterSkill:OnAnimLoadCompleted(monster, animAct, elapsed)
    if animAct ~= global.MMO.ANIM_SKILL then
        return false
    end

    monster.mCurrentActT = global.FrameAnimManager:GetAnimTotalDuration(monster:GetAnimationID(), global.MMO.SFANIM_TYPE_MONSTER, global.MMO.ANIM_SKILL) - elapsed
end

return gameActorStateMonsterSkill