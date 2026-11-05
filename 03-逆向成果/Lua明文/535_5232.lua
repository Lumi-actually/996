local RemoteProxy = requireProxy("RemoteProxy")
local PickupSpriteProxy = class("PickupSpriteProxy", RemoteProxy)
PickupSpriteProxy.NAME = global.ProxyTable.PickupSpriteProxy

function PickupSpriteProxy:ctor()
    PickupSpriteProxy.super.ctor(self)
    self._tickTime = 0
    self._mainID = 0
    self._uiID = 0
    self._metaPos = nil
    self._newPickType = false
end

function PickupSpriteProxy:setMetaPositon(x, y)
    x = x or 0
    y = y or 0
    self._metaPos = cc.p(x, y)
end

function PickupSpriteProxy:getMetaPositon()
    return self._metaPos
end

function PickupSpriteProxy:onRegister()
    PickupSpriteProxy.super.onRegister(self)
end

function PickupSpriteProxy:handle_MSG_SC_PICKUP_SPRITE(msg)
    local header = msg:GetHeader11()
    self._pickSprite = header.t1 == 1 or header.t1 == 2 --是否开启
    self._pickSpriteDelay = header.t2 -- 时间间隔
    self._pickSpriteRange = header.t3--拾取范围

    -- 服务器范围是 < range, 客户端是 <= range,  统一
    if self._pickSpriteRange > 0 then
        self._pickSpriteRange = self._pickSpriteRange - 1
    end

    self._pickSpriteMode = header.t4 -- 拾取模式 1 小精灵附近   0 自己附近  2（自己附近）一个个拾取  3（小精灵附近）一个个拾取

    self._pickSpriteID = header.t0
    if self._pickSprite then
        self._tickTime = 0
    end

    -- 发送过滤挂机拾取物品IDX
    self._newPickType = header.t1 == 2
    if self._newPickType then
        local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
        GameSettingProxy:RequestSendFilterAutoPickItem()
    end
end

function PickupSpriteProxy:FindWidget(mainID, uiID)
    local GuideWidgetConfig = SL:RequireFile(GUIDefine.PATH_GUIDE_CONFIG)
    mainID = tonumber(mainID)
    local getNodesFunc = GuideWidgetConfig[mainID]
    if not getNodesFunc then
        return
    end
    local temp = { typeassist = uiID }
    local widget, parent = getNodesFunc(temp)
    return widget
end

function PickupSpriteProxy:handle_MSG_CS_PICKSPRITE_PICKUP_ANI(msg)
    local header = msg:GetHeader()
    local len = msg:GetDataLength()

    if self._mainID == 0 or self._uiID == 0 then
        return
    end

    if len > 0 then
        -----------------
        local items = {}
        local dd = msg:GetBodyStr()
        local all = G_GetSplitArray(dd, ";")
        for i, v in ipairs(all) do
            local param = G_GetSplitArray(v, ",")
            table.insert(items, { id = param[1], mapX = param[2], mapY = param[3] })
        end
        -----------------
        local targetPos
        if self._metaPos then -- 优先使用元变量设置的坐标
            targetPos = self._metaPos
        else
            local widget = self:FindWidget(self._mainID, self._uiID)
            if widget then
                targetPos    = widget:getWorldPosition()
                local box    = widget:getBoundingBox()
                local anchor = widget:getAnchorPoint()
                local subX   = 0.5 - anchor.x
                local subY   = 0.5 - anchor.y
                targetPos.x  = subX * box.width + targetPos.x
                targetPos.y  = subY * box.height + targetPos.y
            end
        end

        if targetPos then
            ShowFakeDropItemsJustFly2(targetPos, items)
        end
    end
end

function PickupSpriteProxy:handle_MSG_SC_SET_PICKSPRITE_FLY_DST(msg)
    self._mainID = msg:GetP0() --主界面id
    self._uiID = msg:GetP1() -- 控件id
end

function PickupSpriteProxy:getPickSpriteMode()
    return self._pickSpriteMode
end

function PickupSpriteProxy:getMainID()
    return self._mainID
end

function PickupSpriteProxy:getUIID()
    return self._uiID
end

function PickupSpriteProxy:getPickSpriteID()
    return self._pickSpriteID
end

function PickupSpriteProxy:getDelayTime()
    return self._pickSpriteDelay
end

function PickupSpriteProxy:getTickTime()
    return self._tickTime
end

function PickupSpriteProxy:setTickTime(TIME)
    self._tickTime = TIME
end

function PickupSpriteProxy:getPickupRange()
    return self._pickSpriteRange
end

function PickupSpriteProxy:getPickupSpriteState()
    return self._pickSprite
end

function PickupSpriteProxy:IsPickUpNewType()
    return self._newPickType == true
end

function PickupSpriteProxy:ReqPickUpSomething(idStrs)
    --自动捡取
    LuaSendMsg(global.MsgType.MSG_CS_PICKSPRITE_PICKUP, 0, 0, 0, 0, idStrs, string.len(idStrs))
end

function PickupSpriteProxy:RegisterMsgHandler()
    PickupSpriteProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_PICKUP_SPRITE,                 handler(self, self.handle_MSG_SC_PICKUP_SPRITE))            -- 拾取精灵
    LuaRegisterMsgHandler(msgType.MSG_CS_PICKSPRITE_PICKUP_ANI,         handler(self, self.handle_MSG_CS_PICKSPRITE_PICKUP_ANI))   -- 拾取精灵动画
    LuaRegisterMsgHandler(msgType.MSG_SC_SET_PICKSPRITE_FLY_DST,        handler(self, self.handle_MSG_SC_SET_PICKSPRITE_FLY_DST))   -- 拾取精灵动画
end

return PickupSpriteProxy