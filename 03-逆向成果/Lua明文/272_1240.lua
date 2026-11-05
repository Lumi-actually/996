local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerIdleLock = class('gameActorStatePlayerIdleLock', gameActorState)

function gameActorStatePlayerIdleLock:ctor()
    gameActorStatePlayerIdleLock.super.ctor(self)
end

function gameActorStatePlayerIdleLock:GetStateID()    
    return global.MMO.ACTION_IDLE_LOCK
end

function gameActorStatePlayerIdleLock:Tick(dt, player)    
    player.mCurrentActT = player.mCurrentActT - dt

    if player.mCurrentActT <= 0.00001 then 
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_IDLE_LOCK)      
        end
    end
end

function gameActorStatePlayerIdleLock:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_IDLE_LOCK, player.mOrient, 0)
    end

    player.mCurrentActT = 1.0
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerIdleLock:OnExit(actor)    
end

function gameActorStatePlayerIdleLock:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState

    return true
end

return gameActorStatePlayerIdleLock