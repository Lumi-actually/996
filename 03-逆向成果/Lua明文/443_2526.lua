local BaseUIMediator = requireMediator("BaseUIMediator")
local SettingLaunchMediator = class('SettingLaunchMediator', BaseUIMediator)
SettingLaunchMediator.NAME = "SettingLaunchMediator"

function SettingLaunchMediator:ctor()
    SettingLaunchMediator.super.ctor(self)
end

function SettingLaunchMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_SettingLaunch_Open,
        noticeTable.Layer_SettingLaunch_Close,
        noticeTable.GameSettingChange
    }
end

function SettingLaunchMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local name = notification:getName()
    local data = notification:getBody()
    
    if noticeTable.Layer_SettingLaunch_Open == name then
        self:OpenLayer(data)
    elseif noticeTable.Layer_SettingLaunch_Close == name then
        self:CloseLayer()

    elseif noticeTable.GameSettingChange == name then
        self:OnSkillSettingChange(data)

    end
end

function SettingLaunchMediator:OpenLayer(data)
    if not (self._layer) then
        local path =  global.isWinPlayMode and "setting_layer/SettingLaunchLayer_win32" or "setting_layer/SettingLaunchLayer"
        self._layer = requireLayerUI(path).create(data)
        data.parent:addChild(self._layer)
        -- for GUI
        GUI.ATTACH_PARENT = self._layer
        self._layer:InitGUI()
        -- 自定义组件挂接
        local componentData = 
        {
            root  = self._layer:GetSUIParent(),
            index = global.SUIComponentTable.SettingFight
        }
        global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    end
end

function SettingLaunchMediator:CloseLayer()
    if not self._layer then
        return nil
    end
    -- 自定义组件挂接
    local componentData = 
    {
        index = global.SUIComponentTable.SettingFight
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentDetach, componentData)
    self._layer:removeFromParent()
    self._layer = nil
end

function SettingLaunchMediator:OnGameSettingChange(data)
    if not self._layer then
        return nil
    end
    self._layer:OnGameSettingChange(data)
end

function SettingLaunchMediator:OnSkillSettingChange(data)
    local skillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    skillProxy:SkillSettingChange(data and data.id)
end

return SettingLaunchMediator
