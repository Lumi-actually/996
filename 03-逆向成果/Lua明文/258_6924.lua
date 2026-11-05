local gameActorState = require("actor/gameActorState")
local gameActorStateMoveBase = class('gameActorStateMoveBase', gameActorState)

local mFloor = math.floor
local mRound = math.round
local mSqrt  = math.sqrt

local function pGetLength(x, y)
    return mSqrt(x * x + y * y)
end

function gameActorStateMoveBase:ctor()
    gameActorStateMoveBase.super.ctor(self)
end

function gameActorStateMoveBase:GetStateID()
    return global.MMO.ACTION_WALK
end

function gameActorStateMoveBase:GetMoveTime(actor)
    return 0.5
end

function gameActorStateMoveBase:GetMoveFrame(actor)
    if actor:GetIsMoreFullSpeedup()
        or actor:GetIsMoreSpeedRate()
        or actor:GetIsFullSpeedup()
        or actor:GetIsSpeedup() then
        return global.ConstantConfig.PlayerRunAnimFrameCount /2
    end
    return global.ConstantConfig.PlayerRunAnimFrameCount
end

function gameActorStateMoveBase:Tick(dt, actor) 
    if G_ActorUtils.IsSmoothMove(actor) then
        self:smooth_tick(dt, actor)
    else
        self:mir_tick(dt, actor)
    end
end

local moveT = {}
function gameActorStateMoveBase:mir_tick(dt, actor)
    --统一更新时间 移动6次
    local canMove = true
    if actor.mWaitMoveFrame then --站立状态切换到移动 要等统一刷新
        if actor.mNextMoveTime > global.actorManager:GetCurrUpateMoveTime() then
            return 
        end
        canMove = global.actorManager:GetCurrUpateMoveTime() > actor.mNextMoveTime + global.actorManager:GetLockUpateMoveTime()
        actor.mCurrentActT = actor.mMoveTime - (global.actorManager:GetCurrUpateMoveTime() - actor.mNextMoveTime)
    else
        actor.mCurrentActT = actor.mCurrentActT - dt
    end
    
    if not actor.mIsArrived then
        if global.actorManager:IsUpdateMoveTime() and canMove then
            actor.mCurMoveFrame = actor.mCurMoveFrame + 1
            moveT.x = actor.mOriginPositionX + actor.mMoveOrientXEx * actor.mCurMoveFrame
            moveT.y = actor.mOriginPositionY + actor.mMoveOrientYEx * actor.mCurMoveFrame
            -- PC影子闪
            if actor:GetDirection() % 2 == 0 then
                moveT.x = mFloor(moveT.x)
                moveT.y = mFloor(moveT.y)

                moveT.x = (moveT.x%2 == 0) and moveT.x or moveT.x-1
                moveT.y = (moveT.y%2 == 0) and moveT.y or moveT.y-1
            else
                moveT.x = mFloor(moveT.x)
                moveT.y = mFloor(moveT.y)
            end
            actor:setPosition(moveT.x, moveT.y)
            -- if actor.mCurrentActT <= 0.0 then
            if actor.mCurMoveFrame >= actor.mMaxMoveFrame then
                actor:SetIsArrived(true)
            end
        end
    end

    if actor.mActionHandler and actor.mIsArrived and actor.mIsConfirmed then
        actor.mActionHandler:handleActionCompleted(actor, self:GetStateID())
    end

    -- confirmed timeout
    if actor.mCurrentActT <= -5.0 then
        actor:SetConfirmed(true)
    end
end

