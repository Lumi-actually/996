local actorPickerController = class("gameMapController")
actorPickerController.NAME  = "actorPickerController"

local optionsUtils = requireUtil("optionsUtils")
local mAbs = math.abs
local tsort = table.sort
local filterDis = 150

local function checkPickAble(actor)
    if actor:IsSEffect() then
        return false
    end
    if (actor:IsPlayer() or actor:IsMonster()) and not actor:IsAttackType() then
        return false
    end
    return true
end

local function pickCmpFun(a1, a2)
    local dw1 = a1:IsDie() and 1 or 0
    local dw2 = a2:IsDie() and 1 or 0
    if dw1 ~= dw2 then
        return dw1 < dw2
    end

    local y1 = a1:GetMapY()
    local y2 = a2:GetMapY()
    return y1 > y2
end

local function filterActors(actors, ncount, pickX, pickY)
    local newActors = {}
    local actor = nil
    local num = 0

    for i = 1, ncount do
        actor = actors[i]
        if actor and checkPickAble(actor) and mAbs(actor.mPositionX - pickX) <= filterDis or mAbs(actor.mPositionY - pickY) <= filterDis then
            num = num + 1
            newActors[num] = actor
        end
    end

    tsort(newActors, pickCmpFun)
    
    return newActors, num
end

local boundBox = {}
local tempVec2 = {}
local function pickActors(actors, ncount, pickX, pickY)
    local newActors, nums = filterActors(actors, ncount, pickX, pickY)
    local posX      = nil
    local posY      = nil
    local actor     = nil
    local mAnimate  = nil

    for i = 1, nums do
        actor     = newActors[i]
        mAnimate  = actor:GetAnimation()

        if mAnimate then
            posX = actor.mPositionX
            posY = actor.mPositionY
            if actor:IsMonster() and not actor:GetValueByKey(global.MMO.MONSTER_VISIBLE) then
                local hpHudOffsetY = global.MMO.HUD_OFFSET_1.y
                if ActorHud.GetHUDHPSpriteParam then
                    local hudParam = ActorHud.GetHUDHPSpriteParam(actor:GetID())
                    if hudParam and hudParam.offset then
                        hpHudOffsetY = hudParam.offset.y or hpHudOffsetY
                    end
                end
                boundBox.width = global.MMO.MapGridWidth  -- 使用格子宽度
                boundBox.x     = posX - boundBox.width * 0.5
                boundBox.height= hpHudOffsetY + global.MMO.MapGridHeight -- 血条位置高度
                boundBox.y     = posY
            else
                boundBox   = mAnimate:GetBoundingBox()
                boundBox.x = boundBox.x + posX
                boundBox.y = boundBox.y + posY
            end

            tempVec2.x = pickX
            tempVec2.y = pickY
            if cc.rectContainsPoint(boundBox, tempVec2) then
                return actor
            end
        end
    end

    return nil
end

function actorPickerController:ctor()
    self.pickable               = {}
    self.pickable.pickType      = global.MMO.PICK_NONE
    self.pickable.actorPicked   = 0
    self.pickable.xGridPicked   = 0
    self.pickable.yGridPicked   = 0
    self.pickable.touchWay      = 0

    self.lastMouseInsideActor   = nil
    self._lastMouseInDropItem   = false

    self.mouseMovePos           = nil
    self.mouseMoveAble          = true
    self._touchActorID          = nil
    self._lastTouchActID        = nil
end

function actorPickerController:Cleanup()
    self.pickable.pickType      = global.MMO.PICK_NONE
    self.pickable.actorPicked   = 0
    self.pickable.xGridPicked   = 0
    self.pickable.yGridPicked   = 0
    self.pickable.touchWay      = 0
end

function actorPickerController:destory()
end

function actorPickerController.create()
    local _this = actorPickerController.new()
    return _this
end

function actorPickerController:HandleTouchEndEvent(touchPos, touchWay, eventType)
    local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
    local state = ItemMoveProxy:GetMovingItemState()
    if state then
        return
    end
    self:TouchWorldEvent(touchPos, touchWay, eventType)
end

function actorPickerController:Pick(pickX, pickY, pickMainPlayer)
    local actors = nil
    local target = nil
    local ncount = 0

    -- npc
    if not target then
        actors, ncount = global.npcManager:GetAllNpcInCurrViewField()
        target = pickActors(actors, ncount, pickX, pickY)
    end

    -- player
    if not target then
        local noMainPlayer = (not pickMainPlayer)
        actors, ncount = global.playerManager:FindAllPlayerInCurrViewField(noMainPlayer)
        target = pickActors(actors, ncount, pickX, pickY)
    end

    -- monster
    if not target then
        actors, ncount = global.monsterManager:FindAllMonsterInCurrViewField(false, false)
        target = pickActors(actors, ncount, pickX, pickY)
    end

    -- drop item
    if not target then
        actors, ncount = global.dropItemManager:FindAllDropItemInCurrViewField()
        target = pickActors(actors, ncount, pickX, pickY)
    end
    
    return target
end

