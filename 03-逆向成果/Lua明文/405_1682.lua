local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankSupplyMoneyPanelMediator = class('TradingBankSupplyMoneyPanelMediator', BaseUIMediator)
TradingBankSupplyMoneyPanelMediator.NAME = "TradingBankSupplyMoneyPanelMediator"

function TradingBankSupplyMoneyPanelMediator:ctor()
    TradingBankSupplyMoneyPanelMediator.super.ctor(self)
end

function TradingBankSupplyMoneyPanelMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankSupplyMoneyPanel_Open,
        noticeTable.Layer_TradingBankSupplyMoneyPanel_Close,
    }
end

function TradingBankSupplyMoneyPanelMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankSupplyMoneyPanel_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankSupplyMoneyPanel_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankSupplyMoneyPanelMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankSupplyMoneyPanel").create(data)
        self._type        = global.UIZ.UI_NORMAL
        TradingBankSupplyMoneyPanelMediator.super.OpenLayer(self)
    end
end

function TradingBankSupplyMoneyPanelMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:ExitLayer()
    TradingBankSupplyMoneyPanelMediator.super.CloseLayer(self)
end

return TradingBankSupplyMoneyPanelMediator