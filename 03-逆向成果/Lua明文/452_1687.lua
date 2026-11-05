local BaseUIMediator = requireMediator("BaseUIMediator")
local Box996VIPLayerMediator = class("Box996VIPLayerMediator",BaseUIMediator)
Box996VIPLayerMediator.NAME = "Box996VIPLayerMediator"

function Box996VIPLayerMediator:ctor()
    Box996VIPLayerMediator.super.ctor( self )
end


function Box996VIPLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_Box996VIP_Attach,
        noticeTable.Layer_Box996VIP_UnAttach,
        noticeTable.Layer_Box996VIP_Refresh
    }
end

function Box996VIPLayerMediator:handleNotification( notification )
    local noticeName = notification:getName()
    local noticeTable = global.NoticeTable
    local noticeData = notification:getBody()

    if noticeTable.Layer_Box996VIP_Attach == noticeName then
        self:AttachLayer( noticeData )
    elseif noticeTable.Layer_Box996VIP_UnAttach == noticeName then
        self:UnAttachLayer()
    elseif noticeTable.Layer_Box996VIP_Refresh == noticeName then
        self:OnRefresh( noticeData )
    end
end

function Box996VIPLayerMediator:AttachLayer( data )
    if not self._layer then
        self._layer = requireLayerUI("box996_layer/Box996VIPLayer").create( data )
        if data and data.parent then
            data.parent:addChild( self._layer )
        end
    end
end

function Box996VIPLayerMediator:UnAttachLayer()
    if self._layer then
        self._layer:removeFromParent()
        self._layer = nil
    end
end

function Box996VIPLayerMediator:OnRefresh(data)
    if self._layer then
        self._layer:OnRefresh( data )
    end
end

return Box996VIPLayerMediator