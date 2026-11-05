local BaseUIMediator = requireMediator("BaseUIMediator")
local SettingProtectMediator = class('SettingProtectMediator', BaseUIMediator)
SettingProtectMediator.NAME = "SettingProtectMediator"

function SettingProtectMediator:ctor()
    SettingProtectMediator.super.ctor(self)
end

function SettingProtectMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_SettingProtect_Open,
        noticeTable.Layer_SettingProtect_Close,
    }
end

function SettingProtectMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local name = notification:getName()
    local data = notification:getBody()
    
    if noticeTable.Layer_SettingProtect_Open == name then
        self:OpenLayer(data)
    elseif noticeTable.Layer_SettingProtect_Close == name then
        self:CloseLayer()
    end
end

function SettingProtectMediator:OpenLayer(data)
    if not (self._layer) then
        local path = global.isWinPlayMode and "setting_layer/SettingProtectLayer_win32" or "setting_layer/SettingProtectLayer"
        self._layer = requireLayerUI(path).create(data)
        data.parent:addChild(self._layer)
        -- for GUI
        GUI.ATTACH_PARENT = self._layer
        self._layer:InitGUI()
        -- 自定义组件挂接
        local componentData = 
        {
            root  = self._layer:GetSUIParent(),
            index = global.SUIComponentTable.SettingProtect
        }
        global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    end
end

function SettingProtectMediator:CloseLayer()
    if not self._layer then
        return nil
    end
    -- 自定义组件挂接
    local componentData = 
    {
        index = global.SUIComponentTable.SettingProtect
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentDetach, componentData)
    self._layer:removeFromParent()
    self._layer = nil
end

return SettingProtectMediator
