local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankLookTextureMediator = class('TradingBankLookTextureMediator', BaseUIMediator)
TradingBankLookTextureMediator.NAME = "TradingBankLookTextureMediator"

function TradingBankLookTextureMediator:ctor()
    TradingBankLookTextureMediator.super.ctor(self)
end

function TradingBankLookTextureMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankLookTexture_Open,
        noticeTable.Layer_TradingBankLookTexture_Close,
    }
end

function TradingBankLookTextureMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankLookTexture_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankLookTexture_Close == noticeName then
        self:CloseLayer()
    end
end

function TradingBankLookTextureMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankLookTextureLayer").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankLookTextureMediator.super.OpenLayer(self)
    end
end

function TradingBankLookTextureMediator:CloseLayer()
    TradingBankLookTextureMediator.super.CloseLayer(self)
end


return TradingBankLookTextureMediator