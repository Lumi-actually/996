local skillPresentBase = require("skill/skillPresentBase")
local skillPresentHit = class("skillPresentHit", skillPresentBase)

local shareT1 = {}
local shareT2 = {}
function skillPresentHit:ctor(data, config, root, target, delagate)
    skillPresentHit.super.ctor(self, data, config, root, target, delagate)
end

function skillPresentHit:GetType()
    return global.MMO.SKILL_PRESENT_HIT
end

function skillPresentHit:init()
    skillPresentHit.super.init(self)

    self._anim      = nil
    self._status    = -1
    self._tickAble  = false
    self._delayTime = (self._config.hitDelayTime or 0) * 0.001 / self._speed
    self._animFollow= (self._config.skillgensui or 1) == 1

    self._noPlayAudio = false
    if GUIFunction and GUIFunction.IsNoPlayAudioFromSkillPresent then
        local paramData = {
            data = self._data,
            presentType = 2
        }
        self._noPlayAudio = GUIFunction:IsNoPlayAudioFromSkillPresent(paramData)
    end
end

function skillPresentHit:launch()
    skillPresentHit.super.launch(self)

    if self._config.hitID and self._config.hitID ~= -1 then
        local dir = (self._config.hitDir == 8 and self._data.dir or 0)
        local immediate = (self._config.hitID == 198)
        self._anim = global.FrameAnimManager:CreateSkillEffAnim(self._config.hitID, dir, nil, immediate)
        self._anim:setLocalZOrder(self._config.hitID)
        self._anim:setVisible(false)
        self._root:addChild(self._anim)
    end

    -- sound
    if not self._noPlayAudio and self._config.hitSound and self._config.hitSound > 0 then
        local slt     = global.SLT.AudioPlayTable4
        slt.type      = global.MMO.SND_TYPE_SKILL_LUAUNCH
        slt.index     = self._config.hitSound
        slt.delayTime = self._config.hitSoundDelayTime or self._delayTime
        global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
    end

    if not self._anim then
        self._tickAble = false
        self:launchNext()
        self:disable()
        return
    end

    local dWorldX, dWorldY = global.sceneManager:MapPos2WorldPos(self._target.destX, self._target.destY, true)
    if self._target.id and (self._data.skillID ~= 58 and self._data.skillID ~= 581) then
        local target    = global.actorManager:GetActor(self._target.id)
        if target then
            dWorldX     = target.mPositionX
            dWorldY     = target.mPositionY
        end
    end
    self._anim:setPosition(dWorldX+global.MMO.PLAYER_AVATAR_OFFSET.x, dWorldY+global.MMO.PLAYER_AVATAR_OFFSET.y)
    self._anim:setVisible(false)
    self._anim:SetAnimEventCallback(
        function(_, eventType)
            if self._anim then
                self._anim:removeFromParent()
                self._anim = nil
            end
            if self._LightID then
                global.darkNodeManager:removeNode(self._LightID)
            end
            self._LightID = nil
            self._tickAble = false
            self:launchNext()
            self:disable()
        end
    )

    -- launch...
    self._status = -1
    self._tickAble = true
end

