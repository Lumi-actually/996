local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyRoleLayerMediator_other = class('TradingBankBuyRoleLayerMediator_other', BaseUIMediator)
TradingBankBuyRoleLayerMediator_other.NAME = "TradingBankBuyRoleLayerMediator_other"

function TradingBankBuyRoleLayerMediator_other:ctor()
    TradingBankBuyRoleLayerMediator_other.super.ctor(self)
end

function TradingBankBuyRoleLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable

    return {
        noticeTable.Layer_TradingBankBuyRoleLayer_Open_other,
        noticeTable.Layer_TradingBankBuyRoleLayer_Close_other,
        noticeTable.Layer_TradingBankBuyRoleLayer_Search_other
    }
end

function TradingBankBuyRoleLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankBuyRoleLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyRoleLayer_Close_other == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBankBuyRoleLayer_Search_other == noticeName then
        self:Search(noticeData)
    end
end

function TradingBankBuyRoleLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankBuyRoleLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankBuyRoleLayerMediator_other:Search(data)
    if not self._layer then
        return
    end
    self._layer:Search(data)
end

function TradingBankBuyRoleLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankBuyRoleLayerMediator_other