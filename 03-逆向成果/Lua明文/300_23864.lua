local gameActorMoveable = require("actor/gameActorMoveable")
local gameActorMonster = class('gameActorMonster', gameActorMoveable)

local gameActorStateMonsterIdle         = require("actor/gameActorStateMonsterIdle")
local gameActorStateMonsterWalk         = require("actor/gameActorStateMonsterWalk")
local gameActorStateMonsterAttack       = require("actor/gameActorStateMonsterAttack")
local gameActorStateMonsterSkill        = require("actor/gameActorStateMonsterSkill")
local gameActorStateMonsterDie          = require("actor/gameActorStateMonsterDie")
local gameActorStateMonsterStuck        = require("actor/gameActorStateMonsterStuck")
local gameActorStateMonsterBorn         = require("actor/gameActorStateMonsterBorn")
local gameActorStateMonsterDeath        = require("actor/gameActorStateMonsterDeath")
local gameActorStateMonsterChangeShape  = require("actor/gameActorStateMonsterChangeShape")
local gameActorStateMonsterCave         = require("actor/gameActorStateMonsterCave")
local gameActorStateMonsterUnknown1     = require("actor/gameActorStateMonsterUnknown1")
local gameActorStateMonsterUnknown2     = require("actor/gameActorStateMonsterUnknown2")
local gameActorStateMonsterUnknown3     = require("actor/gameActorStateMonsterUnknown3")
local gameActorStateMonsterOnPush       = require("actor/gameActorStateMonsterOnPush")
local gameActorStateMonsterTeleport     = require("actor/gameActorStateMonsterTeleport")

local optionsUtils                      = requireUtil("optionsUtils")
local proxyUtils                        = requireUtil("proxyUtils")

--绑定特效
local AttachAnimMap = {
    [196] = 197,    --黄泉教主
    [901] = 9011,   --沙巴克城墙
    [902] = 9012,   --沙巴克城墙
    [903] = 9013,   --沙巴克城墙
    [904] = 9011,   --沙巴克城墙
    [905] = 9012,   --沙巴克城墙
    [906] = 9013,   --沙巴克城墙
    [256] = 257,    --雪域魔王
    [325] = 3251,   --狐月电眼
    [326] = 3261,   --狐月风眼
    [327] = 3271,   --狐月天竺
    [172] = 173,    --月灵
    [342] = 343,    --黄金龙
    [99998] = 99999,--魔神
}
local mmo = global.MMO
local mapActAnim = {
    [mmo.ACTION_IDLE]           = mmo.ANIM_IDLE,
    [mmo.ACTION_WALK]           = mmo.ANIM_WALK,
    [mmo.ACTION_ATTACK]         = mmo.ANIM_ATTACK,
    [mmo.ACTION_SKILL]          = mmo.ANIM_SKILL,
    [mmo.ACTION_DIE]            = mmo.ANIM_DIE,
    [mmo.ACTION_RUN]            = mmo.ANIM_RUN,
    [mmo.ACTION_STUCK]          = mmo.ANIM_STUCK,
    [mmo.ACTION_BORN]           = mmo.ANIM_BORN,
    [mmo.ACTION_DEATH]          = mmo.ANIM_DEATH,
    [mmo.ACTION_CHANGESHAPE]    = mmo.ANIM_CHANGESHAPE,
    [mmo.ACTION_CAVE]           = mmo.ANIM_BORN,
    [mmo.ACTION_UNKNOWN1]       = mmo.ANIM_UNKNOWN1,
    [mmo.ACTION_UNKNOWN2]       = mmo.ANIM_UNKNOWN2,
    [mmo.ACTION_UNKNOWN3]       = mmo.ANIM_UNKNOWN3,
    [mmo.ACTION_ONPUSH]         = mmo.ANIM_WALK,
    [mmo.ACTION_TELEPORT]       = mmo.ANIM_IDLE,
}

local isStateInited = false
local actState      = {}