local ShareMapPos = {{}, {}, {}, {}}
function skillPresentHit:Tick(dt)
    if not self._tickAble then
        return
    end

    if self._status == -1 then
        self._delayTime = self._delayTime - dt
        if self._delayTime <= 0 then
            self._status = 0
        end

    elseif self._status == 0 then
        self._status = 1

        -- refresh hit pos
        if self._anim then
            local dir = (self._config.hitDir == 8 and self._data.dir or 0)
            self._anim:Play(0, dir, true, self._speed)
            self._anim:setVisible(true)

            if not self._LightID and not (self._config.notLight and self._config.notLight == 1) then
                local dWorldX, dWorldY = global.sceneManager:MapPos2WorldPos(self._target.destX, self._target.destY, true)
                local DarkLayerProxy   = global.Facade:retrieveProxy(global.ProxyTable.DarkLayerProxy)
                local lightData        = DarkLayerProxy.LIGHT_TYPE.Two_Skill
                shareT2.x = dWorldX
                shareT2.y = dWorldY
                shareT2.r = lightData.r
                shareT2.w = lightData.w
                self._LightID = global.darkNodeManager:createNode(shareT2)
            end

            -- 特殊处理流行火雨
            if self._data.skillID == 58 or self._data.skillID == 581 then
            elseif self._data.skillID == 840 then --冰霜群雨
                local range = 3
                
                ShareMapPos[1].x = -1 * range
                ShareMapPos[1].y = -1 * range

                ShareMapPos[2].x = -1 * range
                ShareMapPos[2].y = range

                ShareMapPos[3].x = range
                ShareMapPos[3].y = -1 * range

                ShareMapPos[4].x = range
                ShareMapPos[4].y = range
                self:ShowRandomAnim(self._config.hitID, ShareMapPos, dir)
            else
                self:refreshHitPosition()
            end
        end
    elseif self._status == 1 then
        -- refresh hit pos
        if self._animFollow then
            self:refreshHitPosition()
        end
    end
end

function skillPresentHit:setNodeParent(root)
    if root and self._anim then
        root:addChild(self._anim)
    end
end

function skillPresentHit:refreshHitPosition()
    if not self._anim then
        return false
    end
    if not self._target.id then
        return
    end
    local target = global.actorManager:GetActor(self._target.id)
    if not target then
        return
    end

    local destPosX = target:getPositionX()
    local destPosY = target:getPositionY()
    local x = destPosX + global.MMO.PLAYER_AVATAR_OFFSET.x
    local y = destPosY + global.MMO.PLAYER_AVATAR_OFFSET.y
    self._anim:setPosition(x, y)

    if self._LightID then
        shareT1.x = destPosX
        shareT1.y = destPosY
        global.darkNodeManager:updateNode(self._LightID, shareT1)
    end
end

-- 显示随机特效   sfxID: 特效id   showMapPos: 显示特效的地图位置   dir: 方向
local randomCount = {}  --随机特效显示的数量， 超过30个的就不显示了
function skillPresentHit:ShowRandomAnim(sfxID, showMapPos, dir)
    local sfxMaxNum = 30
    sfxID = sfxID or 204 -- 默认冰霜群雨特效
    if not randomCount[sfxID] then
        randomCount[sfxID] = 0
    end

    if randomCount[sfxID] > sfxMaxNum then
        return
    end

    local mapX = self._target.destX
    local mapY = self._target.destY
    if self._target.id and (self._data.skillID ~= 58 and self._data.skillID ~= 581) then
        local target    = global.actorManager:GetActor(self._target.id)
        if target then
            mapX = target:GetMapX()
            mapY = target:GetMapY()
        end
    end

    local sfxRoot = self._root

    for i = 1, 4 do
        local mapPos = showMapPos[i]

        randomCount[sfxID] = randomCount[sfxID] + 1
        if randomCount[sfxID] > sfxMaxNum then
            break
        end

        local pX, pY = global.sceneManager:MapPos2WorldPos(mapX + mapPos.x, mapY + mapPos.y, true)
        local sfx = global.FrameAnimManager:CreateSkillEffAnim(sfxID, dir or 0)
        sfxRoot:addChild(sfx)
        sfx:setLocalZOrder(sfxID)
        sfx:Play(0, 0, true)
        sfx:setPosition(pX + global.MMO.PLAYER_AVATAR_OFFSET.x, pY + global.MMO.PLAYER_AVATAR_OFFSET.y)
        sfx:SetAnimEventCallback(
            function(_, eventType)
                if sfx then
                    sfx:removeFromParent()
                    sfx = nil
                end
                randomCount[sfxID] = randomCount[sfxID] - 1
            end
        )
    end
end
return skillPresentHit