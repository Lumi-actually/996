SLHandlerEvent = {}
SLHandlerEvent.Events = {}
SLHandlerEvent.EventDesc = {}
SLHandlerEvent.PropertyEvents = {}

------------------------------------------------------------------------------------------------------------------------
-- 窗口事件
WND_EVENT_MOUSE_LB_DOWN             = 1                                         -- 鼠标左键按下事件
WND_EVENT_MOUSE_LB_UP               = 2                                         -- 鼠标左键弹起事件
WND_EVENT_MOUSE_LB_CLICK            = 3                                         -- 鼠标左键点击事件
WND_EVENT_MOUSE_LB_DBCLICK          = 4                                         -- 鼠标左键双击事件
WND_EVENT_MOUSE_RB_DOWN             = 5                                         -- 鼠标右键按下事件
WND_EVENT_MOUSE_RB_UP               = 6                                         -- 鼠标右键弹起事件         
WND_EVENT_MOUSE_RB_CLICK            = 7                                         -- 鼠标右键点击事件
WND_EVENT_MOUSE_RB_DBCLICK          = 8                                         -- 鼠标右键双击事件
WND_EVENT_MOUSE_MOVE                = 9                                         -- 鼠标移动事件
WND_EVENT_MOUSE_WHEEL               = 10                                        -- 鼠标滚轮滚动事件
WND_EVENT_MOUSE_IN                  = 11                                        -- 鼠标进入控件事件
WND_EVENT_MOUSE_OUT                 = 12                                        -- 鼠标离开控件事件

WND_EVENT_WND_VISIBLE               = 21                                        -- 可见状态发生变化事件
WND_EVENT_WND_POS_CHANGE            = 22                                        -- 控件位置发生变化事件
WND_EVENT_WND_SIZECHANGE            = 23                                        -- 窗口大小发生变化事件
WND_EVENT_WND_DESTROY               = 24                                        -- 窗体被销毁事件

WND_EVENT_ITEM_IN                   = 31                                        -- 物品框物品移入事件
WND_EVENT_ITEM_OUT                  = 32                                        -- 物品框物品移出事件
------------------------------------------------------------------------------------------------------------------------

local function RegisterMouseClickEvent(widget)
    local function __OnMouseDown(sender)
        if not widget.__TYPE__ then
            return false
        end
        if not widget._hideTouch then
            if not GetWidgetVisible(widget) then
                return false
            end
        end
        if not widget:isTouchEnabled() then
            return false
        end
        if not widget:isSwallowTouches() then
            return false
        end

        local call_down_r   = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_RB_DOWN)
        local call_down_l   = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_LB_DOWN)
        local call_click_l  = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_LB_CLICK)   
        local call_click_r  = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_RB_CLICK)
        local call_double_l = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_LB_DBCLICK)
        local call_double_r = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_RB_DBCLICK)

        local mousePosX = sender:getCursorX()
        local mousePosY = sender:getCursorY()
        local touchPos  = {x = mousePosX, y = mousePosY}

        local globalM   = global.mouseEventController
        local isInSide  = globalM:CheckNodePos(widget, touchPos)

        local mButton = sender:getMouseButton()
        if mButton == cc.MouseButton.BUTTON_RIGHT then 
            globalM:CancelMove(sender, true, true)

            if isInSide then
                if call_down_r then
                    SLHandlerEvent.swallowMouse = call_down_r(widget) or false
                end
                sender:stopPropagation()
            end
        else
            if isInSide then
                if call_down_l then
                    SLHandlerEvent.swallowMouse = call_down_l(widget) or false
                    widget._DOWN___ =  SLHandlerEvent.swallowMouse
                else
                    widget._DOWN___ = nil
                end
                
                if widget._DOWN___ then
                    sender:stopPropagation()
                    return true
                end

                if SLHandlerEvent.swallowMouse then
                    sender:stopPropagation()
                    return true
                end

                if call_double_l then
                    if widget._onDoubleLClickEvent then
                        widget._onDoubleLClickEvent = false
                        
                        globalM:CancelMove(sender, false, false)
                        SLHandlerEvent.swallowMouse = call_double_l({widget  = widget, touchPos = touchPos}) or false

                        if widget._clickDelayLHandler then
                            UnSchedule(widget._clickDelayLHandler)
                            widget._clickDelayLHandler = false
                        end

                        if SLHandlerEvent.swallowMouse then
                            sender:stopPropagation()
                            return true
                        end
                    else
                        widget._onDoubleLClickEvent = true
                        -- 记录单击触发
                        widget._clickDelayLHandler =
                            PerformWithDelayGlobal(
                            function()
                                widget._clickDelayLHandler = false
                                widget._onDoubleLClickEvent = false
                            end,
                            0.5
                        )
                    end
                end

                if call_click_l then
                    SLHandlerEvent.swallowMouse = call_click_l(widget) or false
                end
                
                sender:stopPropagation()
            end
        end
    end

    local function __OnMouseUp(sender)
        if not widget.__TYPE__ then
            return false
        end 
        if not GetWidgetVisible(widget) then
            return false
        end
        if not widget:isTouchEnabled() then
            return false
        end
        if not widget:isSwallowTouches() then
            return false
        end
        
        local call_up_r     = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_RB_UP)
        local call_up_l     = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_LB_UP) 
        local call_click_r  = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_RB_CLICK)
        local call_double_r = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_RB_DBCLICK)
        
        local mousePosX = sender:getCursorX()
        local mousePosY = sender:getCursorY()
        local touchPos  = {x = mousePosX, y = mousePosY}

        local globalM   = global.mouseEventController
        local isInSide  = global.mouseEventController:CheckNodePos(widget, {x = mousePosX, y = mousePosY})

        local mButton = sender:getMouseButton()
        if mButton == cc.MouseButton.BUTTON_RIGHT then
            if isInSide then
                if call_up_r then
                    SLHandlerEvent.swallowMouse = call_up_r(widget) or false
                end
                if call_double_r then
                    if widget._onDoubleRClickEvent then
                        if widget._clickDelayRHandler then
                            UnSchedule(widget._clickDelayRHandler)
                            widget._clickDelayRHandler = false
                        end

                        widget._onDoubleRClickEvent = false

                        globalM:CancelMove(sender, false, false)
                        SLHandlerEvent.swallowMouse = call_double_r({widget  = widget, touchPos = touchPos}) or false
                    else
                        widget._onDoubleRClickEvent = true
            
                        -- 记录单击触发
                        widget._clickDelayRHandler =
                            PerformWithDelayGlobal(
                            function()
                                if call_click_r then
                                    SLHandlerEvent.swallowMouse = call_click_r({widget  = widget, touchPos = touchPos}) or false
                                end

                                widget._clickDelayRHandler = false
                                widget._onDoubleRClickEvent = false
                            end,
                            global.MMO.CLICK_DOUBLE_TIME
                        )
                    end
                elseif call_click_r then
                    call_click_r(widget)
                end
                sender:stopPropagation()
            end
        else
            if isInSide then
                if call_up_l then
                    SLHandlerEvent.swallowMouse = call_up_l(widget) or false
                end
                sender:stopPropagation()
            end
        end
    end
    
    SLHandlerEvent.swallowMouse = false

    local listener = cc.EventListenerMouse:create()
    listener:registerScriptHandler(__OnMouseDown, cc.Handler.EVENT_MOUSE_DOWN)
    listener:registerScriptHandler(__OnMouseUp,   cc.Handler.EVENT_MOUSE_UP)
    global.EventDispatcher:addEventListenerWithSceneGraphPriority(listener, widget)
