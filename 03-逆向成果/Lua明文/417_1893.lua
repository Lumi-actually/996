local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyServerNameTipsLayerMediator_other = class('TradingBankBuyServerNameTipsLayerMediator_other', BaseUIMediator)
TradingBankBuyServerNameTipsLayerMediator_other.NAME = "TradingBankBuyServerNameTipsLayerMediator_other"

function TradingBankBuyServerNameTipsLayerMediator_other:ctor()
    TradingBankBuyServerNameTipsLayerMediator_other.super.ctor(self)
end

function TradingBankBuyServerNameTipsLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable

    return {
        noticeTable.Layer_TradingBankBuyServerNameTipsLayer_Open_other,
        noticeTable.Layer_TradingBankBuyServerNameTipsLayer_Close_other,
    }
end

function TradingBankBuyServerNameTipsLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankBuyServerNameTipsLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyServerNameTipsLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankBuyServerNameTipsLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankBuyServerNameTipsLayer").create(data)
        self._type  = global.UIZ.UI_TOBOX
        TradingBankBuyServerNameTipsLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankBuyServerNameTipsLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    TradingBankBuyServerNameTipsLayerMediator_other.super.CloseLayer(self)
end

return TradingBankBuyServerNameTipsLayerMediator_other