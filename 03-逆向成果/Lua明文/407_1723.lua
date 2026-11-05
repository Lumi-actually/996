local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyPurchasePayLayerMediator = class('TradingBankBuyPurchasePayLayerMediator', BaseUIMediator)
TradingBankBuyPurchasePayLayerMediator.NAME = "TradingBankBuyPurchasePayLayerMediator"
function TradingBankBuyPurchasePayLayerMediator:ctor()
    TradingBankBuyPurchasePayLayerMediator.super.ctor(self)
end

function TradingBankBuyPurchasePayLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankPurchasePayPanel_Open,
        noticeTable.Layer_TradingBankPurchasePayPanel_Close,
    }
end

function TradingBankBuyPurchasePayLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankPurchasePayPanel_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankPurchasePayPanel_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankBuyPurchasePayLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankBuyPurchasePayLayer").create(data)
        self._type        = global.UIZ.UI_NORMAL
        TradingBankBuyPurchasePayLayerMediator.super.OpenLayer(self)
    end
end

function TradingBankBuyPurchasePayLayerMediator:CloseLayer()
   if not self._layer then
        return
    end
    self._layer:ExitLayer()
    TradingBankBuyPurchasePayLayerMediator.super.CloseLayer(self)
end

return TradingBankBuyPurchasePayLayerMediator