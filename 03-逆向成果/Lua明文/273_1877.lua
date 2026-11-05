local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerTurn = class('gameActorStatePlayerTurn', gameActorState)
function gameActorStatePlayerTurn:ctor()
    gameActorStatePlayerTurn.super.ctor(self)
end

function gameActorStatePlayerTurn:GetStateID()
    return global.MMO.ACTION_TURN
end

function gameActorStatePlayerTurn:Tick(dt, player)  
    player.mCurrentActT = player.mCurrentActT - dt
    if player.mCurrentActT <= 0.00001 then 
        if player.mActionHandler and player.mIsConfirmed then
            player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_TURN)      
        end
    end 

    -- 
    local prepareTime = player:GetAnimPrepare()
    if prepareTime > 0.001 then
        if prepareTime - dt <= 0.001 then
            player:SetAnimPrepare(0.0)
        else
            player:SetAnimPrepare(prepareTime - dt)
        end
    end

    -- confirmed timeout
    if player.mCurrentActT <= -5.0 then
        player:SetConfirmed(true)
    end
end

function gameActorStatePlayerTurn:OnEnter(player)    
    self.super.OnEnter(self, player)

    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_TURN, player.mOrient, 0)
    end 

    local mapProxy          = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    local actionTime        = mapProxy:GetTurnIntervalTime() * 0.001
    player.mCurrentActT     = actionTime

    -- reset some data
    player:SetConfirmed(false)
    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerTurn:OnExit(player)    
    player:DirtyAnimFlag()
end

function gameActorStatePlayerTurn:ChangeState(newState, player, isTerminate)    
    player.mCurrentState = newState   

    return true
end

return gameActorStatePlayerTurn