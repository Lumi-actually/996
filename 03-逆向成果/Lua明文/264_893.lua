local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerReady = class('gameActorStatePlayerReady', gameActorState)

function gameActorStatePlayerReady:ctor()
    gameActorStatePlayerReady.super.ctor(self)
end

function gameActorStatePlayerReady:GetStateID()
    return global.MMO.ACTION_READY
end

function gameActorStatePlayerReady:Tick(dt, player)
    player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_READY)
end

function gameActorStatePlayerReady:ChangeState(newState, player, isTerminate)
    if newState:GetStateID() == self:GetStateID() then
        return false
    end

    player.mCurrentState = newState   

    return true
end

function gameActorStatePlayerReady:OnEnter(player)   
    player:DirtyAnimFlag()
end

function gameActorStatePlayerReady:OnExit(actor)    
end

return gameActorStatePlayerReady