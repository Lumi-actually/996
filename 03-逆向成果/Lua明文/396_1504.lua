local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankCostZFLayerMediator = class('TradingBankCostZFLayerMediator', BaseUIMediator)
TradingBankCostZFLayerMediator.NAME = "TradingBankCostZFLayerMediator"

function TradingBankCostZFLayerMediator:ctor()
    TradingBankCostZFLayerMediator.super.ctor(self)
end

function TradingBankCostZFLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankCostZFLayer_Open,
        noticeTable.Layer_TradingBankCostZFLayer_Close,
    }
end

function TradingBankCostZFLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankCostZFLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankCostZFLayer_Close == noticeName then
        self:CloseLayer()
    end
end
function TradingBankCostZFLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankCostZFLayer").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankCostZFLayerMediator.super.OpenLayer(self)
    end
end

function TradingBankCostZFLayerMediator:CloseLayer()
    TradingBankCostZFLayerMediator.super.CloseLayer(self)
end


return TradingBankCostZFLayerMediator