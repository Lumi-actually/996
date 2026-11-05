local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankGoodsLayerMediator_other = class('TradingBankGoodsLayerMediator_other', BaseUIMediator)
TradingBankGoodsLayerMediator_other.NAME = "TradingBankGoodsLayerMediator_other"

function TradingBankGoodsLayerMediator_other:ctor()
    TradingBankGoodsLayerMediator_other.super.ctor(self)
end

function TradingBankGoodsLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankGoodsLayer_Open_other,
        noticeTable.Layer_TradingBankGoodsLayer_Close_other,
    }
end

function TradingBankGoodsLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankGoodsLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankGoodsLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankGoodsLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankGoodsLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankGoodsLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankGoodsLayerMediator_other