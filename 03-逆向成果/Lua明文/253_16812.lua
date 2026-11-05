local gameActor = require("actor/gameActor")
local gameActorMoveable = class('gameActorMoveable', gameActor)

local mmo = global.MMO

function gameActorMoveable:ctor()
    gameActorMoveable.super.ctor(self)
end

function gameActorMoveable:init()
    gameActorMoveable.super.init(self)

    self.mIsArrived         = true
    self.mIsConfirmed       = true

    self.mWalkStepTime      = mmo.DEFAULT_WALK_TIME
    self.mWalkSpeedRate     = nil
    self.mRunStepTime       = mmo.DEFAULT_RUN_TIME
    self.mRunSpeedRate      = nil
    self.mIsSpeedup         = nil 
    self.mIsFullSpeedup     = nil
    self.mIsMoreFullSpeedup    = nil
    self.mIsMoreSpeedRate      = nil
    
    self.mAttackStepTime    = mmo.DEFAULT_ATTACK_TIME
    self.mAttackSpeedRate   = nil
    self.mMagicStepTime     = mmo.DEFAULT_MAGIC_TIME
    self.mMagicSpeedRate    = nil

    self.mMoveTo            = {}

    self.mGuildID           = ""
    self.mGuildName         = ""
    self.mMasterID          = nil
    self.mFaction           = 0
    self.pklv               = nil
    self.inSafeZone         = nil
    self.mOwnerID           = nil
    self.mOwnerName         = nil
    self.mServerID          = nil

    self.mAdditionZorder    = 0

    self.mCover             = {}

    self.mNameColor         = nil           -- 名字颜色
    self.mWarZone           = nil           -- 行会战标志

    self.mGMData            = nil           -- gm自定义数据，和服务器约定暂定为5个int {}

    self.mArrAppear         = {}
    self.mArrSPAbil         = {}
    self.mArrCurAbil        = {}
    self.mArrMaxAbil        = {}


    self.mArrAppearDirty    = {}
    self.mLastArrCurAbil    = {}
    self.mLastArrMaxAbil    = {}
    self.mShowArrAppear     = {}

    self.mCamps = {
        InTeam = false, InGuild = false, InCamp = false
    }
    self.mCampDirty         = false
end

function gameActorMoveable:destory()
    gameActorMoveable.super.destory(self)
end

function gameActorMoveable:GetFaction()
    return self.mFaction
end
function gameActorMoveable:SetFaction(faction)
    self.mFaction = faction
end

function gameActorMoveable:SetMoveTo(posX, posY)
end

function gameActorMoveable:SetGuildID(id)
    self.mGuildID = id
end
function gameActorMoveable:GetGuildID()
    return self.mGuildID
end

function gameActorMoveable:SetGuildName(name)
    self.mGuildName = name
end
function gameActorMoveable:GetGuildName()
    return self.mGuildName
end

function gameActorMoveable:SetCampValue(key, value, isInit)
    if self.mCamps[key] == value then
        return false
    end
    self.mCamps[key] = value
    if not isInit then
        self.mCampDirty = true
    end
end

-- 是否己方成员
function gameActorMoveable:IsSameCamp()
    local isCamp = self.mCamps.InTeam or self.mCamps.InGuild or self.mCamps.InCamp
    return isCamp
end

function gameActorMoveable:GetMasterID()
    if not self.mMasterID then
        self.mMasterID = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_MASTERID)
    end
    return self.mMasterID
end
function gameActorMoveable:SetMasterID(id)
    self.mMasterID = id
end

function gameActorMoveable:IsHaveMaster()
    return self:GetMasterID() ~= mmo.ACTOR_ID_INVALID
end

function gameActorMoveable:SetPKLv(lv)
    self.pklv = lv
end
function gameActorMoveable:GetPKLv()
    if not self.pklv then
        self.pklv = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_PKLV)
    end
    return self.pklv
end

function gameActorMoveable:RefHPHUD()
end

function gameActorMoveable:SetIsSpeedup(fast)
    self.mIsSpeedup = fast
end

function gameActorMoveable:GetIsSpeedup()
    return self.mIsSpeedup
end

function gameActorMoveable:SetIsFullSpeedup(fast)
    self.mIsFullSpeedup = fast
end

function gameActorMoveable:GetIsFullSpeedup()
    return self.mIsFullSpeedup
end

function gameActorMoveable:SetIsMoreFullSpeedup( fast )
    self.mIsMoreFullSpeedup = fast
end

function gameActorMoveable:GetIsMoreFullSpeedup()
    return self.mIsMoreFullSpeedup
end

