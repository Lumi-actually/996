local actorManager = class("actorManager")
local gameActorPlayer = require("actor/gameActorPlayer")
local gameActorMonster = require("actor/gameActorMonster")
local gameActorNpc = require("actor/gameActorNpc")
local gameActorDropItem = require("actor/gameActorDropItem")
local gameActorEffect = require("actor/gameActorEffect")
local gameActorMonsterGate = require("actor/gameActorMonsterGate")
local gameActorMonsterWall = require("actor/gameActorMonsterWall")

local INVALID_MAP_POS = 0xFFFF
local EVENT_BEFORE_UPDATE = "director_before_update"
local EVENT_AFTER_UPDATE = "director_after_update"
local function addMapXYActorID(mapTab, actorID, mapX, mapY)
    if mapX == INVALID_MAP_POS and mapY == INVALID_MAP_POS then
        return
    end

    local XYKey = G_ActorUtils.KEY_MAP_XY(mapX, mapY)
    if not mapTab[XYKey] then
        mapTab[XYKey] = {}
    end
    mapTab[XYKey][actorID] = true
end

local function rmvMapXYActorID(mapTab, actorID, mapX, mapY)
    if mapX == INVALID_MAP_POS and mapY == INVALID_MAP_POS then
        return
    end
    local XYKey = G_ActorUtils.KEY_MAP_XY(mapX, mapY)
    if not mapTab[XYKey] then
        return
    end
    mapTab[XYKey][actorID] = nil
    if not next(mapTab[XYKey]) then
        mapTab[XYKey] = nil
    end
end

