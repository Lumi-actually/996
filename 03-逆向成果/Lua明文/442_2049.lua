local BaseUIMediator = requireMediator("BaseUIMediator")
local SettingWindowRangeMediator = class('SettingWindowRangeMediator', BaseUIMediator)
SettingWindowRangeMediator.NAME = "SettingWindowRangeMediator"

function SettingWindowRangeMediator:ctor()
    SettingWindowRangeMediator.super.ctor(self)
end

function SettingWindowRangeMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_SettingWindowRange_Open,
        noticeTable.Layer_SettingWindowRange_Close,
    }
end

function SettingWindowRangeMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local name = notification:getName()
    local data = notification:getBody()
    
    if noticeTable.Layer_SettingWindowRange_Open == name then
        self:OpenLayer(data)
    elseif noticeTable.Layer_SettingWindowRange_Close == name then
        self:CloseLayer()
    end
end

function SettingWindowRangeMediator:OpenLayer(data)
    if not (self._layer) then
        local path = "setting_layer/SettingWindowRangeLayer" 
        self._layer = requireLayerUI(path).create(data)
        data.parent:addChild(self._layer)
        -- for GUI
        GUI.ATTACH_PARENT = self._layer
        self._layer:InitGUI()
        -- 自定义组件挂接
        local componentData = 
        {
            root  = self._layer:GetSUIParent(),
            index = global.SUIComponentTable.SettingWindowRange
        }
        global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    end
end

function SettingWindowRangeMediator:CloseLayer()  
    if not self._layer then
        return nil
    end
    -- 自定义组件挂接
    local componentData = 
    {
        index = global.SUIComponentTable.SettingWindowRange
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentDetach, componentData)
    self._layer:removeFromParent()
    self._layer = nil
end



return SettingWindowRangeMediator
