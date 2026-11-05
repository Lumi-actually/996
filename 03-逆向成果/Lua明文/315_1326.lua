local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterTeleport = class('gameActorStateMonsterTeleport', gameActorState)

function gameActorStateMonsterTeleport:ctor()
    gameActorStateMonsterTeleport.super.ctor(self)
end

function gameActorStateMonsterTeleport:GetStateID()
    return global.MMO.ACTION_TELEPORT
end

function gameActorStateMonsterTeleport:Tick(dt, actor)    
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
        end
    end
end

function gameActorStateMonsterTeleport:OnEnter(actor)
    if actor.mActionHandler then 
        actor.mActionHandler:handleActionBegin(actor, self:GetStateID())
    end

    -- reset some data
    actor:SetIsArrived(false)
    actor:DirtyAnimFlag()
end

function gameActorStateMonsterTeleport:OnExit(actor)    
end

function gameActorStateMonsterTeleport:ChangeState(newState, actor, isTerminate)   
    actor.mCurrentState = newState

    return true
end

return gameActorStateMonsterTeleport