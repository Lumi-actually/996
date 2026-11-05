local BaseUIMediator = requireMediator( "BaseUIMediator" )
local ManualService996Mediator = class("ManualService996Mediator", BaseUIMediator)
ManualService996Mediator.NAME = "ManualService996Mediator"

function ManualService996Mediator:ctor()
    ManualService996Mediator.super.ctor( self )
end

function ManualService996Mediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_Manual_Service_996_Open,
        noticeTable.Layer_Manual_Service_996_Close,
    }
end

function ManualService996Mediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_Manual_Service_996_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_Manual_Service_996_Close == noticeName then
        self:CloseLayer()
    end
end

function ManualService996Mediator:OpenLayer(noticeData)
    if not (self._layer) then
        local Layer = requireLayerUI("manual_service_996_layer/ManualService996Layer").create(noticeData)
        if not Layer then
            return
        end
        self._layer         = Layer
        self._type          = global.UIZ.UI_MOUSE
        ManualService996Mediator.super.OpenLayer( self )
    else
        if self._layer then
            self._layer:ShowHideUI(true)
        end
    end
end

function ManualService996Mediator:CloseLayer()
    if self._layer then
        self._layer:OnClose()
    end
    ManualService996Mediator.super.CloseLayer(self)
end

return ManualService996Mediator