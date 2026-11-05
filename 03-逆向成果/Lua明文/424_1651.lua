local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankPlayerInfoMediator_other = class('TradingBankPlayerInfoMediator_other', BaseUIMediator)
TradingBankPlayerInfoMediator_other.NAME = "TradingBankPlayerInfoMediator_other"

function TradingBankPlayerInfoMediator_other:ctor()
    TradingBankPlayerInfoMediator_other.super.ctor(self)
end

function TradingBankPlayerInfoMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankPlayerInfo_Open_other,
        noticeTable.Layer_TradingBankPlayerInfo_Close_other,
    }
end

function TradingBankPlayerInfoMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankPlayerInfo_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankPlayerInfo_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankPlayerInfoMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankPlayerInfo").create(data)
        self._type = global.UIZ.UI_NORMAL
        self._responseMoved = self._layer._root.Panel_1
        TradingBankPlayerInfoMediator_other.super.OpenLayer(self)
    end
end

function TradingBankPlayerInfoMediator_other:CloseLayer()
    TradingBankPlayerInfoMediator_other.super.CloseLayer(self)
end

return TradingBankPlayerInfoMediator_other