end

local function RegisterMouseMoveEvent(widget)
    local function __OnMouseMoved(sender)
        if not widget.__TYPE__ then
            return false
        end
        if not GetWidgetVisible(widget) then
            return false
        end
        local lastTimeNodeState = widget.___wState___
        local mousePosX = sender:getCursorX()
        local mousePosY = sender:getCursorY()
        local touchPos  = {x = mousePosX, y = mousePosY}

        local isInSide = global.mouseEventController:CheckNodePos(widget, touchPos)

        if lastTimeNodeState and isInSide then --一直在内部
            local insideCallback = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_MOVE)
            if insideCallback then
                insideCallback(widget)
            end
            widget.___wState___ = true
            sender:stopPropagation()
        elseif lastTimeNodeState and not isInSide then --移出
            local leaveCallback = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_OUT)
            if leaveCallback then
                leaveCallback(widget)
            end
            widget.___wState___ = false
        elseif not lastTimeNodeState and isInSide then --移入
            local enterCallback = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_IN)
            if enterCallback then
                enterCallback({widget = widget, touchPos = touchPos})
            end
            widget.___wState___ = true
            sender:stopPropagation()
        end
    end
    
    SLHandlerEvent.swallowMouse = false

    local listener = cc.EventListenerMouse:create()
    listener:registerScriptHandler(__OnMouseMoved, cc.Handler.EVENT_MOUSE_MOVE)
    global.EventDispatcher:addEventListenerWithSceneGraphPriority(listener, widget)
end

local function RegisterMouseWheelEvent(widget)
    local function __OnMouseScroll(sender)
        if not widget.__TYPE__ then
            return false
        end
        if not GetWidgetVisible(widget) then
            return false
        end
        local call_scrolling = SLHandlerEvent:GetCallBack(widget, WND_EVENT_MOUSE_WHEEL)
        if not call_scrolling then
            return false
        end

        local mousePosX = sender:getCursorX()
        local mousePosY = sender:getCursorY()
        local isInSide  = global.mouseEventController:CheckNodePos(widget, {x = mousePosX, y = mousePosY})
        if not isInSide then
            return false
        end
        local scrollX  = sender:getScrollX()
        local scrollY  = sender:getScrollY()
        call_scrolling({widget = widget, x = scrollX, y = scrollY})
    end
    
    SLHandlerEvent.swallowMouse = false

    local listener = cc.EventListenerMouse:create()
    listener:registerScriptHandler(__OnMouseScroll, cc.Handler.EVENT_MOUSE_SCROLL)
    global.EventDispatcher:addEventListenerWithSceneGraphPriority(listener, widget)
end

-- 添加窗体控件事件
function SLHandlerEvent:RegisterWndEvent(widget, desc, key, callback)
    if not CheckObjValid(widget) then
        return false
    end

    SLHandlerEvent.Events = SLHandlerEvent.Events or {}
    SLHandlerEvent.Events[widget] = SLHandlerEvent.Events[widget] or {}
    SLHandlerEvent.Events[widget][desc] = SLHandlerEvent.Events[widget][desc] or {}
    SLHandlerEvent.Events[widget][desc][key] = callback

    SLHandlerEvent.EventDesc = SLHandlerEvent.EventDesc or {}
    SLHandlerEvent.EventDesc[widget] = desc

    widget.__TYPE__ = true
    if key == WND_EVENT_MOUSE_MOVE or key == WND_EVENT_MOUSE_IN or key == WND_EVENT_MOUSE_OUT then
        RegisterMouseMoveEvent(widget)
    elseif key == WND_EVENT_MOUSE_WHEEL then
        RegisterMouseWheelEvent(widget)
    elseif key > 0 and key < 9 then
        RegisterMouseClickEvent(widget)
    elseif key == WND_EVENT_WND_DESTROY then
        widget:registerScriptHandler(function(state)
            if state == "exit" then
                SLHandlerEvent:GetCallBack(widget, WND_EVENT_WND_DESTROY, true)
            end
        end )
    end
end

-- 删除窗体控件事件
function SLHandlerEvent:UnRegisterWndEvent(widget, desc, key)
    if not CheckObjValid(widget) then
        return false
    end
    SLHandlerEvent.Events = SLHandlerEvent.Events or {}
    if desc and SLHandlerEvent.Events[widget] and SLHandlerEvent.Events[widget][desc] then
        if key then
            SLHandlerEvent.Events[widget][desc][key] = nil
        else
            SLHandlerEvent.Events[widget][desc] = nil
        end
        return false
    end
    SLHandlerEvent.Events[widget] = nil
end

-- 获取窗体控件事件
function SLHandlerEvent:GetCallBack(widget, key, isExecute)
    if not CheckObjValid(widget) then
        return false
    end

    local desc = SLHandlerEvent.EventDesc[widget]
    if not desc then
        return false
    end

    SLHandlerEvent.Events = SLHandlerEvent.Events or {}
    if SLHandlerEvent.Events[widget] and SLHandlerEvent.Events[widget][desc] then
        if key then
            if SLHandlerEvent.Events[widget][desc][key] then
                return isExecute and SLHandlerEvent.Events[widget][desc][key](widget) or SLHandlerEvent.Events[widget][desc][key]
            end
        end
    end
    return false
end

-- 添加窗体控件自定义属性
function SLHandlerEvent:AddWndProperty(widget, desc, key, value)
    if not CheckObjValid(widget) then
        return false
    end
    SLHandlerEvent.PropertyEvents = SLHandlerEvent.PropertyEvents or {}
    SLHandlerEvent.PropertyEvents[widget] = SLHandlerEvent.PropertyEvents[widget] or {}
    SLHandlerEvent.PropertyEvents[widget][desc] = SLHandlerEvent.PropertyEvents[widget][desc] or {}
    SLHandlerEvent.PropertyEvents[widget][desc][key] = value
end

-- 删除窗体控件自定义属性
function SLHandlerEvent:DelWndProperty(widget, desc, key)
    if not CheckObjValid(widget) then
        return false
    end
    SLHandlerEvent.PropertyEvents = SLHandlerEvent.PropertyEvents or {}
    if desc and SLHandlerEvent.PropertyEvents[widget] and SLHandlerEvent.PropertyEvents[widget][desc] then
        if key then
            SLHandlerEvent.PropertyEvents[widget][desc][key] = nil
        else
            SLHandlerEvent.PropertyEvents[widget][desc] = nil
        end
        return false
    end
    SLHandlerEvent.PropertyEvents[widget] = nil
end

-- 获取窗体控件自定义属性
function SLHandlerEvent:GetWndProperty(widget, desc, key)
    if not CheckObjValid(widget) then
        return nil
    end
    SLHandlerEvent.PropertyEvents = SLHandlerEvent.PropertyEvents or {}
    if SLHandlerEvent.PropertyEvents[widget] and SLHandlerEvent.PropertyEvents[widget][desc] then
        if key then
            return SLHandlerEvent.PropertyEvents[widget][desc][key]
        else
            return SLHandlerEvent.PropertyEvents[widget][desc]
        end
    end
    return nil
end