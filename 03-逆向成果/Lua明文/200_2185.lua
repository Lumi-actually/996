local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankPhoneLayerMediator_other = class('TradingBankPhoneLayerMediator_other', BaseUIMediator)
TradingBankPhoneLayerMediator_other.NAME = "TradingBankPhoneLayerMediator_other"

function TradingBankPhoneLayerMediator_other:ctor()
    TradingBankPhoneLayerMediator_other.super.ctor(self)
end

function TradingBankPhoneLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankPhoneLayer_Open_other,
        noticeTable.Layer_TradingBankPhoneLayer_Close_other,
        noticeTable.Layer_TradingBank_Interface_other,
    }
end

function TradingBankPhoneLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankPhoneLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankPhoneLayer_Close_other == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBank_Interface_other == noticeName then
        self:onInterface(noticeData)
    end
end

function TradingBankPhoneLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._type = global.UIZ.UI_NORMAL
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankPhoneLayer").create(data)
        TradingBankPhoneLayerMediator_other.super.OpenLayer(self)
    end
end

function TradingBankPhoneLayerMediator_other:CloseLayer()
    if self._layer then
        self._layer:exitLayer()
    end
    TradingBankPhoneLayerMediator_other.super.CloseLayer(self)
end

function TradingBankPhoneLayerMediator_other:onInterface(data)
    local OtherTradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.OtherTradingBankProxy)
    if not OtherTradingBankProxy then 
        return 
    end
    if data and data.index then 
        OtherTradingBankProxy:callFunc(data.index,data.jsonString)
    end 
end

return TradingBankPhoneLayerMediator_other