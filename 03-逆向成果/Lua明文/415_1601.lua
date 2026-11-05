local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyMeLayerMediator_other = class('TradingBankBuyMeLayerMediator_other', BaseUIMediator)
TradingBankBuyMeLayerMediator_other.NAME = "TradingBankBuyMeLayerMediator_other"

function TradingBankBuyMeLayerMediator_other:ctor()
    TradingBankBuyMeLayerMediator_other.super.ctor(self)
end

function TradingBankBuyMeLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankBuyMeLayer_Open_other,
        noticeTable.Layer_TradingBankBuyMeLayer_Close_other,
    }
end

function TradingBankBuyMeLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankBuyMeLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyMeLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankBuyMeLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankBuyMeLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankBuyMeLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankBuyMeLayerMediator_other