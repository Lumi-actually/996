local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerTeleport = class('gameActorStatePlayerTeleport', gameActorState)

function gameActorStatePlayerTeleport:ctor()
    gameActorStatePlayerTeleport.super.ctor(self)
end

function gameActorStatePlayerTeleport:GetStateID()
    return global.MMO.ACTION_TELEPORT
end

function gameActorStatePlayerTeleport:Tick(dt, actor)    
    actor.mCurrentActT = actor.mCurrentActT - dt
    if not actor.mIsArrived then
        -- Timing...
        if actor.mCurrentActT <= 0.0 then
            actor:SetIsArrived(true)       
        end
    end

    if actor.mActionHandler then
        if actor.mIsArrived then
            actor.mActionHandler:handleActionCompleted(actor, self:GetStateID())
        else
            actor.mActionHandler:handleActionProcess(actor, self:GetStateID(), dt)
        end
    end
end

function gameActorStatePlayerTeleport:OnEnter(actor)
    if actor.mActionHandler then 
        actor.mActionHandler:handleActionBegin(actor, self:GetStateID())
    end

    -- reset some data
    actor:SetIsArrived(false)
    actor:SetAnimPrepare(0.0)
    actor:DirtyAnimFlag()
end

function gameActorStatePlayerTeleport:OnExit(actor)    
end

function gameActorStatePlayerTeleport:ChangeState(newState, actor, isTerminate)   
    actor.mCurrentState = newState

    return true
end

return gameActorStatePlayerTeleport