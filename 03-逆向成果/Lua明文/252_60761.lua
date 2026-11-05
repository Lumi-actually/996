local gameActorMoveable = require("actor/gameActorMoveable")
local gameActorPlayer = class('gameActorPlayer', gameActorMoveable)

local gameActorStatePlayerIdle          = require("actor/gameActorStatePlayerIdle")
local gameActorStatePlayerWalk          = require("actor/gameActorStatePlayerWalk")
local gameActorStatePlayerRun           = require("actor/gameActorStatePlayerRun")
local gameActorStatePlayerAttack        = require("actor/gameActorStatePlayerAttack")
local gameActorStatePlayerSkill         = require("actor/gameActorStatePlayerSkill")
local gameActorStatePlayerDie           = require("actor/gameActorStatePlayerDie")
local gameActorStatePlayerStuck         = require("actor/gameActorStatePlayerStuck")
local gameActorStatePlayerReady         = require("actor/gameActorStatePlayerReady")
local gameActorStatePlayerMining        = require("actor/gameActorStatePlayerMining")
local gameActorStatePlayerSitdown       = require("actor/gameActorStatePlayerSitdown")
local gameActorStatePlayerRideRun       = require("actor/gameActorStatePlayerRideRun")
local gameActorStatePlayerDash          = require("actor/gameActorStatePlayerDash")
local gameActorStatePlayerDashWaiting   = require("actor/gameActorStatePlayerDashWaiting")
local gameActorStatePlayerOnPush        = require("actor/gameActorStatePlayerOnPush")
local gameActorStatePlayerTeleport      = require("actor/gameActorStatePlayerTeleport")
local gameActorStatePlayerIdleLock      = require("actor/gameActorStatePlayerIdleLock")
local gameActorStatePlayerTurn          = require("actor/gameActorStatePlayerTurn")
local gameActorStatePlayerYTPD          = require("actor/gameActorStatePlayerYTPD")
local gameActorStatePlayerZXC           = require("actor/gameActorStatePlayerZXC")
local gameActorStatePlayerSJS           = require("actor/gameActorStatePlayerSJS")
local gameActorStatePlayerDYZ           = require("actor/gameActorStatePlayerDYZ")
local gameActorStatePlayerHSQJ          = require("actor/gameActorStatePlayerHSQJ")
local gameActorStatePlayerFWJ           = require("actor/gameActorStatePlayerFWJ")
local gameActorStatePlayerJLB           = require("actor/gameActorStatePlayerJLB")
local gameActorStatePlayerBTXD          = require("actor/gameActorStatePlayerBTXD")
local gameActorStatePlayerSLP           = require("actor/gameActorStatePlayerSLP")
local gameActorStatePlayerHXJ           = require("actor/gameActorStatePlayerHXJ")
local gameActorStatePlayerBGZ           = require("actor/gameActorStatePlayerBGZ")
local gameActorStatePlayerSYZ           = require("actor/gameActorStatePlayerSYZ")
local gameActorStatePlayerWJGZ          = require("actor/gameActorStatePlayerWJGZ")
local gameActorStatePlayerDashFail      = require("actor/gameActorStatePlayerDashFail")
local gameActorStatePlayerSBYS          = require("actor/gameActorStatePlayerSBYS")
local gameActorStatePlayerAssassinRun       = require("actor/gameActorStatePlayerAssassinRun") 
local gameActorStatePlayerAssassinSneak     = require("actor/gameActorStatePlayerAssassinSneak") 
local gameActorStatePlayerAssassinSmite     = require("actor/gameActorStatePlayerAssassinSmite") 
local gameActorStatePlayerAssassinSkill     = require("actor/gameActorStatePlayerAssassinSkill") 
local gameActorStatePlayerAssassinSY        = require("actor/gameActorStatePlayerAssassinSY") 
local gameActorStatePlayerAssassinUnknown   = require("actor/gameActorStatePlayerAssassinUnknown") 
local gameActorStatePlayerAssassinXFT       = require("actor/gameActorStatePlayerAssassinXFT") 
local gameActorStatePlayerJY                = require("actor/gameActorStatePlayerJY") 
local gameActorStatePlayerJY2               = require("actor/gameActorStatePlayerJY2") 
local gameActorStatePlayerTSZ               = require("actor/gameActorStatePlayerTSZ") 
local gameActorStatePlayerXLFH              = require("actor/gameActorStatePlayerXLFH") 

local optionsUtils               = requireUtil("optionsUtils")

local walkOnly = SL:GetValue("GAME_DATA","gameOption_WalkOnly") == 1
local horseHair= SL:GetValue("GAME_DATA","horse_hair") == 1

local renderWeaponOrder = G_ActorUtils.PlayerWeaponRenderOrder
local playerRenderOrder = G_ActorUtils.PlayerRenderOrder

local mmo = global.MMO
local mapActAnim_WalkOnly = {
    [mmo.ACTION_IDLE]           = mmo.ANIM_IDLE,
    [mmo.ACTION_WALK]           = walkOnly and mmo.ANIM_RUN or mmo.ANIM_WALK,
    [mmo.ACTION_ATTACK]         = mmo.ANIM_ATTACK,
    [mmo.ACTION_SKILL]          = mmo.ANIM_SKILL,
    [mmo.ACTION_DIE]            = mmo.ANIM_DIE,
    [mmo.ACTION_RUN]            = mmo.ANIM_RUN,
    [mmo.ACTION_STUCK]          = mmo.ANIM_STUCK,
    [mmo.ACTION_READY]          = mmo.ANIM_READY,
    [mmo.ACTION_MINING]         = mmo.ANIM_MINING,
    [mmo.ACTION_SITDOWN]        = mmo.ANIM_SITDOWN,
    [mmo.ACTION_DEATH]          = mmo.ANIM_DEATH,
    [mmo.ACTION_TURN]           = mmo.ANIM_IDLE,
    [mmo.ACTION_RIDE_RUN]       = mmo.ANIM_RUN,
    [mmo.ACTION_DASH]           = mmo.ANIM_RUN,
    [mmo.ACTION_ONPUSH]         = mmo.ANIM_RUN,
    [mmo.ACTION_DASH_WAITING]   = mmo.ANIM_IDLE,
    [mmo.ACTION_TELEPORT]       = mmo.ANIM_IDLE,
    [mmo.ACTION_IDLE_LOCK]      = mmo.ANIM_IDLE,
    [mmo.ACTION_YTPD]           = mmo.ANIM_YTPD,
    [mmo.ACTION_ZXC]            = mmo.ANIM_ZXC,
    [mmo.ACTION_SJS]            = mmo.ANIM_SJS,
    [mmo.ACTION_DYZ]            = mmo.ANIM_DYZ,
    [mmo.ACTION_HSQJ]           = mmo.ANIM_HSQJ,
    [mmo.ACTION_FWJ]            = mmo.ANIM_FWJ,
    [mmo.ACTION_JLB]            = mmo.ANIM_JLB,
    [mmo.ACTION_BTXD]           = mmo.ANIM_BTXD,
    [mmo.ACTION_SLP]            = mmo.ANIM_SLP,
    [mmo.ACTION_HXJ]            = mmo.ANIM_HXJ,
    [mmo.ACTION_BGZ]            = mmo.ANIM_BGZ,
    [mmo.ACTION_SYZ]            = mmo.ANIM_SYZ,
    [mmo.ACTION_WJGZ]           = mmo.ANIM_WJGZ,
    [mmo.ACTION_DASH_FAIL]      = mmo.ANIM_RUN,
    [mmo.ACTION_SBYS]           = mmo.ANIM_IDLE,
    [mmo.ACTION_ASSASSIN_RUN]     = mmo.ANIM_ASSASSIN_RUN,      -- 刺客跑步
	[mmo.ACTION_ASSASSIN_SNEAK]   = mmo.ANIM_ASSASSIN_SNEAK,    -- 刺客潜行
	[mmo.ACTION_ASSASSIN_SMITE]   = mmo.ANIM_ASSASSIN_SMITE,    -- 刺客重击
	[mmo.ACTION_ASSASSIN_SKILL]   = mmo.ANIM_ASSASSIN_SKILL,    -- 刺客施法
	[mmo.ACTION_ASSASSIN_SY]      = mmo.ANIM_ASSASSIN_SY,       -- 刺客霜月
	[mmo.ACTION_ASSASSIN_UNKNOWN] = mmo.ANIM_ASSASSIN_UNKNOWN,  -- 刺客未知动作 
	[mmo.ACTION_ASSASSIN_XFT]     = mmo.ANIM_ASSASSIN_XFT,      -- 旋风腿
	[mmo.ACTION_JY]               = mmo.ANIM_JY,                -- 箭雨1
	[mmo.ACTION_JY2]              = mmo.ANIM_JY2,               -- 箭雨2
	[mmo.ACTION_TSZ]              = mmo.ANIM_TSZ,               -- 推山掌
	[mmo.ACTION_XLFH]             = mmo.ANIM_XLFH,              -- 降龙伏虎
}
local mapActAnim = {
    [mmo.ACTION_IDLE]           = mmo.ANIM_IDLE,
    [mmo.ACTION_WALK]           = mmo.ANIM_WALK,
    [mmo.ACTION_ATTACK]         = mmo.ANIM_ATTACK,
    [mmo.ACTION_SKILL]          = mmo.ANIM_SKILL,
    [mmo.ACTION_DIE]            = mmo.ANIM_DIE,
    [mmo.ACTION_RUN]            = mmo.ANIM_RUN,
    [mmo.ACTION_STUCK]          = mmo.ANIM_STUCK,
    [mmo.ACTION_READY]          = mmo.ANIM_READY,
    [mmo.ACTION_MINING]         = mmo.ANIM_MINING,
    [mmo.ACTION_SITDOWN]        = mmo.ANIM_SITDOWN,
    [mmo.ACTION_DEATH]          = mmo.ANIM_DEATH,
    [mmo.ACTION_TURN]           = mmo.ANIM_IDLE,
    [mmo.ACTION_RIDE_RUN]       = mmo.ANIM_RUN,
    [mmo.ACTION_DASH]           = mmo.ANIM_RUN,
    [mmo.ACTION_ONPUSH]         = mmo.ANIM_RUN,
    [mmo.ACTION_DASH_WAITING]   = mmo.ANIM_IDLE,
    [mmo.ACTION_TELEPORT]       = mmo.ANIM_IDLE,
    [mmo.ACTION_IDLE_LOCK]      = mmo.ANIM_IDLE,
    [mmo.ACTION_YTPD]           = mmo.ANIM_YTPD,
    [mmo.ACTION_ZXC]            = mmo.ANIM_ZXC,
    [mmo.ACTION_SJS]            = mmo.ANIM_SJS,
    [mmo.ACTION_DYZ]            = mmo.ANIM_DYZ,
    [mmo.ACTION_HSQJ]           = mmo.ANIM_HSQJ,
    [mmo.ACTION_FWJ]            = mmo.ANIM_FWJ,
    [mmo.ACTION_JLB]            = mmo.ANIM_JLB,
    [mmo.ACTION_BTXD]           = mmo.ANIM_BTXD,
    [mmo.ACTION_SLP]            = mmo.ANIM_SLP,
    [mmo.ACTION_HXJ]            = mmo.ANIM_HXJ,
    [mmo.ACTION_BGZ]            = mmo.ANIM_BGZ,
    [mmo.ACTION_SYZ]            = mmo.ANIM_SYZ,
    [mmo.ACTION_WJGZ]           = mmo.ANIM_WJGZ,
    [mmo.ACTION_DASH_FAIL]      = mmo.ANIM_RUN,
    [mmo.ACTION_SBYS]           = mmo.ANIM_IDLE,
    [mmo.ACTION_ASSASSIN_RUN]     = mmo.ANIM_ASSASSIN_RUN,      -- 刺客跑步
	[mmo.ACTION_ASSASSIN_SNEAK]   = mmo.ANIM_ASSASSIN_SNEAK,    -- 刺客潜行
	[mmo.ACTION_ASSASSIN_SMITE]   = mmo.ANIM_ASSASSIN_SMITE,    -- 刺客重击
	[mmo.ACTION_ASSASSIN_SKILL]   = mmo.ANIM_ASSASSIN_SKILL,    -- 刺客施法
	[mmo.ACTION_ASSASSIN_SY]      = mmo.ANIM_ASSASSIN_SY,       -- 刺客霜月
	[mmo.ACTION_ASSASSIN_UNKNOWN] = mmo.ANIM_ASSASSIN_UNKNOWN,  -- 刺客未知动作 
	[mmo.ACTION_ASSASSIN_XFT]     = mmo.ANIM_ASSASSIN_XFT,      -- 旋风腿
	[mmo.ACTION_JY]               = mmo.ANIM_JY,                -- 箭雨1
	[mmo.ACTION_JY2]              = mmo.ANIM_JY2,               -- 箭雨2
	[mmo.ACTION_TSZ]              = mmo.ANIM_TSZ,               -- 推山掌
	[mmo.ACTION_XLFH]             = mmo.ANIM_XLFH,              -- 降龙伏虎
}