function gameActorStateMoveBase:smooth_tick(dt, actor)
    actor.mCurrentActT = actor.mCurrentActT - dt
    if not actor.mIsArrived then
        -- Timing...
        if actor.mCurrentActT <= 0.0  then
            actor.mIsArrived   = true       
        end

        -- displacement
        local percent = (actor.mMoveTime - actor.mCurrentActT) / actor.mMoveTime
        local disp = percent * actor.mDistanceToTarget
        moveT.x = actor.mOriginPositionX + actor.mMoveOrientX * disp
        moveT.y = actor.mOriginPositionY + actor.mMoveOrientY * disp  
        
        if global.isWinPlayMode and (actor:IsPlayer() or actor:IsMonster()) then
            moveT.x = mRound(moveT.x)
            moveT.y = mRound(moveT.y)
        end
        actor:setPosition(moveT.x, moveT.y)
    end

    if actor.mActionHandler and actor.mIsArrived and actor.mIsConfirmed then
        actor.mActionHandler:handleActionCompleted(actor, self:GetStateID())
    end


    -- confirmed timeout
    if actor.mCurrentActT <= -5.0 then
        actor:SetConfirmed(true)
    end
end

function gameActorStateMoveBase:OnEnter(actor)
    if actor.mMoveTo and actor.mMoveTo.x then
        self:moveToNextGrid(actor)
        actor.mIsArrived   = false
        actor:SetConfirmed(false)
        actor.mCurrentActT = self:GetMoveTime(actor)
        actor.mMoveTime    = self:GetMoveTime(actor)
    else
        actor.mIsArrived   = true
        actor.mIsConfirmed = true

        actor:SetAction(global.MMO.ACTION_IDLE)
    end

    actor.mNextMoveTime = global.actorManager:GetNextMoveTime()
    actor.mMaxMoveFrame = self:GetMoveFrame(actor)
    actor.mCurMoveFrame = 0

    -- 试玩模式，直接确认
    if global.IsVisitor then
        actor:SetConfirmed(true)
    end
end

function gameActorStateMoveBase:OnExit(actor)    
    actor.mCurrentActT = 0
end

function gameActorStateMoveBase:ChangeState(newState, actor, isTerminate)   
    actor.mCurrentState = newState

    return true
end

function gameActorStateMoveBase:moveToNextGrid(actor)   
    local gridPoint = actor.mMoveTo
    local tX, tY    = global.sceneManager:MapPos2WorldPos(gridPoint.x, gridPoint.y, true)
    local sX        = actor.mPositionX
    local sY        = actor.mPositionY

    actor.mOriginPositionX = sX
    actor.mOriginPositionY = sY
    actor.mTargePosX        = tX
    actor.mTargePosY        = tY
    actor.mMoveOrientX      = tX - sX
    actor.mMoveOrientY      = tY - sY
    actor.mDistanceToTarget = pGetLength(actor.mMoveOrientX, actor.mMoveOrientY)
    actor.mMoveOrientXEx = actor.mMoveOrientX / self:GetMoveFrame(actor)
    actor.mMoveOrientYEx = actor.mMoveOrientY / self:GetMoveFrame(actor)

    if actor.mDistanceToTarget == 0 then
        actor.mMoveOrientX = 1
        actor.mMoveOrientY = 0
    else
        actor.mMoveOrientX = actor.mMoveOrientX / actor.mDistanceToTarget
        actor.mMoveOrientY = actor.mMoveOrientY / actor.mDistanceToTarget
    end
    

    
    -- calcuating the orientation for Animation
    local mapX, mapY        = global.sceneManager:WorldPos2MapPos(actor:getPositionX(), actor:getPositionY())
    local lastOri           = actor.mOrient
    actor.mOrient           = G_ActorUtils.CalcActorDirByPos(mapX, mapY, gridPoint.x, gridPoint.y, lastOri)

    -- store grid position
    global.actorManager:SetActorMapXY(actor, gridPoint.x, gridPoint.y)

    -- gird pos changed
    if actor.mActionHandler then 
        actor.mActionHandler:handleActionBegin(actor, self:GetStateID())
    end

    if lastOri ~= actor.mOrient then
        actor:DirtyAnimFlag()
        
        local actorID = actor:GetID()
        global.BuffManager:UpdateBuffSfxDir(actorID)
        global.ActorEffectManager:UpdateEffectDir(actor, actorID)
    end
end

return gameActorStateMoveBase