--动作方向
local fixAnimDirection = {
    [3]     = 0, --宝箱
    [4]     = 0,
    [7]     = 0, --宝箱
    [8]     = 0, --宝箱
    [41]    = 0, --角蝇
    [132]   = 0, --幻影蜘蛛
    [131]   = 0, --赤月恶魔
    [140]   = 0, --触龙神
    [141]   = 0, --树
    [216]   = 0, --魔龙石碑
    [324]   = 0, --九尾魂石
    [325]   = 0,
    [327]   = 0, --狐月天珠
    [329]   = 0,
    [801]   = 0, --火龙守护兽1
    [802]   = 0, --火龙守护兽2
    [803]   = 0, --卧龙山庄 采集物
    [804]   = 0, --卧龙山庄 采集物
    [805]   = 0, --卧龙山庄 采集物
    [806]   = 0, --卧龙山庄 采集物
    [807]   = 0, --卧龙山庄 采集物
    [901]   = 0, --城墙
    [902]   = 0, --城墙
    [903]   = 0, --城墙
    [904]   = 0, --城墙
    [905]   = 0, --城墙
    [906]   = 0, --城墙

    [10] = {     --食人花
        [mmo.ANIM_IDLE] = 0,
        [mmo.ANIM_BORN] = 0,
    },
    [63] = {     --祖玛教主
        [mmo.ANIM_BORN] = 0,
    },
    [800] = {     --火龙神
        [mmo.ANIM_IDLE] = 0,
        [mmo.ANIM_ATTACK] = 0,
    },
}

function gameActorMonster:getMonsterActionState(act)
    if act > mmo.ACTION_MAX then 
        return nil
    end

    if not isStateInited then
        actState[mmo.ACTION_IDLE]        = gameActorStateMonsterIdle.new()
        actState[mmo.ACTION_WALK]        = gameActorStateMonsterWalk.new()
        actState[mmo.ACTION_ATTACK]      = gameActorStateMonsterAttack.new()
        actState[mmo.ACTION_SKILL]       = gameActorStateMonsterSkill.new()
        actState[mmo.ACTION_DIE]         = gameActorStateMonsterDie.new()
        actState[mmo.ACTION_STUCK]       = gameActorStateMonsterStuck.new()
        actState[mmo.ACTION_BORN]        = gameActorStateMonsterBorn.new()
        actState[mmo.ACTION_DEATH]       = gameActorStateMonsterDeath.new()
        actState[mmo.ACTION_CHANGESHAPE] = gameActorStateMonsterChangeShape.new()
        actState[mmo.ACTION_CAVE]        = gameActorStateMonsterCave.new()
        actState[mmo.ACTION_UNKNOWN1]    = gameActorStateMonsterUnknown1.new()
        actState[mmo.ACTION_UNKNOWN2]    = gameActorStateMonsterUnknown2.new()
        actState[mmo.ACTION_UNKNOWN3]    = gameActorStateMonsterUnknown3.new()
        actState[mmo.ACTION_ONPUSH]      = gameActorStateMonsterOnPush.new()
        actState[mmo.ACTION_TELEPORT]    = gameActorStateMonsterTeleport.new()
        isStateInited = true
    end

    return actState[act]
end

function gameActorMonster:GetAvatarChildNodeByTag(tag)
    if self.mCurrAvatarNode and tag then
        return self.mCurrAvatarNode:getChildByTag(tag)
    end
    return nil
end

function gameActorMonster:SetAvatarChildNodeVisible(value)
    for tag = mmo.MONSTER_BODY_TAG, mmo.MONSTER_BODY_TAG do
        local node = self:GetAvatarChildNodeByTag(tag)
        if node then
            node:setVisible(value)
        end
    end
end

function gameActorMonster:ctor()
    gameActorMonster.super.ctor(self)
end

