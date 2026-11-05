--[[
    readme:has a special mouse event in mouse right button event
    It was used to on the platform expeat window replacing check root node
    
    You can return -1 to continue propagation on the mouse button event but moving.

    mouse move event params

    param = {
        enter = function,   --on enter callback
        leave = function,    --on leave callback
        inside = function,   -- inside moving callback
    }

    mouse button event params

    param = {
        down_r = function, --right button down 函数会传入 touchPos
        up_r = function,    --right button up 函数会传入 touchPos
        special_r = function,   --special : imitate left button down on mobile 函数会传入 touchPos
        double_l = function,    --left button double click 函数会传入 touchPos
        moving = function,  -- on moving 函数会传入 touchPos
        scroll = function  -- on scroll moving 函数会传入 scrollOff = { x = 0, y = 1}   x值目前没变动 Y 值 大于零 向后滚动 小于零 向前
        swallow = number,   > 0 stopPropagation
        checkIsVisible = bool,
        CheckTouchEnable = bool,
        moveTouch = bool  --该参数目前只用于移动
    }

    **self.registerAllChilderMouseRButtonEvent was only used to add swallow mouse event. 
    It will let all children on the father node to get mouse event.
]]

local mouseEventController = class("mouseEventController")

function mouseEventController:ctor()
    self.onDoubleEvent = false
    self.doubleClickDelayTime = 0.3
    self.lastInsideNodeParam = nil
    self.mouseMoveOffPos = nil
end

function mouseEventController:destory()
end

function mouseEventController:create()
    local _this = mouseEventController.new()
    return _this
end

function mouseEventController:GetNodeLastState(node)
    return node._nodeState or false
end

function mouseEventController:SetNodeLastState(node, bool)
    if not tolua.isnull(node) then
        node._nodeState = bool
    end
end

function mouseEventController:SetLastInsideNode(node, param)
    self.lastInsideNodeParam = nil
    if node and param and not tolua.isnull(node) then
        self.lastInsideNodeParam = {
            sideNode = node,
            param = param
        }
    end
end

function mouseEventController:ClearLastInsideNode(node)
    local lastData = self.lastInsideNodeParam
    if lastData and lastData.sideNode and not tolua.isnull(lastData.sideNode) then
        self:SetNodeLastState(lastData.sideNode, false)
    end
    self.lastInsideNodeParam = nil
end

function mouseEventController:GetLastInsideNode()
    local lastData = self.lastInsideNodeParam
    if lastData and lastData.sideNode and not tolua.isnull(lastData.sideNode) then
        return lastData.sideNode
    end
    return nil
end

function mouseEventController:LeaveLastNode()
    local lastData = self.lastInsideNodeParam
    if lastData and lastData.sideNode and not tolua.isnull(lastData.sideNode) and self:GetNodeLastState(lastData.sideNode) then
        self:SetNodeLastState(lastData.sideNode, false)
        local param = lastData.param
        if not param or not next(param) then
            return
        end
        local leaveCallBack = param.leave
        if leaveCallBack then
            leaveCallBack()
        end
    end
end

function mouseEventController:OnMouseMoveEvent(pos)
    if self.onDoubleEvent then
        if not self.mouseMoveOffPos then
            self.mouseMoveOffPos = pos
        else
            local offPos = math.pow((self.mouseMoveOffPos.x - pos.x), 2) + math.pow((self.mouseMoveOffPos.y - pos.y), 2)
            if offPos > 200 then
                self.onDoubleEvent = false
                self.mouseMoveOffPos = nil
            end
        end
    else
        self.mouseMoveOffPos = nil
    end
end

function mouseEventController:CheckNodePos(node, touchPos)
    if tolua.isnull(node) or not next(touchPos) then
        return false
    end
    local worldPos = node:getWorldPosition()
    local anchor = node:getAnchorPoint()
    local content = node:getContentSize()
    local leftPos = worldPos.x - anchor.x*content.width
    local rightPos = worldPos.x + (1-anchor.x)*content.width
    local bottomPos = worldPos.y - anchor.y*content.height
    local topPos = worldPos.y + (1-anchor.y)*content.height
    local isInSide = false
    if touchPos.x > leftPos and  touchPos.x < rightPos and
    touchPos.y > bottomPos and touchPos.y < topPos then
        isInSide = true
    end
    return isInSide
end

function mouseEventController:CancelMove(sender, isStop, isReturn)
    local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
    local state = ItemMoveProxy:GetMovingItemState()
    if state then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        if isStop then
            sender:stopPropagation()
        end
        if isReturn then
            return false
        end
    end
end

