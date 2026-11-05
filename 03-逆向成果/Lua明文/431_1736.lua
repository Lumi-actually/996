local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankPowerfulLayerMediator_other = class('TradingBankPowerfulLayerMediator_other', BaseUIMediator)
TradingBankPowerfulLayerMediator_other.NAME = "TradingBankPowerfulLayerMediator_other"

function TradingBankPowerfulLayerMediator_other:ctor()
    TradingBankPowerfulLayerMediator_other.super.ctor(self)
end

function TradingBankPowerfulLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankPowerfulLayer_Open_other,
        noticeTable.Layer_TradingBankPowerfulLayer_Close_other,
    }
end

function TradingBankPowerfulLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankPowerfulLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankPowerfulLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankPowerfulLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankPowerfulLayer").create(data)
        self._type        = global.UIZ.UI_NORMAL
        TradingBankPowerfulLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankPowerfulLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    TradingBankPowerfulLayerMediator_other.super.CloseLayer(self)
end

return TradingBankPowerfulLayerMediator_other