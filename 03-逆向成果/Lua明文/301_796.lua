local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterIdle = class('gameActorStateMonsterIdle', gameActorState)

function gameActorStateMonsterIdle:ctor()
    gameActorStateMonsterIdle.super.ctor(self)
end

function gameActorStateMonsterIdle:Tick(dt, actor)
end

function gameActorStateMonsterIdle:ChangeState(newState, monster)   
    if newState:GetStateID() == self:GetStateID() then
        return false
    end

    monster.mCurrentState = newState   

    return true
end

function gameActorStateMonsterIdle:OnEnter(monster)
    monster:DirtyAnimFlag()
end

function gameActorStateMonsterIdle:OnExit(actor)
end

function gameActorStateMonsterIdle:GetStateID()
    return global.MMO.ACTION_IDLE
end

return gameActorStateMonsterIdle