function mouseEventController:registerMouseMoveEvent(node, param)
    local eventCallbacks = param or {}
    if not eventCallbacks.show then
        if not global.MouseEventOpen then
            return false
        end
    end

    local enterCallback = eventCallbacks.enter
    local leaveCallback = eventCallbacks.leave
    local insideCallback = eventCallbacks.inside
    local checkIsVisible = eventCallbacks.checkIsVisible
    local needCover      = eventCallbacks.needCover
    local listener        = cc.EventListenerMouse:create()
    local eventDispatcher = global.EventDispatcher

    local function onMouseMoved(sender)
        if checkIsVisible and (not node:isVisible() or (node:getParent() and not node:getParent():isVisible())) then
            return
        end
        local lastTimeNodeState = self:GetNodeLastState(node)
        local mousePosX = sender:getCursorX()
        local mousePosY = sender:getCursorY()
        local touchPos = {
            x = mousePosX,
            y = mousePosY
        }

        self:OnMouseMoveEvent(touchPos)

        local isInSide = self:CheckNodePos(node, touchPos)

        if lastTimeNodeState and isInSide then --一直在内部
            if insideCallback then
                insideCallback()
            end
            self:SetNodeLastState(node, true)
            sender:stopPropagation()
        elseif lastTimeNodeState and not isInSide then --移出
            if leaveCallback then
                leaveCallback()
            end
            self:SetNodeLastState(node, false)
        elseif not lastTimeNodeState and isInSide then --移入
            self:LeaveLastNode()
            if enterCallback then
                enterCallback(touchPos)
            end
            self:SetNodeLastState(node, true)
            self:SetLastInsideNode(node, param)
            sender:stopPropagation()
        end
    end

    -- 覆盖鼠标移动监听
    if node and needCover then
        if node.signRegisterMouseMoveListner then
            eventDispatcher:removeEventListener(node.signRegisterMouseMoveListner)
            node.signRegisterMouseMoveListner = nil
        end
        node.signRegisterMouseMoveListner = listener
    end

    listener:registerScriptHandler(onMouseMoved, cc.Handler.EVENT_MOUSE_MOVE)
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end

local function checkVisibleParent(node, level)
    if not node or not node:getParent() then
        return true
    end

    local maxTimes = math.min(level or 6, 6)
    local times = 2
    local parent = node:getParent()
    local visible = true
    local function checkParent(childNode)
        if times >= maxTimes or not childNode then
            return
        end
        if not tolua.isnull(childNode) then
            local parent = childNode:getParent()
            if not tolua.isnull(parent) then
                if not parent:isVisible() then
                    visible = false
                    return
                end
                times = times + 1
                checkParent(parent)
            end
        end
    end
    checkParent(parent)
    return visible
end

