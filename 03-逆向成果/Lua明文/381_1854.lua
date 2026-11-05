local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyRoleLayerMediator = class('TradingBankBuyRoleLayerMediator', BaseUIMediator)
TradingBankBuyRoleLayerMediator.NAME = "TradingBankBuyRoleLayerMediator"

function TradingBankBuyRoleLayerMediator:ctor()
    TradingBankBuyRoleLayerMediator.super.ctor(self)
end

function TradingBankBuyRoleLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable

    return {
        noticeTable.Layer_TradingBankBuyRoleLayer_Open,
        noticeTable.Layer_TradingBankBuyRoleLayer_Close,
        noticeTable.Layer_TradingBankBuyRoleLayer_Search
    }
end

function TradingBankBuyRoleLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankBuyRoleLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyRoleLayer_Close == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBankBuyRoleLayer_Search == noticeName then
        self:Search(noticeData)
    end
end

function TradingBankBuyRoleLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankBuyRoleLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankBuyRoleLayerMediator:Search(data)
    if not self._layer then
        return
    end
    self._layer:Search(data)
end

function TradingBankBuyRoleLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankBuyRoleLayerMediator