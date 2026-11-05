local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankSupplyEquipLayerMediator = class('TradingBankSupplyEquipLayerMediator', BaseUIMediator)
TradingBankSupplyEquipLayerMediator.NAME = "TradingBankSupplyEquipLayerMediator"

function TradingBankSupplyEquipLayerMediator:ctor()
    TradingBankSupplyEquipLayerMediator.super.ctor(self)
end

function TradingBankSupplyEquipLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankSupplyEquipPanel_Open,
        noticeTable.Layer_TradingBankSupplyEquipPanel_Close,
        noticeTable.Layer_TradingBankBuyEquip_Tips,
    }
end

function TradingBankSupplyEquipLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankSupplyEquipPanel_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankSupplyEquipPanel_Close == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBankBuyEquip_Tips == noticeName then
        self:OnTips(noticeData)
    end
end

function TradingBankSupplyEquipLayerMediator:OpenLayer(data)
    -- if not (self._layer) then
    --     self._layer = requireLayerUI("trading_bank_layer/TradingBankSupplyEquipLayer").create()
    --     data.parent:addChild(self._layer)
    -- end

     if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankSupplyEquipLayer").create(data)
        self._type        = global.UIZ.UI_NORMAL
        TradingBankSupplyEquipLayerMediator.super.OpenLayer(self)
    end

end

function TradingBankSupplyEquipLayerMediator:CloseLayer()
    if not self._layer then
        return
    end

    self._layer:ExitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

function TradingBankSupplyEquipLayerMediator:OnTips(data)
    if not self._layer then
        return
    end
    self._layer:OnTips(data)
end

function TradingBankSupplyEquipLayerMediator:OnUpdateBag(data)
    -- if self._layer then
    --     self._layer:UpdateBag(data)
    -- end
end

return TradingBankSupplyEquipLayerMediator