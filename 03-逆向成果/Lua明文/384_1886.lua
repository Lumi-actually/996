local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuySeekBuyLayerMediator = class('TradingBankBuySeekBuyLayerMediator', BaseUIMediator)
TradingBankBuySeekBuyLayerMediator.NAME = "TradingBankBuySeekBuyLayerMediator"
function TradingBankBuySeekBuyLayerMediator:ctor()
    TradingBankBuySeekBuyLayerMediator.super.ctor(self)
end

function TradingBankBuySeekBuyLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankSeekBuyLayer_Open,
        noticeTable.Layer_TradingBankSeekBuyLayer_Close,
        noticeTable.Layer_TradingBankSeekBuyLayer_Update,
    }
end

function TradingBankBuySeekBuyLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankSeekBuyLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankSeekBuyLayer_Close == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBankSeekBuyLayer_Update == noticeName then
        self:UpdateList()
    end
end

function TradingBankBuySeekBuyLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankBuySeekBuyLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankBuySeekBuyLayerMediator:UpdateList()
    if not self._layer then
        return
    end
    self._layer:UpdateList()
end

function TradingBankBuySeekBuyLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankBuySeekBuyLayerMediator