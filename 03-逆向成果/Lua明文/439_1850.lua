local BaseUIMediator = requireMediator("BaseUIMediator")
local SettingInformationCollectMediator = class('SettingInformationCollectMediator', BaseUIMediator)
SettingInformationCollectMediator.NAME = "SettingInformationCollectMediator"

function SettingInformationCollectMediator:ctor()
    SettingInformationCollectMediator.super.ctor(self)
end

function SettingInformationCollectMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_SettingInformationCollect_Open,
        noticeTable.Layer_SettingInformationCollect_Close,
        noticeTable.Layer_SettingInformationCollect_OnRefresh
    }
end

function SettingInformationCollectMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local name = notification:getName()
    local data = notification:getBody()
    
    if noticeTable.Layer_SettingInformationCollect_Open == name then
        self:OpenLayer(data)
    elseif noticeTable.Layer_SettingInformationCollect_Close == name then
        self:CloseLayer()
    elseif noticeTable.Layer_SettingInformationCollect_OnRefresh == name then
        self:OnRefresh( data )
    end
end

function SettingInformationCollectMediator:OpenLayer(data)
    if not (self._layer) then
        self._layer = requireLayerUI("setting_layer/SettingInformationCollectLayer").create( data )
        self._type = global.UIZ.UI_NORMAL
        SettingInformationCollectMediator.super.OpenLayer(self)
    end
end

function SettingInformationCollectMediator:CloseLayer()
    SettingInformationCollectMediator.super.CloseLayer(self)
end

function SettingInformationCollectMediator:OnRefresh( data )
    if self._layer then
        self._layer:OnRefresh( data,false )
    end
end

return SettingInformationCollectMediator
