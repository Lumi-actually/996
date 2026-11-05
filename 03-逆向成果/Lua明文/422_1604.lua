local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankZFPanelMediator_other = class('TradingBankZFPanelMediator_other', BaseUIMediator)
TradingBankZFPanelMediator_other.NAME = "TradingBankZFPanelMediator_other"

function TradingBankZFPanelMediator_other:ctor()
    TradingBankZFPanelMediator_other.super.ctor(self)
end

function TradingBankZFPanelMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankZFPanel_Open_other,
        noticeTable.Layer_TradingBankZFPanel_Close_other,
    }
end

function TradingBankZFPanelMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankZFPanel_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankZFPanel_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankZFPanelMediator_other:OpenLayer(data)
    if not (self._layer) then
        if data.parent then
            self._layer = requireLayerUI("trading_bank_layer_other/TradingBankZFPanel").create(data)
            self._layer:addTo(data.parent)
        end
    end
end

function TradingBankZFPanelMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankZFPanelMediator_other