local featureMapActAnic = {
    [mmo.P_F_MONSTER_EFF] = {
        [mmo.ANIM_IDLE]         = mmo.ANIM_RIDE_IDLE,
        [mmo.ANIM_WALK]         = mmo.ANIM_RIDE_WALK,
        [mmo.ANIM_RUN]          = mmo.ANIM_RIDE_RUN,
        [mmo.ANIM_DIE]          = mmo.ANIM_RIDE_DIE,
        [mmo.ACTION_ATTACK]     = mmo.ANIM_RIDE_IDLE,
        [mmo.ACTION_SKILL]      = mmo.ANIM_RIDE_IDLE,
    },
    [mmo.P_F_HAIR] = {
        [mmo.ANIM_IDLE]         = mmo.ANIM_RIDE_IDLE,
        [mmo.ANIM_WALK]         = mmo.ANIM_RIDE_WALK,
        [mmo.ANIM_RUN]          = mmo.ANIM_RIDE_RUN,
        [mmo.ANIM_DIE]          = mmo.ANIM_RIDE_DIE,
        [mmo.ANIM_ATTACK]       = mmo.ANIM_RIDE_IDLE,
        [mmo.ANIM_SKILL]        = mmo.ANIM_RIDE_IDLE,
    }
}

local actSpeedFunc = {
    [mmo.ANIM_IDLE]             =   function (_this)
                                        return 1, false
                                    end,
    [mmo.ANIM_WALK]             =   function (_this)
                                        return _this:GetWalkSpeed()
                                    end,
    [mmo.ANIM_ASSASSIN_SNEAK]   =   function (_this)
                                        return _this:GetWalkSpeed()
                                    end,
    [mmo.ANIM_RUN]              =   function (_this)
                                        local runOneSpeed = _this:GetValueByKey(mmo.IS_RUN_ONE) and 2 or 1
                                        return (walkOnly and runOneSpeed == 1 and not (_this:IsHumanoid() or _this:IsHero())) and _this:GetWalkSpeed() / 2 or _this:GetRunSpeed() / runOneSpeed, ((not walkOnly and runOneSpeed == 1) or (_this:IsHumanoid() or _this:IsHero()))
                                    end,
    [mmo.ANIM_ASSASSIN_RUN]    =    function (_this)
                                        local runOneSpeed = _this:GetValueByKey(mmo.IS_RUN_ONE) and 2 or 1
                                        return (walkOnly and runOneSpeed == 1 and not (_this:IsHumanoid() or _this:IsHero())) and _this:GetWalkSpeed() / 2 or _this:GetRunSpeed() / runOneSpeed, ((not walkOnly and runOneSpeed == 1) or (_this:IsHumanoid() or _this:IsHero()))
                                    end,
    [mmo.ANIM_ATTACK]           = gameActorPlayer.GetAttackAnimSpeed,
    [mmo.ANIM_SKILL]            = gameActorPlayer.GetMagicAnimSpeed,
    [mmo.ANIM_MINING]           = gameActorPlayer.GetAttackAnimSpeed,
    [mmo.ANIM_YTPD]             = gameActorPlayer.GetMagicAnimSpeed,
    [mmo.ANIM_ZXC]              = gameActorPlayer.GetAttackAnimSpeed,
    [mmo.ANIM_SJS]              = gameActorPlayer.GetAttackAnimSpeed,
    [mmo.ANIM_DYZ]              = gameActorPlayer.GetAttackAnimSpeed,
    [mmo.ANIM_HSQJ]             = gameActorPlayer.GetAttackAnimSpeed,
    [mmo.ANIM_FWJ]              = gameActorPlayer.GetMagicAnimSpeed,
    [mmo.ANIM_JLB]              = gameActorPlayer.GetMagicAnimSpeed,
    [mmo.ANIM_BTXD]             = gameActorPlayer.GetMagicAnimSpeed,
    [mmo.ANIM_SLP]              = gameActorPlayer.GetMagicAnimSpeed,
    [mmo.ANIM_HXJ]              = gameActorPlayer.GetMagicAnimSpeed,
    [mmo.ANIM_BGZ]              = gameActorPlayer.GetMagicAnimSpeed,
    [mmo.ANIM_SYZ]              = gameActorPlayer.GetMagicAnimSpeed,
    [mmo.ANIM_WJGZ]             = gameActorPlayer.GetMagicAnimSpeed,
    [mmo.ANIM_SITDOWN]          = gameActorPlayer.GetAttackAnimSpeed,
    [mmo.ANIM_ASSASSIN_SMITE]   = gameActorPlayer.GetAttackAnimSpeed,  -- 刺客重击
    [mmo.ANIM_ASSASSIN_SKILL]   = gameActorPlayer.GetAttackAnimSpeed,  -- 刺客施法
    [mmo.ANIM_ASSASSIN_SY]      = gameActorPlayer.GetAttackAnimSpeed,  -- 刺客霜月
    [mmo.ANIM_ASSASSIN_UNKNOWN] = gameActorPlayer.GetAttackAnimSpeed,  -- 刺客未知动作 
    [mmo.ANIM_ASSASSIN_XFT]     = gameActorPlayer.GetAttackAnimSpeed,  -- 旋风腿
    [mmo.ANIM_JY]               = gameActorPlayer.GetMagicAnimSpeed,   -- 箭雨1
    [mmo.ANIM_JY2]              = gameActorPlayer.GetMagicAnimSpeed,   -- 箭雨2
    [mmo.ANIM_TSZ]              = gameActorPlayer.GetAttackAnimSpeed,  -- 推山掌
    [mmo.ANIM_XLFH]             = gameActorPlayer.GetAttackAnimSpeed,  -- 降龙伏虎
}


