local BaseUIMediator = requireMediator("BaseUIMediator")
local Box996EveryDayLayerMediator = class("Box996EveryDayLayerMediator",BaseUIMediator)
Box996EveryDayLayerMediator.NAME = "Box996EveryDayLayerMediator"

function Box996EveryDayLayerMediator:ctor()
    Box996EveryDayLayerMediator.super.ctor( self )
end


function Box996EveryDayLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_Box996EveryDay_Attach,
        noticeTable.Layer_Box996EveryDay_UnAttach,
        noticeTable.Layer_Box996EveryDay_Refresh
    }
end

function Box996EveryDayLayerMediator:handleNotification( notification )
    local noticeName = notification:getName()
    local noticeTable = global.NoticeTable
    local noticeData = notification:getBody()

    if noticeTable.Layer_Box996EveryDay_Attach == noticeName then
        self:AttachLayer( noticeData )
    elseif noticeTable.Layer_Box996EveryDay_UnAttach == noticeName then
        self:UnAttachLayer()
    elseif noticeTable.Layer_Box996EveryDay_Refresh == noticeName then
        self:OnRefresh( noticeData )
    end
end

function Box996EveryDayLayerMediator:AttachLayer( data )
    if not self._layer then
        self._layer = requireLayerUI("box996_layer/Box996EveryDayLayer").create( data )
        if data and data.parent then
            data.parent:addChild( self._layer )
        end
    end
end

function Box996EveryDayLayerMediator:UnAttachLayer()
    if self._layer then
        self._layer:removeFromParent()
        self._layer = nil
    end
end

function Box996EveryDayLayerMediator:OnRefresh(data)
    if self._layer then
        self._layer:OnRefresh( data )
    end
end

return Box996EveryDayLayerMediator