function gameActorMoveable:SetIsMoreSpeedRate( fast )
    self.mIsMoreSpeedRate = fast
end

function gameActorMoveable:GetIsMoreSpeedRate()
    return self.mIsMoreSpeedRate
end

---基础间隔 服务端 只会下发 服务端计算后的间隔 前端计算加速倍速
function gameActorMoveable:SetWalkStepTime(time)
    self.mWalkStepTime = time
end

function gameActorMoveable:GetWalkStepTime()
    return self.mWalkStepTime 
end

function gameActorMoveable:SetWalkSpeed(stepTime)
    stepTime = stepTime * 0.001
    if stepTime == 0.0 then 
        stepTime = mmo.DEFAULT_WALK_TIME
    end 
    self.mWalkSpeedRate = self:GetWalkStepTime() / (stepTime + mmo.NETWORK_DELAY)
end

function gameActorMoveable:GetWalkSpeedByProperty()
    if not self.mWalkSpeedRate then
        local stepTime  = self:GetCurAbilByID(GUIDefine.AttTypeTable.Walk_StepTime)
        self:SetWalkSpeed(stepTime)
    end
    return self.mWalkSpeedRate
end

function gameActorMoveable:GetWalkSpeed()
    local rate = 1
    if self:GetIsMoreFullSpeedup() then
        rate = self:GetWalkStepTime() / mmo.DEFAULT_MORE_MUCH_FAST_TIME / self:GetWalkSpeedByProperty()
    elseif self:GetIsMoreSpeedRate() then
        rate = mmo.DEFAULT_MORE_MUCH_FAST_RATE
    elseif self:GetIsFullSpeedup() then
        rate = mmo.DEFAULT_MUCH_FAST_TIME
    elseif self:GetIsSpeedup() then
        rate = mmo.DEFAULT_FAST_TIME_RATE
    end
    return self:GetWalkSpeedByProperty() * rate
end

function gameActorMoveable:SetRunStepTime(time)
    self.mRunStepTime = time
end

function gameActorMoveable:GetRunStepTime()
    return self.mRunStepTime
end

function gameActorMoveable:SetRunSpeed(stepTime)
    stepTime = stepTime * 0.001
    if stepTime == 0.0 then 
        stepTime = mmo.DEFAULT_RUN_TIME
    end 
    self.mRunSpeedRate = self:GetRunStepTime() / (stepTime +  mmo.NETWORK_DELAY)
end

function gameActorMoveable:GetRunSpeedByProperty()
    if not self.mRunSpeedRate then
        local stepTime  = self:GetCurAbilByID(GUIDefine.AttTypeTable.Run_StepTime)
        self:SetRunSpeed(stepTime)
    end
    return self.mRunSpeedRate
end

function gameActorMoveable:GetRunSpeed()
    local rate = 1
    if self:GetIsMoreFullSpeedup() then
        rate = self:GetRunStepTime() / mmo.DEFAULT_MORE_MUCH_FAST_TIME / self:GetRunSpeedByProperty()
    elseif self:GetIsMoreSpeedRate() then
        rate = mmo.DEFAULT_MORE_MUCH_FAST_RATE
    elseif self:GetIsFullSpeedup() then
        rate = mmo.DEFAULT_MUCH_FAST_TIME
    elseif self:GetIsSpeedup() then
        rate = mmo.DEFAULT_FAST_TIME_RATE
    end
    return self:GetRunSpeedByProperty() * rate
end

function gameActorMoveable:SetAttackStepTime(time)
    self.mAttackStepTime = time
end

function gameActorMoveable:GetAttackStepTime()
    return self.mAttackStepTime
end

function gameActorMoveable:SetAttackSpeed(stepTime)
    stepTime = stepTime * 0.001
    if stepTime == 0.0 then 
        stepTime = mmo.DEFAULT_ATTACK_TIME
    end 
    self.mAttackSpeedRate = self:GetAttackStepTime() / stepTime
end

function gameActorMoveable:GetAttackSpeedByProperty()
    if not self.mAttackSpeedRate then
        local stepTime  = self:GetCurAbilByID(GUIDefine.AttTypeTable.Attack_StepTime)
        self:SetAttackSpeed(stepTime)
    end
    return self.mAttackSpeedRate
end

function gameActorMoveable:GetAttackSpeed()
    local rate = 1
    if self:GetIsMoreFullSpeedup() then
        rate = self:GetAttackStepTime() / mmo.DEFAULT_MORE_MUCH_FAST_TIME / self:GetAttackSpeedByProperty()
    elseif self:GetIsMoreSpeedRate() then
        rate = mmo.DEFAULT_MORE_MUCH_FAST_RATE
    elseif self:GetIsFullSpeedup() then
        rate = mmo.DEFAULT_MUCH_FAST_TIME
    elseif self:GetIsSpeedup() then
        rate = mmo.DEFAULT_FAST_TIME_RATE
    end
    return self:GetAttackSpeedByProperty() * rate