local mFeatureFunc = {
    [mmo.P_F_CLOTH]           = function (_this, appearID) _this:UpdateCloth(appearID)            end,
    [mmo.P_F_WEAPON]          = function (_this, appearID) _this:UpdateWeapon(appearID)           end,
    [mmo.P_F_SHIELD]          = function (_this, appearID) _this:UpdateShield(appearID)           end,
    [mmo.P_F_WINGS]           = function (_this, appearID) _this:UpdateWings(appearID)            end,
    [mmo.P_F_HAIR]            = function (_this, appearID) _this:UpdateHair(appearID == 9999 and _this.mHiarID or appearID) end,
    [mmo.P_F_MONSTER]         = function (_this, appearID) _this:UpdateMonster(appearID)          end,
    [mmo.P_F_WEAPON_EFF]      = function (_this, appearID) _this:UpdateWeaponEffect(appearID)     end,
    [mmo.P_F_MONSTER_EFF]     = function (_this, appearID) _this:UpdateMonsterEffect(appearID)    end,
    [mmo.P_F_MONSTER_CLOTH]   = function (_this, appearID) _this:UpdateMonsterCloth(appearID)     end,

    [mmo.P_F_SHIELD_EFF]      = function (_this, appearID) _this:UpdateShieldEffect(appearID)     end,
    [mmo.P_F_LEFT_WEAPON]     = function (_this, appearID) _this:UpdateLeftWeapon(appearID)       end,
    [mmo.P_F_LEFT_WEAPON_EFF] = function (_this, appearID) _this:UpdateLeftWeaponEffect(appearID) end
}

local shareT1 = {offset = cc.p(0, mmo.PLAYER_AVATAR_OFFSET.y)}

local isStateInited = false
local actState      = {}
function gameActorPlayer:getPlayerActionState(act)
    if act > mmo.ACTION_MAX then
        return nil
    end

    if not isStateInited  then
        actState[mmo.ACTION_IDLE]            = gameActorStatePlayerIdle.new()
        actState[mmo.ACTION_WALK]            = gameActorStatePlayerWalk.new()
        actState[mmo.ACTION_RUN]             = gameActorStatePlayerRun.new()
        actState[mmo.ACTION_ATTACK]          = gameActorStatePlayerAttack.new()
        actState[mmo.ACTION_SKILL]           = gameActorStatePlayerSkill.new()
        actState[mmo.ACTION_DIE]             = gameActorStatePlayerDie.new()
        actState[mmo.ACTION_STUCK]           = gameActorStatePlayerStuck.new()
        actState[mmo.ACTION_READY]           = gameActorStatePlayerReady.new()
        actState[mmo.ACTION_MINING]          = gameActorStatePlayerMining.new()
        actState[mmo.ACTION_SITDOWN]         = gameActorStatePlayerSitdown.new()
        actState[mmo.ACTION_DEATH]           = gameActorStatePlayerDie.new()
        actState[mmo.ACTION_TURN]            = gameActorStatePlayerTurn.new()
        actState[mmo.ACTION_RIDE_RUN]        = gameActorStatePlayerRideRun.new()
        actState[mmo.ACTION_DASH]            = gameActorStatePlayerDash.new()
        actState[mmo.ACTION_ONPUSH]          = gameActorStatePlayerOnPush.new()
        actState[mmo.ACTION_DASH_WAITING]    = gameActorStatePlayerDashWaiting.new()
        actState[mmo.ACTION_TELEPORT]        = gameActorStatePlayerTeleport.new()
        actState[mmo.ACTION_IDLE_LOCK]       = gameActorStatePlayerIdleLock.new()
        actState[mmo.ACTION_YTPD]            = gameActorStatePlayerYTPD.new()
        actState[mmo.ACTION_ZXC]             = gameActorStatePlayerZXC.new()
        actState[mmo.ACTION_SJS]             = gameActorStatePlayerSJS.new()
        actState[mmo.ACTION_DYZ]             = gameActorStatePlayerDYZ.new()
        actState[mmo.ACTION_HSQJ]            = gameActorStatePlayerHSQJ.new()
        actState[mmo.ACTION_FWJ]             = gameActorStatePlayerFWJ.new()
        actState[mmo.ACTION_JLB]             = gameActorStatePlayerJLB.new()
        actState[mmo.ACTION_BTXD]            = gameActorStatePlayerBTXD.new()
        actState[mmo.ACTION_SLP]             = gameActorStatePlayerSLP.new()
        actState[mmo.ACTION_HXJ]             = gameActorStatePlayerHXJ.new()
        actState[mmo.ACTION_BGZ]             = gameActorStatePlayerBGZ.new()
        actState[mmo.ACTION_SYZ]             = gameActorStatePlayerSYZ.new()
        actState[mmo.ACTION_WJGZ]            = gameActorStatePlayerWJGZ.new()
        actState[mmo.ACTION_DASH_FAIL]       = gameActorStatePlayerDashFail.new()
        actState[mmo.ACTION_SBYS]            = gameActorStatePlayerSBYS.new()
        actState[mmo.ACTION_ASSASSIN_RUN]     = gameActorStatePlayerAssassinRun.new()      -- 刺客跑步
        actState[mmo.ACTION_ASSASSIN_SNEAK]   = gameActorStatePlayerAssassinSneak.new()    -- 刺客潜行
        actState[mmo.ACTION_ASSASSIN_SMITE]   = gameActorStatePlayerAssassinSmite.new()    -- 刺客重击
        actState[mmo.ACTION_ASSASSIN_SKILL]   = gameActorStatePlayerAssassinSkill.new()    -- 刺客施法
        actState[mmo.ACTION_ASSASSIN_SY]      = gameActorStatePlayerAssassinSY.new()       -- 刺客霜月
        actState[mmo.ACTION_ASSASSIN_UNKNOWN] = gameActorStatePlayerAssassinUnknown.new()  -- 刺客未知动作 
        actState[mmo.ACTION_ASSASSIN_XFT]     = gameActorStatePlayerAssassinXFT.new()      -- 旋风腿
        actState[mmo.ACTION_JY]               = gameActorStatePlayerJY.new()               -- 箭雨1
        actState[mmo.ACTION_JY2]              = gameActorStatePlayerJY2.new()              -- 箭雨2
        actState[mmo.ACTION_TSZ]              = gameActorStatePlayerTSZ.new()              -- 推山掌
        actState[mmo.ACTION_XLFH]             = gameActorStatePlayerXLFH.new()             -- 降龙伏虎

        isStateInited = true
    end

    return actState[act]
end

function gameActorPlayer:CheckAndCreateAvatarNode(avatar, tag)
    local node = avatar:getChildByTag(tag)
    if not node then
        node = cc.Node:create()
        node:setCascadeColorEnabled(true)
        node:setCascadeOpacityEnabled(true)
        avatar:addChild(node, 0, tag)
    end

    return node
end

function gameActorPlayer:GetAvatarChildNodeByTag(tag)
    if self.mCurrAvatarNode and tag then
        return self.mCurrAvatarNode:getChildByTag(tag)
    end
    return nil
end

function gameActorPlayer:SetAvatarChildNodeVisible(value)
    for tag = mmo.PLAYER_BODY_TAG, mmo.PLAYER_LEFT_WEAPON_EFF_TAG do
        local node = self:GetAvatarChildNodeByTag(tag)
        if node then
            node:setVisible(value)
        end
    end
end

function gameActorPlayer:ctor()
    gameActorPlayer.super.ctor(self)
end

