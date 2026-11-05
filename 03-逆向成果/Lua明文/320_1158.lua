local gameActorMonster = require("actor/gameActorMonster")
local gameActorMonsterWall = class('gameActorMonsterWall', gameActorMonster)

local optionsUtils = requireUtil("optionsUtils")

function gameActorMonsterWall:ctor()
    gameActorMonsterWall.super.ctor(self)

    self.mOpenState = false
end

function gameActorMonsterWall:init()
    gameActorMonsterWall.super.init(self)

    self:SetAdditionZorder(45)
    self.mOpenState = false
end

function gameActorMonsterWall:UpdateAnimation()
    self.mAnimAct = global.MMO.ANIM_IDLE
    local animDir = self:getFixAnimDir() or self.mOrient

    -- 
    local isLoop = false
    local speed = 1

    if self.mAnimation then
        self.mAnimation:Play(self.mAnimAct, animDir, isLoop, speed)
    end

    if self.mAttachAnim then
        self.mAttachAnim:Play(self.mAnimAct, animDir, isLoop, speed)
    end

    if self.mStopAnimFrameIndex then
        self:StopAllAnimation(self.mStopAnimFrameIndex)
    end

    self.mOpenState = self:GetHP() <= 0
    global.sceneManager:MarkCanWalk(self:GetMapX(), self:GetMapY(), self.mOpenState)
end

return gameActorMonsterWall