local actorSequenceFrameAnim = class("actorSequenceFrameAnim", function ()
    return LuaSprite:create()
end)

local action_tag = 1
local default_bound_box = cc.rect( 0, 0, 48, 64 )
local player_bound_box = cc.rect( 0, -16, 48, 80 )
local monster_bound_box = cc.rect( 0, -16, 60, 100 )
local npc_bound_box = cc.rect( 0, -16, 60, 100 )
local seqInitTable = {}
local MMO = global.MMO
local moveAnimTable = {
    [MMO.ANIM_WALK] = 1,
    [MMO.ANIM_RUN] = 1,
    [MMO.ANIM_RIDE_WALK] = 1,
    [MMO.ANIM_RIDE_RUN] = 1,
    [MMO.ANIM_ASSASSIN_SNEAK] = 1,
    [MMO.ANIM_ASSASSIN_RUN] = 1,

}
function actorSequenceFrameAnim:ctor()
    self._animAct         = -1
    self._animDir         = -1
    self._animSpeed       = 1
    self._animIsLoop      = false
    self._isSequence      = true
    self._endAnimListener = nil
    self._isPlaying       = false
    self._stopFrameIndex  = nil


    self._animDataDesc   = nil
    self._animation      = nil
    self._animateAction  = nil
    self._sequenceAction = nil
    self._repeatAction   = nil
    self._callfunc       = nil
    self._syncElapsed    = nil
    self._onChangeFrame  = nil

    self._globalElapseEnable = nil

    self._turePosition   = cc.p(0, 0)

    self:RegisterLuaHandler(handler( self, self.onDestory))
end

function actorSequenceFrameAnim:setPosition(px, py)
    if nil == py then
        self._turePosition.x = px.x
        self._turePosition.y = px.y
    else
        self._turePosition.x = px
        self._turePosition.y = py
    end

    local offsetX = self:GetOffsetX()
    local offsetY = self:GetOffsetY()
    getmetatable(getmetatable(getmetatable(self))).setPosition(self, self._turePosition.x + offsetX, self._turePosition.y + offsetY)
end

function actorSequenceFrameAnim:setPositionX(px)
    self._turePosition.x = px

    local offsetX = self:GetOffsetX()
    getmetatable(getmetatable(getmetatable(self))).setPositionX(self, px + offsetX)
end

function actorSequenceFrameAnim:setPositionY(py)
    self._turePosition.y = py
    
    local offsetY = self:GetOffsetY()
    getmetatable(getmetatable(getmetatable(self))).setPositionY(self, py + offsetY)
end

function actorSequenceFrameAnim:getTurePosition()
    return self._turePosition
end

function actorSequenceFrameAnim:setScaleX(sx)
    local enlarge = self:GetEnlarge()
    getmetatable(getmetatable(getmetatable(self))).setScaleX(self, enlarge * sx)
end

function actorSequenceFrameAnim:setScaleY(sy)
    local enlarge = self:GetEnlarge()
    getmetatable(getmetatable(getmetatable(self))).setScaleY(self, enlarge * sy)
end

function actorSequenceFrameAnim:onDestory()
    self:Stop()

    self:Cleanup()

    global.FrameAnimManager:RemoveSequAnim( self )
end

function actorSequenceFrameAnim:Cleanup()
    if self._animation then
        self._animation:release()
        self._animation = nil
    end

    if self._animateAction then
        self._animateAction:release()
        self._animateAction = nil
    end

    if self._callfunc then
        self._callfunc:release()
        self._callfunc = nil
    end

    if self._delayAction then 
        self._delayAction:release()
        self._delayAction = nil
    end

    if self._sequenceAction then
        self._sequenceAction:release()
        self._sequenceAction = nil
    end

    if self._repeatAction then
        self._repeatAction:release()
        self._repeatAction = nil
    end

    self:CleanupLuaHandler()
end

-----------------------------------------------------------------------------
function actorSequenceFrameAnim:GetID()
    if self._animDataDesc then
        return self._animDataDesc.animID
    end

    return 0
end

-----------------------------------------------------------------------------
function actorSequenceFrameAnim:GetAnimDataDesc()
    return self._animDataDesc
