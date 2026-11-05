local BaseUIMediator        = requireMediator("BaseUIMediator")
local TradingBankRequestQgOrderLayerMediator = class('TradingBankRequestQgOrderLayerMediator', BaseUIMediator)
TradingBankRequestQgOrderLayerMediator.NAME = "TradingBankRequestQgOrderLayerMediator"

function TradingBankRequestQgOrderLayerMediator:ctor()
    TradingBankRequestQgOrderLayerMediator.super.ctor(self)
end

function TradingBankRequestQgOrderLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable

    return {
        noticeTable.Layer_TradingBankOrderLayertwo_open,
        noticeTable.Layer_TradingBankOrderLayertwo_close,
        noticeTable.Layer_TradingBankOrderLayer_Update,
    }
end

function TradingBankRequestQgOrderLayerMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody() 
    if noticeTable.Layer_TradingBankOrderLayertwo_open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankOrderLayertwo_close == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBankOrderLayer_Update == noticeName then
        self:updateTitle(noticeData)
    end
end

function TradingBankRequestQgOrderLayerMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankRequestOrderLayer").create(data)
        self._type        = global.UIZ.UI_NORMAL
        TradingBankRequestQgOrderLayerMediator.super.OpenLayer(self)
    end
end

function TradingBankRequestQgOrderLayerMediator:Search(data)
    if not self._layer then
        return
    end
    self._layer:Search(data)
end

function TradingBankRequestQgOrderLayerMediator:TypeChange(data)
    if not self._layer then
        return
    end
    self._layer:TypeChange(data)
end

function TradingBankRequestQgOrderLayerMediator:OnTips(data)
    if not self._layer then
        return
    end
    self._layer:OnTips(data)
end


function TradingBankRequestQgOrderLayerMediator:updateTitle(data)
    if not self._layer then
        return
    end
    self._layer:updateTitle(data)
end

function TradingBankRequestQgOrderLayerMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:exitLayer()
    TradingBankRequestQgOrderLayerMediator.super.CloseLayer(self)
end

return TradingBankRequestQgOrderLayerMediator