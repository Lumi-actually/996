local BaseUIMediator = requireMediator("BaseUIMediator")
local CommunityLayerMediator = class('CommunityLayerMediator', BaseUIMediator)
CommunityLayerMediator.NAME = "CommunityLayerMediator"

function CommunityLayerMediator:ctor()
    CommunityLayerMediator.super.ctor(self)
end

function CommunityLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_CommunityLayer_Open, 
        noticeTable.Layer_CommunityLayer_Close,
        }
end

function CommunityLayerMediator:handleNotification(notification)
    local noticeName = notification:getName()
    local noticeTable = global.NoticeTable
    local noticeData = notification:getBody()

    if noticeTable.Layer_CommunityLayer_Open == noticeName then
        self:OpenLayer(noticeData)

    elseif noticeTable.Layer_CommunityLayer_Close == noticeName then
        self:CloseLayer()
    end
end

function CommunityLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("community_layer/CommunityLayer").create(data)
        self._type          = global.UIZ.UI_TOBOX
        self._hideMain      = false
        CommunityLayerMediator.super.OpenLayer( self )

    end
end

function CommunityLayerMediator:CloseLayer()
    if not self._layer then
        return nil
    end
    CommunityLayerMediator.super.CloseLayer( self )
end

return CommunityLayerMediator
