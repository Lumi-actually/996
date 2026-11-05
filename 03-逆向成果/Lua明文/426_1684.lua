local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankZFPlayerLayerMediator_other = class('TradingBankZFPlayerLayerMediator_other', BaseUIMediator)
TradingBankZFPlayerLayerMediator_other.NAME = "TradingBankZFPlayerLayerMediator_other"

function TradingBankZFPlayerLayerMediator_other:ctor()
    TradingBankZFPlayerLayerMediator_other.super.ctor(self)
end

function TradingBankZFPlayerLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankZFPlayerLayer_Open_other,
        noticeTable.Layer_TradingBankZFPlayerLayer_Close_other,
    }
end

function TradingBankZFPlayerLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankZFPlayerLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankZFPlayerLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankZFPlayerLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankZFPlayerLayer").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankZFPlayerLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankZFPlayerLayerMediator_other:CloseLayer()
    UIOperator:CloseTradePlyerUI()
    TradingBankZFPlayerLayerMediator_other.super.CloseLayer(self)
end

return TradingBankZFPlayerLayerMediator_other