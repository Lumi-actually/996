local gameActor = require("actor/gameActor")
local gameActorEffect = class('gameActorEffect', gameActor)

function gameActorEffect:ctor()
    gameActorEffect.super.ctor(self)
end

function gameActorEffect:init()
    gameActorEffect.super.init(self)

    self.mClothID           = nil
    self.mIsLoop            = true
    self.mEffectType        = 0
    self.stopFrameIndex     = 0
    self.mFeatureDirty      = false
    self.mDuranceID         = nil
    self.mIsOwn             = false     -- 是否自己所有  
    self.mPlayedCount       = 0         -- 已播放次数
end

function gameActorEffect:destory()
    gameActorEffect.super.destory(self)
end

function gameActorEffect:Tick(dt)
    if self.mFeatureDirty then
        self.mFeatureDirty = false
        self:CheckFeature()
    end
end

function gameActorEffect:setPosition(x, y)
    local offset = global.MMO.EFFECT_AVATAR_OFFSET
    x = x + offset.x
    y = y + offset.y
    gameActorEffect.super.setPosition(self, x, y)

    -- refresh zOrder
    self:GetNode():setLocalZOrder(math.floor(-y))
end

function gameActorEffect:setRotation(angle)
    self:GetNode():setRotation(angle)
end

function gameActorEffect:SetAction(newAction, isTerminate)
    self:UpdateAnimation()
end

function gameActorEffect:GetAnimationID()
    if self.mAnimation then
        return self.mAnimation:GetID()
    else
        return -1
    end
end

function gameActorEffect:InitParam(param)
    self.mCurrActorNode = cc.Node:create()

    self.mClothID       = param.sfxId
    self.mIsLoop        = param.isLoop
    self.mEffectType    = param.type
    self.stopFrameIndex = param.param
    self.mDuranceID     = param.DuranceID
    self.mIsOwn         = param.isOwn
    self.mStopCount     = tonumber(param.num) and tonumber(param.num) > 0 and tonumber(param.num)

    return 1
end

function gameActorEffect:DirtyFeature()
    self.mFeatureDirty = true
end

function gameActorEffect:CheckFeature()
    if (self.mAnimation) then
        self.mAnimation:removeFromParent()
        self.mAnimation = nil
    end

    if self.mStopCount then
        self.mIsLoop = true
    end
    self.mPlayedCount = 0

    self.mAnimation = global.FrameAnimManager:CreateSFXAnim(self.mClothID)
    self.mAnimation:SetGlobalElapseEnable(self.mEffectType ~= global.MMO.EFFECT_TYPE_SFX and self.mIsLoop == true)
    self.mCurrActorNode:addChild(self.mAnimation)

    -- 火墙透明度处理
    if self.mEffectType == global.MMO.EFFECT_TYPE_FIRE then
        local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
        local opacity = GameSettingProxy:GetFireEffectOpactiy()
        self.mAnimation:setOpacity(opacity)
    end

    -- 火墙颜色 自己放的 / 自己英雄放的
    if self.mEffectType == global.MMO.EFFECT_TYPE_FIRE and self.mIsOwn then
        local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
        local values = SL:GetValue("SETTING_VALUE", SLDefine.SETTINGID.SETTING_IDX_FIRE_OWN_HIGHTLIGHT)
        local enable = values and values[1] == 1
        if enable then
            self.mAnimation:setColor(cc.Color3B.GREEN)
        end
    end

    self:UpdateAnimation()
end

function gameActorEffect:UpdateAnimation()
    if self.mAnimation then
        self.mAnimation:Play(0, 0, self.mIsLoop)
        if self.mStopCount then
            self.mAnimation:SetAnimEventCallback(function()
                self.mPlayedCount = self.mPlayedCount + 1
                if self.mPlayedCount == self.mStopCount then    -- 达播放次数停止
                    self.mAnimation:Stop(self.stopFrameIndex and self.stopFrameIndex > 0 and self.stopFrameIndex or nil, 0, 0)
                    self.mPlayedCount = 0
                    local actorID = self:GetID()
                    local mapID = SL:GetValue("MAP_ID")
                    if self.mEffectType == global.MMO.EFFECT_TYPE_SFX and CheckIsSLAddMapEffect(actorID, mapID) then
                        SL:RmvMapSpecialEffect(actorID, mapID)
                    end
                end
            end)
        end

        if self.stopFrameIndex and self.stopFrameIndex > 0 then
            self.mAnimation:Stop(self.stopFrameIndex, 0, 0)
        end
    end
end

function gameActorEffect:GetType()
    return global.MMO.ACTOR_SEFFECT
end

function gameActorEffect:GetAnimation()
    return self.mAnimation
end

function gameActorEffect:GetEffectType()
    return self.mEffectType
end

function gameActorEffect:GetDuranceID()
    return self.mDuranceID
end

function gameActorEffect:IsOwn()
    return self.mIsOwn
end

return gameActorEffect