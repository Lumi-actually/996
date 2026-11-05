local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankSellLayerMediator_other = class('TradingBankSellLayerMediator_other', BaseUIMediator)
TradingBankSellLayerMediator_other.NAME = "TradingBankSellLayerMediator_other"

function TradingBankSellLayerMediator_other:ctor()
    TradingBankSellLayerMediator_other.super.ctor(self)
end

function TradingBankSellLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankSellLayer_Open_other,
        noticeTable.Layer_TradingBankSellLayer_Close_other,
    }
end

function TradingBankSellLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankSellLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankSellLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankSellLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankSellLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankSellLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:ExitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankSellLayerMediator_other