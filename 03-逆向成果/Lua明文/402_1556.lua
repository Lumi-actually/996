local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankRefuseLayerMediator = class('TradingBankRefuseLayerMediator', BaseUIMediator)
TradingBankRefuseLayerMediator.NAME = "TradingBankRefuseLayerMediator"

function TradingBankRefuseLayerMediator:ctor()
    TradingBankRefuseLayerMediator.super.ctor(self)
end

function TradingBankRefuseLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankRefuseLayer_Open,
        noticeTable.Layer_TradingBankRefuseLayer_Close,
    }
end

function TradingBankRefuseLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankRefuseLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankRefuseLayer_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankRefuseLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankRefuseLayer").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankRefuseLayerMediator.super.OpenLayer(self)
    end
end

function TradingBankRefuseLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    TradingBankRefuseLayerMediator.super.CloseLayer(self)
end

return TradingBankRefuseLayerMediator