local function findAllActorByMapXY(mapTab, mapX, mapY)
    local actors = {}
    if mapX == INVALID_MAP_POS and mapY == INVALID_MAP_POS then
        return actors
    end
    local XYKey = G_ActorUtils.KEY_MAP_XY(mapX, mapY)
    if not mapTab[XYKey] then
        return actors
    end

    for k, v in pairs(mapTab[XYKey]) do
        local actor = global.actorManager:GetActor(k)
        if actor then
            actors[#actors + 1] = actor
        end
    end

    return actors
end

local function findAllActorIDByMapXY(mapTab, mapX, mapY)
    local actorIDs = {}
    if mapX == INVALID_MAP_POS and mapY == INVALID_MAP_POS then
        return actorIDs
    end
    local XYKey = G_ActorUtils.KEY_MAP_XY(mapX, mapY)
    if not mapTab[XYKey] then
        return actorIDs
    end

    for k, v in pairs(mapTab[XYKey]) do
        local actor = global.actorManager:GetActor(k)
        if actor then
            actorIDs[#actorIDs + 1] = actor:GetID()
        end
    end

    return actorIDs
end

local effectRootNodeZOrder = {0, 4, 1, 2, 3, -1, 5}

function actorManager:ctor()
    self.mActorIndexMap = {}
    self.mGameActorMap = {}
    self.mGameActorArr = {}
    self.mActorCount = 0

    self.mTicking = false

    self.mAddingActorCount = 0
    self.mAddingActorMap = {}
    self.mAddingActors = {}
    self.mAddingDirty = false

    self.mRmvingActorCount = 0
    self.mRmvingActors = {}
    self.mRmvingDirty = false

    self.mEffectRootNode = {}
    self.mNodeOfActorSprite = nil
    self.mNodeOfActorSpriteBehind = nil

    self.mMonsterMapXYActorID = {}
    self.mPlayerMapXYActorID = {}
    self.mNPCMapXYActorID = {}

    self.mCurrUpateMoveTime = 0
    self.mNextUpateMoveTime = 0
    self.mLockUpateMoveTime = 0.01
    self._beforeUpdateHandler = cc.EventListenerCustom:create(EVENT_BEFORE_UPDATE, handler(self, self.TickBefore))
    self._afterUpdateHandler = cc.EventListenerCustom:create(EVENT_AFTER_UPDATE, handler(self, self.TickAfter))
    global.EventDispatcher:addEventListenerWithFixedPriority(self._beforeUpdateHandler, 1)
    global.EventDispatcher:addEventListenerWithFixedPriority(self._afterUpdateHandler, 1)
end

function actorManager:destory()
    if self._beforeUpdateHandler then 
        global.EventDispatcher:removeEventListener(self._beforeUpdateHandler)
        self._beforeUpdateHandler = nil
    end
    if self._afterUpdateHandler then 
        global.EventDispatcher:removeEventListener(self._afterUpdateHandler)
        self._afterUpdateHandler = nil
    end
end

function actorManager:create()
    local _this = actorManager.new()
    return _this
end

function actorManager:GetActors()
    return self.mGameActorArr, self.mActorCount
end


function actorManager:IsUpdateMoveTime()
    return self.mCurrUpateMoveTime >= self.mNextUpateMoveTime
end

function actorManager:GetCurrUpateMoveTime()
    return self.mCurrUpateMoveTime
end

function actorManager:GetNextUpateMoveTime()
    return self.mNextUpateMoveTime
end

--下一次刷新位置的时间
function actorManager:GetNextMoveTime()
    if self.mNextUpateMoveTime >= self.mCurrUpateMoveTime then 
        return self.mNextUpateMoveTime 
    else 
        return self.mNextUpateMoveTime + self.mLockUpateMoveTime
    end
end

--距离下一次刷新位置的时间
function actorManager:GetNextMoveTimeDelay()
    if self.mNextUpateMoveTime >= self.mCurrUpateMoveTime then 
        return self.mNextUpateMoveTime -  self.mCurrUpateMoveTime
    else 
        return self.mNextUpateMoveTime + self.mLockUpateMoveTime - self.mCurrUpateMoveTime
    end
end

function actorManager:GetLockUpateMoveTime()
    return self.mLockUpateMoveTime
end

function actorManager:SyncUpdateMoveTime()
    -- 根据玩家动作: 走/跑，计算刷新位置时间，达到切动画帧时刷新位置的效果
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return
    end
    self.mLockUpateMoveTime = mainPlayer:GetUpdateMoveFrameInterval()
    -- print("SyncUpdateMoveTime", os.clock(),self.mCurrUpateMoveTime,self.mLockUpateMoveTime, global.Director:getTotalFrames())
end

function actorManager:Tick(dt)
    if self.mAddingDirty then
        for i = 1, self.mAddingActorCount do
            local d = self.mAddingActors[i]
            self:AddActor(d.actorID, d.actor)
        end

        self.mAddingDirty = false
        self.mAddingActorMap = {}
        self.mAddingActors = {}
        self.mAddingActorCount = 0
    end

    if self.mRmvingDirty then
        for i = 1, self.mRmvingActorCount do
            self:RemoveActor(self.mRmvingActors[i])
        end

        self.mRmvingDirty = false
        self.mRmvingActors = {}
        self.mRmvingActorCount = 0
    end

    self.mTicking = true
    local actor = nil
    for i = 1, self.mActorCount do
        actor = self.mGameActorArr[i]
        actor:Tick(dt)
    end
    self.mTicking = false
end

function actorManager:TickBefore()
    local dt = global.Director:getDeltaTime()
    self.mCurrUpateMoveTime = self.mCurrUpateMoveTime + dt
end

function actorManager:TickAfter()
    if self.mCurrUpateMoveTime >= self.mNextUpateMoveTime then
        self.mNextUpateMoveTime = self.mLockUpateMoveTime + self.mNextUpateMoveTime
    end
end

function actorManager:AddActor(actorID, actor)
    if not actorID then
        return false
    end

    if not actor then
        return false
    end

    if self.mTicking then
        self.mAddingDirty = true

        self.mAddingActorMap[actorID] = actor

        self.mAddingActorCount = self.mAddingActorCount + 1

        local n = self.mAddingActorCount

        self.mAddingActors[n] = {actor = actor, actorID = actorID}
    else
        self.mActorCount = self.mActorCount + 1

        local n = self.mActorCount

        self.mActorIndexMap[actorID] = n

        self.mGameActorArr[n] = actor

        self.mGameActorMap[actorID] = actor
    end
end

local actorNews = {
    [global.MMO.ACTOR_PLAYER] = function()
        return gameActorPlayer.new()
    end,
    [global.MMO.ACTOR_DROPITEM] = function()
        return gameActorDropItem.new()
    end,
    [global.MMO.ACTOR_NPC] = function()
        return gameActorNpc.new()
    end,
    [global.MMO.ACTOR_SEFFECT] = function()
        return gameActorEffect.new()
    end
}
local actorMonsterNews = {
    [900] = function()
        return gameActorMonsterGate.new()
    end,
    [901] = function()
        return gameActorMonsterWall.new()
    end,
    [902] = function()
        return gameActorMonsterWall.new()
    end,
    [903] = function()
        return gameActorMonsterWall.new()
    end,
    [904] = function()
        return gameActorMonsterWall.new()
    end,
    [905] = function()
        return gameActorMonsterWall.new()
    end,
    [906] = function()
        return gameActorMonsterWall.new()
    end,
    [-1] = function()
        return gameActorMonster.new()
    end
}
function actorManager:CreateActor(actorID, atype, params, isBehind, isFront)
    if self.mGameActorMap[actorID] then
        return false
    end

    local createFunc = nil
    if atype == global.MMO.ACTOR_MONSTER then
        createFunc = actorMonsterNews[params.clothID] or actorMonsterNews[-1]
    else
        createFunc = actorNews[atype]
    end

    local actor = createFunc()
    actor:init()
    actor:SetID(actorID)
    actor:InitParam(params)

    self:AddActor(actorID, actor)

    -- Add to Actor Sprite Node.
    if isBehind then
        self:AddActorSfxInBehind(actor, atype, params.type)
    elseif isFront then
        self:AddActorSfxInFront(actor, atype, params.sfxId or 0)
    else
        self:AddActorSfx(actor)
    end

    return actor
end

----------------------------------------------------------------------------
-- actor 后面
function actorManager:AddActorSfxInBehind(actor, type, effectType)
    if global.MMO.ACTOR_SEFFECT == type then
        if self.mEffectRootNode[effectType] then
            self.mEffectRootNode[effectType]:addChild(actor:GetNode())
        else
            self.mNodeOfActorSpriteBehind:addChild(actor:GetNode())
        end
    else
        self.mNodeOfActorSpriteBehind:addChild(actor:GetNode())
    end
end

-- actor 前面
function actorManager:AddActorSfxInFront(actor, type, order)
    local IsSfx = global.MMO.ACTOR_SEFFECT == type
    local zOrder = IsSfx and order or 0
    self.mNodeOfActorSpriteFront:addChild(actor:GetNode(), zOrder)
end

function actorManager:AddActorSfx(actor)
    self.mNodeOfActorSprite:addChild(actor:GetNode())
end

function actorManager:GetActor(actorID)
    return self.mGameActorMap[actorID] or self.mAddingActorMap[actorID]
end

function actorManager:GetActorNum()
    return self.mActorCount
end

function actorManager:RemoveActor(actorID)
    if not actorID then
        return false
    end

    local actor = self.mGameActorMap[actorID]

    if not actor then
        return false
    end

    if self.mTicking then
        self.mRmvingDirty = true

        self.mRmvingActorCount = self.mRmvingActorCount + 1

        local n = self.mRmvingActorCount

        self.mRmvingActors[n] = actorID
    else
        self:RmvMapXYActor(actor, actor:GetMapX(), actor:GetMapY())
        self:DestoryActor(actor)

        self.mGameActorMap[actorID] = nil

        -- remove index
        local index = self.mActorIndexMap[actorID]

        if index == self.mActorCount then
            self.mGameActorArr[index] = nil
        else
            -- last index --> index
            local lastActor = self.mGameActorArr[self.mActorCount]
            self.mGameActorArr[index] = lastActor
            self.mActorIndexMap[lastActor:GetID()] = index

            -- reset last value
            self.mGameActorArr[self.mActorCount] = nil
        end

        self.mActorIndexMap[actorID] = nil
        self.mActorCount = self.mActorCount - 1
    end
end

function actorManager:RemoveAllActor(excludeID)
    local excludeActor = nil
    if excludeID and excludeID ~= 0 then
        excludeActor = self.mGameActorMap[excludeID]
    end

    for i = 1, self.mActorCount do
        local actor = self.mGameActorArr[i]
        if actor and actor:GetID() ~= excludeID then
            self:RmvMapXYActor(actor, actor:GetMapX(), actor:GetMapY())
            self:DestoryActor(actor)
        end
    end

    if excludeActor then
        local actorID = excludeActor:GetID()
        self.mGameActorMap = {
            [actorID] = excludeActor
        }
        self.mActorIndexMap = {
            [actorID] = 1
        }
        self.mGameActorArr = {excludeActor}
        self.mActorCount = 1
    else
        self.mGameActorMap = {}
        self.mActorIndexMap = {}
        self.mGameActorArr = {}
        self.mActorCount = 0
    end
end

function actorManager:Cleanup()
    self:RemoveAllActor()
    self:CleanupActorRootNode()
end

function actorManager:DestoryActor(actor)
    local actorNode = actor:GetNode()
    if actorNode and not tolua.isnull(actorNode) then
        actorNode:removeFromParent()
    end
    actor:destory()
end

function actorManager:CleanupActorRootNode()
    if self.mNodeOfActorSpriteFront then
        self.mNodeOfActorSpriteFront:autorelease()
        self.mNodeOfActorSpriteFront = nil
    end

    if self.mNodeOfActorSprite then
        self.mNodeOfActorSprite:autorelease()
        self.mNodeOfActorSprite = nil
    end

    if self.mNodeOfActorSpriteBehind then
        self.mNodeOfActorSpriteBehind:autorelease()
        self.mNodeOfActorSpriteBehind = nil
    end

    for i = 1, global.MMO.EFFECT_TYPE_MAX do
        if self.mEffectRootNode[i] then
            self.mEffectRootNode[i]:removeFromParent()
            self.mEffectRootNode[i] = nil
        end
    end
    self.mEffectRootNode = {}
end

function actorManager:InitOnEnterWorld()
    self.mNodeOfActorSprite = global.sceneGraphCtl:GetActorSpriteNode()
    self.mNodeOfActorSprite:retain()
    GUI._actorRootNode = self.mNodeOfActorSprite

    self.mNodeOfActorSpriteBehind = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_ACTOR_SFX_BEHIND)
    self.mNodeOfActorSpriteBehind:retain()

    if #self.mEffectRootNode == 0 then
        for i = 1, global.MMO.EFFECT_TYPE_MAX do
            self.mEffectRootNode[i] = cc.Node:create()
            if self.mNodeOfActorSpriteBehind then
                self.mNodeOfActorSpriteBehind:addChild(self.mEffectRootNode[i], effectRootNodeZOrder[i])
            end
        end
    end
    if not self.mNodeOfActorSpriteFront then
        self.mNodeOfActorSpriteFront = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_ACTOR_SFX_FRONT)
        self.mNodeOfActorSpriteFront:retain()
    end
