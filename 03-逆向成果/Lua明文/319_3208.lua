local gameActorMonster = require("actor/gameActorMonster")
local gameActorMonsterGate = class('gameActorMonsterGate', gameActorMonster)


local optionsUtils = requireUtil("optionsUtils")

function gameActorMonsterGate:ctor()
    self.mOpenState = false
    gameActorMonsterGate.super.ctor(self)
end

function gameActorMonsterGate:init()
    gameActorMonsterGate.super.init(self)

    self.mOpenState = false
end

function gameActorMonsterGate:SetAnimAct(newAnim)
    if self.mAnimAct ~= newAnim then
        self.mAnimAct = newAnim

        -- in die anim, zOrder is lowest
        if newAnim == global.MMO.ANIM_DIE then
            self:GetNode():setLocalZOrder(-self:GetNode():getPositionY() + self:GetAdditionZorder() + global.MMO.DieAddZorder)
        end

        self:DirtyAnimFlag()
    end
end

function gameActorMonsterGate:ConvertAnimAct(anim)
    if anim == global.MMO.ANIM_IDLE then
        if self:GetGateOpenState() then
            return global.MMO.ANIM_BORN
        end
        return global.MMO.ANIM_STUCK
    end
    return anim
end

--动画的方向
function gameActorMonsterGate:GetAnimDir()
    if self.mAction == global.MMO.ACTION_BORN then
        if self:GetGateOpenState() then
            return 0
        else
            return 1
        end

    elseif self.mAction == global.MMO.ACTION_DIE then
        return 0

    elseif self.mAction == global.MMO.ACTION_IDLE and self:GetGateOpenState() then
        return 0
    end

    local percent = self:GetHP() / self:GetMaxHP()
    if percent >= 0.5 then
        return 0
    else
        return 1
    end
    return 0
end

--城门打开状态
function gameActorMonsterGate:SetGateOpenState(state)
    self.mOpenState = state
    global.sceneManager:changeGateState(self:GetMapX(), self:GetMapY(), false)
end

function gameActorMonsterGate:GetGateOpenState()
    return self.mOpenState
end

function gameActorMonsterGate:StopAllAnimation(frameIndex)
    local animAct = self:ConvertAnimAct(self.mAnimAct)
    local animDir = self:GetAnimDir()
    if self.mAnimation then
        self.mAnimation:Stop(frameIndex, animAct, animDir)
    end

    if self.mAttachAnim then
        self.mAttachAnim:Stop(frameIndex, animAct, animDir)
    end
end

function gameActorMonsterGate:UpdateAnimation()
    -- speed
    local isLoop  = false
    local speed   = 1
    local animAct = self:ConvertAnimAct(self.mAnimAct)
    local animDir = self:GetAnimDir()

    if self.mAnimation then
        self.mAnimation:Play(animAct, animDir, isLoop, speed)
    end

    if self.mAttachAnim then
        self.mAttachAnim:Play(animAct, animDir, isLoop, speed)
    end

    if self.mStopAnimFrameIndex then
        self:StopAllAnimation(self.mStopAnimFrameIndex)
    elseif self.mAction == global.MMO.ACTION_IDLE then
        if self:GetGateOpenState() then
            self:StopAllAnimation(-1)
        else
            self:StopAllAnimation(1)
        end
    end

    if self.mAction == global.MMO.ACTION_DIE then
        global.sceneManager:changeGateState(self:GetMapX(), self:GetMapY(), true)
    end
end

return gameActorMonsterGate