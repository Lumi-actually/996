local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankPurchasePowerfulLayerMediator = class('TradingBankPurchasePowerfulLayerMediator', BaseUIMediator)
TradingBankPurchasePowerfulLayerMediator.NAME = "TradingBankPurchasePowerfulLayerMediator"

function TradingBankPurchasePowerfulLayerMediator:ctor()
    TradingBankPurchasePowerfulLayerMediator.super.ctor(self)
end

function TradingBankPurchasePowerfulLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankPurchasePowerfulLayer_Open,
        noticeTable.Layer_TradingBankPurchasePowerfulLayer_Close,
    }
end

function TradingBankPurchasePowerfulLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankPurchasePowerfulLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankPurchasePowerfulLayer_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankPurchasePowerfulLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankPurchasePowerfulLayer").create(data)
        self._type        = global.UIZ.UI_NORMAL
        TradingBankPurchasePowerfulLayerMediator.super.OpenLayer(self)
    end
end

function TradingBankPurchasePowerfulLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    TradingBankPurchasePowerfulLayerMediator.super.CloseLayer(self)
end

return TradingBankPurchasePowerfulLayerMediator