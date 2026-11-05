local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyMoneyLayerMediator_other = class('TradingBankBuyMoneyLayerMediator_other', BaseUIMediator)
TradingBankBuyMoneyLayerMediator_other.NAME = "TradingBankBuyMoneyLayerMediator_other"

function TradingBankBuyMoneyLayerMediator_other:ctor()
    TradingBankBuyMoneyLayerMediator_other.super.ctor(self)
end

function TradingBankBuyMoneyLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankBuyMoneyLayer_Open_other,
        noticeTable.Layer_TradingBankBuyMoneyLayer_Close_other,
    }
end

function TradingBankBuyMoneyLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankBuyMoneyLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyMoneyLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankBuyMoneyLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankBuyMoneyLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankBuyMoneyLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankBuyMoneyLayerMediator_other