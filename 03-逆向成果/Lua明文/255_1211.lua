local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerIdle = class('gameActorStatePlayerIdle', gameActorState)

function gameActorStatePlayerIdle:ctor()
    gameActorStatePlayerIdle.super.ctor(self)
end

function gameActorStatePlayerIdle:GetStateID()
    return global.MMO.ACTION_IDLE
end

function gameActorStatePlayerIdle:Tick(dt, player)
    if player:GetAnimPrepare() > 0.0 then
        player:SetAnimPrepare(player:GetAnimPrepare() - dt)

        if player:GetAnimPrepare() <= 0.0 then
            player:SetAnimAct(global.MMO.ANIM_IDLE)
            player:DirtyAnimFlag()
        end
    end

    if player.mActionHandler then
        player.mActionHandler:handleActionCompleted(player, global.MMO.ACTION_IDLE)
    end
end

function gameActorStatePlayerIdle:ChangeState(newState, player, isTerminate)    
    if newState:GetStateID() == self:GetStateID() then
        return false
    end

    player.mCurrentState = newState   

    return true
end

function gameActorStatePlayerIdle:OnEnter(player)    
    self.super.OnEnter(self, player)
end

function gameActorStatePlayerIdle:OnExit(actor)    
end

return gameActorStatePlayerIdle