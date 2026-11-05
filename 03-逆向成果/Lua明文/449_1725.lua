local BaseUIMediator = requireMediator("BaseUIMediator")
local Box996TitleLayerMediator = class("Box996TitleLayerMediator",BaseUIMediator)
Box996TitleLayerMediator.NAME = "Box996TitleLayerMediator"

function Box996TitleLayerMediator:ctor()
    Box996TitleLayerMediator.super.ctor( self )
end


function Box996TitleLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_Box996Title_Attach,
        noticeTable.Layer_Box996Title_UnAttach,
        noticeTable.Layer_Box996Title_Refresh
    }
end

function Box996TitleLayerMediator:handleNotification( notification )
    local noticeName = notification:getName()
    local noticeTable = global.NoticeTable
    local noticeData = notification:getBody()

    if noticeTable.Layer_Box996Title_Attach == noticeName then
        self:AttachLayer( noticeData )
    elseif noticeTable.Layer_Box996Title_UnAttach == noticeName then
        self:UnAttachLayer()
    elseif noticeTable.Layer_Box996Title_Refresh == noticeName then
        self:OnRefresh( noticeData )
    end
end

function Box996TitleLayerMediator:AttachLayer( data )
    if not self._layer then
        self._layer = requireLayerUI("box996_layer/Box996TitleLayer").create( data )
        if data and data.parent then
            data.parent:addChild( self._layer )
        end
    end
end

function Box996TitleLayerMediator:UnAttachLayer()
    if self._layer then
        self._layer:removeFromParent()
        self._layer = nil
    end
end

function Box996TitleLayerMediator:OnRefresh(data)
    if self._layer then
        self._layer:OnRefresh( data )
    end
end

return Box996TitleLayerMediator