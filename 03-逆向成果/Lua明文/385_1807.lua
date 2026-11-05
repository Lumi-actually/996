local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyMeLayerMediator = class('TradingBankBuyMeLayerMediator', BaseUIMediator)
TradingBankBuyMeLayerMediator.NAME = "TradingBankBuyMeLayerMediator"
function TradingBankBuyMeLayerMediator:ctor()
    TradingBankBuyMeLayerMediator.super.ctor(self)
end

function TradingBankBuyMeLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankBuyMeLayer_Open,
        noticeTable.Layer_TradingBankBuyMeLayer_Close,
        noticeTable.Layer_TradingBankBuyEquip_Tips,
    }
end

function TradingBankBuyMeLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankBuyMeLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyMeLayer_Close == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBankBuyEquip_Tips == noticeName then
        self:OnTips(noticeData)
    end
end

function TradingBankBuyMeLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankBuyMeLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankBuyMeLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

function TradingBankBuyMeLayerMediator:OnTips(data)
    if not self._layer then
        return
    end
    self._layer:OnTips(data)
end

return TradingBankBuyMeLayerMediator