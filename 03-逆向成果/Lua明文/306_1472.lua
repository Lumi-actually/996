local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterStuck = class('gameActorStateMonsterStuck', gameActorState)

function gameActorStateMonsterStuck:ctor()
    gameActorStateMonsterStuck.super.ctor(self)
end

function gameActorStateMonsterStuck:Tick(dt, monster)    
    monster.mCurrentActT = monster.mCurrentActT - dt

    if monster.mCurrentActT <= 0.00001 then
        if monster.mActionHandler then
            monster.mActionHandler:handleActionCompleted(monster, global.MMO.ACTION_STUCK)  
        end
    end 
end

function gameActorStateMonsterStuck:OnEnter(monster)    
    local mapProxy          = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    local stuckTimeMS       = (mapProxy:GetStuckActionTime() or 200) / 1000
    local currentActT       = stuckTimeMS
    if monster:GetIsFullSpeedup() then
        currentActT         = stuckTimeMS / global.MMO.DEFAULT_MUCH_FAST_TIME
    elseif monster:GetIsSpeedup() then
        currentActT         = stuckTimeMS / global.MMO.DEFAULT_FAST_TIME_RATE
    end
    monster.mCurrentActT    = currentActT
end

function gameActorStateMonsterStuck:OnExit(actor)   
end

function gameActorStateMonsterStuck:ChangeState(newState, monster, isTerminate)   
    monster.mCurrentState = newState
    
    return true
end

function gameActorStateMonsterStuck:GetStateID() 
    return global.MMO.ACTION_STUCK
end

return gameActorStateMonsterStuck