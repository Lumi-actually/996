local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerDie = class('gameActorStatePlayerDie', gameActorState)

function gameActorStatePlayerDie:ctor()
    gameActorStatePlayerDie.super.ctor(self)
end

function gameActorStatePlayerDie:Tick(dt, actor)
end

function gameActorStatePlayerDie:OnEnter(player)
    if player.mActionHandler then
        player.mActionHandler:handleActionBegin(player, global.MMO.ACTION_DIE, player.mOrient, 0)
    end

    player:SetAnimPrepare(0.0)
    player:DirtyAnimFlag()
end

function gameActorStatePlayerDie:OnExit(player)
    if player.mActionHandler then
        player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_DIE)
    end
end

function gameActorStatePlayerDie:ChangeState(newState, player, isTerminate)
    player.mCurrentState = newState

    return true
end

function gameActorStatePlayerDie:GetStateID()    
    return global.MMO.ACTION_DIE
end

return gameActorStatePlayerDie
