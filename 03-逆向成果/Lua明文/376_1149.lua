local BaseUIMediator = requireMediator("BaseUIMediator")
local TopTouchMediator = class("TopTouchMediator", BaseUIMediator)
TopTouchMediator.NAME = "TopTouchMediator"

function TopTouchMediator:ctor()
    TopTouchMediator.super.ctor(self)
end

function TopTouchMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_Main_Init,
    }
end

function TopTouchMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local id = notification:getName()
    local data = notification:getBody()

    if noticeTable.Layer_Main_Init == id then
        self:OnOpen()
    end
end

function TopTouchMediator:OnOpen()
    if not self._layer then
        self._layer = requireLayerUI("top_touch_layer/TopTouchLayer").create()
        self._type = global.UIZ.UI_NOTICE
        TopTouchMediator.super.OpenLayer(self)
    end
end

function TopTouchMediator:OnClose()
    TopTouchMediator.super.CloseLayer(self)
end

function TopTouchMediator:onRegister()
    TopTouchMediator.super.onRegister(self)
end


return TopTouchMediator