function actorPickerController:Assign(pickable)
    if pickable then
        self.pickable = pickable
        global.Facade:sendNotification(global.NoticeTable.PickerChange, self.pickable)
    end
end

function actorPickerController:GetPickable()
    return self.pickable
end

local touchWorldEventTempPoint = cc.p(0, 0)
function actorPickerController:TouchWorldEvent(touchPos, touchWay, eventType)
    -- convert touch to world
    touchWorldEventTempPoint.x, touchWorldEventTempPoint.y = Screen2World(touchPos)

    -- pick
    local pickable     = {}
    pickable.touchWay  = touchWay
    pickable.eventType = eventType


    --按了守护按钮 英雄去守护
    local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    if touchWay == global.MMO.MOVE_EVENT_TOUCH_AND_MOUSE_L and eventType == cc.Handler.EVENT_TOUCH_BEGAN and HeroPropertyProxy:HeroIsLogin() and HeroPropertyProxy:getGuardBtnState() then
        local mapPosX, mapPosY = global.sceneManager:WorldPos2MapPos(touchWorldEventTempPoint.x, touchWorldEventTempPoint.y)
        HeroPropertyProxy:RequestTargetXY(mapPosX, mapPosY)
        HeroPropertyProxy:setGuardBtnState(false)
        return
    end
    -- ctrl + 右键 查看
    if touchWay == global.MMO.MOVE_EVENT_MOUSE_R and eventType == cc.Handler.EVENT_TOUCH_BEGAN and global.userInputController:IsPressedCtrl() then
        local actor = global.actorPickerController:Pick(touchWorldEventTempPoint.x, touchWorldEventTempPoint.y)
        local mainPlayerID = global.gamePlayerController:GetMainPlayerID()
        if actor and not actor:IsDie() and (actor:IsPlayer() or actor:IsHumanoid()) and actor:GetID() ~= mainPlayerID then
            -- 当前禁止查看
            local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
            if mapProxy:IsForbidVisitPlayer() then
                ShowSystemChat(GET_STRING(30001071), 255, 249)
                return
            end

            if actor:IsHumanoid() then --人形怪
                local disHeadLookHumanoid = tonumber(global.ConstantConfig.disHeadLookHumanoid) == 1
                if disHeadLookHumanoid then
                    ShowSystemTips(GET_STRING(50000269))
                    return
                end
            end

            local LookPlayerProxy = global.Facade:retrieveProxy(global.ProxyTable.LookPlayerProxy)
            LookPlayerProxy:RequestPlayerData(actor:GetID())
            return
        end
    end

    -- alt + 右键 快速私聊
    if touchWay == global.MMO.MOVE_EVENT_MOUSE_R and eventType == cc.Handler.EVENT_TOUCH_BEGAN and global.userInputController:IsPressedAlt() then
        local actor = global.actorPickerController:Pick(touchWorldEventTempPoint.x, touchWorldEventTempPoint.y)
        local mainPlayerID = global.gamePlayerController:GetMainPlayerID()
        if actor and not actor:IsDie() and actor:IsPlayer() and actor:GetID() ~= mainPlayerID then
            SL:onLUAEvent(LUA_EVENT_CHAT_PRIVATE_TARGET, {name = actor:GetName(), uid = actor:GetID()})
            return
        end
    end

    -- alt + 鼠标左右键挖肉
    if global.userInputController:IsPressedAlt() then
        -- touchWorldEventTempPoint
        local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        inputProxy:SetDigDest(touchWorldEventTempPoint)
        return
    end


    -- find pickable
    local actor = nil
    self._touchActorID = nil
    if touchWay == global.MMO.MOVE_EVENT_TOUCH_AND_MOUSE_L and eventType == cc.Handler.EVENT_TOUCH_BEGAN then
        if global.HUDManager.Pick then
            actor = global.HUDManager:Pick(touchWorldEventTempPoint.x, touchWorldEventTempPoint.y)
        end

        if not actor then
            actor = global.actorPickerController:Pick(touchWorldEventTempPoint.x, touchWorldEventTempPoint.y)
        end

        local mainPlayerID = global.gamePlayerController:GetMainPlayerID()
        local mainPlayer = global.gamePlayerController:GetMainPlayer()

        if actor then
            -- dead
            if actor:IsDie() then
                actor = nil

            elseif actor:IsDeath() then
                if self._lastTouchActID then
                    optionsUtils:SetHUDLabelNameVisible(self._lastTouchActID, false)
                end
                if actor and actor:GetID() then
                    optionsUtils:SetHUDLabelNameVisible(actor:GetID(), true)
                    self._lastTouchActID = actor:GetID()
                    self._touchActorID = actor:GetID()
                end
                actor = nil

            elseif actor:IsCave() then
                actor = nil
            end
        end

        -- ignore main player
        if actor and (actor:GetID() == mainPlayerID) then
            actor = nil
        end
        -- ignore pickup sprite
        if actor and actor:IsPickUpSprite() then
            actor = nil
        end

        if actor and actor.IsAttackType and not actor:IsAttackType() then
            actor = nil
        end
        -- ignore master is main player
        -- if actor and (actor:GetMasterID() == mainPlayerID) then
        --     actor = nil
        -- end
    end

    local dirtyFlag = false
    if actor then
        local actorType = actor:GetType()
        if actorType == global.MMO.ACTOR_MONSTER then -- monster
            dirtyFlag = true
            pickable.pickType = global.MMO.PICK_ACTOR_MONSTER
            pickable.actorPicked = actor:GetID()
            pickable.xGridPicked = actor:GetMapX()
            pickable.yGridPicked = actor:GetMapY()
            if actor:IsCollection() then
                pickable.pickType = global.MMO.PICK_ACTOR_COLLECTION

            elseif actor:IsDie() then
                if not global.isWinPlayMode or global.userInputController:IsPressedCtrl() then
                    pickable.pickType = global.MMO.PICK_ACTOR_CORPSE
                end
            else
                pickable.pickType = global.MMO.PICK_ACTOR_MONSTER
            end

        elseif actorType == global.MMO.ACTOR_PLAYER then -- player
            dirtyFlag = true
            pickable.pickType = global.MMO.PICK_ACTOR_PLAYER
            pickable.actorPicked = actor:GetID()
            pickable.xGridPicked = actor:GetMapX()
            pickable.yGridPicked = actor:GetMapY()

        elseif actorType == global.MMO.ACTOR_NPC then -- NPC
            dirtyFlag = true
            pickable.pickType = global.MMO.PICK_ACTOR_NPC
            pickable.actorPicked = actor:GetID()
            pickable.xGridPicked = actor:GetMapX()
            pickable.yGridPicked = actor:GetMapY()

        elseif actorType == global.MMO.ACTOR_DROPITEM then -- NPC
            actor = nil
        end
    end


    if nil == actor then --Nothing was picked.
        local mapX, mapY = global.sceneManager:WorldPos2MapPos(touchWorldEventTempPoint.x, touchWorldEventTempPoint.y)

        dirtyFlag = true
        pickable.pickType = global.MMO.PICK_MAP_GRID
        pickable.actorPicked = 0
        pickable.xGridPicked = mapX
        pickable.yGridPicked = mapY
    end


    if global.MMO.PICK_ACTOR_NPC == pickable.pickType or
        global.MMO.PICK_ACTOR_COLLECTION == pickable.pickType or -- always dirty NPC
        global.MMO.PICK_MAP_GRID == pickable.pickType then -- always dirty grid
        dirtyFlag = true
    end

    if dirtyFlag then
        self:Assign(pickable)
    end

    if not self._touchActorID then
        if self._lastTouchActID then
            optionsUtils:SetHUDLabelNameVisible(self._lastTouchActID, false)
        end
    end
