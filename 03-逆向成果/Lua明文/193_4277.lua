local DebugMediator = requireMediator("DebugMediator")
local BaseUIMediator = class("BaseUIMediator", DebugMediator)
BaseUIMediator.NAME = "BaseUIMediator"

function BaseUIMediator:ctor()
    BaseUIMediator.super.ctor(self, self.NAME)

    self._type          = nil
    self._layer         = nil
    self._voice         = true
    self._hideMain      = false
    self._hideLast      = false
    self._responseMoved = nil
    self._resetPostion  = nil
    self._mouseBtnEvent = true
    self._escClose      = true
    self._GUI_ID        = nil

    --
    self.__savedPosX    = 0
    self.__savedPosY    = 0
end

function BaseUIMediator:OpenLayer()
    if not self._type or not self._layer then
        print("-------- Error:  " .. self.NAME .. "  OpenLayer")
        return false
    end

    -- open
    local data = {}
    data.ltype = self._type
    data.layer = self._layer
    data.mediator = self

    if self._type == global.UIZ.UI_NORMAL and self._adapet then
        local viewSize = global.Director:getVisibleSize()
        local blackLayout = ccui.Layout:create()
        self._layer:addChild(blackLayout, -999)
        blackLayout:setContentSize(viewSize)
        blackLayout:setBackGroundColor(cc.c3b(0, 0, 0))
        blackLayout:setBackGroundColorType(1)
        blackLayout:setBackGroundColorOpacity(80)
        blackLayout:setTouchEnabled(true)
        blackLayout:addClickEventListener(function()
            self:CloseLayer()
        end)
        
        if SL:GetValue("IS_PC_OPER_MODE") then
            global.mouseEventController:registerMouseMoveEvent(blackLayout)
        end
    end

    global.Facade:sendNotification(global.NoticeTable.Layer_Open, data)

    RefreshPositionByParent(self._layer)

    if SL:GetValue("IS_PC_OPER_MODE") then
        SL:onLUAEvent(LUA_EVENT_NOTICE_CHILD_REMOVE, "__MouseTips")
        SL:onLUAEvent(LUA_EVENT_MAIN_CLOSE_KEYBOARD)
    end

    self._moveWidget = nil
    -- event move
    if self._responseMoved then
        self:setLayerMoveEnable(self._responseMoved)
    end
end

function BaseUIMediator:CloseLayer()
    if not self._type or not self._layer then
        return false
    end

    local data = {}
    data.ltype = self._type
    data.layer = self._layer
    data.mediator = self

    SLBridge:onLUAEvent(LUA_EVENT_CLOSEWIN, self._GUI_ID)

    global.Facade:sendNotification(global.NoticeTable.Layer_Close, data)

    self._layer = nil
    self._type = nil
end

function BaseUIMediator:handlePressedEnter()
    return false
end

function BaseUIMediator:SetLocalZOrder(zOrder)
    if not self._type or not self._layer then
        return false
    end

    self._layer:setLocalZOrder(zOrder)
end

function BaseUIMediator:getResetPosition()
    if self._resetPostion then
        if type(self._resetPostion) == "table" then 
            return cc.p(self._resetPostion.x, self._resetPostion.y)
        end
        return cc.p(0, 0)
    end

    return cc.p(self.__savedPosX, self.__savedPosY)
end

function BaseUIMediator:setSavedPosition(px, py)
    self.__savedPosX = px
    self.__savedPosY = py
end

function BaseUIMediator:setLayerMoveEnable(moveWidget)
    if not self._type or not self._layer then
        return false
    end
    if not moveWidget then
        return false
    end

    local data = {}
    data.ltype = self._type
    data.layer = self._layer
    data.mediator = self
    data.moveWidget = moveWidget
    global.Facade:sendNotification(global.NoticeTable.Layer_SetMoveEnable, data)
end

function BaseUIMediator:setHideMainUI(hide)
    if type(hide) ~= "boolean" then
        return false
    end
    if self._hideMain == hide then
        return false
    end
    self._hideMain = hide
    global.Facade:sendNotification(global.NoticeTable.Layer_HideMainEvent, self)
end

function BaseUIMediator:setLayerZPanel(panel)
    if not self._type or not self._layer then
        return false
    end
    if not panel then
        return false
    end

    local data = {}
    data.mediator = self
    data.zPanel = panel
    global.Facade:sendNotification(global.NoticeTable.Layer_SetZOrderPanel, data)
end

return BaseUIMediator