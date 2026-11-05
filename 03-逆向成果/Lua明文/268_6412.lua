local gameActorState = require("actor/gameActorState")
local gameActorStatePlayerDash = class('gameActorStatePlayerDash', gameActorState)

local mRound = math.round
local mSqrt  = math.sqrt
local mMin   = math.min

local function pGetLength(x, y)
    return mSqrt(x * x + y * y)
end

local SharedPoint = {}
local SharedPoint2 = {}

local MOVETO_GHOST_FADEOUT_TIME = 0.7
local MOVETO_GHOST_INTERVAL     = 0.15

function gameActorStatePlayerDash:ctor()
    gameActorStatePlayerDash.super.ctor(self)
end

function gameActorStatePlayerDash:GetStateID()
    return global.MMO.ACTION_DASH
end

function gameActorStatePlayerDash:Tick(dt, actor)    
    actor._ghostTime = actor._ghostTime - dt
    if actor._ghostTime <= 0.00001 then
        actor._ghostTime = actor._ghostInterval
        
        SharedPoint2.x = actor:getPositionX()
        SharedPoint2.y = actor:getPositionY()
        local anim      = nil
        local isMonster = true

        -- monster
        anim = actor:GetAnimationMonster()
        if anim then
            SharedPoint.x = anim:GetStandPointX()
            SharedPoint.y = anim:GetStandPointY()
            self:ghostSprite(anim:getSpriteFrame(), SharedPoint2, SharedPoint, anim)
            isMonster = false
        end

        -- anchor pos is same of weapon/wings
        anim = actor:GetAnimation()
        if isMonster and anim then
            SharedPoint.x = anim:GetStandPointX()
            SharedPoint.y = anim:GetStandPointY()
            self:ghostSprite(anim:getSpriteFrame(), SharedPoint2, SharedPoint, anim)
            isMonster = false
        end
        
        anim = actor:GetAnimationWeapon()
        if isMonster and anim then
            SharedPoint.x = anim:GetStandPointX()
            SharedPoint.y = anim:GetStandPointY()
            self:ghostSprite(anim:getSpriteFrame(), SharedPoint2, SharedPoint, anim)
        end
        
        anim = actor:GetAnimationShield()
        if isMonster and anim then
            SharedPoint.x = anim:GetStandPointX()
            SharedPoint.y = anim:GetStandPointY()
            self:ghostSprite(anim:getSpriteFrame(), SharedPoint2, SharedPoint, anim)
        end
        
        anim = actor:GetAnimationWings()
        if isMonster and anim then
            SharedPoint.x = anim:GetStandPointX()
            SharedPoint.y = anim:GetStandPointY()
            self:ghostSprite(anim:getSpriteFrame(), SharedPoint2, SharedPoint, anim)
        end

        anim = actor:GetAnimationHair()
        if isMonster and anim then
            SharedPoint.x = anim:GetStandPointX()
            SharedPoint.y = anim:GetStandPointY()
            self:ghostSprite(anim:getSpriteFrame(), SharedPoint2, SharedPoint, anim)
        end
    end

    actor.mCurrentActT = actor.mCurrentActT - dt
    if not actor.mIsArrived then
        -- Timing...
        if actor.mCurrentActT <= 0.0 then
            actor:SetIsArrived(true)       
        end

        -- displacement
        local percent   = (actor.mMoveTime - actor.mCurrentActT) / actor.mMoveTime
        percent         = mMin(1, percent)
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

function gameActorStatePlayerDash:OnEnter(actor,param)
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

    -- 
    actor.mMoveTime         = actor.mCurrentActT
    actor.mIsArrived        = false
    actor._ghostTime        = 0
    actor._ghostInterval    = MOVETO_GHOST_INTERVAL

    -- reset some data
    actor:SetAnimPrepare(0.0)
    actor:DirtyAnimFlag()
end

function gameActorStatePlayerDash:OnExit(actor)    
    actor.mCurrentActT = 0.0
    -- reset some data
    actor:SetAnimPrepare(0.0)
    actor:DirtyAnimFlag()
end

function gameActorStatePlayerDash:ChangeState(newState, actor, isTerminate)   
    actor.mCurrentState = newState

    return true
end

function gameActorStatePlayerDash:ghostSprite(frame, pos, anchorPos, anim)
    if not frame then
        return
    end
    
    local ghost = cc.Sprite:createWithSpriteFrame(frame)
    if ghost then
        local behind_sfx_node = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_ACTOR_SFX_FRONT)
        behind_sfx_node:addChild(ghost)
        local offsetX = anim:GetOffsetX()
        local offsetY = anim:GetOffsetY()
        pos.x = pos.x + offsetX + global.MMO.PLAYER_AVATAR_OFFSET.x
        pos.y = pos.y + offsetY + global.MMO.PLAYER_AVATAR_OFFSET.y
        ghost:setPosition(pos)
        ghost:setAnchorPoint(anchorPos)
        ghost:setBlendFunc(anim:getBlendFunc())
        
        local function FadeOutEnd()
            ghost:removeFromParent()
        end
        
        local fo = cc.FadeOut:create(MOVETO_GHOST_FADEOUT_TIME)
        local seq = cc.Sequence:create(fo, cc.CallFunc:create(FadeOutEnd))
        
        ghost:runAction(seq)
    end
end

return gameActorStatePlayerDash