end

function actorPickerController:MouseMoveWorldEvent(touchPos)
    self.mouseMovePos = touchPos
    self:CheckMouseMoveEvent()
end

function actorPickerController:CheckMouseMoveEvent()
    if not self.mouseMovePos or not self.mouseMoveAble then
        return false
    end

    -- convert touch to world
    touchWorldEventTempPoint.x, touchWorldEventTempPoint.y = Screen2World(self.mouseMovePos)

    -- find pickable
    -- actor manager only
    local actor = global.actorPickerController:Pick(touchWorldEventTempPoint.x, touchWorldEventTempPoint.y, true)

    if nil == actor or actor:IsBorn() or actor:IsCave() or actor:GetValueByKey(global.MMO.HUD_SNEAK) then --Nothing was picked.
        if self.lastMouseInsideActor then
            -- 移出
            global.Facade:sendNotification(global.NoticeTable.MouseMoveOutActorSide, self.lastMouseInsideActor)
            self.lastMouseInsideActor = nil
            self._lastMouseInDropItem = false
        end
    else
        if self.lastMouseInsideActor and self.lastMouseInsideActor ~= actor:GetID() then
            -- 移出
            global.Facade:sendNotification(global.NoticeTable.MouseMoveOutActorSide, self.lastMouseInsideActor)
            -- 移入
            self.lastMouseInsideActor = actor:GetID()
            self._lastMouseInDropItem = actor:IsDropItem()
            global.Facade:sendNotification(global.NoticeTable.MouseMoveInActorSide, self.lastMouseInsideActor)
            if actor:IsDeath() then
                optionsUtils:SetHUDLabelNameVisible(self.lastMouseInsideActor, true)
            end
        elseif not self.lastMouseInsideActor then
            -- 移入
            self.lastMouseInsideActor = actor:GetID()
            self._lastMouseInDropItem = actor:IsDropItem()
            global.Facade:sendNotification(global.NoticeTable.MouseMoveInActorSide, self.lastMouseInsideActor)
            if actor:IsDeath() then
                optionsUtils:SetHUDLabelNameVisible(self.lastMouseInsideActor, true)
            end
        end
    end

    self.mouseMoveAble = false
    PerformWithDelayGlobal(function()
        self.mouseMoveAble = true
        self:CheckMouseMoveEvent()
    end, 0.1)
end

function actorPickerController:GetLastMouseInsideActor()
    return self.lastMouseInsideActor
end

function actorPickerController:GetLastMouseInDropItem()
    return self._lastMouseInDropItem
end

return actorPickerController