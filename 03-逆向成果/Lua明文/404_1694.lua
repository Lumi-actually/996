local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankDownGetEquipPanelMediator = class('TradingBankDownGetEquipPanelMediator', BaseUIMediator)
TradingBankDownGetEquipPanelMediator.NAME = "TradingBankDownGetEquipPanelMediator"

function TradingBankDownGetEquipPanelMediator:ctor()
    TradingBankDownGetEquipPanelMediator.super.ctor(self)
end

function TradingBankDownGetEquipPanelMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankDownGetEquipPanel_Open,
        noticeTable.Layer_TradingBankDownGetEquipPanel_Close,
    }
end

function TradingBankDownGetEquipPanelMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankDownGetEquipPanel_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankDownGetEquipPanel_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankDownGetEquipPanelMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankDownGetEquipPanel").create(data)
        self._type  = global.UIZ.UI_NORMAL
        TradingBankDownGetEquipPanelMediator.super.OpenLayer(self)
    end
end

function TradingBankDownGetEquipPanelMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:ExitLayer()
    TradingBankDownGetEquipPanelMediator.super.CloseLayer(self)
end

return TradingBankDownGetEquipPanelMediator