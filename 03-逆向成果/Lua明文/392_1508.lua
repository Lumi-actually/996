local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankZFPanelMediator = class('TradingBankZFPanelMediator', BaseUIMediator)
TradingBankZFPanelMediator.NAME = "TradingBankZFPanelMediator"

function TradingBankZFPanelMediator:ctor()
    TradingBankZFPanelMediator.super.ctor(self)
end

function TradingBankZFPanelMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankZFPanel_Open,
        noticeTable.Layer_TradingBankZFPanel_Close,
    }
end

function TradingBankZFPanelMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankZFPanel_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankZFPanel_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankZFPanelMediator:OpenLayer(data)
    if not (self._layer) then
        if data.parent then
            self._layer = requireLayerUI("trading_bank_layer/TradingBankZFPanel").create(data)
            self._layer:addTo(data.parent)
        end
    end
end

function TradingBankZFPanelMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankZFPanelMediator