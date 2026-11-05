local gameActorMoveable = require( "actor/gameActorMoveable")
local gameActorNpc      = class('gameActorNpc', gameActorMoveable)

local mmo = global.MMO
local mapActAnim = {
    [mmo.ACTION_IDLE] = mmo.ANIM_IDLE,
    [mmo.ACTION_BORN] = mmo.ANIM_BORN,
}

local fixAnimDirection = {
    [59]      = 0,
}

function gameActorNpc:ctor()
    gameActorNpc.super.ctor(self)
end

function gameActorNpc:init()
    gameActorNpc.super.init(self)

    self.mFeatureDirty       = false
    self.mUseMonsterAnim     = nil
    self.mAnimAct            = global.MMO.ANIM_IDLE
    self.mIsAnimNeedToUpdate = false
    self.mStopAnimFrameIndex = nil

    self._autoColorList      = {}
    self._openAutoColor      = false
    self._autoColorIdx       = 1
    self._onlyShowBubbleName = nil      -- 只显示气泡名
end

function gameActorNpc:destory()
    gameActorNpc.super.destory(self)

    -- remove hud
    global.HUDManager:RemoveActorAllHUD( self.mID )
end

function gameActorNpc:Tick(dt)
    if self.mFeatureDirty then
        self.mFeatureDirty = false
        self:CheckFeature()
    end

    if self.mIsAnimNeedToUpdate then
        self:UpdateAnimation()
        self.mIsAnimNeedToUpdate = false
    end

    if self._openAutoColor then
        self:OpenAutoColorTimer()
    else
        self:ClearAutoColorTimer()
    end
end

function gameActorNpc:setPosition(x, y)
    gameActorNpc.super.setPosition(self, x, y)

    -- refresh zOrder
    self:GetNode():setLocalZOrder( math.floor(-y) )

    -- update hud pos
    local hudTop = self:GetHUDTop()
    global.HUDManager:setPosition( self.mID, x, y + hudTop )

    -- update buff pos
    global.BuffManager:setPosition(self:GetID(), x, y)
    global.ActorEffectManager:setPosition(self:GetID(), x, y)
end

function gameActorNpc:SetAction(newAction, isTerminate)
    local actAnim = mapActAnim[newAction] or global.MMO.ANIM_IDLE
    self:SetAnimAct( actAnim )
    self:DirtyAnimFlag()
end

function gameActorNpc:SetAnimAct(newAnim)
    if self.mAnimAct ~= newAnim then
        self.mAnimAct = newAnim

        -- in die anim, zOrder is lowest
        if newAnim == global.MMO.ANIM_DIE then
            self:GetNode():setLocalZOrder( -self:GetNode():getPositionY() + self:GetAdditionZorder() + global.MMO.DieAddZorder )
        end

        self:DirtyAnimFlag()
    end
end

function gameActorNpc:SetDirection( dir )
    gameActorNpc.super.SetDirection(self, dir)
end

function gameActorNpc:OnSequAnimLoadCompleted(npcID, animID, seqAnim)
    -- There is a strange bug that *this* pointer will be invalid in sometime.
    local _this = global.actorManager:GetActor( npcID ) 
    if nil == _this then
        return 
    end

    -- Refresh npc name label hud top
    local posX = _this:getPositionX()
    local posY = _this:getPositionY()
    local hudTop = _this:GetHUDTop()
    global.HUDManager:setPosition( _this.mID, posX, posY + hudTop)
end

function gameActorNpc:InitParam( param )
    self.mCurrActorNode = cc.Node:create()

    self.mCurrMountNode = cc.Node:create()
    self.mCurrActorNode:addChild(self.mCurrMountNode)
    self.mCurrMountNode:setTag(mmo.NPC_MOUNT_TAG)
    self.mCurrMountNode:setPosition(mmo.PLAYER_AVATAR_OFFSET)

    return 1
end

function gameActorNpc:SetAppearByID(i, v)
    if i == global.MMO.P_F_CLOTH then 
        self:SetClothID(v)
    else
        self.mArrAppear[i] = v
    end
end