function gameActorPlayer:init()
    gameActorPlayer.super.init(self)

    self.mCurrentState  = self:getPlayerActionState(self.mAction)
    self.mActionHandler = nil
    self.mCurrentActT   = 0
    self.mDashWaiting   = false         -- 野蛮等待
    self.mOnPushIdleT   = 0             -- 被野蛮等待时间

    self.mAnimPrepare       = 0.0
    
    self.mOriginPositionX   = 0.0
    self.mOriginPositionY   = 0.0

    self.mMoveOrientX       = 0.0
    self.mMoveOrientY       = 0.0

    self.mTargePosX         = 0.0
    self.mTargePosY         = 0.0

    self.mDistanceToTarget  = 0.0

    self.mAnimAct                   = mmo.ANIM_IDLE
    self.mIsAnimNeedToUpdate        = false
    self.mCurrAvatarNode            = nil
    self.mAnimationWeapon           = nil
    self.mAnimationShield           = nil
    self.mAnimationWings            = nil
    self.mAnimationHair             = nil
    self.mAnimationMonster          = nil
    self.mAnimationWeaponEff        = nil
    self.mAnimationShieldEffect     = nil
    self.mAnimationLeftWeapon       = nil
    self.mAnimationLeftWeaponEff    = nil
    self.mStopAnimFrameIndex        = nil
    self.mAnimationElapsed          = nil

    self.mFeatureDirty              = false
    self.mShowArrAppear             = {}
    self.mHUDUI                     = {}

    self.mSex                       = nil
    self.mJobID                     = nil

    self.mTeamState                 = nil
    self.mIsOffLine                 = nil
    self.mNearShow                  = nil
    self.mAttacked                  = false     -- 是否被攻击过   没被攻击过  刚刚进视野要是满血状态 2021-11-6 文华提的需求
    self.mMouleHorse                = nil       -- 坐骑状态区分（0：单人   1：双人  2：连体）

    self.mMoveEff                   = nil       -- 移动足迹特效
    self.mMoveEffSkip               = nil       -- 移动足迹特效跳过一步走
    self.mIsSkip                    = nil       -- 移动足迹特效 是否跳过一步（0：跳过 1：不跳过）

    self.mDearID                    = ""        -- 夫妻ID
    self.mSiTuID                    = nil       -- 师徒ID
    self.mHateID                    = nil       -- 仇恨
    self.mJoinNetData               = {}        -- 加入关系网信息

    self.mSettingColorID            = nil       -- 内挂设置的玩家颜色 （设置后任何都改变不了颜色
    self.mWaitMoveFrame             = nil       -- 等待移动帧 （非平滑模式待机到移动需要等到 固定移动帧 开始移动  连续移动不需要等待）
    self.mLastFrameAction           = 0         -- 上一帧的动作 
end

function gameActorPlayer:destory()
    gameActorPlayer.super.destory(self)
    
    -- remove hud
    global.HUDManager:RemoveActorAllHUD(self.mID)
end

function gameActorPlayer:Tick(dt)
    gameActorPlayer.super.Tick(self, dt)
    self.mLastFrameAction = self.mAction
    if not self.skipOneTick then
        self.mCurrentState:Tick(dt, self)
    else
        self.skipOneTick = nil
    end


    if self.mFeatureDirty then
        self.mFeatureDirty = false
        self:CheckFeature()
    end

    if self.mCampDirty then
        self.mCampDirty = false
        self:CheckOwnSidePlayerVisible()
    end

    if self.mIsAnimNeedToUpdate then
        self:UpdateAnimation()
        self.mIsAnimNeedToUpdate = false
    end
end

function gameActorPlayer:setPosition(x, y)
    gameActorPlayer.super.setPosition(self, x, y)

    -- refresh zOrder
    if self.mAction == mmo.ACTION_DIE then
        self:GetNode():setLocalZOrder(-(y) + self:GetAdditionZorder() + mmo.DieAddZorder)
    else
        self:GetNode():setLocalZOrder(-(y) + self:GetAdditionZorder())
    end

    -- update hud pos
    local hudTop = self:GetHUDTop()
    global.HUDManager:setPosition(self.mID, x, y + hudTop)

    -- update buff pos
    global.BuffManager:setPosition(self.mID, x, y)
    global.ActorEffectManager:setPosition(self.mID, x, y)

    --update light pos
    if self.mLight then 
        shareT1.x = x
        shareT1.y = y
        global.darkNodeManager:updateNode(self.mLight, shareT1)
    end
end

function gameActorPlayer:SetMoveTo(posX, posY)
    self.mMoveTo.x = posX
    self.mMoveTo.y = posY
end

function gameActorPlayer:SetAction(newAction, isTerminate, notSkipOneTick)
    if not isTerminate then isTerminate = false end

    local stateNew  = self:getPlayerActionState(newAction)
    local stateOld  = self.mCurrentState
    local oldAction = self.mAction
    -- print("SetAction:",newAction)
    if self.mCurrentState:ChangeState(stateNew, self, isTerminate) then    
        if 0 ~= stateOld then
            stateOld:OnExit(self)
        end
        -- print("old:",stateOld:GetStateID())
        self.mWaitMoveFrame = G_ActorUtils.IsMoveAction(self.mLastFrameAction) ~= 1
        self.mAction = newAction    

        if 0 ~= stateNew then
            stateNew:OnEnter(self)
        end

        if (isTerminate or oldAction ~= newAction) and self:GetAnimPrepare() <= 0.0 then
            local actAnim = (walkOnly and not (self:IsHumanoid() or self:IsHero())) and mapActAnim_WalkOnly[newAction] or mapActAnim[newAction]
            self:SetAnimAct(actAnim)

            -- 
            if stateNew ~= mmo.ACTION_IDLE and not notSkipOneTick then
                self.skipOneTick = true
            end
        end
    end
end

function gameActorPlayer:SetAnimAct(newAnim)
    if self.mAnimAct ~= newAnim then
        self.mAnimAct = newAnim

        -- in die anim, zOrder is lowest
        if newAnim == mmo.ANIM_DIE then
            self:GetNode():setLocalZOrder(-self:getPositionY() + self:GetAdditionZorder() + mmo.DieAddZorder)
        end
    end
end

function gameActorPlayer:RefHPHUD()
    local HP    = self:GetHP()
    local maxHP = self:GetMaxHP()
    local preHp = self:GetLastCurAbilByID(GUIDefine.AttTypeTable.HP)

    self:SetKeyValue(mmo.HUD_Hp_Full, HP >= maxHP and maxHP > 0)
    self:SetKeyValue(mmo.HUD_Hp_Null, HP < 1 or maxHP < 1)
    
    local bar = self.mHUDUI[mmo.HUDHPUI_BAR]
    if not bar then
        return false
    end

    if preHp > HP then
        self:SetKeyValue(mmo.HUD_BAR_SHOW_FULL_HP, true)
    end

    local hpPerc = nil
    if ActorHud.GetHUDHPBarPer then
        hpPerc = ActorHud.GetHUDHPBarPer(self:GetID())
    end
    if not hpPerc then
        hpPerc = HP / maxHP
        if global.ConstantConfig.showFewHp == 1 and not self:GetValueByKey(mmo.HUD_BAR_SHOW_FULL_HP) then
            local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
            local heroActor  = HeroPropertyProxy:GetHeroActor()
            local mainPlayer = global.gamePlayerController:GetMainPlayer()
            if self ~= heroActor and self ~= mainPlayer then 
                hpPerc = 1
            end
        end
    end

    global.HUDManager:SetHUDBarPercent(bar, hpPerc)

    optionsUtils:InitHUDVisibleValue(self, mmo.HUD_HPBAR_VISIBLE)
    optionsUtils:InitHUDVisibleValue(self, mmo.HUD_HMPLabel_VISIBLE)
    optionsUtils:CheckHUDHpBarVisible(self)

    global.HUDHPManager:Update(self)
end

function gameActorPlayer:RefMPHUD()
    local MP    = self:GetMP()
    local maxMP = self:GetMaxMP()

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

function gameActorPlayer:RefNGHUD()
    local force    = self:GetInternal()
    local maxForce = self:GetMaxInternal()

    -- if maxForce < 1 then
    --     return false
    -- end

    if not self.mHUDUI[mmo.HUDNGUI_BAR] then
        return
    end

    local bar = self.mHUDUI[mmo.HUDNGUI_BAR]
    local percent = maxForce == 0 and 0 or (force / maxForce)
    if ActorHud.GetHUDNGBarPer then
        percent = ActorHud.GetHUDNGBarPer(self:GetID()) or percent
    end
    global.HUDManager:SetHUDBarPercent(bar, percent)

    optionsUtils:InitHUDVisibleValue(self, mmo.HUD_NGBAR_VISIBLE)
    optionsUtils:CheckHUDNGBarVisible(self)
end

function gameActorPlayer:GetHP() 
    return self:GetCurAbilByID(GUIDefine.AttTypeTable.HP)
end
function gameActorPlayer:GetMaxHP()
    return self:GetMaxAbilByID(GUIDefine.AttTypeTable.HP)
end

function gameActorPlayer:GetMP()
    return self:GetCurAbilByID(GUIDefine.AttTypeTable.MP)
end
function gameActorPlayer:GetMaxMP()
	return self:GetMaxAbilByID(GUIDefine.AttTypeTable.MP)
end

function gameActorPlayer:GetInternal()
    return self:GetCurAbilByID(GUIDefine.AttTypeTable.Internal_Value)
end

function gameActorPlayer:GetMaxInternal()
	return self:GetMaxAbilByID(GUIDefine.AttTypeTable.Internal_Value)
end

