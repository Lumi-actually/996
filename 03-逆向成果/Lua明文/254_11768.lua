local gameActor = class("gameActor")
local INVALID_MAP_POS = 0xFFFF
local LIMIT_DISTANCE = 40   -- 近距离判定值

local mmo = global.MMO

function gameActor:ctor()
end

function gameActor:init()
    self.mONameStr          = ""
    self.mName              = ""
    self.mTypeIndex         = 0
    self.mID                = mmo.ACTOR_ID_INVALID
    self.mRace              = mmo.ACTOR_RACE_NONE
    self.mSubType           = mmo.ACTOR_SUBTYPE_NONE

    self.mCurrMapX          = INVALID_MAP_POS 
    self.mCurrMapY          = INVALID_MAP_POS 

    self.mLastMapX          = INVALID_MAP_POS
    self.mLastMapY          = INVALID_MAP_POS

    self.mPositionX         = 0
    self.mPositionY         = 0

    self.mAction            = mmo.ACTION_IDLE 
    self.mOrient            = mmo.ORIENT_U 

    self.mCurrActorNode     = nil
    self.mAnimation         = nil

    self.mIgnored           = nil
    self.mIgnoredT          = 0.0

    self.mLight             = nil           -- 灯光

    self.mPauseIgnored      = nil
    self.mPauseIgnoredT     = 0.0

    self.mVisible           = false

    self.mServerHpLabel     = false

    self.mObstacleFlag      = false         -- 阻挡标识

    self.mVisibles          = {}

    self.mIsMainPlayer      = false

    self.mBuffer            = {}            -- 源数据

    self.mInViewCheckT      = 10.0          -- 自动战斗状态检查距离时间
    self.mInViewCheckFlag   = false         -- 是否开启检测标识
end

function gameActor:destory()
end

local function squLen(x, y)
    return x * x + y * y
end

function gameActor:Tick(dt)
    if self:IsIgnored() then
        self.mIgnoredT = self.mIgnoredT + dt
        if self.mIgnoredT >= 3.0 then
            self.mIgnoredT = 0.0
            self:IgnoreActor(false)
            if self:IsDropItem() then
                global.Facade:sendNotification(global.NoticeTable.RefreshDropItem, self:GetID())
            end
        end
    end

    if self:IsPauseIgnored() then
        self.mPauseIgnoredT = self.mPauseIgnoredT + dt
        if self.mPauseIgnoredT >= 3.0 then
            self.mPauseIgnoredT = 0.0
            self:IgnoreActor(true)
            self:PauseIgnoredActor()
        end
    end

    if not SL:GetValue("BATTLE_IS_AUTO_FIGHT_STATE") then
        self.mInViewCheckT = 10.0
        self.mInViewCheckFlag = false
    end

    if self.mInViewCheckFlag and not self:IsMainPlayer() then
        self.mInViewCheckT = self.mInViewCheckT - dt
        
        self:CheckAutoTargetDistance()
        if self.mInViewCheckT <= 0.0 then
            self.mInViewCheckT = 10.0
            self.mInViewCheckFlag = false
        end
    end
end

function gameActor:CheckAutoTargetDistance()
    if GUIFunction.CheckAutoTargetEnableByID(self.mID) then
        local aX = self.mCurrMapX
        local aY = self.mCurrMapY
        local len = squLen(aX - SL:GetValue("X"), aY - SL:GetValue("Y"))
        if len <= LIMIT_DISTANCE then
            global.Facade:sendNotification(global.NoticeTable.CheckAutoTarget, self:GetID())
            self.mInViewCheckT = 10.0
            self.mInViewCheckFlag = false
        end
    end
end

function gameActor:SetInViewCheckFlag(flag)
    self.mInViewCheckFlag = flag == true
    if self.mInViewCheckFlag then
        self.mInViewCheckT = 10.0
    end
end

function gameActor:GetType()
    return mmo.ACTOR_NONE
end
function gameActor:SetLightID(Light)
    self.mLight = Light
end
function gameActor:GetLightID()
    return self.mLight
end
function gameActor:SetID(id)
    self.mID = id
end
function gameActor:GetID()
    return self.mID
end

function gameActor:GetRace()
    return self.mRace
end
function gameActor:SetRace(race)
    self.mRace = race
end

function gameActor:IsPlayer()
    return self:GetType() == mmo.ACTOR_PLAYER
