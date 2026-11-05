local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankFrameMediator_other = class("TradingBankFrameMediator_other", BaseUIMediator)
TradingBankFrameMediator_other.NAME = "TradingBankFrameMediator_other"

function TradingBankFrameMediator_other:ctor()
    TradingBankFrameMediator_other.super.ctor( self )
end

function TradingBankFrameMediator_other:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return 
    {
        noticeTable.Layer_TradingBankFrame_Open_other,
        noticeTable.Layer_TradingBankFrame_Close_other,
    }
end

function TradingBankFrameMediator_other:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local id = notification:getName()
    local data = notification:getBody()

    if noticeTable.Layer_TradingBankFrame_Open_other == id then
        self:OpenLayer(data)
    elseif noticeTable.Layer_TradingBankFrame_Close_other == id then
        self:CloseLayer()
    end
end

function TradingBankFrameMediator_other:OpenLayer(data)
    if not (self._layer) then
        local path = "trading_bank_layer_other/TradingBankFrameLayer" 
        self._layer    = requireLayerUI(path).create()
        self._type     = global.UIZ.UI_NORMAL
        self._escClose = true
        self._GUI_ID   = UIConst.LAYERID.TradingBankFrame
        TradingBankFrameMediator_other.super.OpenLayer(self)
    else
        if data then 
            if self._layer:getCurPageID() == data.id then 
                self:CloseLayer()
            else
                self._layer:changPage(data.id)
            end
        end
    end
end

function TradingBankFrameMediator_other:CloseLayer()
    if self._layer then
        self._layer:OnClose()
    end
    TradingBankFrameMediator_other.super.CloseLayer(self)
end

return TradingBankFrameMediator_other
