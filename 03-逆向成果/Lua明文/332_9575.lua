local skillPresentBase = require("skill/skillPresentBase")
local skillPresentFly = class("skillPresentFly", skillPresentBase)

local effectOff = {
    [131] = { x = -25, y = 0 }
}
local offsetys = {[13] = 1, [14] = 1, [15] = 1, [19] = 1, [38] = 1, [44] = 1, [63] = 1 }--13灵魂火符 14幽灵盾 15神圣战甲术 19集体隐身术  38诅咒术 44寒冰掌 85裂神符 63噬魂沼泽需要向上偏移
local dir1t8 = {
    [9] = true
}
local zOnePointX = 0.0
local zOnePointY = 1.0
local shareT1 = {}
local shareT2 = {}


local mSqrt  = math.sqrt
local mAtan2 = math.atan2
local mAbs   = math.abs

function pGetLength(ptX, ptY)
    return mSqrt(ptX * ptX + ptY * ptY)
end

function pNormalize(ptX, ptY)
    local length = pGetLength(ptX, ptY)
    if 0 == length then
        return 1, 0
    end

    return  ptX / length, ptY / length
end

function pCross(selfX, selfY, otherX, otherY)
    return selfX * otherY - selfY * otherX
end

function pDot(selfX, selfY, otherX, otherY)
    return selfX * otherX + selfY * otherY
end

function pGetAngle(p1X, p1Y, p2X, p2Y)
    local ax,ay = pNormalize(p1X, p1Y)
    local bx,by = pNormalize(p2X, p2Y)
    local angle = mAtan2(pCross(ax, ay, bx, by), pDot(ax, ay, bx, by))
    if mAbs(angle) < 1.192092896e-7 then
        return 0.0
    end

    return angle
end

function skillPresentFly:ctor(data, config, root, target, delagate)
    skillPresentFly.super.ctor(self, data, config, root, target, delagate)
end

function skillPresentFly:GetType()
    return global.MMO.SKILL_PRESENT_FLY
end

function skillPresentFly:init()
    skillPresentFly.super.init(self)

    self._anim          = nil
    self._status        = -1
    self._tickAble      = false
    self._delayTime     = (self._config.flyDelayTime or 0) * 0.001 / self._speed

    self._flyDirX       = 0.0
    self._flyDirY       = 0.0
    self._flySpeed      = ((not self._config.flySpeed or self._config.flySpeed == 0) and 1500.0 or self._config.flySpeed) * self._speed

    self._curWorldPosX  = 0.0
    self._curWorldPosY  = 0.0

    self._destWorldPosX = 0.0
    self._destWorldPosY = 0.0

    self._animDir       = (self._config.flyDir == 8) and 8 or 0

    -- 是否不播放音效
    self._noPlayAudio = false
    if GUIFunction and GUIFunction.IsNoPlayAudioFromSkillPresent then
        local paramData = {
            data = self._data,
            presentType = 2
        }
        self._noPlayAudio = GUIFunction:IsNoPlayAudioFromSkillPresent(paramData)
    end
end

function skillPresentFly:launch()
    skillPresentFly.super.launch(self)

    if self._config.flyID and self._config.flyID ~= -1 then
        self._anim = global.FrameAnimManager:CreateSkillEffAnim(self._config.flyID)
        self._anim:setLocalZOrder(self._config.flyID)
        self._anim:setVisible(false)
        self._root:addChild(self._anim)
    end

    -- play sound
    if not self._noPlayAudio and self._config.flySound and self._config.flySound > 0 then
        local slt     = global.SLT.AudioPlayTable4
        slt.type      = global.MMO.SND_TYPE_SKILL_LUAUNCH
        slt.index     = self._config.flySound
        slt.delayTime = self._config.flySoundDelayTime or self._delayTime
        global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
    end

    if self._anim == nil then
        self._tickAble = false
        self:launchNext()
        self:disable()
        return
    end

    -- fix hit pos
    local hitX = self._target.destX
    local hitY = self._target.destY
    if self._target.id then
        local target = global.actorManager:GetActor(self._target.id)
        if target then
            hitX = target:GetMapX()
            hitY = target:GetMapY()
        end
    end

    local sWorldX, sWorldY  = global.sceneManager:MapPos2WorldPos(self._data.launchX, self._data.launchY, true)
    sWorldY                 = sWorldY + 40
    self._curWorldPosX      = sWorldX
    self._curWorldPosY      = sWorldY
    local dWorldX, dWorldY  = global.sceneManager:MapPos2WorldPos(hitX, hitY, true)
    dWorldY                 = dWorldY + 40
    self._destWorldPosX     = dWorldX
    self._destWorldPosY     = dWorldY
    
    if effectOff[self._config.flyID] then
        sWorldX = sWorldX + effectOff[self._config.flyID].x
        sWorldY = sWorldY + effectOff[self._config.flyID].y
    end
    self._anim:setPosition(sWorldX, sWorldY)
    self._anim:setVisible(false)

    -- launch...
    self._status = -1
    self._tickAble = true
