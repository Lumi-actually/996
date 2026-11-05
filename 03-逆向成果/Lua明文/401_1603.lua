local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankReceiveLayerMediator = class('TradingBankReceiveLayerMediator', BaseUIMediator)
TradingBankReceiveLayerMediator.NAME = "TradingBankReceiveLayerMediator"

function TradingBankReceiveLayerMediator:ctor()
    TradingBankReceiveLayerMediator.super.ctor(self)
end

function TradingBankReceiveLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankReceiveLayer_Open,
        noticeTable.Layer_TradingBankReceiveLayer_Close,
    }
end

function TradingBankReceiveLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankReceiveLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankReceiveLayer_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankReceiveLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankReceiveLayer").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankReceiveLayerMediator.super.OpenLayer(self)
    end
end

function TradingBankReceiveLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    TradingBankReceiveLayerMediator.super.CloseLayer(self)
end

return TradingBankReceiveLayerMediator