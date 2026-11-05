local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankSuggestPanelLayerMediator_other = class('TradingBankSuggestPanelLayerMediator_other', BaseUIMediator)
TradingBankSuggestPanelLayerMediator_other.NAME = "TradingBankSuggestPanelLayerMediator_other"

function TradingBankSuggestPanelLayerMediator_other:ctor()
    TradingBankSuggestPanelLayerMediator_other.super.ctor(self)
end

function TradingBankSuggestPanelLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankSuggestPanelLayer_Open_other,
        noticeTable.Layer_TradingBankSuggestPanelLayer_Close_other,
    }
end

function TradingBankSuggestPanelLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankSuggestPanelLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankSuggestPanelLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankSuggestPanelLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankSuggestPanel").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankSuggestPanelLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankSuggestPanelLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:ExitLayer()
    TradingBankSuggestPanelLayerMediator_other.super.CloseLayer(self)
end

return TradingBankSuggestPanelLayerMediator_other