end

function gameActorMoveable:GetAttackAnimSpeed(action)
    return self:GetAttackSpeed()
end

function gameActorMoveable:SetMagicStepTime(time)
    self.mMagicStepTime = time
end

function gameActorMoveable:GetMagicStepTime()
    return self.mMagicStepTime
end

function gameActorMoveable:SetMagicSpeed(stepTime)
    stepTime = stepTime * 0.001
    if stepTime == 0.0 then 
        stepTime = mmo.DEFAULT_MAGIC_TIME
    end 
    self.mMagicSpeedRate = self:GetMagicStepTime() / stepTime
end

function gameActorMoveable:GetMagicSpeedByProperty()
    if not self.mMagicSpeedRate then
        local stepTime  = self:GetCurAbilByID(GUIDefine.AttTypeTable.Magic_StepTime)
        self:SetMagicSpeed(stepTime)
    end
    return self.mMagicSpeedRate
end

function gameActorMoveable:GetMagicSpeed()
    local rate = 1
    if self:GetIsMoreFullSpeedup() then
        rate = self:GetMagicStepTime() / mmo.DEFAULT_MORE_MUCH_FAST_TIME / self:GetMagicSpeedByProperty()
    elseif self:GetIsMoreSpeedRate() then
        rate = mmo.DEFAULT_MORE_MUCH_FAST_RATE
    elseif self:GetIsFullSpeedup() then
        rate = mmo.DEFAULT_MUCH_FAST_TIME
    elseif self:GetIsSpeedup() then
        rate = mmo.DEFAULT_FAST_TIME_RATE
    end
    return self:GetMagicSpeedByProperty() * rate
end

function gameActorMoveable:GetMagicAnimSpeed(action)
    return self:GetMagicSpeed()
end

function gameActorMoveable:SetGameActorActionHandler(handler)
end

function gameActorMoveable:GetGameActorActionHandler()
end

function gameActorMoveable:DirtyAnimFlag()
end

function gameActorMoveable:StopAnimToFrame(frameIndex)
end

function gameActorMoveable:SetAdditionZorder(zorder)
    self.mAdditionZorder = zorder
end
function gameActorMoveable:GetAdditionZorder()
    return self.mAdditionZorder
end

function gameActorMoveable:SetInSafeZone(inSafe)
    self.inSafeZone = inSafe
end
function gameActorMoveable:GetInSafeZone()
    return self.inSafeZone
end

function gameActorMoveable:SetIsThrough(through)
    self.mIsThrough = through
end
function gameActorMoveable:IsThroughAble()
    if nil == self.mIsThrough then
        self.mIsThrough = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_THROUGH) == 1
    end
    return self.mIsThrough
end

function gameActorMoveable:SetOwnerName(name)
    self.mOwnerName = name
end
function gameActorMoveable:GetOwnerName()
    if not self.mOwnerName then
        self.mOwnerName = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_OWNERNAME)
    end
    return self.mOwnerName
end

function gameActorMoveable:SetOwnerID(id)
    self.mOwnerID = id
end
function gameActorMoveable:GetOwnerID()
    if not self.mOwnerID then
        self.mOwnerID = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_OWNERID)
    end
    return self.mOwnerID
end

function gameActorMoveable:SetServerID(id)
    self.mServerID = id
end
function gameActorMoveable:GetServerID()
    if not self.mServerID then
        self.mServerID = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_NSERVERID)
    end
    return self.mServerID
end

function gameActorMoveable:Bright()
    if not self.mIsBright then
        self.mIsBright = true

        local actorAnim = self:GetAnimation()
        ShaderUtils.SetTypeShader(actorAnim, SLDefine.SHADER_TYPE.SHADER_TYPE_HIGHTLIGHT)
    end
end
function gameActorMoveable:UnBright()
    if self.mIsBright then
        self.mIsBright = false

        local actorAnim = self:GetAnimation()
        ShaderUtils.SetTypeShader(actorAnim, SLDefine.SHADER_TYPE.SHADER_TYPE_NORMAL)
    end
end
function gameActorMoveable:IsBright()
    return self.mIsBright
end

function gameActorMoveable:IsArrived()
    return self.mIsArrived
end
function gameActorMoveable:SetIsArrived(b)
    self.mIsArrived = b
end

function gameActorMoveable:GetConfirmed()
    return self.mIsConfirmed
