local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankIdentityLayerMediator_other = class('TradingBankIdentityLayerMediator_other', BaseUIMediator)
TradingBankIdentityLayerMediator_other.NAME = "TradingBankIdentityLayerMediator_other"

function TradingBankIdentityLayerMediator_other:ctor()
    TradingBankIdentityLayerMediator_other.super.ctor(self)
end

function TradingBankIdentityLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankBindIdentityLayer_Open_other,
        noticeTable.Layer_TradingBankBindIdentityLayer_Close_other,
    }
end

function TradingBankIdentityLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankBindIdentityLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBindIdentityLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankIdentityLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._type = global.UIZ.UI_NORMAL
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankBindIdentityLayer").create(data)
        TradingBankIdentityLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankIdentityLayerMediator_other:CloseLayer()
    if self._layer then
        self._layer:exitLayer()
    end
    TradingBankIdentityLayerMediator_other.super.CloseLayer(self)
end

return TradingBankIdentityLayerMediator_other