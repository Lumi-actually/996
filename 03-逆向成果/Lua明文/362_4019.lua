local KeepMovingController = class("KeepMovingController", framework.Mediator)
KeepMovingController.NAME = "KeepMovingController"

local noticeTable = global.NoticeTable

function KeepMovingController:ctor()
    KeepMovingController.super.ctor(self, self.NAME)
    self.isMoving = false
    self.touchPos = nil
    self.movingWay = global.MMO.MOVE_EVENT_TOUCH_AND_MOUSE_L
    self.TIMER_INTERVAL = 0.05
    self._beginDelay = 0.05
end

function KeepMovingController:listNotificationInterests()
    return {
        noticeTable.keepMovingBegin,
        noticeTable.keepMovingUpdate,
        noticeTable.keepMovingEnded
    }
end

function KeepMovingController:handleNotification(notification)
    local id = notification:getName()
    local data = notification:getBody()
    
    if noticeTable.keepMovingBegin == id then
        self:keepMovingBegin(data)
    elseif noticeTable.keepMovingUpdate == id then
        self:updateMovingData(data)
    elseif noticeTable.keepMovingEnded == id then
        self:keepMovingEnded()
    end
end

function KeepMovingController:ResetMoveState(state)
    self.isMoving = state or false
end

function KeepMovingController:getMoveState()
    return self.isMoving
end

function KeepMovingController:resetMoveWay(way)
    self.movingWay = way
end

function KeepMovingController:getMoveWay()
    return self.movingWay
end

function KeepMovingController:resetMoveTouchPos(pos)
    local newPos = pos
    self.touchPos = newPos
end

function KeepMovingController:getMoveTouchPos()
    return self.touchPos
end

function KeepMovingController:keepMovingBegin(data)
    if not self._timerID and not self._dalayTimerID then
        self:ResetMoveState(true)

        self:resetMoveWay(data.way)

        self:resetMoveTouchPos(data.pos)

        local function delayFunc()
            local state  = self:getMoveState()
            if state then
                local function callback(delta)
                    self:moveUpdate(delta)
                end
                self._timerID = Schedule(callback, self.TIMER_INTERVAL)
            end
            self._dalayTimerID = nil
        end
        self._dalayTimerID = PerformWithDelayGlobal(delayFunc,self._beginDelay)
    end
end

function KeepMovingController:moveUpdate(delta)
    local touchPos  = self:getMoveTouchPos()
    local touchWay  = self:getMoveWay()
    local eventType = cc.Handler.EVENT_TOUCH_MOVED

    if self._timerID then
        global.actorPickerController:HandleTouchEndEvent( touchPos, touchWay, eventType )
    end
end

function KeepMovingController:keepMovingEnded(data)
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if mainPlayer and not mainPlayer:IsLaunch() then
        local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        inputProxy:ClearMouseTouch()
    end

    if self._dalayTimerID then
        UnSchedule(self._dalayTimerID)
        self._dalayTimerID = nil
    end

    if self._timerID then
        UnSchedule(self._timerID)
        self._timerID = nil
    end

    self:cleanData()
end

function KeepMovingController:updateMovingData(data)
    local state = self:getMoveState()
    if not data or not next(data) or not state then
        return
    end

    self:checkMousePos(data.pos)

    self:resetMoveWay(data.way)

    self:resetMoveTouchPos(data.pos)

end

function KeepMovingController:checkMousePos(pos)
    if not pos or not next(pos) then
        return
    end
    local winSize = global.Director:getWinSize()
    local y = pos.y
    local x = pos.x
    if y > winSize.height or y < 0 or x < 0 or x > winSize.width then
        SL:onLUAEvent(LUA_EVENT_RTOUCH_STATE_CHANGE, false)
    end
end

function KeepMovingController:cleanData()
    self.isMoving = false
    self.touchPos = {}
    self.movingWay = global.MMO.MOVE_EVENT_TOUCH_AND_MOUSE_L
end

return KeepMovingController