function gameActorPlayer:InitParam()
    self.mCurrActorNode = cc.Node:create()

    -- avater    
    self.mCurrAvatarNode = cc.Node:create()
    self.mCurrActorNode:addChild(self.mCurrAvatarNode)
    self.mCurrAvatarNode:setTag(mmo.PLAYER_AVATAR_TAG)
    self.mCurrAvatarNode:setCascadeColorEnabled(true)
    self.mCurrAvatarNode:setCascadeOpacityEnabled(true)
    self.mCurrAvatarNode:setPosition(mmo.PLAYER_AVATAR_OFFSET)

    -- gm
    self.mCurrMountNode = cc.Node:create()
    self.mCurrActorNode:addChild(self.mCurrMountNode)
    self.mCurrMountNode:setTag(mmo.PLAYER_MOUNT_TAG)
    self.mCurrMountNode:setPosition(mmo.PLAYER_AVATAR_OFFSET)

    return 1
end

function gameActorPlayer:StopAnimToFrame(frameIndex)
    self.mStopAnimFrameIndex = frameIndex
end

function gameActorPlayer:StopAllAnimation(frameIndex)
    local isLastFrame = frameIndex==6
    if self.mAnimation then
        self.mAnimation:Stop(frameIndex, self.mAnimAct, self.mOrient, isLastFrame)
    end

    if self.mAnimationWeapon then
        self.mAnimationWeapon:Stop(frameIndex, self.mAnimAct, self.mOrientx, isLastFrame)
    end

    if self.mAnimationShield then
        self.mAnimationShield:Stop(frameIndex, self.mAnimAct, self.mOrient, isLastFrame)
    end

    if self.mAnimationWings then
        self.mAnimationWings:Stop(frameIndex, self.mAnimAct, self.mOrient, isLastFrame)
    end

    if self.mAnimationHair then
        self.mAnimationHair:Stop(frameIndex, self.mAnimAct, self.mOrient, isLastFrame)
    end
    
    if self.mAnimationMonster then
        self.mAnimationMonster:Stop(frameIndex, self.mAnimAct, self.mOrient, isLastFrame)
    end
    
    if self.mAnimationWeaponEff then
        self.mAnimationWeaponEff:Stop(frameIndex, self.mAnimAct, self.mOrient, isLastFrame)
    end

    if self.mAnimationShieldEffect then
        self.mAnimationShieldEffect:Stop(frameIndex, self.mAnimAct, self.mOrient, isLastFrame)
    end

    if self.mAnimationLeftWeapon then
        self.mAnimationLeftWeapon:Stop(frameIndex, self.mAnimAct, self.mOrientx, isLastFrame)
    end

    if self.mAnimationLeftWeaponEff then
        self.mAnimationLeftWeaponEff:Stop(frameIndex, self.mAnimAct, self.mOrientx, isLastFrame)
    end
end

local loops = {
    [mmo.ANIM_IDLE] = true,
    [mmo.ANIM_WALK] = true,
    [mmo.ANIM_RUN]  = true,
}

function gameActorPlayer:UpdateAnimation()
    local renderOrder      = playerRenderOrder[self.mAnimAct] or playerRenderOrder[mmo.ANIM_IDLE]
    local isLoop           = loops[self.mAnimAct]

    local showMonster      = self.mAnimationMonster ~= nil
    local notShowMonster   = not showMonster
    local showCloth        = notShowMonster
    local showWeapon       = notShowMonster
    local showShield       = notShowMonster
    local showWings        = notShowMonster
    local showHair         = notShowMonster
    local showMonsterCloth = showMonster

    local showMapActAnic = false
    if self:GetHorseMasterID() then
        showMapActAnic = true
        if self:IsDoubleHorse() or self:IsBodyHorse() then
            showMonsterCloth = false
        else
            showHair = horseHair
        end
    end

    local newOrient = self.mOrient
    local weaponID = self:GetAnimationWeaponID()

    local renderWeaponID = weaponID * 100 + self.mAnimAct
    if weaponID and renderWeaponOrder and renderWeaponOrder[renderWeaponID] and renderWeaponOrder[renderWeaponID][newOrient + 1] then
        renderOrder = renderWeaponOrder[renderWeaponID]
    end

    -- 计算速度
    local speed, needStop = 1, true
    local isSkipFrame = false
    if actSpeedFunc[self.mAnimAct] then
        --非平滑移动时，用主玩家的速度
        if G_ActorUtils.IsMoveAnim(self.mAnimAct) and not G_ActorUtils.IsSmoothMove() and not self:IsMainPlayer() then 
            speed, needStop, isSkipFrame = self:GetMainPlayerSpeedByAnim(self.mAnimAct)
        else
            speed, needStop = actSpeedFunc[self.mAnimAct](self)
        end
        if needStop == nil then
            needStop = true
        end
    end

    -- cloth
    self:AnimDisplay(self.mAnimation,               self.mAnimAct, showCloth, renderOrder[newOrient+1][2],  isLoop, speed, needStop, isSkipFrame)

    -- weapon
    self:AnimDisplay(self.mAnimationWeapon,         self.mAnimAct, showWeapon, renderOrder[newOrient+1][1], isLoop, speed, needStop, isSkipFrame)

    -- shield
    self:AnimDisplay(self.mAnimationShield,         self.mAnimAct, showShield, renderOrder[newOrient+1][4], isLoop, speed, needStop, isSkipFrame)

    -- wings
    self:AnimDisplay(self.mAnimationWings,          self.mAnimAct, showWings, renderOrder[newOrient+1][3],  isLoop, speed, needStop, isSkipFrame)

    -- hair
    self:AnimDisplay(self.mAnimationHair,           showMapActAnic and featureMapActAnic[mmo.P_F_HAIR][self.mAnimAct] or self.mAnimAct, showHair, renderOrder[newOrient+1][5], isLoop, speed, needStop, isSkipFrame)

    -- monster
    self:AnimDisplay(self.mAnimationMonster,        self.mAnimAct, showMonster, renderOrder[newOrient+1][2], isLoop, speed, needStop, isSkipFrame)

    --weaponEffect
    self:AnimDisplay(self.mAnimationWeaponEff,      self.mAnimAct, showWeapon, renderOrder[newOrient+1][1],  isLoop, speed, needStop, isSkipFrame)

    --monsterEffect
    self:AnimDisplay(self.mAnimationMonsterEff,     self.mAnimAct, showMonster, renderOrder[newOrient+1][2]+1, isLoop, speed, needStop, isSkipFrame)

    --moster cloth
    self:AnimDisplay(self.mAnimationMonsterCloth,   showMapActAnic and featureMapActAnic[mmo.P_F_MONSTER_EFF][self.mAnimAct] or self.mAnimAct, showMonsterCloth, renderOrder[newOrient+1][2], isLoop, speed, needStop, isSkipFrame)

    --shield effect
    self:AnimDisplay(self.mAnimationShieldEffect,   self.mAnimAct, showShield, renderOrder[newOrient+1][4], isLoop, speed, needStop, isSkipFrame)

    --left weapon
    self:AnimDisplay(self.mAnimationLeftWeapon,     self.mAnimAct, showWeapon, renderOrder[newOrient+1][6], isLoop, speed, needStop, isSkipFrame)

    --left weaponEffect
    self:AnimDisplay(self.mAnimationLeftWeaponEff,  self.mAnimAct, showWeapon, renderOrder[newOrient+1][6], isLoop, speed, needStop, isSkipFrame)


    -- stop
    if self.mStopAnimFrameIndex then
        self:StopAllAnimation(self.mStopAnimFrameIndex)
    end

    -- 
    global.Facade:sendNotification(global.NoticeTable.ActorBuffPresentUpdate, self:GetID())

    self.mAnimationElapsed = nil



    -- 同步经典模式移动时间
    if self:IsMainPlayer() then
        self:CalcFrameIntervalForUpdateMove()

        global.actorManager:SyncUpdateMoveTime()
    end
end

function gameActorPlayer:AnimDisplay(anim, act, show, order, isLoop, speed, needStop, isSkipFrame)
    if not anim then
        return false
    end

    anim:getParent():setLocalZOrder(order)
    anim:setVisible(show)

    if show then
        if needStop then
            anim:Stop()
        end

        anim:SyncElapsed(self.mAnimationElapsed)
        anim:Play(act, self.mOrient, isLoop, speed, true, isSkipFrame, self.mWaitMoveFrame)
    else
        anim:Stop()
    end
end

function gameActorPlayer:OnSequAnimLoadCompleted(animType, playerID)
    -- refresh HUD TOP
    if mmo.SFANIM_TYPE_PLAYER == animType then
        local player = global.actorManager:GetActor(playerID)
        if nil == player then
            return 
        end

        local posX = player:getPositionX()
        local posY = player:getPositionY()
        player:setPosition(posX, posY)
    end
end

function gameActorPlayer:IsCloaking()
    return (self.mCover[2] == true)
end

function gameActorPlayer:SetCloaking(isCloaking, index)
    -- 隐身术
    self.mCover[index] = isCloaking
    self:CalcCover()
end

function gameActorPlayer:CalcCover()
    local isInCover = false
    for k, v in pairs(self.mCover) do
        if v then
            isInCover = true
            break
        end
    end

    local opacityV = (isInCover) and 155 or 255 
    self.mCurrAvatarNode:setOpacity(opacityV)
end

