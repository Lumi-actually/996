local BaseUIMediator        = requireMediator("BaseUIMediator")
local TradingBankBuyAllLayerMediator = class('TradingBankBuyAllLayerMediator', BaseUIMediator)
TradingBankBuyAllLayerMediator.NAME = "TradingBankBuyAllLayerMediator"
function TradingBankBuyAllLayerMediator:ctor()
    TradingBankBuyAllLayerMediator.super.ctor(self)
end

function TradingBankBuyAllLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankBuyAllLayer_Open,
        noticeTable.Layer_TradingBankBuyAllLayer_Close,
        noticeTable.Layer_TradingBankBuyEquip_Tips,
    }
end

function TradingBankBuyAllLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankBuyAllLayer_Open == noticeName then

        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyAllLayer_Close == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBankBuyEquip_Tips == noticeName then
        self:OnTips(noticeData)
    end
end
function TradingBankBuyAllLayerMediator:OpenLayer(Data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankBuyAllLayer").create()
        Data.parent:addChild(self._layer)
    end
end

function TradingBankBuyAllLayerMediator:OnTips(data)
    if not self._layer then
        return
    end
    self._layer:OnTips(data)
end
function TradingBankBuyAllLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end


return TradingBankBuyAllLayerMediator