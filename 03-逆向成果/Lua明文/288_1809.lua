local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerSBYS = class('gameActorStatePlayerSBYS', gameActorState)

function gameActorStatePlayerSBYS:ctor()
    gameActorStatePlayerSBYS.super.ctor(self)
end

function gameActorStatePlayerSBYS:GetStateID()
    return global.MMO.ACTION_SBYS
end

function gameActorStatePlayerSBYS:Tick(dt, actor)    
    actor.mCurrentActT = actor.mCurrentActT - dt
    if not actor.mIsArrived then
        -- Timing...
        if actor.mCurrentActT <= 0.0 then
            actor:SetIsArrived(true)

            local mapX = actor:GetMapX()
            local mapY = actor:GetMapY()
            local wX, wY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
            actor:setPosition(wX, wY) 
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

function gameActorStatePlayerSBYS:OnEnter(actor)
    if actor.mActionHandler then 
        actor.mActionHandler:handleActionBegin(actor, self:GetStateID())
    end

    local animTime = 0.1 / actor:GetAttackSpeed()
    actor:SetCurrActTime(animTime)
    actor:SetIsArrived(false)
    actor:SetAnimPrepare(0.5)
    actor:SetAnimAct(global.MMO.ANIM_READY)
    actor:DirtyAnimFlag()
end

function gameActorStatePlayerSBYS:OnExit(actor)
    actor:SetAnimPrepare(3.0)
    actor:SetAnimAct(global.MMO.ANIM_READY)
    actor:DirtyAnimFlag()
end

function gameActorStatePlayerSBYS:ChangeState(newState, actor, isTerminate)   
    actor.mCurrentState = newState

    return true
end

return gameActorStatePlayerSBYS