end

function actorSequenceFrameAnim:SetAnimDataDesc(animDataDesc)
    self._animDataDesc = animDataDesc
end

-----------------------------------------------------------------------------
function actorSequenceFrameAnim:Play( act, dir, isLoop, speed, isSequence, isSkipFrame, waitMoveFrame)
    act   = (not act or act < global.MMO.ANIM_DEFAULT or global.MMO.ANIM_COUNT <= act) and global.MMO.ANIM_DEFAULT or act
    dir   = (dir == nil or dir < global.MMO.ORIENT_U or global.MMO.ORIENT_COUNT <= dir) and global.MMO.ORIENT_U or dir
    speed = nil == speed and 1 or speed
    isSequence = isSequence ~= false

    if self._isPlaying and self._animSpeed == speed and self._animAct == act and self._animDir == dir then
        return false
    end
    
    -- stop
    self:Stop()

    -- Mark something.
    self._isPlaying     = true
    self._animAct       = act
    self._animDir       = dir
    self._animIsLoop    = isLoop
    self._animSpeed     = speed
    self._isSequence    = isSequence

    -- check and load res
    self:CheckAndLoadRes( act, dir )


    local index         = GetFrameAnimIndex( act, dir )
    local animFrameVec  = self._animDataDesc.animFrameVecs[index]
    local frameInterval = self._animDataDesc.animDelays[index] or global.MMO.ANIM_DEFAULT_INTERVAL

    -- use empty anim frame
    if not animFrameVec then
        animFrameVec = global.FrameAnimManager:getAnimFrameVecEmpty()
    end

    if not isSequence then
        local newAnimFrameVec = {}
        for i=1,#animFrameVec do
            newAnimFrameVec[i] = animFrameVec[#animFrameVec-i+1]
        end
        animFrameVec = newAnimFrameVec
    end

    --非平滑模式加速跳帧
    if isSkipFrame then 
        local newAnimFrameVec = {}
        local skip = true
        local index = 1
        for i = 1, #animFrameVec do 
            if skip then 
                skip = false 
            else
                skip = true
                newAnimFrameVec[index] = animFrameVec[i]
                index = index + 1
            end
        end
        animFrameVec = newAnimFrameVec
    end
    
    -- check cc.Animation
    if not self._animation then
        self._animation = cc.Animation:create( animFrameVec, frameInterval / speed, 1 )
        self._animation:retain()
    else
        self._animation:initWithAnimationFrames( animFrameVec, frameInterval / speed, 1 )
    end


    -- check cc.Animate
    if not self._animateAction then
        self._animateAction = cc.Animate:create( self._animation )
        self._animateAction:retain()
    else
        self._animateAction:initWithAnimation( self._animation )
    end

    -- 
    -- if self._onChangeFrame then
        -- self._animateAction:setPlayFrameListener(handler(self, self.onChangeFrame))
    -- end

    -- check cc.CallFunc
    if not self._callfunc then
        self._callfunc = cc.CallFunc:create( handler( self, self.onAnimationEnd ) )
        self._callfunc:retain()
    end

    local notSmoothMove = false
    if G_ActorUtils.IsMoveAnim(self._animAct) and not G_ActorUtils.IsSmoothMove() then
        notSmoothMove = true
        local updateMoveTime = 0
        if waitMoveFrame then
            updateMoveTime = frameInterval / speed + global.actorManager:GetNextMoveTimeDelay()
        else
            updateMoveTime = global.actorManager:GetNextMoveTimeDelay() 
        end
        if not self._delayAction then
            self._delayAction = cc.DelayTime:create(updateMoveTime)
            self._delayAction:retain()
        else 
            self._delayAction:initWithDuration(updateMoveTime)
        end
        -- check sequence action
        if not self._sequenceAction then
            self._sequenceAction = cc.Sequence:create(self._delayAction, self._animateAction, self._callfunc)
            self._sequenceAction:retain()
        else
            seqInitTable[1] = self._delayAction
            seqInitTable[2] = self._animateAction
            seqInitTable[3] = self._callfunc
            self._sequenceAction:init(seqInitTable)
        end
    else 
        -- check sequence action
        if not self._sequenceAction then
            self._sequenceAction = cc.Sequence:create(self._animateAction, self._callfunc)
            self._sequenceAction:retain()
        else
            self._sequenceAction:initWithTwoActions(self._animateAction, self._callfunc)
        end
    end

    local action = nil
    if isLoop then
        -- check repeat action
        if not self._repeatAction then
            self._repeatAction = cc.RepeatForever:create( self._sequenceAction )
            self._repeatAction:retain()
        else
            self._repeatAction:initWithAction( self._sequenceAction )
        end

        action = self._repeatAction
    else
        -- non-loop
        action = self._sequenceAction
    end

    action:setTag( action_tag )

    -- Play it!
    self:runAction( action )
    
    -- sync elapsed
    if self._syncElapsed and self._syncElapsed > 0 then
        self._sequenceAction:setElapsed( self._syncElapsed )
        self._syncElapsed = nil
    else
        if notSmoothMove then 
            self._sequenceAction:setElapsed(0)
        end
    end

    -- sync global elapsed
    if self._globalElapseEnable then
        self._sequenceAction:setElapsed( global.FrameAnimManager:getGlobalElapsed() )
    end

    return true
end

function actorSequenceFrameAnim:Replay()
    self:Stop()
    self:Play( self._animAct, self._animDir, self._animIsLoop, self._animSpeed, self._isSequence )
end

function actorSequenceFrameAnim:Stop( frameIndex, act, dir, isForceLastFrame )
    if isForceLastFrame then
        local frameCount = self:GetAnimActFrameCount(act or self._animAct, dir or self._animDir)
        frameIndex = frameCount > 0 and frameCount or frameIndex
    end

    self:SetStopFrameIndex( frameIndex, act, dir )

    if not self._isPlaying then
        return
    end
    
    self:stopAllActionsByTag( action_tag )
    self._isPlaying = false

    if self._sequenceAction then
        self._sequenceAction:setElapsed(0)
    end
end

function actorSequenceFrameAnim:SetStopFrameIndex( frameIndex, act, dir )
    self._stopFrameIndex = frameIndex
    if not self._stopFrameIndex then
        return
    end

    local checkRes = false
    if act and act ~= self._animAct then
        self._animAct = act
        checkRes = true
    end
    if dir and dir ~= self._animDir then
        self._animDir = dir
        checkRes = true
    end

    -- check and load res
    if checkRes then
        self:CheckAndLoadRes( self._animAct, self._animDir )
    end


    local animIndex    = GetFrameAnimIndex( self._animAct, self._animDir )
    local animFrameVec = self._animDataDesc.animFrameVecs[animIndex]
    if not animFrameVec then
        return nil
    end

    -- end frame
    if frameIndex == -1 then
        frameIndex = #animFrameVec
    end
    local animFrame = animFrameVec[frameIndex]
    if animFrame then
        self:setSpriteFrame( animFrame:getSpriteFrame() )
    end
end

function actorSequenceFrameAnim:SetSpeed( speed )
    speed = nil == speed and 1 or speed
    if speed ~= self._animSpeed then
        self:Play( self._animAct, self._animDir, self._animIsLoop, self._animSpeed, self._isSequence )
    end
end

function actorSequenceFrameAnim:GetSpeed()
    return self._animSpeed
end

function actorSequenceFrameAnim:SetAnimEventCallback( listener )
    self._endAnimListener = listener
end

function actorSequenceFrameAnim:GetHUDTop()
    if not self._animDataDesc then
        return 20
    end
    
    return self._animDataDesc.hudTop or 20
end

function actorSequenceFrameAnim:GetOffsetX()
    if not self._animDataDesc then
        return 0
    end
    
    return self._animDataDesc.offsetX or 0
end

function actorSequenceFrameAnim:GetOffsetY()
    if not self._animDataDesc then
        return 0
    end
    
    return self._animDataDesc.offsetY or 0
end

function actorSequenceFrameAnim:GetEnlarge()
    if not self._animDataDesc then
        return 1
    end

    return self._animDataDesc.enlarge or 1
end

function actorSequenceFrameAnim:GetStandPointX()
    if not self._animDataDesc then
        return 0.5
    end

    return self._animDataDesc.standPointX
end

function actorSequenceFrameAnim:GetStandPointY()
    if not self._animDataDesc then
        return 0.5
    end

    return self._animDataDesc.standPointY
end

function actorSequenceFrameAnim:GetBlendMode()
    if not self._animDataDesc then
        return 0
    end

    return self._animDataDesc.blendMode or 0
end

function actorSequenceFrameAnim:GetHasShadow()
    if not self._animDataDesc then
        return true
    end

    return self._animDataDesc.hasShadow
end

local boundingBox = cc.rect(0,0,0,0)
function actorSequenceFrameAnim:GetBoundingBox()
    if not self._animDataDesc then
        return default_bound_box
    end

    local animType = self._animDataDesc.animType
    if global.MMO.SFANIM_TYPE_MONSTER == animType then
        local enlarge     = self:GetEnlarge()
        local isShadow    = self:GetHasShadow()
        local widthRatio  = isShadow and 0.6 or 1
        local rect        = self:GetFrameBox()
        rect.x = monster_bound_box.x--ret.x - ret.width * anchorPoint.x + global.MMO.PLAYER_AVATAR_OFFSET.x
        rect.y = monster_bound_box.y--ret.y - ret.height * anchorPoint.y + global.MMO.PLAYER_AVATAR_OFFSET.y
        rect.width = rect.width * widthRatio * enlarge
        rect.height = rect.height * enlarge
        rect.x = rect.x - rect.width * 0.5

        return rect
    end


    local box = default_bound_box
    if global.MMO.SFANIM_TYPE_PLAYER == animType then
        box = player_bound_box
    elseif global.MMO.SFANIM_TYPE_NPC == animType then
        box = npc_bound_box
    else
        if self._animDataDesc.boxWidth and self._animDataDesc.boxHeight then
            local boxWidth = self._animDataDesc.boxWidth
            local boxHeight = self._animDataDesc.boxHeight
            boundingBox.x = -boxWidth * 0.5
            boundingBox.y = npc_bound_box.y
            boundingBox.width = boxWidth
            boundingBox.height = boxHeight
            return boundingBox
        end
    end

    local height = box.height
    local hudTop = self:GetHUDTop()
    if hudTop and hudTop > height then
        height = hudTop
    end

    boundingBox.x = box.x
    boundingBox.y = box.y
    boundingBox.width = box.width
    boundingBox.height = height
    boundingBox.x = boundingBox.x - boundingBox.width * 0.5
    return boundingBox
end

function actorSequenceFrameAnim:GetFrameBox()
    local spriteFrame = self:getSpriteFrame()
    if not spriteFrame then
        local animIndex = GetFrameAnimIndex( global.MMO.ANIM_IDLE, global.MMO.ORIENT_U )
        local animFrameVec = self._animDataDesc.animFrameVecs[animIndex]
        if animFrameVec and animFrameVec[1] then
            spriteFrame = animFrameVec[1]:getSpriteFrame()
        end
    end 

    if not spriteFrame then
        return default_bound_box
    end

    local bbox   = spriteFrame:getRectInPixels()
    local offset = spriteFrame:getOffset()
    bbox.x = offset.x
    bbox.y = offset.y
    return bbox
end

function actorSequenceFrameAnim:Sync( anim )
    if nil == anim then return end
    if nil == self._animDataDesc then return end

    self._endAnimListener = anim._endAnimListener
    if anim._sequenceAction and not self._animDataDesc.ignoreSync then
        self._syncElapsed = anim._sequenceAction:getElapsed()
    else
        self._syncElapsed = nil
    end

    self._animAct = anim._animAct
    self._animDir = anim._animDir

    -- sync stop frame
    if anim._stopFrameIndex then
        self:SetStopFrameIndex( anim._stopFrameIndex, anim._animAct, anim._animDir )
    end

    -- sync color
    self:setColor( anim:getColor() )

    -- sync shader
    self:setGLProgram( anim:getGLProgram() )
end

function actorSequenceFrameAnim:GetElapsed()
    if self._sequenceAction then
        return self._sequenceAction:getElapsed()
    end
    return nil
end

function actorSequenceFrameAnim:SyncElapsed( elapsed )
    self._syncElapsed = elapsed
end

function actorSequenceFrameAnim:resetAnimPlay( unitID )
    if not self._isPlaying then
        if self._stopFrameIndex then
            self:SetStopFrameIndex( self._stopFrameIndex )
        else
            self:SetStopFrameIndex( -1 )
        end
        return 
    end

    local checkUnitID = self._animAct
    if global.MMO.SFANIM_TYPE_SKILL == self._animDataDesc.animType then
        checkUnitID = self._animDir
    end

    -- load act res callback, but act ~= currentAct
    if unitID and unitID ~= checkUnitID then return end

    self:Sync( self )
    self:Stop()
    self:Play( self._animAct, self._animDir, self._animIsLoop, self._animSpeed, self._isSequence )
end


function actorSequenceFrameAnim:onAnimationEnd()
    if not self._animIsLoop then
        self._isPlaying = false
    end
    if nil ~= self._endAnimListener then
        local isLoaded = self:CheckResIsLoaded(self._animAct, self._animDir)
        local loadCode = isLoaded and 1 or 0
        self._endAnimListener( self, 1, loadCode )
    end
end

function actorSequenceFrameAnim:onAnimationLoadError()
    if nil ~= self._endAnimListener then
        local loadCode = -1
        self._endAnimListener( self, 1, loadCode )
    end
end

function actorSequenceFrameAnim:CheckResIsLoaded( act, dir )
    if not self._animDataDesc then
        return false
    end


    local animID        = self._animDataDesc.animID
    local animType      = self._animDataDesc.animType
    local frameLoaded   = self._animDataDesc.frameLoaded
    local unitID        = act
    if global.MMO.SFANIM_TYPE_SKILL == animType then
        unitID = dir
    end

    return frameLoaded[unitID] == true
end

function actorSequenceFrameAnim:CheckAndLoadRes( act, dir )
    if not self._animDataDesc then
        return false
    end

    local animID        = self._animDataDesc.animID
    local animType      = self._animDataDesc.animType
    local frameLoaded   = self._animDataDesc.frameLoaded
    local unitID        = act
    if global.MMO.SFANIM_TYPE_SKILL == animType then
        unitID = dir
    end

    if true ~= frameLoaded[unitID] then
        global.FrameAnimManager:LoadAnimUnit( animID, animType, unitID )
    end

    return true
end

-- unitID(act or dir)
function actorSequenceFrameAnim:CheckCurrUnit( unitID )
    if not self._animDataDesc then
        return false
    end


    local animType = self._animDataDesc.animType
    if global.MMO.SFANIM_TYPE_SKILL == animType then
        return unitID == self._animDir
    else
        return unitID == self._animAct
    end
end

function actorSequenceFrameAnim:SetGlobalElapseEnable(enable)
    self._globalElapseEnable = enable
end

function actorSequenceFrameAnim:GetCurrAnimAct()
    return self._animAct
end

function actorSequenceFrameAnim:GetCurrAnimDir()
    return self._animDir
end

function actorSequenceFrameAnim:CheckAnimActIsLoaded()
    if not self._animDataDesc then
        return false
    end

    local animType      = self._animDataDesc.animType
    local frameLoaded   = self._animDataDesc.frameLoaded
    local unitID        = self._animAct
    if global.MMO.SFANIM_TYPE_SKILL == animType then
        unitID = self._animDir
    end
    
    return frameLoaded[unitID]
end

function actorSequenceFrameAnim:GetAnimActFrameCount(act, dir)
    if not self._animDataDesc then
        return 0
    end

    local index         = GetFrameAnimIndex( act, dir )
    local animFrameVec  = self._animDataDesc.animFrameVecs[index]

    -- use empty anim frame
    if not animFrameVec then
        return 0
    end

    return #animFrameVec
end

function actorSequenceFrameAnim:SetChangeFrameCallback(callback)
    self._onChangeFrame = callback
end

function actorSequenceFrameAnim:onChangeFrame(sender, currFrame, maxFrame)
    if self._onChangeFrame then
        self._onChangeFrame(currFrame, maxFrame)
    end
end

return actorSequenceFrameAnim

