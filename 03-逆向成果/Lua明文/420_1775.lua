local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankCaptureLayerMediator_other = class('TradingBankCaptureLayerMediator_other', BaseUIMediator)
TradingBankCaptureLayerMediator_other.NAME = "TradingBankCaptureLayerMediator_other"

function TradingBankCaptureLayerMediator_other:ctor()
    TradingBankCaptureLayerMediator_other.super.ctor(self)
end

function TradingBankCaptureLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankCaptureLayer_Open_other,
        noticeTable.Layer_TradingBankCaptureLayer_Close_other,
    }
end

function TradingBankCaptureLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankCaptureLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankCaptureLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankCaptureLayerMediator_other:OpenLayer(data)
    if not self._layer then
        self._type = global.UIZ.UI_NORMAL
        self._hideLast = false
        self._hideMain = false
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankCaptureLayer").create(data)
        TradingBankCaptureLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankCaptureLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    TradingBankCaptureLayerMediator_other.super.CloseLayer(self)
end

return TradingBankCaptureLayerMediator_other