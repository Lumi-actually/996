local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankZFLayerMediator = class('TradingBankZFLayerMediator', BaseUIMediator)
TradingBankZFLayerMediator.NAME = "TradingBankZFLayerMediator"

function TradingBankZFLayerMediator:ctor()
    TradingBankZFLayerMediator.super.ctor(self)
end

function TradingBankZFLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankZFLayer_Open,
        noticeTable.Layer_TradingBankZFLayer_Close,
    }
end

function TradingBankZFLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankZFLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankZFLayer_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankZFLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankZFLayer").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankZFLayerMediator.super.OpenLayer(self)
    end
end

function TradingBankZFLayerMediator:CloseLayer()
    TradingBankZFLayerMediator.super.CloseLayer(self)
end

return TradingBankZFLayerMediator