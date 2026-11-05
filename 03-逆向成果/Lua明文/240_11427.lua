local DebugMediator = requireMediator("DebugMediator")
local ActorEffectManager = class("ActorEffectManager", DebugMediator)
ActorEffectManager.NAME = "ActorEffectManager"

function ActorEffectManager:ctor()
    ActorEffectManager.super.ctor(self, self.NAME)

    self._effects   = {}
    self._rootNodeB = nil
    self._rootNodeF = nil

    self._npcEffects= {}
end

function ActorEffectManager:destory()
    global.Facade:removeMediator(ActorEffectManager.NAME)
end

function ActorEffectManager:create()
    local _this = ActorEffectManager.new()
    global.Facade:registerMediator(_this)
    return _this
end

function ActorEffectManager:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return
    {
        noticeTable.ActorOutOfView,
        noticeTable.ActorInOfView,
        noticeTable.DropItemOutOfView,
    }
end

function ActorEffectManager:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()

    if noticeTable.ActorOutOfView == noticeID then
        self:OnActorOutOfView(data)

    elseif noticeTable.ActorInOfView == noticeID then
        self:OnActorInOfView(data)

    elseif noticeTable.DropItemOutOfView == noticeID then
        self:OnDropItemOutOfView(data)
    end
end

function ActorEffectManager:InitRoots()
    self._rootNodeB = self._rootNodeB or global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_SKILL_BEHIND)
    self._rootNodeF = self._rootNodeF or global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_SKILL)
end

function ActorEffectManager:Tick(dt)
    for actorID, items in pairs(self._effects) do
        for sfxID, item in pairs(items) do
            if self:CheckInvalid(item) then
                self:RmvEffect({actorID = actorID, sfxID = sfxID})
                if item and item.finishCallBack then
                    item.finishCallBack()
                end
            end
        end
    end
end

function ActorEffectManager:CheckInvalid(item)
    -- forever
    if item.count == 0 then
        return false
    end

    -- count compare
    if item.counting >= item.count then
        return true
    end

    return false
end

function ActorEffectManager:IsEmpty(actorID)
    local items = self._effects[actorID]
    if not items or not next(items) then
        return true
    end
    return false
end

function ActorEffectManager:Cleanup()
    for _, items in pairs(self._effects) do
        for _, item in pairs(items) do
            self:CleanupByActorID(item.actorID)
        end
    end
    self._effects = {}
end

function ActorEffectManager:CleanupByActorID(actorID)
    if self:IsEmpty(actorID) then
        return
    end

    local items = self:GetItemsByActorID(actorID)
    for _, item in pairs(items) do
        self:RmvEffect({actorID = item.actorID, sfxID = item.sfxID})
    end
end

function ActorEffectManager:OnActorOutOfView(actorID)
    self:CleanupByActorID(actorID)
end

function ActorEffectManager:OnActorInOfView(data)
    self:CheckAddNPCEffect(data.actorID)
end

function ActorEffectManager:OnDropItemOutOfView(actorID)
    self:CleanupByActorID(actorID)
end

function ActorEffectManager:GetItemsByActorID(actorID)
    self._effects[actorID] = self._effects[actorID] or {}
    return self._effects[actorID]
end

function ActorEffectManager:setPosition(actorID, x, y)
    if self:IsEmpty(actorID) then
        return nil
    end

    local items = self._effects[actorID]
    if not items then
        return nil
    end

    local offsetX    = 0
    local offsetY    = 0
    local positionX  = 0
    local positionY  = 0
    local avatorOffset = global.MMO.PLAYER_AVATAR_OFFSET
    for _, item in pairs(items) do
        offsetX      = item.offsetX or 0
        offsetY      = item.offsetY or 0
        positionX    = x + avatorOffset.x + offsetX
        positionY    = y + avatorOffset.y + offsetY
        item.anim:setPosition(positionX, positionY)
    end
end

function ActorEffectManager:AddEffect(item)
    self:InitRoots()

    -- error param
    local actorID = item.actorID
    local sfxID   = item.sfxID
    if not actorID or not sfxID then
        return false
    end

    -- can't find actor
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        print("+++++++++++++++++++ AddEffect can't find actor")
        return false
    end

    self._effects[actorID]  = self._effects[actorID] or {}
    local items             = self._effects[actorID]

    local visible = type(item.visible) ~= "boolean" and true or item.visible
    visible = visible and CHECK_SETTING(global.MMO.SETTING_IDX_EFFECT_SHOW) ~= 1
    if actor:IsPlayer() and actor:IsDoubleHorse() then
        visible = false
    end
    -- exist
    if items[sfxID] then
        items[sfxID].anim:setVisible(visible)
        return false
    end

    
    local dir = 0
    if item.dirfollow then
        local actor = global.actorManager:GetActor(actorID)
        if actor and actor.GetDirection then
            dir = actor:GetDirection()
        end
    end

    -- add sfx
    local root = item.front == true and self._rootNodeF or self._rootNodeB
    local anim = global.FrameAnimManager:CreateSFXAnim(sfxID)
    anim:SetGlobalElapseEnable(item.count == 0)
    root:addChild(anim, sfxID)
    anim:Play(0, dir, true, item.speed)
    anim:SetAnimEventCallback(function()
        item.counting = item.counting + 1
    end)

    anim:setVisible(visible)
    
    -- fix param
    item.counting = 0
    item.anim     = anim
    items[sfxID]  = item
    
    -- 
    self:setPosition(actorID, actor:getPositionX(), actor:getPositionY())

    return true
