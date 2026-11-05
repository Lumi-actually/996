local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerStuck = class('gameActorStatePlayerStuck', gameActorState)

function gameActorStatePlayerStuck:ctor()
    gameActorStatePlayerStuck.super.ctor(self)
end

function gameActorStatePlayerStuck:Tick(dt, player)    
    player.mCurrentActT = player.mCurrentActT - dt
    if player.mActionHandler then
        player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_STUCK)
    end
end

function gameActorStatePlayerStuck:OnEnter(player)   
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_STUCK, player.mOrient, 0)
    end 
    local mapProxy          = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    local stuckTimeMS       = (mapProxy:GetStuckActionTime() or 200) / 1000
    local currentActT       = stuckTimeMS
    if player:GetIsFullSpeedup() then
        currentActT         = stuckTimeMS / global.MMO.DEFAULT_MUCH_FAST_TIME
    elseif player:GetIsSpeedup() then
        currentActT         = stuckTimeMS / global.MMO.DEFAULT_FAST_TIME_RATE
    end
    player.mCurrentActT     = currentActT

    --
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerStuck:OnExit(player)    
    player:SetAnimPrepare(player.mCurrentActT)
    player:DirtyAnimFlag()

    player.mCurrentActT = 0
end

function gameActorStatePlayerStuck:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState

    return true
end

function gameActorStatePlayerStuck:GetStateID()    
    return global.MMO.ACTION_STUCK
end

return gameActorStatePlayerStuck