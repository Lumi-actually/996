local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankCaptureMaskLayerMediator_other = class('TradingBankCaptureMaskLayerMediator_other', BaseUIMediator)
TradingBankCaptureMaskLayerMediator_other.NAME = "TradingBankCaptureMaskLayerMediator_other"

function TradingBankCaptureMaskLayerMediator_other:ctor()
    TradingBankCaptureMaskLayerMediator_other.super.ctor(self)
end

function TradingBankCaptureMaskLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankCaptureMaskLayer_Open_other,
        noticeTable.Layer_TradingBankCaptureMaskLayer_Close_other,
    }
end

function TradingBankCaptureMaskLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankCaptureMaskLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankCaptureMaskLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankCaptureMaskLayerMediator_other:OpenLayer(data)
    if not self._layer then
        self._type = global.UIZ.UI_MASK
        self._hideLast = false
        self._hideMain = false
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankCaptureMaskLayer").create(data)
        TradingBankCaptureMaskLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankCaptureMaskLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    TradingBankCaptureMaskLayerMediator_other.super.CloseLayer(self)
end

return TradingBankCaptureMaskLayerMediator_other