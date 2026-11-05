local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankBuyLayerMediator_other = class('TradingBankBuyLayerMediator_other', BaseUIMediator)
TradingBankBuyLayerMediator_other.NAME = "TradingBankBuyLayerMediator_other"

function TradingBankBuyLayerMediator_other:ctor()
    TradingBankBuyLayerMediator_other.super.ctor(self)
end

function TradingBankBuyLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable

    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "TradingBankBuyLayerMediator_other", handler(self, self.ProxyInit))

    return {
        noticeTable.Layer_TradingBankBuyLayer_Open_other,
        noticeTable.Layer_TradingBankBuyLayer_Close_other,
    }
end

function TradingBankBuyLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankBuyLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankBuyLayer_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankBuyLayerMediator_other:ProxyInit()
    local OtherTradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.OtherTradingBankProxy)
    OtherTradingBankProxy:init()
end

function TradingBankBuyLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankBuyLayer").create()
        data.parent:addChild(self._layer)
    else
        self:CloseLayer()
    end
end

function TradingBankBuyLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    self._layer:removePanel()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankBuyLayerMediator_other