local Sexs = {
    [mmo.SFANIM_TYPE_PLAYER]  = function (_this)
        return _this:GetValueByKey(mmo.BUFF_PLAYER_AVATAR_SEX) or _this:GetSexID()
    end,
    [mmo.SFANIM_TYPE_WEAPON]  = function (_this)
        return _this:GetSexID()
    end,
    [mmo.SFANIM_TYPE_SHIELD]  = function (_this)
        return GUIDefine.Sex.MALE
    end,
    [mmo.SFANIM_TYPE_WINGS]   = function (_this)
        return _this:GetSexID()
    end,
    [mmo.SFANIM_TYPE_HAIR]    = function (_this)
        return _this:GetSexID()
    end,
    [mmo.SFANIM_TYPE_MONSTER] = function (_this)
        return _this:GetValueByKey(mmo.HORSE_SEX)
    end
}

local ResetActorAnim = {
    [mmo.SFANIM_TYPE_PLAYER]  = function (_this, lastAnimID, ID, sex, act)
        return global.FrameAnimManager:ResetActorPlayerAnim(lastAnimID, ID, sex, act, function (_, __, animType) _this:OnSequAnimLoadCompleted(animType, _this:GetID()) end)
    end,
    [mmo.SFANIM_TYPE_WEAPON]  = function (_this, lastAnimID, ID, sex, act)
        return global.FrameAnimManager:ResetActorPlayerWeaponAnim(lastAnimID, ID, sex, act, function (_, __, animType) _this:OnSequAnimLoadCompleted(animType, _this:GetID()) end)
    end,
    [mmo.SFANIM_TYPE_SHIELD]  = function (_this, lastAnimID, ID, sex, act)
        return global.FrameAnimManager:ResetActorPlayerShieldAnim(lastAnimID, ID, sex, act, function (_, __, animType) _this:OnSequAnimLoadCompleted(animType, _this:GetID()) end)
    end,
    [mmo.SFANIM_TYPE_WINGS]   = function (_this, lastAnimID, ID, sex, act)
        return global.FrameAnimManager:ResetActorPlayerWingsAnim(lastAnimID, ID, sex, act, function (_, __, animType) _this:OnSequAnimLoadCompleted(animType, _this:GetID()) end)
    end,
    [mmo.SFANIM_TYPE_HAIR]    = function (_this, lastAnimID, ID, sex, act)
        return global.FrameAnimManager:ResetActorPlayerHairAnim(lastAnimID, ID, sex, act, function (_, __, animType) _this:OnSequAnimLoadCompleted(animType, _this:GetID()) end)
    end,
    [mmo.SFANIM_TYPE_MONSTER] = function (_this, lastAnimID, ID, sex, act)
        return global.FrameAnimManager:ResetActorMonsterAnim(lastAnimID, ID, act, function (_, __, animType) _this:OnSequAnimLoadCompleted(animType, _this:GetID()) end, sex)
    end
}

local CreateActorAnim = {
    [mmo.SFANIM_TYPE_PLAYER]  = function (_this, lastAnimID, ID, sex, act)
        return global.FrameAnimManager:CreateActorPlayerAnim(ID, sex, act, function (_, __, animType) _this:OnSequAnimLoadCompleted(animType, _this:GetID()) end)
    end,
    [mmo.SFANIM_TYPE_WEAPON]  = function (_this, lastAnimID, ID, sex, act)
        return global.FrameAnimManager:CreateActorPlayerWeaponAnim(ID, sex, act, function (_, __, animType) _this:OnSequAnimLoadCompleted(animType, _this:GetID()) end)
    end,
    [mmo.SFANIM_TYPE_SHIELD]  = function (_this, lastAnimID, ID, sex, act)
        return global.FrameAnimManager:CreateActorPlayerShieldAnim(ID, sex, act, function (_, __, animType) _this:OnSequAnimLoadCompleted(animType, _this:GetID()) end)
    end,
    [mmo.SFANIM_TYPE_WINGS]   = function (_this, lastAnimID, ID, sex, act)
        return global.FrameAnimManager:CreateActorPlayerWingsAnim(ID, sex, act, function (_, __, animType) _this:OnSequAnimLoadCompleted(animType, _this:GetID()) end)
    end,
    [mmo.SFANIM_TYPE_HAIR]    = function (_this, lastAnimID, ID, sex, act)
        return global.FrameAnimManager:CreateActorPlayerHairAnim(ID, sex, act, function (_, __, animType) _this:OnSequAnimLoadCompleted(animType, _this:GetID()) end)
    end,
    [mmo.SFANIM_TYPE_MONSTER] = function (_this, lastAnimID, ID, sex, act)
        return global.FrameAnimManager:CreateActorMonsterAnim(ID, act, function (_, __, animType) _this:OnSequAnimLoadCompleted(animType, _this:GetID()) end, sex)
    end
} 

function gameActorPlayer:CreateAnim(ID, animType, lastAnim, tag)
    local newAnim = nil
    if ID and ID > 0 then
        local anims = lastAnim and ResetActorAnim or CreateActorAnim
        newAnim = anims[animType] and anims[animType](self, lastAnim, ID, Sexs[animType](self), self.mAnimAct)
    end 

    if newAnim then
        newAnim:Stop()
    end

    if not lastAnim and newAnim then
        if nil == tag then
            tag = 0
        end
        local parentNode = self:CheckAndCreateAvatarNode(self.mCurrAvatarNode, tag)
        parentNode:addChild(newAnim, 0, tag)
    end

    if lastAnim and not newAnim then
        lastAnim:removeFromParent()
    end

    self:DirtyAnimFlag()

    return newAnim
end

function gameActorPlayer:UpdateCloth(ID)
    if 0 == ID then
        local jobData = SL:GetValue("GAME_DATA", "MultipleJobSetMap")[self:GetJobID()]
        local isOpenJob = jobData and jobData.isOpen
        ID =  isOpenJob and jobData.clothFeatureShowID or 9999
    end
    self.mAnimation = self:CreateAnim(ID, mmo.SFANIM_TYPE_PLAYER, self.mAnimation, mmo.PLAYER_BODY_TAG)
end

function gameActorPlayer:UpdateWeapon(ID)
    if ID == 9999 then
        ID = nil
    end
    self.mAnimationWeapon = self:CreateAnim(ID, mmo.SFANIM_TYPE_WEAPON, self.mAnimationWeapon, mmo.PLAYER_WEAPON_TAG)
end

function gameActorPlayer:UpdateLeftWeapon(ID)
    if ID == 9999 then
        ID = nil
    end
    self.mAnimationLeftWeapon = self:CreateAnim(ID, mmo.SFANIM_TYPE_WEAPON, self.mAnimationLeftWeapon, mmo.PLAYER_LEFT_WEAPON_TAG)
end  

function gameActorPlayer:UpdateShield(ID)
    if ID == 9999 then
        ID = nil
    end
    self.mAnimationShield = self:CreateAnim(ID, mmo.SFANIM_TYPE_SHIELD, self.mAnimationShield, mmo.PLAYER_SHIELD_TAG)
end

function gameActorPlayer:UpdateWings(ID)
    if ID == 9999 then
        ID = nil
    end
    self.mAnimationWings = self:CreateAnim(ID, mmo.SFANIM_TYPE_WINGS, self.mAnimationWings, mmo.PLAYER_WINGS_TAG)
end

function gameActorPlayer:UpdateHair(ID)
    if 0 == ID then
        ID = 9999
    end
    self.mAnimationHair = self:CreateAnim(ID, mmo.SFANIM_TYPE_HAIR, self.mAnimationHair, mmo.PLAYER_HAIR_TAG)
end

function gameActorPlayer:UpdateMonster(ID)
    local animType = self:GetValueByKey(mmo.BUFF_PLAYER_AVATAR_SEX) and mmo.SFANIM_TYPE_PLAYER or mmo.SFANIM_TYPE_MONSTER
    self.mAnimationMonster = self:CreateAnim(ID, animType, self.mAnimationMonster, mmo.PLAYER_MONSTER_TAG)
end

function gameActorPlayer:UpdateWeaponEffect(ID)
    if ID == 9999 then
        ID = nil
    end
    self.mAnimationWeaponEff = self:CreateAnim(ID, mmo.SFANIM_TYPE_WEAPON, self.mAnimationWeaponEff, mmo.PLAYER_WEAPON_EFF_TAG)
end

function gameActorPlayer:UpdateLeftWeaponEffect(ID)
    if ID == 9999 then
        ID = nil
    end
    self.mAnimationLeftWeaponEff = self:CreateAnim(ID, mmo.SFANIM_TYPE_WEAPON, self.mAnimationLeftWeaponEff, mmo.PLAYER_LEFT_WEAPON_EFF_TAG)
end

function gameActorPlayer:UpdateMonsterEffect(ID)
    self.mAnimationMonsterEff = self:CreateAnim(ID, mmo.SFANIM_TYPE_MONSTER, self.mAnimationMonsterEff, mmo.PLAYER_MONSTER_EFF_TAG)
end

function gameActorPlayer:UpdateMonsterCloth(ID)
    self.mAnimationMonsterCloth = self:CreateAnim(ID, mmo.SFANIM_TYPE_PLAYER, self.mAnimationMonsterCloth, mmo.PLAYER_MONSTER_CLOTH_TAG)