end

function ActorEffectManager:RmvEffect(data)
    -- error param
    local actorID = data.actorID
    local sfxID   = data.sfxID

    if not actorID or not sfxID then
        return false
    end

    if self:IsEmpty(actorID) then
        return false
    end

    local items = self._effects[actorID]

    -- can'd find item
    if nil == items[sfxID] then
        return false
    end

    items[sfxID].anim:removeFromParent()
    items[sfxID] = nil

    -- cleanup, when empty
    if self:IsEmpty(actorID) then
        self._effects[actorID] = nil
    end
end

function ActorEffectManager:UpdateEffectDir(actor, actorID)
    if not actor or not actorID then
        return false
    end

    if self:IsEmpty(actorID) then
        return false
    end

    local items = self._effects[actorID] or {}

    for sfxID, item in pairs(items) do
        if item.dirfollow then
            local sfx = item.anim
            if sfx and actor.GetDirection then
                sfx:Stop()
                sfx:Play(0, actor:GetDirection(), true, item.speed)
            end
        end
    end
end

function ActorEffectManager:ActorEffectRefresh(data)
    local action = data.action
    local UserID = data.UserID
    local items  = data.items or {}
    local nItem  = #items

    for i = 1, nItem do
        local v     = items[i]
        local data  =
        {
            actorID = UserID,
            sfxID   = tonumber(v.sEffSrc),
            frame   = v.iFrame or 0,
            speed   = v.iSpeed or 1,
            count   = v.iCount or 0,
            front   = not v.iBehind,
            offsetX = v.offsetX or 0,
            offsetY = v.offsetY or 0,
            dirfollow = v.boDirFollow
        }

        if action == 1 then
            self:AddEffect(data)
        elseif action == 0 then
            self:RmvEffect(data)
        end
    end
end

function ActorEffectManager:handle_ActorEffectUpdate(netPkg)
    -- boSelfShow 可见类型：0所有人可见 1仅自己可见;
    local items = netPkg:GetBodyValues(
        {"i4", "i4", "i4", "i4", "i4", "i8", "i1", "i4", "i4", "i1", "i1"},
        {"sEffSrc", "iFrame", "iSpeed", "iCount", "iStartTime", "iOverTime", "iBehind", "offsetX", "offsetY", "boSelfShow", "boDirFollow"})

    if not items then
        return false
    end

    -- 玩家ID
    local UserID = netPkg:GetP0Str()

    -- 1.增加 0.删除
    local action  = netPkg:GetP1()

    self:ActorEffectRefresh({action = action, items = items, UserID = UserID})
end
-------------------------------------------------------------------

-------------------------------------------------------------------
function ActorEffectManager:CheckAddNPCEffect(actorID)
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end
    local effect = self._npcEffects[actorID]
    if not effect then
        return nil
    end

    local data =
    {
        actorID = actorID,
        sfxID   = effect.sfxID,
        frame   = 0,
        speed   = 1,
        count   = 0,
        front   = true,
        offsetX = effect.offsetX,
        offsetY = effect.offsetY,
    }
    self:AddEffect(data)
end

function ActorEffectManager:CheckRmvNPCEffect(actorID)
    local effect = self._npcEffects[actorID]
    if not effect then
        return nil
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    local data =
    {
        actorID = actorID,
        sfxID   = effect.sfxID,
        frame   = 0,
        speed   = 1,
        count   = 0,
        front   = true,
        offsetX = effect.offsetX,
        offsetY = effect.offsetY,
    }
    self:RmvEffect(data)
end

function ActorEffectManager:RespAddNPCEffect(msg)
    local header = msg:GetHeader()
    local msgLen = msg:GetDataLength()
    if msgLen <= 0 then
        return nil
    end
    local npcID = msg:GetBodyStr()

    self._npcEffects[npcID] = 
    {
        sfxID   = header.param1,
        offsetX = header.param2,
        offsetY = header.param3,
    }

    self:CheckAddNPCEffect(npcID)
end
    
function ActorEffectManager:RespRmvNPCEffect(msg)
    local msgLen = msg:GetDataLength()
    if msgLen <= 0 then
        return nil
    end
    local npcID = msg:GetBodyStr()

    self:CheckRmvNPCEffect(npcID)

    self._npcEffects[npcID] = nil
end

function ActorEffectManager:RefreshActorEffectVisible( actorID,visible )
    if not actorID then
        return
    end

    local effects = self._effects[actorID]
    if not effects or not next(effects) then
        return
    end

    local actor = global.actorManager:GetActor(actorID)
    if actor and actor:IsPlayer() and actor:IsDoubleHorse() then
        visible = false
    end

    if visible and actor:GetValueByKey(global.MMO.HUD_SNEAK) then
        visible = false
    end

    for sfxid, item in pairs(effects) do
        local itemVisible = visible
        if visible then
            itemVisible = item.visible or visible
        end
        item.anim:setVisible(itemVisible == true)
    end
end

function ActorEffectManager:onRegister()
    local msgType = global.MsgType
    LuaRegisterMsgHandler(msgType.MSG_SC_ADD_NPC_EFFECT, handler(self, self.RespAddNPCEffect))
    LuaRegisterMsgHandler(msgType.MSG_SC_RMV_NPC_EFFECT, handler(self, self.RespRmvNPCEffect))
end

return ActorEffectManager
