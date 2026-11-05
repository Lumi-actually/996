local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerSkill = class('gameActorStatePlayerSkill', gameActorState)

function gameActorStatePlayerSkill:ctor()
    gameActorStatePlayerSkill.super.ctor(self)
end

function gameActorStatePlayerSkill:Tick(dt, player)    
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_SKILL)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end

function gameActorStatePlayerSkill:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_SKILL, player.mOrient, 0)
    end

    local animTime      = player:GetMagicStepTime() / player:GetMagicSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerSkill:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerSkill:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState
    
    return true
end

function gameActorStatePlayerSkill:GetStateID()    
    return global.MMO.ACTION_SKILL
end

return gameActorStatePlayerSkill