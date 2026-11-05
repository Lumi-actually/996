local BaseUIMediator = requireMediator("BaseUIMediator")
local Box996GuideLayerMediator = class("Box996GuideLayerMediator",BaseUIMediator)
Box996GuideLayerMediator.NAME = "Box996GuideLayerMediator"

function Box996GuideLayerMediator:ctor()
    Box996GuideLayerMediator.super.ctor( self )
end


function Box996GuideLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_Box996Guide_Open,
        noticeTable.Layer_Box996Guide_Close,
        noticeTable.Layer_Box996Guide_Refresh,
    }
end

function Box996GuideLayerMediator:handleNotification( notification )
    local noticeName = notification:getName()
    local noticeTable = global.NoticeTable
    local noticeData = notification:getBody()

    if noticeTable.Layer_Box996Guide_Open == noticeName then
        self:OnOpen( noticeData )
    elseif noticeTable.Layer_Box996Guide_Close == noticeName then
        self:OnClose()
    elseif noticeTable.Layer_Box996Guide_Refresh == noticeName then
        self:OnRefresh( noticeData )
    end
end

function Box996GuideLayerMediator:OnOpen( data )
    if not self._layer then
        self._layer = requireLayerUI("box996_layer/Box996GuideLayer").create( data )
        self._type = global.UIZ.UI_NORMAL

        Box996GuideLayerMediator.super.OpenLayer(self)
    end
end

function Box996GuideLayerMediator:OnClose()
    Box996GuideLayerMediator.super.CloseLayer(self)
end

function Box996GuideLayerMediator:OnRefresh( data )
    if self._layer then
        self._layer:OnRefresh( data )
    end
end

return Box996GuideLayerMediator