function gameActorNpc:SetClothID(clothID)
    self.mUseMonsterAnim = false

    if clothID and clothID > global.MMO.NPC_MONSTER_ID_PART then
        clothID = clothID % global.MMO.NPC_MONSTER_ID_PART
        self.mUseMonsterAnim = true
    end
    self.mArrAppear[global.MMO.P_F_CLOTH] = clothID
end

function gameActorNpc:DirtyFeature()
    self.mFeatureDirty = true
end

function gameActorNpc:CheckFeature()
    self:UpdateCloth()
end

function gameActorNpc:UpdateCloth()
    local function loadCompleted(animID, seqAnim)
        self:OnSequAnimLoadCompleted(self:GetID(), animID, seqAnim)
    end
    local clothID = self:GetAppearByID(global.MMO.P_F_CLOTH)
    local anim = nil
    if not self.mUseMonsterAnim then
        anim = global.FrameAnimManager:CreateActorNpcAnim( clothID, loadCompleted )
    else
        anim = global.FrameAnimManager:CreateActorMonsterAnim( clothID, self.mAnimAct, loadCompleted )
    end

    if self.mAnimation then
        self.mAnimation:removeFromParent()
        self.mAnimation = nil
    end

    self.mAnimation = anim
    self.mAnimation:setPosition( global.MMO.PLAYER_AVATAR_OFFSET )
    self.mCurrActorNode:addChild( anim )

    -- Refresh npc name label hud top
    local posX = self:getPositionX()
    local posY = self:getPositionY()
    global.HUDManager:setPosition(self:GetID(), posX, posY + self:GetHUDTop())

    self:DirtyAnimFlag()
end

function gameActorNpc:UpdateAnimation()
    local animDir = self:getFixAnimDir() or self.mOrient

    if self.mAnimation then
        self.mAnimation:Play( self.mAnimAct, animDir, true )
    end

    if self.mStopAnimFrameIndex then
        self:StopAllAnimation( self.mStopAnimFrameIndex )
    end
end

function gameActorNpc:getFixAnimDir()
    local clothID = self:GetAppearByID(global.MMO.P_F_CLOTH)
    if fixAnimDirection[clothID] then
        if type(fixAnimDirection[clothID]) == "table" then
            return fixAnimDirection[clothID][self.mAnimAct]
        else
            return fixAnimDirection[clothID]
        end
    end
    return nil
end

function gameActorNpc:DirtyAnimFlag()
    if self.mStopAnimFrameIndex then
        return
    end

    self.mIsAnimNeedToUpdate = true
end

function gameActorNpc:StopAnimToFrame( frameIndex )
    self.mStopAnimFrameIndex = frameIndex
end

function gameActorNpc:StopAllAnimation( frameIndex )
    local animDir = self:getFixAnimDir() or self.mOrient
    if self.mAnimation then
        self.mAnimation:Stop( frameIndex, self.mAnimAct, animDir )
    end
end

function gameActorNpc:GetType()
    return global.MMO.ACTOR_NPC
end

function gameActorNpc:GetAnimationID()
    return self:GetAppearByID(global.MMO.P_F_CLOTH)
end

function gameActorNpc:GetHUDTop()
    if not self.mAnimation then
        return 20
    end
    return self.mAnimation:GetHUDTop() or 20
end

function gameActorNpc:SetAutoNameColor(autoColor)
    if autoColor and next(autoColor) then
        self._autoColorList = autoColor
        self._openAutoColor = true
    end
end

function gameActorNpc:OpenAutoColorTimer()
    if self._autoColorTimerID then
        return
    end

    self._autoColorTimerID = Schedule(function()
        self._autoColorIdx = self._autoColorIdx + 1
        if self._autoColorIdx > #self._autoColorList then
            self._autoColorIdx = 1
        end
        self:SetNameColor(self._autoColorList[self._autoColorIdx])
        global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabelColor, self:GetID())
    end, 1.5)
end

function gameActorNpc:ClearAutoColorTimer()
    if self._autoColorTimerID then
        UnSchedule(self._autoColorTimerID)
        self._autoColorTimerID = nil
        self._autoColorIdx = 1
    end
end

function gameActorNpc:SetOnlyShowBubbleName(name)
    self._onlyShowBubbleName = name
end

function gameActorNpc:GetOnlyShowBubbleName()
    return self._onlyShowBubbleName
end

return gameActorNpc