end

function gameActor:IsMonster()
    return self:GetType() == mmo.ACTOR_MONSTER
end

function gameActor:IsNPC()
    return self:GetType() == mmo.ACTOR_NPC
end

function gameActor:IsDropItem()
    return self:GetType() == mmo.ACTOR_DROPITEM
end

function gameActor:IsSEffect()
    return self:GetType() == mmo.ACTOR_SEFFECT
end

function gameActor:IsNetPlayer()
    return self:GetRace() == mmo.ACTOR_RACE_NET_PLAYER
end

function gameActor:IsHero()
    return self:GetRace() == mmo.ACTOR_RACE_HERO
end

function gameActor:IsPet()
    return self:GetRace() == mmo.ACTOR_RACE_PET
end

function gameActor:IsPickUpSprite()
    return self:GetRace() == mmo.ACTOR_RACE_PICKUPSPRITE
end

function gameActor:IsHumanoid()
    return self:GetRace() == mmo.ACTOR_RACE_HUMANOID
end

function gameActor:IsDefender()
    return self:GetRace() == mmo.ACTOR_RACE_DEFENDER
end

function gameActor:IsBoss()
    return self:GetSubType() == mmo.ACTOR_SUBTYPE_BOSS
end

function gameActor:IsNormalMonster()
    return self:GetSubType() == mmo.ACTOR_SUBTYPE_NORMAL
end

function gameActor:IsElite()
    return self:GetSubType() == mmo.ACTOR_SUBTYPE_ELITE
end

function gameActor:IsEscort()
    return self:GetRace() == mmo.ACTOR_RACE_ESCORT
end

function gameActor:IsCollection()
    return self:GetRace() == mmo.ACTOR_RACE_COLLECTION
end

-- 沙巴克大门
function gameActor:IsGate()
    if not self:IsMonster() then
        return false
    end
    return self:GetAnimationID() == 900
end

-- 沙巴克城墙
local wallT = {
    [901] = 1,
    [902] = 1,
    [903] = 1,
    [904] = 1,
    [905] = 1,
    [906] = 1,
}
function gameActor:IsWall()
    if not self:IsMonster() then
        return false
    end
    local animId = self:GetAnimationID()
    if not animId then
        return false
    end
    return wallT[animId] == 1
end

-- 是否是趴狗
local followDogT = {
    [mmo.ACTOR_SERVER_RACE_FOLLOW_DOG]  = 1,
    [mmo.ACTOR_SERVER_RACE_FOLLOW_DOG1] = 1,
    [mmo.ACTOR_SERVER_RACE_FOLLOW_DOG2] = 1,
    [mmo.ACTOR_SERVER_RACE_FOLLOW_DOG3] = 1,
}
function gameActor:IsFollowDog()
    if not self:IsMonster() then
        return false
    end
    local raceServer = self:GetRaceServer()
    if not raceServer then
        return false
    end
    return followDogT[raceServer] == 1
end

-- 是否是站狗
local fightDogT = {
    [mmo.ACTOR_SERVER_RACE_FIGHT_DOG]  = 1,
    [mmo.ACTOR_SERVER_RACE_FIGHT_DOG1] = 1,
    [mmo.ACTOR_SERVER_RACE_FIGHT_DOG2] = 1,
    [mmo.ACTOR_SERVER_RACE_FIGHT_DOG3] = 1,
}
function gameActor:IsFightDog()
    if not self:IsMonster() then
        return false
    end
    local raceServer = self:GetRaceServer()
    if not raceServer then
        return false
    end
    return fightDogT[raceServer] == 1
end

--动画顺序播放
function gameActor:IsSequence()
    -- 趴狗 变身倒着播放
    if self:IsFollowDog() and self.mAction == mmo.ACTION_CHANGESHAPE then
        return false
    end
    -- 钻回地下
    if self.mAction == mmo.ACTION_CAVE then
        return false
    end
    return true
end

function gameActor:GetTypeIndex()
    return self.mTypeIndex
end
function gameActor:SetTypeIndex(index)
    self.mTypeIndex = index
end

function gameActor:GetSubType()
    return self.mSubType
end
function gameActor:SetSubType(type)
    self.mSubType = type
end

function gameActor:GetMapX()
    return self.mCurrMapX
end

function gameActor:GetLastMapX()
    return self.mLastMapX
end

function gameActor:SetMapX(x)
    self.mLastMapX = self.mCurrMapX
    self.mCurrMapX = x
    if self.mLastMapX == INVALID_MAP_POS then   -- 进视野默认开启检测
        self.mInViewCheckFlag = true
    end
end

function gameActor:GetMapY()
    return self.mCurrMapY
end

function gameActor:GetLastMapY()
    return self.mLastMapY
end

function gameActor:SetMapY(y)
    self.mLastMapY = self.mCurrMapY
    self.mCurrMapY = y
end

function gameActor:setPosition(x, y)
    if (self.mPositionX == x and self.mPositionY == y) then
        return
    end
    self.mPositionX = x
    self.mPositionY = y
    self:GetNode():setPosition(x, y)
end

function gameActor:getPositionX()
    return self.mPositionX
end

function gameActor:getPositionY()
    return self.mPositionY
end

function gameActor:getPosition()
    return cc.p(self.mPositionX, self.mPositionY)
end

function gameActor:SetAction(newAction, isTerminate)
end

function gameActor:GetAction()
    return self.mAction
end

function gameActor:IsDie()
    return self.mAction == mmo.ACTION_DIE
end

function gameActor:IsDeath()
    return self.mAction == mmo.ACTION_DEATH
end

function gameActor:IsBorn()
    return self.mAction == mmo.ACTION_BORN
end

function gameActor:IsCave()
    return self.mAction == mmo.ACTION_CAVE
end

function gameActor:IsLaunch()
    return self.mAction == mmo.ACTION_ATTACK or self.mAction == mmo.ACTION_SKILL
end

function gameActor:IsDash()
    return self.mAction == mmo.ACTION_DASH
end

function gameActor:IsOnPush()
    return self.mAction == mmo.ACTION_ONPUSH
end

function gameActor:SetDirection(dir)
    dir = tonumber(dir)
    if dir and (dir >= 0 and dir < 8) then
        self.mOrient = dir 
    else
        -- print("SetDirection error:", dir)
        -- PrintTraceback()
    end
end
function gameActor:GetDirection()
    return self.mOrient
end

function gameActor:GetNode()
    return self.mCurrActorNode
end

function gameActor:GetMountNode()
    return self.mCurrMountNode
end

function gameActor:GetAnimationID()
    if self.mAnimation then
        return self.mAnimation:GetID()
    end

    return 0
end

function gameActor:GetAnimation()
    return self.mAnimation
end

function gameActor:SetONameStr(str)
    self.mONameStr = str
end
function gameActor:GetONameStr()
    return self.mONameStr
end

function gameActor:SetName(name)
    self.mName = name
end
function gameActor:GetName()
    return self.mName
end

function gameActor:IsIgnored()
    return self.mIgnored
end

function gameActor:IgnoreActor(state)
    self.mIgnored = state
end

function gameActor:Bright()
end

function gameActor:UnBright()
end

function gameActor:IsBright()
    return false
end

function gameActor:GetHUDTop()
    return 0
end

function gameActor:IsPauseIgnored()
    return self.mPauseIgnored
end

function gameActor:PauseIgnoredActor(state)
    self.mPauseIgnored = state
    if not state then
        self.mPauseIgnoredT = 0
    end
end

---------------------------------------------------------------------------
-- Server Hp
function gameActor:IsVisibleServerHpLabel()
    return self.mServerHpLabel
end

function gameActor:setVisibleServerHpLabel(visible)
    self.mServerHpLabel = visible
end

function gameActor:SetKeyValue(key, value)
    if self.mVisibles[key] == value then
        return false
    end
    self.mVisibles[key] = value
end

function gameActor:GetValueByKey(key)
    return self.mVisibles[key]
end

function gameActor:SetObstacleFlag(state)
    self.mObstacleFlag = state
end

function gameActor:IsObstacleFlag()
    return self.mObstacleFlag
end

-- 是否是主玩家
function gameActor:SetIsMainPlayer(value)
    self.mIsMainPlayer = value
end

function gameActor:IsMainPlayer()
    return self.mIsMainPlayer
end

-----------------------------------------------------------------------------
function gameActor:GetBuffer()
    return self.mBuffer
end
function gameActor:SetBuffer(buffer)
    self.mBuffer = buffer
end

-----------------------------------------------------------------------------
return gameActor