end

----------------- MapXY   begin ---------------------
function actorManager:AddMapXYActor(actor, mapX, mapY)
    if not actor then
        return
    end
    if actor:IsMonster() then
        addMapXYActorID(self.mMonsterMapXYActorID, actor:GetID(), mapX, mapY)
    elseif actor:IsPlayer() then
        addMapXYActorID(self.mPlayerMapXYActorID, actor:GetID(), mapX, mapY)
    elseif actor:IsNPC() then
        addMapXYActorID(self.mNPCMapXYActorID, actor:GetID(), mapX, mapY)
    end
end

function actorManager:RmvMapXYActor(actor, mapX, mapY)
    if not actor then
        return
    end

    if actor:IsMonster() then
        rmvMapXYActorID(self.mMonsterMapXYActorID, actor:GetID(), mapX, mapY)
    elseif actor:IsPlayer() then
        rmvMapXYActorID(self.mPlayerMapXYActorID, actor:GetID(), mapX, mapY)
    elseif actor:IsNPC() then
        rmvMapXYActorID(self.mNPCMapXYActorID, actor:GetID(), mapX, mapY)
    end
end

function actorManager:GetMonsterActorByMapXY(mapX, mapY, isAll)
    if isAll then
        return findAllActorByMapXY(self.mMonsterMapXYActorID, mapX, mapY)
    end

    local XYKey = G_ActorUtils.KEY_MAP_XY(mapX, mapY)
    local actorID = self.mMonsterMapXYActorID[XYKey] and next(self.mMonsterMapXYActorID[XYKey]) or nil
    if not actorID then
        return nil
    end
    return self:GetActor(actorID)
