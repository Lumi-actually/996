local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankCaptureMaskLayerMediator = class('TradingBankCaptureMaskLayerMediator', BaseUIMediator)
TradingBankCaptureMaskLayerMediator.NAME = "TradingBankCaptureMaskLayerMediator"

function TradingBankCaptureMaskLayerMediator:ctor()
    TradingBankCaptureMaskLayerMediator.super.ctor(self)
end

function TradingBankCaptureMaskLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankCaptureMaskLayer_Open,
        noticeTable.Layer_TradingBankCaptureMaskLayer_Close,
    }
end

function TradingBankCaptureMaskLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankCaptureMaskLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankCaptureMaskLayer_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankCaptureMaskLayerMediator:OpenLayer(data)
    if not self._layer then
        self._type = global.UIZ.UI_MASK
        self._hideLast = false
        self._hideMain = false
        self._layer = requireLayerUI("trading_bank_layer/TradingBankCaptureMaskLayer").create(data)
        TradingBankCaptureMaskLayerMediator.super.OpenLayer(self)
    end
end

function TradingBankCaptureMaskLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    TradingBankCaptureMaskLayerMediator.super.CloseLayer(self)
end

return TradingBankCaptureMaskLayerMediator