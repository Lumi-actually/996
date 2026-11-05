local BaseUIMediator = requireMediator("BaseUIMediator")
local Box996CloudPhoneLayerMediator = class("Box996CloudPhoneLayerMediator",BaseUIMediator)
Box996CloudPhoneLayerMediator.NAME = "Box996CloudPhoneLayerMediator"

function Box996CloudPhoneLayerMediator:ctor()
    Box996CloudPhoneLayerMediator.super.ctor( self )
end


function Box996CloudPhoneLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_Box996CloudPhone_Attach,
        noticeTable.Layer_Box996CloudPhone_UnAttach,
        noticeTable.Layer_Box996CloudPhone_Refresh
    }
end

function Box996CloudPhoneLayerMediator:handleNotification( notification )
    local noticeName = notification:getName()
    local noticeTable = global.NoticeTable
    local noticeData = notification:getBody()

    if noticeTable.Layer_Box996CloudPhone_Attach == noticeName then
        self:AttachLayer( noticeData )
    elseif noticeTable.Layer_Box996CloudPhone_UnAttach == noticeName then
        self:UnAttachLayer()
    elseif noticeTable.Layer_Box996CloudPhone_Refresh == noticeName then
        self:OnRefresh( noticeData )
    end
end

function Box996CloudPhoneLayerMediator:AttachLayer( data )
    if not self._layer then
        self._layer = requireLayerUI("box996_layer/Box996CloudPhoneLayer").create( data )
        if data and data.parent then
            data.parent:addChild( self._layer )
        end
    end
end

function Box996CloudPhoneLayerMediator:UnAttachLayer()
    if self._layer then
        self._layer:removeFromParent()
        self._layer = nil
    end
end

function Box996CloudPhoneLayerMediator:OnRefresh(data)
    if self._layer then
        self._layer:OnRefresh( data )
    end
end

return Box996CloudPhoneLayerMediator