local gameActorState = require("actor/gameActorState")
local gameActorStateMonsterOnPush = class('gameActorStateMonsterOnPush', gameActorState)

local mMin  = math.min
local mSqrt = math.sqrt
local mRound = math.round

local function pGetLength(x, y)
    return mSqrt(x * x + y * y)
end

function gameActorStateMonsterOnPush:ctor()
    gameActorStateMonsterOnPush.super.ctor(self)
end

function gameActorStateMonsterOnPush:GetStateID()
    return global.MMO.ACTION_ONPUSH
end

function gameActorStateMonsterOnPush:Tick(dt, actor)    
    actor.mCurrentActT = actor.mCurrentActT - dt
    if not actor.mIsArrived then
        -- Timing...
        if actor.mCurrentActT <= 0.0 then
            actor:SetIsArrived(true)       
        end

        -- displacement
        local percent = (actor.mMoveTime - actor.mCurrentActT) / actor.mMoveTime
        percent       = mMin(1, percent)
        local disp    = percent * actor.mDistanceToTarget
        local dispX   = actor.mOriginPositionX + actor.mMoveOrientX * disp
        local dispY   = actor.mOriginPositionY + actor.mMoveOrientY * disp  

        if global.isWinPlayMode and actor:IsMonster() then
            dispX = mRound(dispX)
            dispY = mRound(dispY)
        end

        actor:setPosition(dispX, dispY)
    end

    if actor.mActionHandler and actor.mIsArrived then
        actor.mActionHandler:handleActionCompleted(actor, self:GetStateID())
    end
end

function gameActorStateMonsterOnPush:OnEnter(actor)
    if actor.mActionHandler then 
        actor.mActionHandler:handleActionBegin(actor, self:GetStateID())
    end
    
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

    actor.mMoveTime         = actor.mCurrentActT
    actor.mIsArrived        = false

    -- reset some data
    actor:DirtyAnimFlag()
end

function gameActorStateMonsterOnPush:OnExit(actor)    
    actor.mCurrentActT = 0.0
end

function gameActorStateMonsterOnPush:ChangeState(newState, actor, isTerminate)   
    actor.mCurrentState = newState
    return true
end

return gameActorStateMonsterOnPush