end

function actorManager:GetMonsterActorIDByMapXY(mapX, mapY, isAll)
    if isAll then
        return findAllActorIDByMapXY(self.mMonsterMapXYActorID, mapX, mapY)
    end

    local XYKey = G_ActorUtils.KEY_MAP_XY(mapX, mapY)
    local actorID = self.mMonsterMapXYActorID[XYKey] and next(self.mMonsterMapXYActorID[XYKey]) or nil
    if not actorID then
        return nil
    end
    return actorID
end

function actorManager:GetPlayerActorByMapXY(mapX, mapY, isAll)
    if isAll then
        return findAllActorByMapXY(self.mPlayerMapXYActorID, mapX, mapY)
    end

    local XYKey = G_ActorUtils.KEY_MAP_XY(mapX, mapY)
    local actorID = self.mPlayerMapXYActorID[XYKey] and next(self.mPlayerMapXYActorID[XYKey]) or nil
    if not actorID then
        return nil
    end
    return self:GetActor(actorID)
end

function actorManager:GetPlayerActorIDByMapXY(mapX, mapY, isAll)
    if isAll then
        return findAllActorIDByMapXY(self.mPlayerMapXYActorID, mapX, mapY)
    end

    local XYKey = G_ActorUtils.KEY_MAP_XY(mapX, mapY)
    local actorID = self.mPlayerMapXYActorID[XYKey] and next(self.mPlayerMapXYActorID[XYKey]) or nil
    if not actorID then
        return nil
    end
    return actorID
