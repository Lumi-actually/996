local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankMeGetMoneyPanelLayerMediator_other = class('TradingBankMeGetMoneyPanelLayerMediator_other', BaseUIMediator)
TradingBankMeGetMoneyPanelLayerMediator_other.NAME = "TradingBankMeGetMoneyPanelLayerMediator_other"

function TradingBankMeGetMoneyPanelLayerMediator_other:ctor()
    TradingBankMeGetMoneyPanelLayerMediator_other.super.ctor(self)
end

function TradingBankMeGetMoneyPanelLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankMeGetMoneyPanelLayer_Open_other,
        noticeTable.Layer_TradingBankMeGetMoneyPanelLayer_Close_other,
    }
end

function TradingBankMeGetMoneyPanelLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankMeGetMoneyPanelLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankMeGetMoneyPanelLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end
function TradingBankMeGetMoneyPanelLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankMeGetMoneyPanel").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankMeGetMoneyPanelLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankMeGetMoneyPanelLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    TradingBankMeGetMoneyPanelLayerMediator_other.super.CloseLayer(self)
end

return TradingBankMeGetMoneyPanelLayerMediator_other