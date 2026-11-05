local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankPowerfulLayerMediator = class('TradingBankPowerfulLayerMediator', BaseUIMediator)
TradingBankPowerfulLayerMediator.NAME = "TradingBankPowerfulLayerMediator"

function TradingBankPowerfulLayerMediator:ctor()
    TradingBankPowerfulLayerMediator.super.ctor(self)
end

function TradingBankPowerfulLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankPowerfulLayer_Open,
        noticeTable.Layer_TradingBankPowerfulLayer_Close,
    }
end

function TradingBankPowerfulLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankPowerfulLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankPowerfulLayer_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankPowerfulLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankPowerfulLayer").create(data)
        self._type        = global.UIZ.UI_NORMAL
        TradingBankPowerfulLayerMediator.super.OpenLayer(self)
    end
end

function TradingBankPowerfulLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    TradingBankPowerfulLayerMediator.super.CloseLayer(self)
end

return TradingBankPowerfulLayerMediator