local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankTipsLayerMediator = class('TradingBankTipsLayerMediator', BaseUIMediator)
TradingBankTipsLayerMediator.NAME = "TradingBankTipsLayerMediator"

function TradingBankTipsLayerMediator:ctor()
    TradingBankTipsLayerMediator.super.ctor(self)
    self._mr = global.UIZ.UI_NORMAL
end

function TradingBankTipsLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "TradingBankTipsLayerMediator", function ()
        self._mr = global.UIZ.UI_TOBOX
    end)

    return {
        noticeTable.Layer_TradingBankTipsLayer_Open,
        noticeTable.Layer_TradingBankTipsLayer_Close,
    }
end

function TradingBankTipsLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankTipsLayer_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankTipsLayer_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankTipsLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankTipsLayer").create(data)
        self._type        = self._mr
        if data and data.canmove then
            self._type        = global.UIZ.UI_NORMAL
            self._responseMoved = self._layer._root.Image_1
        else
            self._responseMoved = nil
        end
        TradingBankTipsLayerMediator.super.OpenLayer(self)
    end
end

function TradingBankTipsLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    TradingBankTipsLayerMediator.super.CloseLayer(self)
end

return TradingBankTipsLayerMediator