end
function gameActorMoveable:SetConfirmed(b)
    self.mIsConfirmed = b
end

function gameActorMoveable:SetNameColor(state)
    self.mNameColor = state
end
function gameActorMoveable:GetNameColor()
    if not self.mNameColor then
        self.mNameColor = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_COLOR)
    end
    -- 有内挂配置颜色 优先使用
    if self.mSettingColorID then
        return self.mSettingColorID
    end
    return self.mNameColor
end

function gameActorMoveable:SetWarZone(state)
    self.mWarZone = state
end
function gameActorMoveable:IsWarZone()
    if not self.mWarZone then
        self.mWarZone = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_WARZONE)
    end
    return self.mWarZone == 1
end

function gameActorMoveable:SetGMData(data, idx)
    if not self.mGMData then
        self.mGMData = {}
    end
    self.mGMData[idx] = data
end
function gameActorMoveable:GetGMData()
    if not self.mGMData then
        self.mGMData = {}
        for i = 1, 5 do
            self.mGMData[i] = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_GMDATA, i)
        end
    end
    return self.mGMData
end

function gameActorMoveable:SetShaBaKeZone(value)
    self.mShabakeZone = value
end

function gameActorMoveable:GetShaBaKeZone()
    return self.mShabakeZone
end

function gameActorMoveable:IsAttackType()
    local value = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_ACTIONTYPE)
    local isAttack = not CheckBit(value or 0, 1)
    return isAttack
end

---------------------------------------------------------------------------------
function gameActorMoveable:SetAppearByID(i, v)
    self.mArrAppear[i] = v
    self.mArrAppearDirty[i] = true
end
function gameActorMoveable:GetAppearByID(i)
    if not self.mArrAppear[i] then
        self:SetAppearByID(i, G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_ARRAPPEAR, i))
    end
    return self.mArrAppear[i]
end

function gameActorMoveable:GetFeatureByID(i)
    if self.mShowArrAppear[i] and self.mShowArrAppear[i] > 0 then
        return self.mShowArrAppear[i]
    end
    return self:GetAppearByID(i)
end

---------------------------------------------------------------------------------
function gameActorMoveable:SetArrSPAbilByID(i, v)
    self.mArrSPAbil[i] = v
end

function gameActorMoveable:GetArrSPAbilByID(i)
    if not self.mArrSPAbil[i] then
        self:SetArrSPAbilByID(i, G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_ARRSPABIL, i))
    end
    return self.mArrSPAbil[i]
end

---------------------------------------------------------------------------------
function gameActorMoveable:SetCurAbilByID(i, v)
    self.mLastArrCurAbil[i] = self.mArrCurAbil[i]
    self.mArrCurAbil[i] = v
    if i == GUIDefine.AttTypeTable.Walk_StepTime then
        self:SetWalkSpeed(v)
    elseif i == GUIDefine.AttTypeTable.Run_StepTime then
        self:SetRunSpeed(v)
    elseif i == GUIDefine.AttTypeTable.Attack_StepTime then
        self:SetAttackSpeed(v)
    elseif i == GUIDefine.AttTypeTable.Magic_StepTime then
        self:SetMagicSpeed(v)
    end
end
function gameActorMoveable:GetCurAbilByID(i)
    if not self.mArrCurAbil[i] then
        self:SetCurAbilByID(i, G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_ARRCURABIL, i))
    end
    return self.mArrCurAbil[i]
end

---------------------------------------------------------------------------------
function gameActorMoveable:SetMaxAbilByID(i, v)
    self.mLastArrMaxAbil[i] = self.mArrMaxAbil[i]
    self.mArrMaxAbil[i] = v
end

function gameActorMoveable:GetMaxAbilByID(i)
    if not self.mArrMaxAbil[i] then
        self:SetMaxAbilByID(i, G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_ARRMAXABIL, i))
    end
    return self.mArrMaxAbil[i]
end

---------------------------------------------------------------------------------
function gameActorMoveable:GetLastCurAbilByID(i)
    return self.mLastArrCurAbil[i] or 0
end
function gameActorMoveable:GetLastMaxAbilByID(i)
    return self.mLastArrMaxAbil[i] or 0
end
function gameActorMoveable:GetAppearDirtyByID(i)
    return self.mArrAppearDirty[i]
end
function gameActorMoveable:SetAppearDirtyByID(i, v)
    self.mArrAppearDirty[i] = v
end

function gameActorMoveable:SetShowArrAppearByID(i, v)
    self.mShowArrAppear[i] = v
end
function gameActorMoveable:GetShowArrAppearByID(i)
    return self.mShowArrAppear[i]
end

return gameActorMoveable
