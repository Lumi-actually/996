local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyEquipLayerMediator = class('TradingBankBuyEquipLayerMediator', BaseUIMediator)
TradingBankBuyEquipLayerMediator.NAME = "TradingBankBuyEquipLayerMediator"

function TradingBankBuyEquipLayerMediator:ctor()
    TradingBankBuyEquipLayerMediator.super.ctor(self)
end

function TradingBankBuyEquipLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable

    return {
        noticeTable.Layer_TradingBankBuyEquipLayer_Open,
        noticeTable.Layer_TradingBankBuyEquipLayer_Close,
        noticeTable.Layer_TradingBankBuyEquipLayer_Search,
        noticeTable.Layer_TradingBankBuyEquip_Tips,
        noticeTable.Layer_TradingBankBuyEquipLayer_TypeChange
    }
end

function TradingBankBuyEquipLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankBuyEquipLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyEquipLayer_Close == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBankBuyEquipLayer_Search == noticeName then
        self:Search(noticeData)
    elseif noticeTable.Layer_TradingBankBuyEquip_Tips == noticeName then
        self:OnTips(noticeData)
    elseif noticeTable.Layer_TradingBankBuyEquipLayer_TypeChange == noticeName then
        self:TypeChange(noticeData)
    end
end

function TradingBankBuyEquipLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankBuyEquipLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankBuyEquipLayerMediator:Search(data)
    if not self._layer then
        return
    end
    self._layer:Search(data)
end

function TradingBankBuyEquipLayerMediator:TypeChange(data)
    if not self._layer then
        return
    end
    self._layer:TypeChange(data)
end

function TradingBankBuyEquipLayerMediator:OnTips(data)
    if not self._layer then
        return
    end
    self._layer:OnTips(data)
end

function TradingBankBuyEquipLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:ExitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankBuyEquipLayerMediator