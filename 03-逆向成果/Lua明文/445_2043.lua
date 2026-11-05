local BaseUIMediator = requireMediator("BaseUIMediator")
local SettingAutoMediator = class('SettingAutoMediator', BaseUIMediator)
SettingAutoMediator.NAME = "SettingAutoMediator"

function SettingAutoMediator:ctor()
    SettingAutoMediator.super.ctor(self)
end

function SettingAutoMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_SettingAuto_Open,
        noticeTable.Layer_SettingAuto_Close,
    }
end

function SettingAutoMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local name = notification:getName()
    local data = notification:getBody()
    
    if noticeTable.Layer_SettingAuto_Open == name then
        self:OpenLayer(data)
    elseif noticeTable.Layer_SettingAuto_Close == name then
        self:CloseLayer()
    end
end

function SettingAutoMediator:OpenLayer(data)
    if not (self._layer) then
        local path =  global.isWinPlayMode and "setting_layer/SettingAutoLayer_win32" or "setting_layer/SettingAutoLayer"
        self._layer = requireLayerUI(path).create(data)
        data.parent:addChild(self._layer)
        -- for GUI
        GUI.ATTACH_PARENT = self._layer
        self._layer:InitGUI()
        -- 自定义组件挂接
        local componentData = 
        {
            root  = self._layer:GetSUIParent(),
            index = global.SUIComponentTable.SettingAuto
        }
        global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    end
end

function SettingAutoMediator:CloseLayer()
    if not self._layer then
        return nil
    end
    -- 自定义组件挂接
    local componentData = 
    {
        index = global.SUIComponentTable.SettingAuto
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentDetach, componentData)
    self._layer:OnClose()
    -- 自定义组件挂接
    self._layer:removeFromParent()
    self._layer = nil
end


return SettingAutoMediator
