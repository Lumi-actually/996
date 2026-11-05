local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankLookTextureMediator_other = class('TradingBankLookTextureMediator_other', BaseUIMediator)
TradingBankLookTextureMediator_other.NAME = "TradingBankLookTextureMediator_other"

function TradingBankLookTextureMediator_other:ctor()
    TradingBankLookTextureMediator_other.super.ctor(self)
end

function TradingBankLookTextureMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankLookTexture_Open_other,
        noticeTable.Layer_TradingBankLookTexture_Close_other,
    }
end

function TradingBankLookTextureMediator_other:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()

    if noticeTable.Layer_TradingBankLookTexture_Open_other == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankLookTexture_Close_other == noticeName then
        self:CloseLayer()
    end
end

function TradingBankLookTextureMediator_other:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer_other/TradingBankLookTextureLayer").create(data)
        self._type = global.UIZ.UI_NORMAL
        TradingBankLookTextureMediator_other.super.OpenLayer(self)
    end
end

function TradingBankLookTextureMediator_other:CloseLayer()
    TradingBankLookTextureMediator_other.super.CloseLayer(self)
end

return TradingBankLookTextureMediator_other