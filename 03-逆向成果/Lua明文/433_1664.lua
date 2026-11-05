local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankRefuseLayerMediator_other = class('TradingBankRefuseLayerMediator_other', BaseUIMediator)
TradingBankRefuseLayerMediator_other.NAME = "TradingBankRefuseLayerMediator_other"

function TradingBankRefuseLayerMediator_other:ctor()
    TradingBankRefuseLayerMediator_other.super.ctor(self)
end

function TradingBankRefuseLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankRefuseLayer_Open_other,
        noticeTable.Layer_TradingBankRefuseLayer_Close_other,
    }
end

function TradingBankRefuseLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankRefuseLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankRefuseLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankRefuseLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankRefuseLayer").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankRefuseLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankRefuseLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    TradingBankRefuseLayerMediator_other.super.CloseLayer(self)
end

return TradingBankRefuseLayerMediator_other