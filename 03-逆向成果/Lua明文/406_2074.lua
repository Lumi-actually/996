local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyPurchaseEquipLayerMediator = class('TradingBankBuyPurchaseEquipLayerMediator', BaseUIMediator)
TradingBankBuyPurchaseEquipLayerMediator.NAME = "TradingBankBuyPurchaseEquipLayerMediator"
function TradingBankBuyPurchaseEquipLayerMediator:ctor()
    TradingBankBuyPurchaseEquipLayerMediator.super.ctor(self)
end

function TradingBankBuyPurchaseEquipLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankPurchaseEquipPanel_Open,
        noticeTable.Layer_TradingBankPurchaseEquipPanel_Close,
        noticeTable.Layer_TradingBankBuyEquip_Tips,
    }
end

function TradingBankBuyPurchaseEquipLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankPurchaseEquipPanel_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankPurchaseEquipPanel_Close == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBankBuyEquip_Tips == noticeName then
        self:OnTips(noticeData)
    end
end

function TradingBankBuyPurchaseEquipLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankBuyPurchaseEquipLayer").create(data)
        self._type        = global.UIZ.UI_NORMAL
        TradingBankBuyPurchaseEquipLayerMediator.super.OpenLayer(self)
    end
end

function TradingBankBuyPurchaseEquipLayerMediator:OnTips(data)
    if not self._layer then
        return
    end
    self._layer:OnTips(data)
end

function TradingBankBuyPurchaseEquipLayerMediator:CloseLayer()
   if not self._layer then
        return
    end
    self._layer:ExitLayer()
    TradingBankBuyPurchaseEquipLayerMediator.super.CloseLayer(self)
end

return TradingBankBuyPurchaseEquipLayerMediator