function gameActorMonster:init()
    gameActorMonster.super.init(self)

    self.mActionHandler = nil
    self.mCurrentState  = self:getMonsterActionState(self.mAction)
    self.mCurrentActT   = 0.0

    self.mOriginPositionX   = 0.0
    self.mOriginPositionY   = 0.0

    self.mMoveOrientX       = 0.0
    self.mMoveOrientY       = 0.0

    self.mTargePosX         = 0.0
    self.mTargePosY         = 0.0

    self.mDistanceToTarget  = 0.0

    self.mFeatureDirty       = false
    self.mAnimAct            = mmo.ANIM_IDLE
    self.mIsAnimNeedToUpdate = false
    self.mStopAnimFrameIndex = nil
    self.mCurrAvatarNode     = nil

    self.mHUDUI         = {}
    self.mOwnerName     = nil
    self.mStoneMode     = nil
    self.mRaceServer    = nil         -- 服务器race字段，只有怪物有，目前用以区分怪物是否可挖掘
    self.mRaceImg       = 0

    self.mIsSleepInCave = false     -- 在洞穴中，钻回洞穴有个过渡，该变量表示已经完全钻回去

    self.mActionEffect1  = nil       -- 动作对象
    self.mActionEffect2  = nil       -- 动作对象
    self.mActionEffect3  = nil       -- 动作对象
    self.mSkillAction    = {}
end

function gameActorMonster:destory()
    gameActorMonster.super.destory(self)
    -- remove hud
    global.HUDManager:RemoveActorAllHUD(self.mID)
end

function gameActorMonster:Tick(dt)
    gameActorMonster.super.Tick(self, dt)

    self.mCurrentState:Tick(dt, self)

    if self.mFeatureDirty then
        self.mFeatureDirty = false
        self:CheckFeature()
    end

    if self.mIsAnimNeedToUpdate then
        self:UpdateAnimation()
        self.mIsAnimNeedToUpdate = false
    end
end

function gameActorMonster:setPosition(x, y)
    gameActorMonster.super.setPosition(self, x, y)

    -- refresh zOrder
    if self.mAction == mmo.ACTION_DIE then
        self:GetNode():setLocalZOrder(math.floor(-y) + self:GetAdditionZorder() + mmo.DieAddZorder)
    else
        self:GetNode():setLocalZOrder(math.floor(-y) + self:GetAdditionZorder())
    end

    -- update hud pos
    local hudTop = self:GetHUDTop()
    global.HUDManager:setPosition(self.mID, x, y + hudTop)
    
    -- update buff pos
    global.BuffManager:setPosition(self:GetID(), x, y)
    global.ActorEffectManager:setPosition(self:GetID(), x, y)
end

function gameActorMonster:SetMoveTo(posX, posY)
    self.mMoveTo.x = posX
    self.mMoveTo.y = posY

    return 1
end

function gameActorMonster:SetDirection(dir)
    gameActorMonster.super.SetDirection(self, dir)

    local isUpdate = (self.mOrient ~= dir)
    if isUpdate then self:DirtyAnimFlag() end
end

function gameActorMonster:SetAction(newAction, isTerminate)
    if nil == isTerminate then isTerminate = false end
    local   stateNew  = self:getMonsterActionState(newAction)
    local   stateOld  = self.mCurrentState
    local   oldAction = self.mAction

    if self.mCurrentState:ChangeState(stateNew, self, isTerminate) then
        if 0 ~= stateOld then
            stateOld:OnExit(self)
        end

        self.mAction = newAction    

        if 0 ~= stateNew then
            stateNew:OnEnter(self)
        end

        if oldAction ~= newAction then
            local actAnim = mapActAnim[newAction]
            self:SetAnimAct(actAnim)
        end
    end
end

function gameActorMonster:SetAnimAct(newAnim)
    if self.mAnimAct ~= newAnim then
        self.mAnimAct = newAnim

        -- in die anim, zOrder is lowest
        if newAnim == mmo.ANIM_DIE then
            self:GetNode():setLocalZOrder(-self:GetNode():getPositionY() + self:GetAdditionZorder() + mmo.DieAddZorder)
        end

        self:DirtyAnimFlag()
    end
end

function gameActorMonster:GetAnimAct()
    return self.mAnimAct
end

function gameActorMonster:SetName(name)
    self.mName = name
end

function gameActorMonster:RefHPHUD()
    local preHp = self:GetLastCurAbilByID(GUIDefine.AttTypeTable.HP)
    local maxHP = self:GetMaxAbilByID(GUIDefine.AttTypeTable.HP)
    local HP = self:GetCurAbilByID(GUIDefine.AttTypeTable.HP)

    self:SetKeyValue(mmo.HUD_Hp_Full, HP >= maxHP and maxHP > 0)
    self:SetKeyValue(mmo.HUD_Hp_Null, HP < 1 or maxHP < 1)
    
    local bar = self.mHUDUI[mmo.HUDHPUI_BAR]
    if not bar then
        return false
    end

    if preHp > HP then
        self:SetKeyValue(mmo.HUD_BAR_SHOW_FULL_HP, true)
    end

    local hpPerc = HP / maxHP
    if global.ConstantConfig.showFewHp == 1 and not self:GetValueByKey(mmo.HUD_BAR_SHOW_FULL_HP) then
        hpPerc = 1
    end

    if ActorHud.GetHUDHPBarPer then
        hpPerc = ActorHud.GetHUDHPBarPer(self:GetID()) or hpPerc
    end

    global.HUDManager:SetHUDBarPercent(bar, hpPerc)

    optionsUtils:InitHUDVisibleValue(self, mmo.HUD_HPBAR_VISIBLE)
    optionsUtils:InitHUDVisibleValue(self, mmo.HUD_HMPLabel_VISIBLE)
    optionsUtils:CheckHUDHpBarVisible(self)

    global.HUDHPManager:Update(self)
end

function gameActorMonster:RefMPHUD()
    local maxMP = self:GetMaxAbilByID(GUIDefine.AttTypeTable.MP)
    local MP = self:GetCurAbilByID(GUIDefine.AttTypeTable.MP)

    if maxMP < 1 then
        return false
    end

    if not self.mHUDUI[mmo.HUDMPUI_BAR] then
        return false
    end

    local bar = self.mHUDUI[mmo.HUDMPUI_BAR]
    local percent = MP / maxMP
    if ActorHud.GetHUDMPBarPer then
        percent = ActorHud.GetHUDMPBarPer(self:GetID()) or percent
    end
    global.HUDManager:SetHUDBarPercent(bar, percent)

    optionsUtils:InitHUDVisibleValue(self, mmo.HUD_MPBAR_VISIBLE)
    optionsUtils:CheckHUDMpBarVisible(self)
end

function gameActorMonster:GetHP()
	return self:GetCurAbilByID(GUIDefine.AttTypeTable.HP)
end

function gameActorMonster:GetMaxHP()
	return self:GetMaxAbilByID(GUIDefine.AttTypeTable.HP)
end


function gameActorMonster:GetMP()
	return self:GetCurAbilByID(GUIDefine.AttTypeTable.MP)
end

function gameActorMonster:GetMaxMP()
	return self:GetMaxAbilByID(GUIDefine.AttTypeTable.MP)
end

function gameActorMonster:GetInternal()
    return self:GetCurAbilByID(GUIDefine.AttTypeTable.Internal_Value)
end

function gameActorMonster:GetMaxInternal()
	return self:GetMaxAbilByID(GUIDefine.AttTypeTable.Internal_Value)
end

function gameActorMonster:OnSequAnimLoadCompleted(actorID, animID, seqAnim)
    local _this = global.actorManager:GetActor(actorID)
    if nil == _this then
        return 
    end
    
    -- Refresh monster name label hud top
    local px = _this:getPositionX()
    local py = _this:getPositionY()
    global.HUDManager:setPosition(_this:GetID(), px, py + seqAnim:GetHUDTop())

    -- sync Total Duration
    local animAct = seqAnim:GetCurrAnimAct()
    local elapsed = seqAnim:GetElapsed() or 0
    _this.mCurrentState:OnAnimLoadCompleted(_this, animAct, elapsed)
end

function gameActorMonster:InitParam(param)
    self.mCurrActorNode = cc.Node:create()

    -- avater
    self.mCurrAvatarNode = cc.Node:create()
    self.mCurrActorNode:addChild(self.mCurrAvatarNode)
    self.mCurrAvatarNode:setTag(mmo.MONSTER_AVATAR_TAG)
    self.mCurrAvatarNode:setPosition(mmo.PLAYER_AVATAR_OFFSET)

    -- mount
    self.mCurrMountNode = cc.Node:create()
    self.mCurrActorNode:addChild(self.mCurrMountNode)
    self.mCurrMountNode:setTag(mmo.MONSTER_MOUNT_TAG)
    self.mCurrMountNode:setPosition(mmo.PLAYER_AVATAR_OFFSET)

    return 1
end

function gameActorMonster:DirtyFeature()
    self.mFeatureDirty = true
end

function gameActorMonster:CheckFeature()
    self:UpdateCloth()
end

function gameActorMonster:UpdateCloth()
    local function loadCallback(animID, seqAnim)
        self:OnSequAnimLoadCompleted(self:GetID(), animID, seqAnim)
    end

    if self.mAnimation then
        self.mAnimation:removeFromParent()
        self.mAnimation = nil
    end
    if self.mAttachAnim then
        self.mAttachAnim:removeFromParent()
        self.mAttachAnim = nil
    end

    -- 简装
    local clothID   = self:GetAppearByID(mmo.P_F_CLOTH)
    local ID        = optionsUtils:GetMonsterSimpleDress(self) or clothID
    self.mAnimation = global.FrameAnimManager:CreateActorMonsterAnim(ID, self.mAnimAct, loadCallback)
    self.mCurrAvatarNode:addChild(self.mAnimation)
    self.mAnimation:setTag(mmo.MONSTER_BODY_TAG)


    local attachAnimID = AttachAnimMap[ID]
    if attachAnimID then
        self.mAttachAnim = global.FrameAnimManager:CreateActorMonsterAnim(attachAnimID, self.mAnimAct)
        self.mCurrAvatarNode:addChild(self.mAttachAnim)

        -- 特殊处理月灵
        if ID == 172 then
            self.mAttachAnim:setLocalZOrder(-1)
        end
    end

    -- Refresh npc name label hud top
    local posX = self:getPositionX()
    local posY = self:getPositionY()
    global.HUDManager:setPosition(self:GetID(), posX, posY + self:GetHUDTop())

    self:DirtyAnimFlag()
end

function gameActorMonster:StopAnimToFrame(frameIndex)
    self.mStopAnimFrameIndex = frameIndex
end

function gameActorMonster:StopAllAnimation(frameIndex)
    local animDir = self:getFixAnimDir() or self.mOrient

    if self.mAnimation then
        self.mAnimation:Stop(frameIndex, self.mAnimAct, animDir)
    end

    if self.mAttachAnim then
        self.mAttachAnim:Stop(frameIndex, self.mAnimAct, animDir)
    end
end

