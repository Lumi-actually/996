local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankCostZFLayerMediator_other = class('TradingBankCostZFLayerMediator_other', BaseUIMediator)
TradingBankCostZFLayerMediator_other.NAME = "TradingBankCostZFLayerMediator_other"

function TradingBankCostZFLayerMediator_other:ctor()
    TradingBankCostZFLayerMediator_other.super.ctor(self)
end

function TradingBankCostZFLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankCostZFLayer_Open_other,
        noticeTable.Layer_TradingBankCostZFLayer_Close_other,
    }
end

function TradingBankCostZFLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankCostZFLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankCostZFLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankCostZFLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankCostZFLayer").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankCostZFLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankCostZFLayerMediator_other:CloseLayer()
    TradingBankCostZFLayerMediator_other.super.CloseLayer(self)
end

return TradingBankCostZFLayerMediator_other