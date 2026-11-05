local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankMeLayerMediator = class('TradingBankMeLayerMediator', BaseUIMediator)
TradingBankMeLayerMediator.NAME = "TradingBankMeLayerMediator"
function TradingBankMeLayerMediator:ctor()
    TradingBankMeLayerMediator.super.ctor(self)
end

function TradingBankMeLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankMeLayer_Open,
        noticeTable.Layer_TradingBankMeLayer_Close,
    }
end

function TradingBankMeLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankMeLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankMeLayer_Close == noticeName then
        self:CloseLayer()
    end
end
function TradingBankMeLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankMeLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankMeLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankMeLayerMediator