local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyTipsLayerMediator_other = class('TradingBankBuyTipsLayerMediator_other', BaseUIMediator)
TradingBankBuyTipsLayerMediator_other.NAME = "TradingBankBuyTipsLayerMediator_other"

function TradingBankBuyTipsLayerMediator_other:ctor()
    TradingBankBuyTipsLayerMediator_other.super.ctor(self)
end

function TradingBankBuyTipsLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable

    return {
        noticeTable.Layer_TradingBankBuyTipsLayer_Open_other,
        noticeTable.Layer_TradingBankBuyTipsLayer_Close_other,
    }
end

function TradingBankBuyTipsLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankBuyTipsLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyTipsLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankBuyTipsLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankBuyTipsLayer").create(data)
        self._type  = global.UIZ.UI_TOBOX
        TradingBankBuyTipsLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankBuyTipsLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    TradingBankBuyTipsLayerMediator_other.super.CloseLayer(self)
end

return TradingBankBuyTipsLayerMediator_other