local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankWaitPayPanelLayerMediator_other = class('TradingBankWaitPayPanelLayerMediator_other', BaseUIMediator)
TradingBankWaitPayPanelLayerMediator_other.NAME = "TradingBankWaitPayPanelLayerMediator_other"

function TradingBankWaitPayPanelLayerMediator_other:ctor()
    TradingBankWaitPayPanelLayerMediator_other.super.ctor(self)
end

function TradingBankWaitPayPanelLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankWaitPayPanelLayer_Open_other,
        noticeTable.Layer_TradingBankWaitPayPanelLayer_Close_other,
    }
end

function TradingBankWaitPayPanelLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankWaitPayPanelLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankWaitPayPanelLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankWaitPayPanelLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankWaitPayPanel").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankWaitPayPanelLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankWaitPayPanelLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:ExitLayer()
    TradingBankWaitPayPanelLayerMediator_other.super.CloseLayer(self)
end

return TradingBankWaitPayPanelLayerMediator_other