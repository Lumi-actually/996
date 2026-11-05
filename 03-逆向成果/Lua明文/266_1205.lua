local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerSitdown = class('gameActorStatePlayerSitdown', gameActorState)

function gameActorStatePlayerSitdown:ctor()
    gameActorStatePlayerSitdown.super.ctor(self)
end

function gameActorStatePlayerSitdown:Tick(dt, player)    
    player.mCurrentActT = player.mCurrentActT - dt

    if player.mCurrentActT <= 0.00001 then 
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_SITDOWN)
        end
    end
end

function gameActorStatePlayerSitdown:OnEnter(player)    
    local animTime      = player:GetAttackStepTime() / player:GetAttackSpeed()
    player.mCurrentActT = animTime

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerSitdown:OnExit(player)  
    player:DirtyAnimFlag()
end

function gameActorStatePlayerSitdown:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState

    return true
end

function gameActorStatePlayerSitdown:GetStateID()  
    return global.MMO.ACTION_SITDOWN
end

return gameActorStatePlayerSitdown