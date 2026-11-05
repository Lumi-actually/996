local BaseUIMediator= requireMediator("BaseUIMediator")
local TradingBankMeRecodPanelLayerMediator_other = class('TradingBankMeRecodPanelLayerMediator_other', BaseUIMediator)
TradingBankMeRecodPanelLayerMediator_other.NAME = "TradingBankMeRecodPanelLayerMediator_other"

function TradingBankMeRecodPanelLayerMediator_other:ctor()
    TradingBankMeRecodPanelLayerMediator_other.super.ctor(self)
end

function TradingBankMeRecodPanelLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankMeRecordPanelLayer_Open_other,
        noticeTable.Layer_TradingBankMeRecordPanelLayer_Close_other,
    }
end

function TradingBankMeRecodPanelLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankMeRecordPanelLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankMeRecordPanelLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end
function TradingBankMeRecodPanelLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankMeRecordPanel").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankMeRecodPanelLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankMeRecodPanelLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    TradingBankMeRecodPanelLayerMediator_other.super.CloseLayer(self)
end

return TradingBankMeRecodPanelLayerMediator_other