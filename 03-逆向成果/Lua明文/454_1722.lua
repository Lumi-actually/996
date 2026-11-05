local BaseUIMediator = requireMediator("BaseUIMediator")
local Box996SVIPLayerMediator = class("Box996SVIPLayerMediator",BaseUIMediator)
Box996SVIPLayerMediator.NAME = "Box996SVIPLayerMediator"

function Box996SVIPLayerMediator:ctor()
    Box996SVIPLayerMediator.super.ctor( self )
end


function Box996SVIPLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_Box996SVIP_Attach,
        noticeTable.Layer_Box996SVIP_UnAttach,
        noticeTable.Layer_Box996SVIP_Refresh
    }
end

function Box996SVIPLayerMediator:handleNotification( notification )
    local noticeName = notification:getName()
    local noticeTable = global.NoticeTable
    local noticeData = notification:getBody()

    if noticeTable.Layer_Box996SVIP_Attach == noticeName then
        self:AttachLayer( noticeData )
    elseif noticeTable.Layer_Box996SVIP_UnAttach == noticeName then
        self:UnAttachLayer()
    elseif noticeTable.Layer_Box996SVIP_Refresh == noticeName then
        self:OnRefresh( noticeData )
    end
end

function Box996SVIPLayerMediator:AttachLayer( data )
    if not self._layer then
        self._layer = requireLayerUI("box996_layer/Box996SVIPLayer").create( data )
        if data and data.parent and self._layer then
            data.parent:addChild( self._layer )
        end
    end
end

function Box996SVIPLayerMediator:UnAttachLayer()
    if self._layer then
        self._layer:removeFromParent()
        self._layer = nil
    end
end

function Box996SVIPLayerMediator:OnRefresh(data)
    if self._layer then
        self._layer:OnRefresh( data )
    end
end

return Box996SVIPLayerMediator