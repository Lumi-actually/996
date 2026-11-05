local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerDashWaiting = class('gameActorStatePlayerDashWaiting', gameActorState)

function gameActorStatePlayerDashWaiting:ctor()
    gameActorStatePlayerDashWaiting.super.ctor(self)
end

function gameActorStatePlayerDashWaiting:GetStateID()    
    return global.MMO.ACTION_DASH_WAITING
end

function gameActorStatePlayerDashWaiting:Tick(dt, player)    
    player.mCurrentActT = player.mCurrentActT - dt

    if player.mCurrentActT <= 0.00001 or player.mDashWaiting == false then 
        if player.mActionHandler then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_DASH_WAITING)      
        end
    end
end

function gameActorStatePlayerDashWaiting:OnEnter(player)    
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_DASH_WAITING, player.mOrient, 0)
    end

    player.mCurrentActT = 3.0
    player:SetDashWaiting(true)

    -- reset some data
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerDashWaiting:OnExit(actor)    
end

function gameActorStatePlayerDashWaiting:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState

    return true
end

return gameActorStatePlayerDashWaiting