end

function actorManager:GetNPCActorByMapXY(mapX, mapY, isAll)
    if isAll then
        return findAllActorByMapXY(self.mNPCMapXYActorID, mapX, mapY)
    end

    local XYKey = G_ActorUtils.KEY_MAP_XY(mapX, mapY)
    local actorID = self.mNPCMapXYActorID[XYKey] and next(self.mNPCMapXYActorID[XYKey]) or nil
    if not actorID then
        return nil
    end
    return self:GetActor(actorID)
end
----------------- MapXY     end ---------------------

function actorManager:SetActorMapXY(actor, mapX, mapY)
    actor:SetMapX(mapX)
    actor:SetMapY(mapY)

    if actor:IsMonster() then
        self:RmvMapXYActor(actor, actor:GetLastMapX(), actor:GetLastMapY())
        self:AddMapXYActor(actor, mapX, mapY)
        global.netMonsterController:handle_ActorMapXYChange(actor, mapX, mapY)
    elseif actor:IsPlayer() then
        if not actor:IsMainPlayer() then
            self:RmvMapXYActor(actor, actor:GetLastMapX(), actor:GetLastMapY())
            self:AddMapXYActor(actor, mapX, mapY)
            global.netPlayerController:handle_ActorMapXYChange(actor, mapX, mapY)
        end
    elseif actor:IsNPC() then
        self:RmvMapXYActor(actor, actor:GetLastMapX(), actor:GetLastMapY())
        self:AddMapXYActor(actor, mapX, mapY)
    end
end

return actorManager
