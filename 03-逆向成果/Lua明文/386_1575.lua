local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyTipsLayerMediator = class('TradingBankBuyTipsLayerMediator', BaseUIMediator)
TradingBankBuyTipsLayerMediator.NAME = "TradingBankBuyTipsLayerMediator"

function TradingBankBuyTipsLayerMediator:ctor()
    TradingBankBuyTipsLayerMediator.super.ctor(self)
end

function TradingBankBuyTipsLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable

    return {
        noticeTable.Layer_TradingBankBuyTipsLayer_Open,
        noticeTable.Layer_TradingBankBuyTipsLayer_Close,
    }
end

function TradingBankBuyTipsLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankBuyTipsLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyTipsLayer_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankBuyTipsLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankBuyTipsLayer").create(data)
        self._type  = global.UIZ.UI_TOBOX
        TradingBankBuyTipsLayerMediator.super.OpenLayer(self)
    end
end

function TradingBankBuyTipsLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankBuyTipsLayerMediator