local BehaviorController = class('BehaviorController', framework.Mediator)
BehaviorController.NAME = "BehaviorController"

local BehaviorSelector = require("bt/BehaviorSelector")

function BehaviorController:ctor()
    BehaviorController.super.ctor(self, self.NAME)
end

function BehaviorController:destory()
    global.Facade:removeMediator( BehaviorController.NAME )
end

function BehaviorController:create()
    local _this = BehaviorController.new()
    global.Facade:registerMediator(_this)
    return _this
end

function BehaviorController:InitOnEnterWorld()
    global.gamePlayerController:RegisterLuaInputHandler(handler(self, self.ProcessInput))
    self._selector = BehaviorSelector.new()
end

function BehaviorController:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return 
    {
        noticeTable.GameWorldInitComplete
    }
end

function BehaviorController:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    if noticeTable.GameWorldInitComplete == noticeID then
        self:OnGameWorldInitComplete()
    end
end

function BehaviorController:ProcessInput(player, actCompleted)
    if self._selector then
        self._selector:Process(player, actCompleted)
    end
end

function BehaviorController:OnGameWorldInitComplete()
    self._selector:Init()
end

return BehaviorController
