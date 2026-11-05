local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankMeLayerMediator_other = class('TradingBankMeLayerMediator_other', BaseUIMediator)
TradingBankMeLayerMediator_other.NAME = "TradingBankMeLayerMediator_other"

function TradingBankMeLayerMediator_other:ctor()
    TradingBankMeLayerMediator_other.super.ctor(self)
end

function TradingBankMeLayerMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankMeLayer_Open_other,
        noticeTable.Layer_TradingBankMeLayer_Close_other,
        noticeTable.Layer_TradingBankMeLayer_ShowGetMoneyRecord_other
    }
end

function TradingBankMeLayerMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankMeLayer_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankMeLayer_Close_other == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBankMeLayer_ShowGetMoneyRecord_other == noticeName then
        self:ShowGetMoneyRecord(noticeData)
    end
end

function TradingBankMeLayerMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankMeLayer").create()
        data.parent:addChild(self._layer)
    end
end

function TradingBankMeLayerMediator_other:ShowGetMoneyRecord(noticeData)
    if not self._layer then
        return
    end
    self._layer:ShowGetMoneyRecord(noticeData)
end

function TradingBankMeLayerMediator_other:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:ExitLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

return TradingBankMeLayerMediator_other