end

function gameActorPlayer:UpdateShieldEffect(ID)
    if ID == 9999 then
        ID = nil
    end
    self.mAnimationShieldEffect = self:CreateAnim(ID, mmo.SFANIM_TYPE_SHIELD, self.mAnimationShieldEffect, mmo.PLAYER_SHIELD_TAG)
end

function gameActorPlayer:DirtyFeature()
    self.mFeatureDirty = true
end

function gameActorPlayer:CheckFeature()
    self.mAnimationElapsed = self.mAnimation and self.mAnimation:GetElapsed() or nil
    local appearDirty = nil
    local needUpdate = false
    for i = 0, mmo.P_F_MAX - 1 do
        appearDirty = self:GetAppearDirtyByID(i)
        if appearDirty then
            local func = mFeatureFunc[i] 
            if func then
                func(self, self:GetFeatureByID(i))
            end
            self:SetAppearDirtyByID(i, false)
            needUpdate = true
        end
    end

    self.mAnimationElapsed = needUpdate == true and self.mAnimationElapsed or nil
end

function gameActorPlayer:GetType()
    return mmo.ACTOR_PLAYER
end

function gameActorPlayer:GetAnimationID()
    return self:GetFeatureByID(mmo.P_F_CLOTH)
end

function gameActorPlayer:GetAnimationWeapon()
    return self.mAnimationWeapon
end

function gameActorPlayer:GetAnimationWeaponID()
    return self:GetFeatureByID(mmo.P_F_WEAPON)
end

function gameActorPlayer:GetAnimationWeaponEff()
    return self.mAnimationWeaponEff
end

function gameActorPlayer:GetAnimationLeftWeapon()
    return self.mAnimationLeftWeapon
end
function gameActorPlayer:GetAnimationLeftWeaponID()
    return self:GetFeatureByID(mmo.P_F_LEFT_WEAPON)
end

function gameActorPlayer:GetAnimationLeftWeaponEff()
    return self.mAnimationLeftWeaponEff
end

function gameActorPlayer:GetAnimationShield()
    return self.mAnimationShield
end
function gameActorPlayer:GetAnimationShieldID()
    return self:GetFeatureByID(mmo.P_F_SHIELD)
end

function gameActorPlayer:GetAnimationShieldEff()
    return self.mAnimationShieldEffect
end

function gameActorPlayer:GetAnimationWings()
    return self.mAnimationWings
end
function gameActorPlayer:GetAnimationWingsID()
    return self:GetFeatureByID(mmo.P_F_WINGS)
end

function gameActorPlayer:GetAnimationMonster()
    return self.mAnimationMonster
end

function gameActorPlayer:GetAnimationHair()
    return self.mAnimationHair
end
function gameActorPlayer:GetAnimationHairID()
    return  self:GetFeatureByID(mmo.P_F_HAIR) 
end

function gameActorPlayer:GetAnimationMount()
    return nil
end

function gameActorPlayer:GetAnimAct()
    return self.mAnimAct
end

-- 前摇，暂不影响任何动作(仅仅为了表现)
function gameActorPlayer:GetAnimPrepare()
    return self.mAnimPrepare
end

function gameActorPlayer:SetAnimPrepare(t)
    self.mAnimPrepare = t
end

function gameActorPlayer:GetDashWaiting()
    return self.mDashWaiting
end

function gameActorPlayer:SetDashWaiting(b)
    self.mDashWaiting = b
end

function gameActorPlayer:IsStallStatus()
    return self:GetSellStatus() == 1
end

function gameActorPlayer:SetSellStatus(status)
    self.mSellStatus = status
end

function gameActorPlayer:GetSellStatus()
    return self.mSellStatus
end

function gameActorPlayer:SetStallName(name)
    self.mStallName = name
end

function gameActorPlayer:GetStallName()
    return self.mStallName
end

function gameActorPlayer:SetIsOffLine(state)
    self.mIsOffLine = state
end

function gameActorPlayer:GetIsOffLine()
    if self.mIsOffLine == nil then
        self.mIsOffLine = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_OFFLINE)
    end
    return self.mIsOffLine
end

function gameActorPlayer:SetGameActorActionHandler(handler)
    self.mActionHandler = handler
end

function gameActorPlayer:GetGameActorActionHandler()
    return self.mActionHandler
end

function gameActorPlayer:SetTeamState(state)
    self.mTeamState = state
end

function gameActorPlayer:GetTeamState()
    if not self.mTeamState then
        self.mTeamState = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_TEAMID)
    end
    return self.mTeamState
end

function gameActorPlayer:SetShowClothID(id)
    self.mShowArrAppear[mmo.P_F_CLOTH] = id
    self:SetAppearDirtyByID(mmo.P_F_CLOTH, true)
end

function gameActorPlayer:GetShowClothID()
    return self.mShowArrAppear[mmo.P_F_CLOTH]
end

function gameActorPlayer:SetShowWeaponID(id)
    self.mShowArrAppear[mmo.P_F_WEAPON] = id
    self:SetAppearDirtyByID(mmo.P_F_WEAPON, true)
end

function gameActorPlayer:GetShowWeaponID()
    return self.mShowArrAppear[mmo.P_F_WEAPON]
end

function gameActorPlayer:SetShowLeftWeaponID(id)
    self.mShowArrAppear[mmo.P_F_LEFT_WEAPON] = id
    self:SetAppearDirtyByID(mmo.P_F_LEFT_WEAPON, true)
end

function gameActorPlayer:GetShowLeftWeaponID()
    return self.mShowArrAppear[mmo.P_F_LEFT_WEAPON]
end

function gameActorPlayer:SetShowShieldID(id)
    self.mShowArrAppear[mmo.P_F_SHIELD] = id
    self:SetAppearDirtyByID(mmo.P_F_SHIELD, true)
end

function gameActorPlayer:GetShowShieldID()
    return self.mShowArrAppear[mmo.P_F_SHIELD]
end

function gameActorPlayer:SetShowWingsID(id)
    self.mShowArrAppear[mmo.P_F_WINGS] = id
    self:SetAppearDirtyByID(mmo.P_F_WINGS, true)
end

function gameActorPlayer:GetShowWingsID()
    return self.mShowArrAppear[mmo.P_F_WINGS] 
end

function gameActorPlayer:SetRealHairID(id)
    self.mHiarID = id
end

function gameActorPlayer:SetShowHairID(id)
    self.mShowArrAppear[mmo.P_F_HAIR] = id
    self:SetAppearDirtyByID(mmo.P_F_HAIR, true)
end

function gameActorPlayer:GetShowHairID()
    return self.mShowArrAppear[mmo.P_F_HAIR]
end


function gameActorPlayer:SetShowWeaponEffectID(id)
    self.mShowArrAppear[mmo.P_F_WEAPON_EFF] = id
    self:SetAppearDirtyByID(mmo.P_F_WEAPON_EFF, true)
end
function gameActorPlayer:GetShowWeaponEffectID()
    return self.mShowArrAppear[mmo.P_F_WEAPON_EFF] 
end

function gameActorPlayer:SetShowLeftWeaponEffectID(id)
    self.mShowArrAppear[mmo.P_F_LEFT_WEAPON_EFF] = id
    self:SetAppearDirtyByID(mmo.P_F_LEFT_WEAPON_EFF, true)
end

function gameActorPlayer:GetShowLeftWeaponEffectID()
    return self.mShowArrAppear[mmo.P_F_LEFT_WEAPON_EFF]
end

function gameActorPlayer:SetShowShieldEffectID(id)
    self.mShowArrAppear[mmo.P_F_SHIELD_EFF] = id
    self:SetAppearDirtyByID(mmo.P_F_SHIELD_EFF, true)
end

function gameActorPlayer:GetShowShieldEffectID()
    return self.mShowArrAppear[mmo.P_F_SHIELD_EFF]
end

function gameActorPlayer:SetSexID(sex)
    self.mSex = sex
end
function gameActorPlayer:GetSexID()
    if not self.mSex then
        self.mSex = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_SEX)
    end
    return self.mSex
end

function gameActorPlayer:GetJobID()
    if not self.mJobID then
        self.mJobID = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_JOB)
    end
    return self.mJobID or GUIDefine.Job.FIGHTER
end
function gameActorPlayer:SetJobID(job)
    self.mJobID = job
end

function gameActorPlayer:GetLevel()
    return self:GetCurAbilByID(GUIDefine.AttTypeTable.LEVEL)
end

function gameActorPlayer:GetCurrActTime()
    return self.mCurrentActT
end
function gameActorPlayer:SetCurrActTime(t)
    self.mCurrentActT = t
end

function gameActorPlayer:DirtyAnimFlag()
    self.mIsAnimNeedToUpdate = true
end