end

function skillPresentFly:Tick(dt)
    if not self._tickAble then
        return
    end

    if self._status == -1 then
        self._delayTime = self._delayTime - dt
        if self._delayTime <= 0 then
            self._status = 0
        end

    elseif self._status == 0 then
        if self._anim then
            local launcher = global.actorManager:GetActor(self._data.launcherID)

            local direction = (self._animDir == 8 and launcher and (not dir1t8[self._config.flyID])) and launcher:GetDirection() or 0
            self._anim:Stop()
            self._anim:Play(0, direction, true, self._speed)
            self._anim:setVisible(true)

            -- calc dir
            self._flyDirX, self._flyDirY = pNormalize(self._destWorldPosX - self._curWorldPosX, self._destWorldPosY - self._curWorldPosY)
            local angle   = pGetAngle(self._flyDirX, self._flyDirY, zOnePointX, zOnePointY)
            local rotate  = (self._animDir == 0) and angle*57.29577951 or 0
            self._anim:setRotation(rotate)
            -----light 
            if not self._LightID and not (self._config.notLight and self._config.notLight == 1) then
                local DarkLayerProxy = global.Facade:retrieveProxy(global.ProxyTable.DarkLayerProxy)
                local lightData = DarkLayerProxy.LIGHT_TYPE.Two_Skill
                shareT1.x = self._curWorldPosX
                shareT1.y = self._curWorldPosY
                shareT1.r = lightData.r
                shareT1.w = lightData.w
                self._LightID = global.darkNodeManager:createNode(shareT1)
            end
        end
        self._status = 1
    elseif self._status == 1 then
        if self._anim then
            local distance = self._flySpeed * dt

            --
            self:calcTarget()

            if self:isHitTarget(distance) then
                if self._anim then
                    self._anim:removeFromParent()
                    self._anim = nil
                end

                self._tickAble = false
                self:launchNext()
                self:disable()
                if self._LightID then
                    global.darkNodeManager:removeNode(self._LightID)
                    self._LightID = nil
                end
            else
                local posNewX = self._curWorldPosX + self._flyDirX * distance
                local posNewY = self._curWorldPosY + self._flyDirY * distance

                local offy = 0
                if self._data and self._data.skillID and offsetys[self._data.skillID] then
                    offy = 28
                end
                self._anim:setPosition(posNewX, posNewY + offy)
                self._curWorldPosX = posNewX
                self._curWorldPosY = posNewY
                -----light 
                if self._LightID then
                    shareT2.x = posNewX
                    shareT2.y = posNewY
                    global.darkNodeManager:updateNode(self._LightID, shareT2)
                end
            end
        end
    end
end

function skillPresentFly:setNodeParent(root)
    if self._anim and root then
        root:addChild(self._anim)
    end
end

function skillPresentFly:calcTarget()
    if self._anim and self._config.needTarget == 1 then
        if self._target.id then
            local targetActor = global.actorManager:GetActor(self._target.id)
            if targetActor then
                self._destWorldPosX = targetActor.mPositionX
                self._destWorldPosY = targetActor.mPositionY
                self._destWorldPosY = self._destWorldPosY + 40
            else
                local dWorldX, dWorldY  = global.sceneManager:MapPos2WorldPos(self._target.destX, self._target.destY, true)
                self._destWorldPosX = dWorldX
                self._destWorldPosY = dWorldY + 40
            end
        else
            local normal            = G_ActorUtils.DirToNormalizeVec2(self._data.dir)
            local destX             = self._data.launchX + normal.x * 25
            local destY             = self._data.launchY + normal.y * 25
            local dWorldX, dWorldY  = global.sceneManager:MapPos2WorldPos(destX, destY, true)
            self._destWorldPosX     = dWorldX
            self._destWorldPosY     = dWorldY + 40
        end

        self._flyDirX, self._flyDirY = pNormalize(self._destWorldPosX - self._curWorldPosX, self._destWorldPosY - self._curWorldPosY)
        local angle   = pGetAngle(self._flyDirX, self._flyDirY, zOnePointX, zOnePointY)
        local rotate  = (self._animDir == 0) and angle * 57.29577951 or 0
        self._anim:setRotation(rotate)
    end
end

function skillPresentFly:isHitTarget(distance)
    local destDist = pGetLength(self._destWorldPosX - self._curWorldPosX, self._destWorldPosY - self._curWorldPosY)
    return destDist <= distance * 3
end

return skillPresentFly