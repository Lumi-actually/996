local gameActorStateMoveBase = require("actor/gameActorStateMoveBase")
local gameActorStatePlayerDashFail = class('gameActorStatePlayerWalk', gameActorStateMoveBase)

local mSqrt = math.sqrt

local function pGetLength(x, y)
    return mSqrt(x * x + y * y)
end

function gameActorStatePlayerDashFail:ctor()
    self.super.ctor(self)
end

function gameActorStatePlayerDashFail:GetStateID()
    return global.MMO.ACTION_DASH_FAIL
end

function gameActorStatePlayerDashFail:OnEnter(actor)
    local sX        = actor.mPositionX
    local sY        = actor.mPositionY
    local tX        = sX
    local tY        = sY
    local actorDir  = actor:GetDirection()

    local gridFactor = 0.5
    if actorDir == global.MMO.ORIENT_U then
        tY = tY + global.MMO.MapGridHeight * gridFactor
    elseif actorDir == global.MMO.ORIENT_RU then
        tX = tX + global.MMO.MapGridWidth * gridFactor
        tY = tY + global.MMO.MapGridHeight * gridFactor
    elseif actorDir == global.MMO.ORIENT_R then
        tX = tX + global.MMO.MapGridWidth * gridFactor
    elseif actorDir == global.MMO.ORIENT_RB then
        tX = tX + global.MMO.MapGridWidth * gridFactor
        tY = tY - global.MMO.MapGridHeight * gridFactor
    elseif actorDir == global.MMO.ORIENT_B then
        tY = tY - global.MMO.MapGridHeight * gridFactor
    elseif actorDir == global.MMO.ORIENT_LB then
        tX = tX - global.MMO.MapGridWidth * gridFactor
        tY = tY - global.MMO.MapGridHeight * gridFactor
    elseif actorDir == global.MMO.ORIENT_L then
        tX = tX - global.MMO.MapGridWidth * gridFactor
    elseif actorDir == global.MMO.ORIENT_LU then
        tX = tX - global.MMO.MapGridWidth * gridFactor
        tY = tY + global.MMO.MapGridHeight * gridFactor
    end

    actor.mNextMoveTime     = global.actorManager:GetNextMoveTime()
    actor.mMaxMoveFrame     = self:GetMoveFrame(actor)
    actor.mCurMoveFrame     = 0

    actor.mOriginPositionX  = sX
    actor.mOriginPositionY  = sY
    actor.mTargePosX        = tX
    actor.mTargePosY        = tY
    actor.mMoveOrientX      = tX - sX
    actor.mMoveOrientY      = tY - sY
    actor.mDistanceToTarget = pGetLength(actor.mMoveOrientX, actor.mMoveOrientY)
    actor.mMoveOrientXEx    = actor.mMoveOrientX / self:GetMoveFrame(actor)
    actor.mMoveOrientYEx    = actor.mMoveOrientY / self:GetMoveFrame(actor)
    if actor.mDistanceToTarget == 0 then
        actor.mMoveOrientX = 1
        actor.mMoveOrientY = 0
    else
        actor.mMoveOrientX = actor.mMoveOrientX / actor.mDistanceToTarget
        actor.mMoveOrientY = actor.mMoveOrientY / actor.mDistanceToTarget
    end

    print("sX", sX, sY, tX, tY)

    local animTime          = actor:GetRunStepTime() / actor:GetRunSpeed() / 4
    actor.mCurrentActT      = animTime
    actor.mMoveTime         = animTime
    actor.mIsArrived        = false

    if actor.mActionHandler then 
        actor.mActionHandler:handleActionBegin(actor, self:GetStateID())
    end

    -- reset some data
    actor:SetConfirmed(true)
    actor:SetAnimPrepare(0.0)
    actor:DirtyAnimFlag()
end

function gameActorStatePlayerDashFail:OnExit(actor)    
    actor:SetAnimPrepare(0.1)
    actor:StopAllAnimation(6)
end

return gameActorStatePlayerDashFail