local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankGoodsLayerMediator = class('TradingBankGoodsLayerMediator', BaseUIMediator)
TradingBankGoodsLayerMediator.NAME = "TradingBankGoodsLayerMediator"

function TradingBankGoodsLayerMediator:ctor()
    TradingBankGoodsLayerMediator.super.ctor(self)
end

function TradingBankGoodsLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankGoodsLayer_Open,
        noticeTable.Layer_TradingBankGoodsLayer_Close,
        noticeTable.Layer_TradingBankBuyEquip_Tips,
    }
end

function TradingBankGoodsLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankGoodsLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankGoodsLayer_Close == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBankBuyEquip_Tips == noticeName then
        self:OnTips(noticeData)
    end
end

function TradingBankGoodsLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankGoodsLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankGoodsLayerMediator:OnTips(data)
    if not self._layer then
        return
    end
    self._layer:OnTips(data)
end

function TradingBankGoodsLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end


return TradingBankGoodsLayerMediator