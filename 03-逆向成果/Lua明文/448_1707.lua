local BaseUIMediator = requireMediator("BaseUIMediator")
local Box996MainLayerMediator = class("Box996MainLayerMediator",BaseUIMediator)
Box996MainLayerMediator.NAME = "Box996MainLayerMediator"

function Box996MainLayerMediator:ctor()
    Box996MainLayerMediator.super.ctor( self )
end


function Box996MainLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_Box996Main_Open,
        noticeTable.Layer_Box996Main_Close,
        noticeTable.Layer_Box996Main_Refresh,
    }
end

function Box996MainLayerMediator:handleNotification( notification )
    local noticeName = notification:getName()
    local noticeTable = global.NoticeTable
    local noticeData = notification:getBody()

    if noticeTable.Layer_Box996Main_Open == noticeName then
        self:OpenLayer( noticeData )
    elseif noticeTable.Layer_Box996Main_Close == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_Box996Main_Refresh == noticeName then
        self:OnRefresh( noticeData )
    end
end

function Box996MainLayerMediator:OpenLayer( data )
    if not self._layer then
        self._layer = requireLayerUI("box996_layer/Box996MainLayer").create( data )
        self._type = global.UIZ.UI_NORMAL

        Box996MainLayerMediator.super.OpenLayer(self)
    end
end

function Box996MainLayerMediator:CloseLayer()
    if self._layer then
        self._layer:OnClose()
    end

    Box996MainLayerMediator.super.CloseLayer(self)
end

function Box996MainLayerMediator:OnRefresh( data )
    if self._layer then
        self._layer:OnRefresh( data )
    end
end

return Box996MainLayerMediator