function mouseEventController:registerMouseButtonEvent(node, param)

    local eventCallbacks = param or {}
    local call_down_r = eventCallbacks.down_r
    local call_up_r = eventCallbacks.up_r
    local call_special_r = eventCallbacks.special_r
    local call_double_l = eventCallbacks.double_l
    local call_moving  = eventCallbacks.moving
    local call_scrolling = eventCallbacks.scroll
    local swallowMouse = eventCallbacks.swallow or 1
    local checkIsVisible = eventCallbacks.checkIsVisible
    local CheckTouchEnable = eventCallbacks.checkTouchEnable
    local checkSwallowTouches = eventCallbacks.checkSwallowTouches
    local checkVisibleLevel = eventCallbacks.checkVisibleLevel or 2
    local listener        = cc.EventListenerMouse:create()
    local eventDispatcher = global.EventDispatcher
    local isNeedNodeParam = false

    if not call_scrolling and node.RegisterWin32MouseMoveScrollCall then --GoodsItem注册的鼠标滚动回调
        call_scrolling = node.RegisterWin32MouseMoveScrollCall
        isNeedNodeParam = true
    end

    local function onMouseDown(sender)
        if checkIsVisible and (not node:isVisible() or (node:getParent() and not node:getParent():isVisible())) then
            return
        end
        if checkIsVisible and checkVisibleLevel and checkVisibleLevel > 2 and not checkVisibleParent(node, checkVisibleLevel) then
            return
        end
        if CheckTouchEnable and not node:isTouchEnabled() then
            return
        end
        if checkSwallowTouches and not node:isSwallowTouches() then
            return
        end

        local mousePosX = sender:getCursorX()
        local mousePosY = sender:getCursorY()
        local touchPos = {
            x = mousePosX,
            y = mousePosY
        }

        local isInSide = self:CheckNodePos(node, touchPos)
        local button = sender:getMouseButton()
        if button == cc.MouseButton.BUTTON_RIGHT then 
            if sender.specialRight then
                if isInSide then
                    if call_special_r then
                        swallowMouse = call_special_r(touchPos) or 1
                    else
                        self:CancelMove(sender, true, false)
                    end
                    if swallowMouse > 0 then
                        sender:stopPropagation()
                    end
                end
                return
            end

            self:CancelMove(sender, true, true)

            if isInSide then
                if call_down_r then
                    if eventCallbacks.moveTouch then
                        swallowMouse = call_down_r(touchPos) or 1
                    else
                        swallowMouse = call_down_r() or 1
                    end
                end
                if swallowMouse > 0 then
                    sender:stopPropagation()
                end
            end
        else
            if isInSide then
                if call_double_l then
                    if not node._onDoubleClickEvent then
                        node._onDoubleClickEvent = true
                        self.onDoubleEvent = true
                        -- 记录单击触发
                        node._clickDelayHandler =
                            PerformWithDelayGlobal(
                            function()
                                if call_special_r then
                                    swallowMouse = call_special_r(touchPos) or 1
                                end

                                node._onDoubleClickEvent = nil
                                self.onDoubleEvent = false
                            end,
                            self.doubleClickDelayTime
                    )
                    else
                        if node._clickDelayHandler then
                            UnSchedule(node._clickDelayHandler)
                            node._clickDelayHandler = nil
                        end

                        self:CancelMove(sender, false, false)
                        
                        swallowMouse = call_double_l(touchPos) or 1

                        node._onDoubleClickEvent = nil
                        self.onDoubleEvent = false
                    end
                elseif call_special_r then
                    if not self.onDoubleEvent then
                        swallowMouse = call_special_r(touchPos) or 1
                    end
                end
                
                if swallowMouse > 0 then
                    sender:stopPropagation()
                end
            end
        end
    end

    local function onMouseUp(sender)
        SL:onLUAEvent(LUA_EVENT_RTOUCH_STATE_CHANGE, false)
        if checkIsVisible and not node:isVisible() then
            return
        end
        if CheckTouchEnable and not node:isTouchEnabled() then
            return
        end
        if checkSwallowTouches and not node:isSwallowTouches() then
            return
        end
        local button = sender:getMouseButton()
        if button == cc.MouseButton.BUTTON_RIGHT then
            local mousePosX = sender:getCursorX()
            local mousePosY = sender:getCursorY()
            local touchPos = {
                x = mousePosX,
                y = mousePosY
            }
            local isInSide = self:CheckNodePos(node, touchPos)
            if isInSide then
                if call_up_r then
                    swallowMouse = call_up_r() or 1
                end
                if swallowMouse > 0 then
                    sender:stopPropagation()
                end
            end
        end
    end

    if eventCallbacks.moveTouch then --only moving
        local function onMouseMoved(sender)
            if eventCallbacks.moveTouch then
                local mousePosX = sender:getCursorX()
                local mousePosY = sender:getCursorY()
                if call_moving then
                    call_moving({x = mousePosX, y = mousePosY})
                end
            end
        end
        listener:registerScriptHandler(onMouseMoved, cc.Handler.EVENT_MOUSE_MOVE)
    end

    if call_scrolling then
        local function omMouseScroll(sender)
            local mousePosX = sender:getCursorX()
            local mousePosY = sender:getCursorY()
            local touchPos = {
                x = mousePosX,
                y = mousePosY
            }
            local isInSide = self:CheckNodePos(node, touchPos)
            if isInSide then
                local scrollX  = sender:getScrollX()
                local scrollY  = sender:getScrollY()
                local scrollData = {
                    x = scrollX,
                    y = scrollY
                }
                if isNeedNodeParam then
                    call_scrolling(node,scrollData)
                else
                    call_scrolling(scrollData)
                end
            end
        end
        listener:registerScriptHandler(omMouseScroll, cc.Handler.EVENT_MOUSE_SCROLL)
    end
    
    if node and node.isSignMouListner then
        if node.signRegisterMouseListner then
            eventDispatcher:removeEventListener(node.signRegisterMouseListner)
            node.signRegisterMouseListner = nil
        end
        node.signRegisterMouseListner = listener
    end

    listener:registerScriptHandler(onMouseDown, cc.Handler.EVENT_MOUSE_DOWN)
    listener:registerScriptHandler(onMouseUp, cc.Handler.EVENT_MOUSE_UP)
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)

end
-- readme: 本方法只适用于添加吞噬 不建议添加回调
function mouseEventController:registerAllChilderMouseRButtonEvent(node, param)
    if not node or tolua.isnull(node) then
        return
    end
    local allNode = {}
    local function addToTable(Widget)
        if tolua.iskindof(Widget,"ccui.Widget")then
            table.insert(allNode, Widget)
        end
    end

    addToTable(node)

    local function checkChild(parent)
        local childCount = parent:getChildrenCount()
        if childCount > 0 then
            local childern = parent:getChildren()
            for _,child in pairs(childern) do
                addToTable(child)
                checkChild(child)
            end
        end
    end

    checkChild(node)

    for k,v in pairs(allNode) do
        if not v._noAutoRegisterMouseSwollow then
            self:registerMouseButtonEvent(v, param)
        end
    end
end

return mouseEventController
