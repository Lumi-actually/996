local BaseUIMediator = requireMediator("BaseUIMediator")
local Box996SuperLayerMediator = class("Box996SuperLayerMediator",BaseUIMediator)
Box996SuperLayerMediator.NAME = "Box996SuperLayerMediator"

function Box996SuperLayerMediator:ctor()
    Box996SuperLayerMediator.super.ctor( self )
end


function Box996SuperLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_Box996Super_Attach,
        noticeTable.Layer_Box996Super_UnAttach,
        noticeTable.Layer_Box996Super_Refresh
    }
end

function Box996SuperLayerMediator:handleNotification( notification )
    local noticeName = notification:getName()
    local noticeTable = global.NoticeTable
    local noticeData = notification:getBody()

    if noticeTable.Layer_Box996Super_Attach == noticeName then
        self:AttachLayer( noticeData )
    elseif noticeTable.Layer_Box996Super_UnAttach == noticeName then
        self:UnAttachLayer()
    elseif noticeTable.Layer_Box996Super_Refresh == noticeName then
        self:OnRefresh( noticeData )
    end
end

function Box996SuperLayerMediator:AttachLayer( data )
    if not self._layer then
        self._layer = requireLayerUI("box996_layer/Box996SuperLayer").create( data )
        if data and data.parent then
            data.parent:addChild( self._layer )
        end
    end
end

function Box996SuperLayerMediator:UnAttachLayer()
    if self._layer then
        self._layer:removeFromParent()
        self._layer = nil
    end
end

function Box996SuperLayerMediator:OnRefresh(data)
    if self._layer then
        self._layer:OnRefresh( data )
    end
end

return Box996SuperLayerMediator