function gameActorPlayer:Bright()
    if not self.mIsBright then
        self.mIsBright = true

        local isInCover = false
        for k, v in pairs(self.mCover) do
            if v then
                isInCover = true
                break
            end
        end
        local actorAnim = self:GetAnimation()
        if isInCover then
            ShaderUtils.SetTypeShader(actorAnim, SLDefine.SHADER_TYPE.SHADER_TYPE_HIGHTLIGHT_COVER)
        else
            ShaderUtils.SetTypeShader(actorAnim, SLDefine.SHADER_TYPE.SHADER_TYPE_HIGHTLIGHT)
        end
    end
end

function gameActorPlayer:SetNearShow(state)
    self.mNearShow = state
end

function gameActorPlayer:IsNearShow()
    if not self.mNearShow then
        self.mNearShow = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_RANGECANFINDME)
    end
    return self.mNearShow == 1
end

-- 神秘人状态(戴斗笠)
function gameActorPlayer:SetShenMiRen(value)
    -- body
    self.mShenMiRen = value
end

function gameActorPlayer:IsShenMiRen()
    if self.mShenMiRen == nil then
        self.mShenMiRen = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_SHENMIREN)
    end
    return self.mShenMiRen
end

--护身
function gameActorPlayer:SetHuShen(value)
    -- body
    self.mHuShen = value
end
function gameActorPlayer:IsHuShen()
    -- body
    return self.mHuShen == 1
end

--受到攻击
function gameActorPlayer:SetDamage(value)
    -- body
    self.mDamage = value
end

function gameActorPlayer:IsDamage()
    -- body
    return self.mDamage
end


-- 设置国家id
function gameActorPlayer:SetNationID(id)
    self._nationID = id
end

function gameActorPlayer:GetNationID()
    if not self._nationID then
        self._nationID = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_NATIONID)
    end
    return self._nationID
end

function gameActorPlayer:GetHUDTop()
    if not self.mAnimation then
        return 20
    end
    return self.mAnimation:GetHUDTop() or 20
end

-- 获取主驾id
function gameActorPlayer:GetHorseMasterID()
    return self:GetValueByKey(mmo.HORSE_MAIN)
end

-- 获取副驾id
function gameActorPlayer:GetHorseCopilotID()
    return self:GetValueByKey(mmo.HORSE_COPILOT)
end


-- 是否是副驾
function gameActorPlayer:IsHoreseCopilot()
    return self:GetHorseCopilotID() == self:GetID()
end

-- 双人坐骑
function gameActorPlayer:SetDoubleHorse(value)
    self.mMouleHorse = value
end

-- 是否是双人坐骑
function gameActorPlayer:IsDoubleHorse()
    return self.mMouleHorse == 1
end

-- 是否是连体坐骑
function gameActorPlayer:IsBodyHorse()
    return self.mMouleHorse == 2
end

function gameActorPlayer:SetMoveEff(value)
    self.mMoveEff = value
end

function gameActorPlayer:GetMoveEff()
    if not self.mMoveEff then
        self.mMoveEff = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), mmo.ACTOR_BUFFER_ME)
    end
    return self.mMoveEff
end

function gameActorPlayer:IsMoveEff()
    return self:GetMoveEff() ~= 0 and self:GetMoveEff() ~= nil
end

function gameActorPlayer:SetMoveEffSkipWalk(value)
    self.mMoveEffSkip = value
end

function gameActorPlayer:GetMoveEffSkipWalk()
    return self.mMoveEffSkip
end

function gameActorPlayer:SetEffSkipWalkSwitch(value)
    self.mIsSkip = value
end

function gameActorPlayer:GetEffSkipWalkSwitch()
    return self.mIsSkip
end

function gameActorPlayer:SetDearID(value)
    self.mDearID = value
end

function gameActorPlayer:GetDearID()
    return self.mDearID
end

function gameActorPlayer:SetSiTuID(value)
    self.mSiTuID = value
end

function gameActorPlayer:GetSiTuID()
    return self.mSiTuID
end

function gameActorPlayer:GetHateID()
    return self.mHateID
end

function gameActorPlayer:SetHateID(id)
    self.mHateID = id
end

function gameActorPlayer:SetJoinNetData(data)
    self.mJoinNetData = data
end

function gameActorPlayer:GetJoinNetTypeData(type, idx)
    local key = GetJoinNetTypeIndex(type, idx)
    if not self.mJoinNetData[key] then
        self.mJoinNetData[key] = G_ActorUtils.GetBufferPropertyByID(self:GetBuffer(), global.MMO.ACTOR_BUFFER_NETID, type, idx)
    end
    return self.mJoinNetData[key]
end

function gameActorPlayer:GetOnPushIdleTime()
    return self.mOnPushIdleT
end

function gameActorPlayer:SetOnPushIdleTime(value)
    self.mOnPushIdleT = value
end

function gameActorPlayer:SetSettingColorID(id)
    self.mSettingColorID = id
end

function gameActorPlayer:GetSettingColorID()
    return self.mSettingColorID
end
---------------------------
function gameActorPlayer:CheckOwnSidePlayerVisible()
    if self:IsMainPlayer() then
        return
    end

    optionsUtils:UpdateOwnSidePlayerVisible(self)
end

-----------------------------------------------------------------------------
-- 老传奇移动效果，记录一些时间， 根据玩家动作: 走/跑，计算刷新位置时间，达到切动画帧时刷新位置的效果
-- 记录动画帧时间，用以控制非平滑移动刷新坐标，记录的是单帧时间
function gameActorPlayer:CalcFrameIntervalForUpdateMove()
    local action = self:GetAction()
    if action == global.MMO.ACTION_WALK 
    or action == global.MMO.ACTION_ASSASSIN_SNEAK then
        local baseTime = self:GetWalkStepTime()/global.ConstantConfig.PlayerWalkAnimFrameCount
        self.mUpdateMoveFrameInterval = baseTime/self:GetWalkSpeed()
    elseif action == global.MMO.ACTION_RUN 
    or action == global.MMO.ACTION_ASSASSIN_RUN
    or action == global.MMO.ACTION_RIDE_RUN then
        local baseTime = self:GetRunStepTime()/global.ConstantConfig.PlayerRunAnimFrameCount
        self.mUpdateMoveFrameInterval = baseTime/self:GetRunSpeed()
    else 
        local baseTime = self:GetRunStepTime()/global.ConstantConfig.PlayerRunAnimFrameCount
        self.mUpdateMoveFrameInterval = baseTime/self:GetRunSpeed()
    end
    -- print("self.mUpdateMoveFrameInterval:", self.mUpdateMoveFrameInterval, global.Director:getTotalFrames())
end

function gameActorPlayer:GetUpdateMoveFrameInterval()
    return self.mUpdateMoveFrameInterval
end

--非平滑使用的是主玩家的速度
function gameActorPlayer:GetMainPlayerSpeedByAction(action)
    local baseSpeed = 1
    if action == global.MMO.ACTION_WALK 
    or action == global.MMO.ACTION_ASSASSIN_SNEAK then
        local mainPlayer = global.gamePlayerController:GetMainPlayer()
        if mainPlayer then
            baseSpeed = mainPlayer:GetWalkSpeedByProperty()
        else 
            baseSpeed = self:GetWalkSpeedByProperty()
        end
    elseif action == global.MMO.ACTION_RUN 
    or action == global.MMO.ACTION_ASSASSIN_RUN
    or action == global.MMO.ACTION_RIDE_RUN then
        local mainPlayer = global.gamePlayerController:GetMainPlayer()
        if mainPlayer then
            baseSpeed = mainPlayer:GetRunSpeedByProperty()
        else
            baseSpeed = self:GetRunSpeedByProperty()
        end
    end
    --非平滑模式 加速为2倍
    local rate = 1
    if self:GetIsMoreFullSpeedup()
        or self:GetIsMoreSpeedRate()
        or self:GetIsFullSpeedup()
        or self:GetIsSpeedup() then
        rate = 2
    end

    local speed = baseSpeed * rate 
    return speed
end

--非平滑使用的是主玩家的速度
function gameActorPlayer:GetMainPlayerSpeedByAnim(anim)
    local baseSpeed = 1
    if anim == global.MMO.ANIM_WALK 
    or anim == global.MMO.ANIM_ASSASSIN_SNEAK then
        local mainPlayer = global.gamePlayerController:GetMainPlayer()
        if mainPlayer then
            baseSpeed = mainPlayer:GetWalkSpeedByProperty()
        else 
            baseSpeed = self:GetWalkSpeedByProperty()
        end
    elseif anim == global.MMO.ANIM_RUN 
    or anim == global.MMO.ANIM_ASSASSIN_RUN
    or anim == global.MMO.ANIM_RIDE_RUN then
        local mainPlayer = global.gamePlayerController:GetMainPlayer()
        if mainPlayer then
            baseSpeed = mainPlayer:GetRunSpeedByProperty()
        else
            baseSpeed = self:GetRunSpeedByProperty()
            
        end
    end
    --非平滑模式 加速为2倍 动画表现为跳帧
    local isSpeedUp = false 
    if self:GetIsMoreFullSpeedup()
        or self:GetIsMoreSpeedRate()
        or self:GetIsFullSpeedup()
        or self:GetIsSpeedup() then

        isSpeedUp = true
    end
    return baseSpeed, false, isSpeedUp
end
return gameActorPlayer
