local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyRequestLayerMediator_other = class('TradingBankBuyRequestLayerMediator_other', BaseUIMediator)
TradingBankBuyRequestLayerMediator_other.NAME = "TradingBankBuyRequestLayerMediator_other"

function TradingBankBuyRequestLayerMediator_other:ctor()
    TradingBankBuyRequestLayerMediator_other.super.ctor(self)
end

function TradingBankBuyRequestLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankBuyRequestLayer_Open_other,
        noticeTable.Layer_TradingBankBuyRequestLayer_Close_other,
        noticeTable.Layer_TradingBankBuyRequestLayer_RefList_other
    }
end

function TradingBankBuyRequestLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankBuyRequestLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyRequestLayer_Close_other == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBankBuyRequestLayer_RefList_other == noticeName then
        self:RefList()
    end
end

function TradingBankBuyRequestLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankBuyRequestLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankBuyRequestLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

function TradingBankBuyRequestLayerMediator_other:RefList()
    if not self._layer then
        return
    end
    self._layer:RefList()
end

return TradingBankBuyRequestLayerMediator_other