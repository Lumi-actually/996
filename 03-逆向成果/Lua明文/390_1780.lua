local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankCaptureLayerMediator = class('TradingBankCaptureLayerMediator', BaseUIMediator)
TradingBankCaptureLayerMediator.NAME = "TradingBankCaptureLayerMediator"

function TradingBankCaptureLayerMediator:ctor()
    TradingBankCaptureLayerMediator.super.ctor(self)
end

function TradingBankCaptureLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankCaptureLayer_Open,
        noticeTable.Layer_TradingBankCaptureLayer_Close,
    }
end

function TradingBankCaptureLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankCaptureLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankCaptureLayer_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankCaptureLayerMediator:OpenLayer(data)
    if not self._layer then
        self._type = global.UIZ.UI_NORMAL
        self._hideLast = false
        self._hideMain = false
        self._layer = requireLayerUI("trading_bank_layer/TradingBankCaptureLayer").create(data)
        TradingBankCaptureLayerMediator.super.OpenLayer(self)
        global.userInputController:SetKeyboardAble(false)
    end
end

function TradingBankCaptureLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    TradingBankCaptureLayerMediator.super.CloseLayer(self)
    global.userInputController:SetKeyboardAble(true)
end

return TradingBankCaptureLayerMediator