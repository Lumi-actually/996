local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankLookOtherServerPlayerLayerMediator_other = class('TradingBankLookOtherServerPlayerLayerMediator_other', BaseUIMediator)
TradingBankLookOtherServerPlayerLayerMediator_other.NAME = "TradingBankLookOtherServerPlayerLayerMediator_other"

function TradingBankLookOtherServerPlayerLayerMediator_other:ctor()
    TradingBankLookOtherServerPlayerLayerMediator_other.super.ctor(self)
end

function TradingBankLookOtherServerPlayerLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable

    return {
        noticeTable.Layer_TradingBankLookOtherServerPlayerLayer_Open_other,
        noticeTable.Layer_TradingBankLookOtherServerPlayerLayer_Close_other,
    }
end

function TradingBankLookOtherServerPlayerLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankLookOtherServerPlayerLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankLookOtherServerPlayerLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankLookOtherServerPlayerLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankLookOtherServerPlayerLayer").create(data)
        self._type  = global.UIZ.UI_NORMAL
        TradingBankLookOtherServerPlayerLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankLookOtherServerPlayerLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    TradingBankLookOtherServerPlayerLayerMediator_other.super.CloseLayer(self)
end

return TradingBankLookOtherServerPlayerLayerMediator_other