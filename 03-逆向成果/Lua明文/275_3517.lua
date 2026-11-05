local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerZXC = class('gameActorStatePlayerZXC', gameActorState)

local mRound = math.round
local mSqrt  = math.sqrt

local function pGetLength(x, y)
    return mSqrt(x * x + y * y)
end

function gameActorStatePlayerZXC:ctor()
    gameActorStatePlayerZXC.super.ctor(self)
end

function gameActorStatePlayerZXC:GetStateID()
    return global.MMO.ACTION_ZXC
end
-----------------------------------------------------------------------------
function gameActorStatePlayerZXC:Tick(dt, actor)  
    actor.mCurrentActT = actor.mCurrentActT - dt
    if not actor.mIsArrived then
        -- Timing...
        if actor.mCurrentActT <= 0.0 then
            actor:SetIsArrived(true)     
        end

        -- displacement
        local percent = (actor.mMoveTime - actor.mCurrentActT) / actor.mMoveTime
        percent       = math.min(1, percent)
        local disp    = percent * actor.mDistanceToTarget
        local dispX   = actor.mOriginPositionX + actor.mMoveOrientX * disp
        local dispY   = actor.mOriginPositionY + actor.mMoveOrientY * disp  

        if global.isWinPlayMode and actor:IsPlayer() then
            dispX = mRound(dispX)
            dispY = mRound(dispY)
        end

        actor:setPosition(dispX, dispY)
    end

    if actor.mActionHandler then
        if actor.mIsArrived then
            actor.mActionHandler:handleActionCompleted(actor, self:GetStateID())
        else
            actor.mActionHandler:handleActionProcess(actor, self:GetStateID(), dt)
        end
    end
end
-----------------------------------------------------------------------------
function gameActorStatePlayerZXC:OnEnter(actor)    
    if actor.mActionHandler then
        actor.mActionHandler:handleActionBegin(actor, self:GetStateID())
    end 
    local animTime      = global.MMO.DEFAULT_ZXC_TIME / actor:GetAttackSpeed()
    actor.mCurrentActT = animTime

    local tX, tY    = global.sceneManager:MapPos2WorldPos(actor:GetMapX(), actor:GetMapY(), true)
    local sX        = actor:getPositionX()
    local sY        = actor:getPositionY()
    actor.mOriginPositionX  = sX
    actor.mOriginPositionY  = sY
    actor.mTargePosX        = tX
    actor.mTargePosY        = tY
    actor.mMoveOrientX      = tX - sX
    actor.mMoveOrientY      = tY - sY
    actor.mDistanceToTarget = pGetLength(actor.mMoveOrientX, actor.mMoveOrientY)
    if actor.mDistanceToTarget == 0 then
        actor.mMoveOrientX = 1
        actor.mMoveOrientY = 0
    else
        actor.mMoveOrientX = actor.mMoveOrientX / actor.mDistanceToTarget
        actor.mMoveOrientY = actor.mMoveOrientY / actor.mDistanceToTarget
    end


    actor.mMoveTime        = actor.mCurrentActT
    actor.mIsArrived       = false   

    -- reset some data
    actor:SetAnimPrepare(0.0)
    actor:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerZXC:OnExit(actor)    
    actor.mCurrentActT = 0.0
    -- reset prepare time
    actor:SetAnimPrepare(0.0)
    actor:DirtyAnimFlag()
end
-----------------------------------------------------------------------------
function gameActorStatePlayerZXC:ChangeState(newState, actor, isTerminate)    
    actor.mCurrentState = newState   

    return true
end
return gameActorStatePlayerZXC
-----------------------------------------------------------------------------

