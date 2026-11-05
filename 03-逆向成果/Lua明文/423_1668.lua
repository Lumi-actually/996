local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankCostZFPanelMediator_other = class('TradingBankCostZFPanelMediator_other', BaseUIMediator)
TradingBankCostZFPanelMediator_other.NAME = "TradingBankCostZFPanelMediator_other"

function TradingBankCostZFPanelMediator_other:ctor()
    TradingBankCostZFPanelMediator_other.super.ctor(self)
end

function TradingBankCostZFPanelMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankCostZFPanel_Open_other,
        noticeTable.Layer_TradingBankCostZFPanel_Close_other,
    }
end

function TradingBankCostZFPanelMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankCostZFPanel_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankCostZFPanel_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankCostZFPanelMediator_other:OpenLayer(data)
    if not (self._layer) then
        if data.parent then
            self._layer = requireLayerUI("trading_bank_layer_other/TradingBankCostZFPanel").create(data)
            self._layer:addTo(data.parent)
        end
    end
end

function TradingBankCostZFPanelMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankCostZFPanelMediator_other