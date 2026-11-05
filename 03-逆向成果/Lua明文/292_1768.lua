local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerAssassinSkill = class('gameActorStatePlayerAssassinSkill', gameActorState)
function gameActorStatePlayerAssassinSkill:ctor()
    gameActorStatePlayerAssassinSkill.super.ctor(self)
end

function gameActorStatePlayerAssassinSkill:Tick(dt, player)    
    player.mCurrentActT = player.mCurrentActT - dt

    if 0.0 >= player.mCurrentActT and player.mIsConfirmed then
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_ASSASSIN_SKILL)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end

function gameActorStatePlayerAssassinSkill:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_ASSASSIN_SKILL, player.mOrient, 0)
    end

    local animTime      = global.MMO.DEFAULT_ASSASSIN_SKILL_TIME / player:GetAttackSpeed()
    player.mAnimTime    = animTime
    player.mCurrentActT = animTime
    player:SetConfirmed(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerAssassinSkill:OnExit(player)    
    -- reset prepare time
    player:SetAnimPrepare(3.0)

    -- 
    player:SetAnimAct(global.MMO.ANIM_READY)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerAssassinSkill:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState
    
    return true
end

function gameActorStatePlayerAssassinSkill:GetStateID()    
    return global.MMO.ACTION_ASSASSIN_SKILL
end

return gameActorStatePlayerAssassinSkill