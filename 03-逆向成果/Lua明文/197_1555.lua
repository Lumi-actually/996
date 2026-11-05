local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankPhoneLayerMediator = class('TradingBankPhoneLayerMediator', BaseUIMediator)
TradingBankPhoneLayerMediator.NAME = "TradingBankPhoneLayerMediator"

function TradingBankPhoneLayerMediator:ctor()
    TradingBankPhoneLayerMediator.super.ctor(self)
end

function TradingBankPhoneLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankPhoneLayer_Open,
        noticeTable.Layer_TradingBankPhoneLayer_Close,
    }
end

function TradingBankPhoneLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankPhoneLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankPhoneLayer_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankPhoneLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._type = global.UIZ.UI_NORMAL
        self._layer = requireLayerUI("trading_bank_layer/TradingBankPhoneLayer").create(data)
        TradingBankPhoneLayerMediator.super.OpenLayer(self)
    end
end

function TradingBankPhoneLayerMediator:CloseLayer()
    if self._layer then
        self._layer:exitLayer()
    end
    TradingBankPhoneLayerMediator.super.CloseLayer(self)
end


return TradingBankPhoneLayerMediator