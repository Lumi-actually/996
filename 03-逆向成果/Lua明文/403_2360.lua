local BaseUIMediator = requireMediator("BaseUIMediator")
local TradingBankUpModifyEquipPanelMediator = class('TradingBankUpModifyEquipPanelMediator', BaseUIMediator)
TradingBankUpModifyEquipPanelMediator.NAME = "TradingBankUpModifyEquipPanelMediator"

function TradingBankUpModifyEquipPanelMediator:ctor()
    TradingBankUpModifyEquipPanelMediator.super.ctor(self)
end

function TradingBankUpModifyEquipPanelMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_TradingBankUpModifyEquipPanel_Open,
        noticeTable.Layer_TradingBankUpModifyEquipPanel_Close,
        noticeTable.Layer_TradingBankUpModifyEquipPanel_CheckSuccess,
        noticeTable.Layer_Box996SVIP_Refresh,
    }
end

function TradingBankUpModifyEquipPanelMediator:handleNotification(notification)
    local noticeName    = notification:getName()
    local noticeTable   = global.NoticeTable
    local noticeData    = notification:getBody()
    if noticeTable.Layer_TradingBankUpModifyEquipPanel_Open == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.Layer_TradingBankUpModifyEquipPanel_Close == noticeName then
        self:CloseLayer()
    elseif noticeTable.Layer_TradingBankUpModifyEquipPanel_CheckSuccess == noticeName then
        self:CheckSuccess()
    elseif noticeTable.Layer_Box996SVIP_Refresh == noticeName then
        self:OnRefresh(noticeData)
    end
end

function TradingBankUpModifyEquipPanelMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("trading_bank_layer/TradingBankUpModifyEquipPanel").create(data)
        self._type        = global.UIZ.UI_NORMAL
        TradingBankUpModifyEquipPanelMediator.super.OpenLayer(self)
    end
end

function TradingBankUpModifyEquipPanelMediator:CloseLayer()
    if not self._layer then
        return
    end
    self._layer:ExitLayer()
    TradingBankUpModifyEquipPanelMediator.super.CloseLayer(self)
end

function TradingBankUpModifyEquipPanelMediator:OnRefresh(data)
    if self._layer then
        self._layer:OnRefreshSVIPTitle(data)
    end
end

function TradingBankUpModifyEquipPanelMediator:CheckSuccess(data)
    if self._layer then
        self._layer:CheckSuccess(data)
    end
end

return TradingBankUpModifyEquipPanelMediator