local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankPlayerInfoMediator = class('TradingBankPlayerInfoMediator', BaseUIMediator)
TradingBankPlayerInfoMediator.NAME = "TradingBankPlayerInfoMediator"

function TradingBankPlayerInfoMediator:ctor()
    TradingBankPlayerInfoMediator.super.ctor(self)
end

function TradingBankPlayerInfoMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankPlayerInfo_Open,
        noticeTable.Layer_TradingBankPlayerInfo_Close,
    }
end

function TradingBankPlayerInfoMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankPlayerInfo_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankPlayerInfo_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankPlayerInfoMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankPlayerInfo").create(data)
        self._type = global.UIZ.UI_NORMAL
        self._responseMoved = self._layer._root.Panel_1
        TradingBankPlayerInfoMediator.super.OpenLayer(self)
    end
end

function TradingBankPlayerInfoMediator:CloseLayer()
    TradingBankPlayerInfoMediator.super.CloseLayer(self)
end

return TradingBankPlayerInfoMediator