function gameActorMonster:UpdateAnimation()
    local isLoop = self.mAnimAct == mmo.ANIM_IDLE or self.mAnimAct == mmo.ANIM_WALK
    local animDir = self:getFixAnimDir() or self.mOrient
    local show    =  not self.mSkillAction[1] and true or false

    -- speed
    local speed = 1
    if self.mAnimAct == mmo.ANIM_WALK then
        speed = self:GetWalkSpeed()
    elseif self.mAnimAct == mmo.ANIM_RUN then
        speed = self:GetRunSpeed()
    elseif self.mAnimAct == mmo.ANIM_ATTACK then
        if self:GetAttackAnimSpeed() > 1 then 
            speed = self:GetAttackAnimSpeed()
        end
    elseif self.mAnimAct == mmo.ANIM_SKILL then
        if self:GetMagicAnimSpeed() > 1 then 
            speed = self:GetMagicAnimSpeed()
        end
    end

    if self.mAnimation then 
        self.mAnimation:Stop()
        self.mAnimation:Play(self.mAnimAct, animDir, isLoop, speed, self:IsSequence())
        self.mAnimation:setVisible(show)
    end

    if self.mAttachAnim then
        self.mAttachAnim:Stop()
        self.mAttachAnim:Play(self.mAnimAct, animDir, isLoop, speed, self:IsSequence())
        self.mAttachAnim:setVisible(show)
    end

    if self.mStopAnimFrameIndex then
        self:StopAllAnimation(self.mStopAnimFrameIndex)
    end

    if not show then
        self:PlayActionEffect()
    end
    
    -- 
    global.Facade:sendNotification(global.NoticeTable.ActorBuffPresentUpdate, self:GetID())
end

function gameActorMonster:getFixAnimDir()
    local clothID = self:GetAppearByID(mmo.P_F_CLOTH)
    if fixAnimDirection[clothID] then
        if type(fixAnimDirection[clothID]) == "table" then
            return fixAnimDirection[clothID][self.mAnimAct]
        else
            return fixAnimDirection[clothID]
        end
    end
    return nil
end

function gameActorMonster:DirtyAnimFlag()
    self.mIsAnimNeedToUpdate = true
end

function gameActorMonster:GetType()
    return mmo.ACTOR_MONSTER
end

function gameActorMonster:GetAnimationID()
    return self:GetAppearByID(mmo.P_F_CLOTH)
end

function gameActorMonster:SetGameActorActionHandler(handler)
    self.mActionHandler = handler
end

function gameActorMonster:GetGameActorActionHandler()
    return self.mActionHandler
end

function gameActorMonster:GetLevel()
    return self:GetCurAbilByID(GUIDefine.AttTypeTable.LEVEL)
end

function gameActorMonster:SetOwnerName(name)
    self.mOwnerName = name
end
function gameActorMonster:GetOwnerName()
    if not self.mOwnerName then
        self.mOwnerName = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_OWNERNAME)
    end
    return self.mOwnerName
end

function gameActorMonster:GetCurrActTime()
    return self.mCurrentActT
end
function gameActorMonster:SetCurrActTime(t)
    self.mCurrentActT = t
end

function gameActorMonster:SetStoneMode(mode)
    self.mStoneMode = mode
end
function gameActorMonster:GetStoneMode()
    if self.mStoneMode == nil then
        self.mStoneMode = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_ARRSPABIL, mmo.STATE_TYPE_STONE)
    end
    return self.mStoneMode
end

function gameActorMonster:SetTypeIdex(index)
    self.mTypeIndex = index
end
function gameActorMonster:GetTypeIdex()
    return self.mTypeIndex
end

function gameActorMonster:SetRaceServer(race)
    self.mRaceServer = race
end
function gameActorMonster:GetRaceServer()
    if not self.mRaceServer then
        self.mRaceServer = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_RACESERVER)
    end
    return self.mRaceServer
end

function gameActorMonster:SetRaceImg(rm)
    self.mRaceImg = rm
end
function gameActorMonster:GetRaceImg()
    return self.mRaceImg
end

function gameActorMoveable:SetCloaking(isCloaking, index)
    -- 隐身术
    self.mClocking = isCloaking
    self:CalcCover()
end

function gameActorMoveable:CalcCover()
    local opacityV = self.mClocking and 155 or 255 

    if self.mAnimation then
        self.mAnimation:setOpacity(opacityV)
    end

    if self.mAttachAnim then
        self.mAttachAnim:setOpacity(opacityV)
    end
end

function gameActorMonster:GetHUDTop()
    if not self.mAnimation then
        return 20
    end
    return self.mAnimation:GetHUDTop() or 20
end

-- 大血条的头像id
function gameActorMonster:SetBigTipIcon(value)
    self.mbigTipIcon = value
end

function gameActorMonster:GetBigTipIcon()
    if self.mbigTipIcon and self.mbigTipIcon <= 0 then 
        self.mbigTipIcon =  nil
    end
    return self.mbigTipIcon
end

function gameActorMonster:SetNoShowName(value)
    self.mNoShowName = value
end

function gameActorMonster:IsNoShowName()
    return self.mNoShowName == 1
end

function gameActorMonster:SetNoShowHPBar(value)
    self.mNoShowHPBar = value
end

function gameActorMonster:IsNoShowHPBar()
    return self.mNoShowHPBar == 1
end

-- 设置国家id
function gameActorMonster:SetNationID(id)
    self._nationID = id
end

function gameActorMonster:GetNationID()
    if not self._nationID then
        self._nationID = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_NATIONID)
    end
    return self._nationID
end

-- 国家模式是否可被攻击
function gameActorMonster:SetNationEnemyPK(pk)
    self._nationEnemyPK = pk
end

function gameActorMonster:IsNationEnemyPK()
    if self._nationEnemyPK == nil then
        self._nationEnemyPK = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_NATIONENEMYPK)
    end
    return self._nationEnemyPK
end

-- 钻地怪，在洞穴中
function gameActorMonster:SetSleepInCave(v)
    self.mIsSleepInCave = v
end
function gameActorMonster:IsSleepInCave()
    return self.mIsSleepInCave
end

-- 高亮
function gameActorMonster:Bright()
    if self.mStoneMode then
        return
    end
    gameActorMonster.super.Bright(self)
end

function gameActorMonster:SetSkillActionID(value)
    if not value then
        return
    end
    self.mSkillAction[1] = value.effect1
    self.mSkillAction[2] = value.effect2
    self.mSkillAction[3] = value.effect3
    self.mSkillAction[4] = value.dir
    self.mIsAnimNeedToUpdate = true
end

function gameActorMonster:CreateActionEffect(id, dir, callback)
    if not self.mCurrAvatarNode then
        return
    end

    if not id or not dir then
        return
    end

    local effect = global.FrameAnimManager:CreateActorMonsterAnim(id, mmo.ANIM_IDLE)
    if not effect then
        if callback then
            callback()
        end
        return
    end

    self.mCurrAvatarNode:addChild(effect)
    effect:Play(0, dir, false)
    effect:SetAnimEventCallback(function()
        if callback then
            callback()
        end
        self:SetSkillActionID({})
    end)
    return effect
end

function gameActorMonster:PlayActionEffect()
    if self.mActionEffect1 or self.mActionEffect2 or self.mActionEffect3 then
        return
    end

    local playDir = self.mSkillAction[4] == 8 and self.mOrient or self.mSkillAction[4]
    self.mActionEffect1 = self:CreateActionEffect(self.mSkillAction[1], playDir, function()
        if self.mActionEffect1 then
            self.mActionEffect1:removeFromParent()
            self.mActionEffect1 = nil
        end
        self.mSkillAction[1] = nil
    end)
    self.mActionEffect2 = self:CreateActionEffect(self.mSkillAction[2], playDir, function()
        if self.mActionEffect2 then
            self.mActionEffect2:removeFromParent()
            self.mActionEffect2 = nil
        end
        self.mSkillAction[2] = nil
    end)
    self.mActionEffect3 = self:CreateActionEffect(self.mSkillAction[3], playDir, function()
        if self.mActionEffect3 then
            self.mActionEffect3:removeFromParent()
            self.mActionEffect3 = nil
        end
        self.mSkillAction[3] = nil
    end)

    if not self.mActionEffect1 and not self.mActionEffect2 and not self.mActionEffect3 then
        self:SetSkillActionID({})
    end
end

return gameActorMonster
