local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankReceiveLayerMediator_other = class('TradingBankReceiveLayerMediator_other', BaseUIMediator)
TradingBankReceiveLayerMediator_other.NAME = "TradingBankReceiveLayerMediator_other"

function TradingBankReceiveLayerMediator_other:ctor()
    TradingBankReceiveLayerMediator_other.super.ctor(self)
end

function TradingBankReceiveLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankReceiveLayer_Open_other,
        noticeTable.Layer_TradingBankReceiveLayer_Close_other,
    }
end

function TradingBankReceiveLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankReceiveLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankReceiveLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankReceiveLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankReceiveLayer").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankReceiveLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankReceiveLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    TradingBankReceiveLayerMediator_other.super.CloseLayer(self)
end

return TradingBankReceiveLayerMediator_other