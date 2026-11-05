local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyMoneyLayerMediator = class('TradingBankBuyMoneyLayerMediator', BaseUIMediator)
TradingBankBuyMoneyLayerMediator.NAME = "TradingBankBuyMoneyLayerMediator"
function TradingBankBuyMoneyLayerMediator:ctor()
    TradingBankBuyMoneyLayerMediator.super.ctor(self)
end

function TradingBankBuyMoneyLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankBuyMoneyLayer_Open,
        noticeTable.Layer_TradingBankBuyMoneyLayer_Close,
    }
end

function TradingBankBuyMoneyLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankBuyMoneyLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyMoneyLayer_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankBuyMoneyLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankBuyMoneyLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankBuyMoneyLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankBuyMoneyLayerMediator