local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyLayerMediator = class('TradingBankBuyLayerMediator', BaseUIMediator)
TradingBankBuyLayerMediator.NAME = "TradingBankBuyLayerMediator"

function TradingBankBuyLayerMediator:ctor()
    TradingBankBuyLayerMediator.super.ctor(self)
end

function TradingBankBuyLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "TradingBankBuyLayerMediator", handler(self, self.ProxyInit))

    return {
        noticeTable.Layer_TradingBankBuyLayer_Open,
        noticeTable.Layer_TradingBankBuyLayer_Close,
    }
end

function TradingBankBuyLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankBuyLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyLayer_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankBuyLayerMediator:ProxyInit()
    local TradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.TradingBankProxy)
    TradingBankProxy:init()
end

function TradingBankBuyLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankBuyLayer").create()
        data.parent:addChild(self._layer)
    else
        self:CloseLayer()
    end
end

function TradingBankBuyLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:ExitLayer()
    self._layer:RemovePanel()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankBuyLayerMediator