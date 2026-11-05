local BaseUIMediator = requireMediator("BaseUIMediator")
local SettingHelpMediator = class('SettingHelpMediator', BaseUIMediator)
SettingHelpMediator.NAME = "SettingHelpMediator"

function SettingHelpMediator:ctor()
    SettingHelpMediator.super.ctor(self)
end

function SettingHelpMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_SettingHelp_Open,
        noticeTable.Layer_SettingHelp_Close,
    }
end

function SettingHelpMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local name = notification:getName()
    local data = notification:getBody()
    
    if noticeTable.Layer_SettingHelp_Open == name then
        self:OpenLayer(data)
    elseif noticeTable.Layer_SettingHelp_Close == name then
        self:CloseLayer()
    end
end

function SettingHelpMediator:OpenLayer(data)
    if not (self._layer) then
        local path =  global.isWinPlayMode and "setting_layer/SettingHelpLayer_win32" or "setting_layer/SettingHelpLayer"
        self._layer = requireLayerUI(path).create(data)
        data.parent:addChild(self._layer)
        -- for GUI
        GUI.ATTACH_PARENT = self._layer
        self._layer:InitGUI()
    end
end

function SettingHelpMediator:CloseLayer()
    if not self._layer then
        return nil
    end
    self._layer:removeFromParent()
    self._layer = nil
end




return SettingHelpMediator
