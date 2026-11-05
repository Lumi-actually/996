local BaseUIMediator = requireMediator("BaseUIMediator")
local MainRootMediator = class("MainRootMediator", BaseUIMediator)
MainRootMediator.NAME = "MainRootMediator"

local sformat = string.format

function MainRootMediator:ctor()
    MainRootMediator.super.ctor(self)

    self._options = {}
    self._mediators = {}
end

function MainRootMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_Main_Open,
        noticeTable.Layer_Main_Init,
        noticeTable.Layer_Main_AddChild,
        noticeTable.Layer_Main_Show,
        noticeTable.Layer_Main_Hide,
        noticeTable.WindowResized,
        noticeTable.DRotationChanged,
        noticeTable.GameSettingInited,
        noticeTable.GameSettingChange,
        noticeTable.PlayerPropertyInited,
    }
end

function MainRootMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()

    if noticeTable.Layer_Main_Open == noticeID then
        self:OpenLayer()

    elseif noticeTable.Layer_Main_Init == noticeID then
        self:OnInit()

    elseif noticeTable.Layer_Main_AddChild == noticeID then
        self:AddChild(data)

    elseif noticeTable.Layer_Main_Show == noticeID then
        self:OnShow(data)

    elseif noticeTable.Layer_Main_Hide == noticeID then
        self:OnHide(data)

    elseif noticeTable.WindowResized == noticeID then
        self:OnWindowResized()

    elseif noticeTable.DRotationChanged == noticeID then
        self:OnDRotationChanged(data)

    elseif noticeTable.GameSettingInited == noticeID then
        self:OnGameSettingInited(data)

    elseif noticeTable.GameSettingChange == noticeID then
        self:OnGameSettingChange(data)

    elseif noticeTable.PlayerPropertyInited == noticeID then
        self:OnPlayerPropertyInited(data)
    end
end

function MainRootMediator:OpenLayer()
    if not (self._layer) then
        self._layer = requireMainUI("MainRootLayer").create()
        self._type = global.UIZ.UI_MAIN
        
        MainRootMediator.super.OpenLayer(self)
    end
end

function MainRootMediator:CloseLayer()
    MainRootMediator.super.CloseLayer(self)
end

function MainRootMediator:handlePressedEnter()
    for i = #self._mediators, 1, -1 do
        local mediator = self._mediators[i]
        if mediator.handlePressedEnter and mediator:handlePressedEnter() then
            return true
        end
    end
    return false
end

function MainRootMediator:OnInit()
    if not self._layer then
        return nil
    end

    -- 自定义组件挂接
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_LT],
        index = global.SUIComponentTable.MainRootLT,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_RT],
        index = global.SUIComponentTable.MainRootRT,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_RB],
        index = global.SUIComponentTable.MainRootRB,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_LB],
        index = global.SUIComponentTable.MainRootLB,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_LM],
        index = global.SUIComponentTable.MainRootLM,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_TM],
        index = global.SUIComponentTable.MainRootTM,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_RM],
        index = global.SUIComponentTable.MainRootRM,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_BM],
        index = global.SUIComponentTable.MainRootBM,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    -- BOTTOM
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_BOTTOM_LT],
        index = global.SUIComponentTable.MainRootBottom_LT,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_BOTTOM_RT],
        index = global.SUIComponentTable.MainRootBottom_RT,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_BOTTOM_LB],
        index = global.SUIComponentTable.MainRootBottom_LB,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_BOTTOM_RB],
        index = global.SUIComponentTable.MainRootBottom_RB,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    -- TOP
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_TOP_LT],
        index = global.SUIComponentTable.MainRootTop_LT,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_TOP_RT],
        index = global.SUIComponentTable.MainRootTop_RT,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_TOP_LB],
        index = global.SUIComponentTable.MainRootTop_LB,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)
    local componentData = {
        root  = self._layer._nodes[global.MMO.MAIN_NODE_SUI_TOP_RB],
        index = global.SUIComponentTable.MainRootTop_RB,
    }
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, componentData)


    GUI:SetGUIParent(10, self._layer)
    GUI:SetGUIParent(101, self._layer._nodes[global.MMO.MAIN_NODE_SUI_LT])
    GUI:SetGUIParent(102, self._layer._nodes[global.MMO.MAIN_NODE_SUI_RT])
    GUI:SetGUIParent(103, self._layer._nodes[global.MMO.MAIN_NODE_SUI_LB])
    GUI:SetGUIParent(104, self._layer._nodes[global.MMO.MAIN_NODE_SUI_RB])
    GUI:SetGUIParent(105, self._layer._nodes[global.MMO.MAIN_NODE_SUI_LM])
    GUI:SetGUIParent(106, self._layer._nodes[global.MMO.MAIN_NODE_SUI_TM])
    GUI:SetGUIParent(107, self._layer._nodes[global.MMO.MAIN_NODE_SUI_RM])
    GUI:SetGUIParent(108, self._layer._nodes[global.MMO.MAIN_NODE_SUI_BM])

    GUI:SetGUIParent(1101, self._layer._nodes[global.MMO.MAIN_NODE_SUI_TOP_LT])
    GUI:SetGUIParent(1102, self._layer._nodes[global.MMO.MAIN_NODE_SUI_TOP_RT])
    GUI:SetGUIParent(1103, self._layer._nodes[global.MMO.MAIN_NODE_SUI_TOP_LB])
    GUI:SetGUIParent(1104, self._layer._nodes[global.MMO.MAIN_NODE_SUI_TOP_RB])
end

function MainRootMediator:OnPlayerPropertyInited()
    if not self._layer then
        return nil
    end

    -- 内挂映射到主界面
    local roots = 
    {
        [global.SUIComponentTable.MainRootLT] = self._layer._nodes[global.MMO.MAIN_NODE_SUI_LT],
        [global.SUIComponentTable.MainRootRT] = self._layer._nodes[global.MMO.MAIN_NODE_SUI_RT],
        [global.SUIComponentTable.MainRootRB] = self._layer._nodes[global.MMO.MAIN_NODE_SUI_RB],
        [global.SUIComponentTable.MainRootLB] = self._layer._nodes[global.MMO.MAIN_NODE_SUI_LB],
        [global.SUIComponentTable.MainRootLM] = self._layer._nodes[global.MMO.MAIN_NODE_SUI_LM],
        [global.SUIComponentTable.MainRootTM] = self._layer._nodes[global.MMO.MAIN_NODE_SUI_TM],
        [global.SUIComponentTable.MainRootRM] = self._layer._nodes[global.MMO.MAIN_NODE_SUI_RM],
        [global.SUIComponentTable.MainRootBM] = self._layer._nodes[global.MMO.MAIN_NODE_SUI_BM],
    }
    self._SetRoots = roots
    local GameSettingProxy  = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    local items             = GameSettingProxy:GetMainOptions()
    for _, item in pairs(items) do
        if item.lid and roots[item.lid] then
            local filepath  = CHECK_SETTING(item.id) == 1 and item.brightPath or item.normalPath
            if item.id == 27 or item.id == 52 then
                filepath = CHECK_SETTING(item.id) ~= 0 and item.brightPath or item.normalPath
            end
            local button    = ccui.Button:create()
            roots[item.lid]:addChild(button)
            button:setPosition(cc.p(item.x, item.y))
            button:loadTextureNormal(string.format(("res/%s"), filepath))
            button:addClickEventListener(function()
                local value = CHECK_SETTING(item.id)
                if item.id == 27 or item.id == 52 then
                    CHANGE_SETTING(item.id, value == 0 and {30} or {0})
                else
                    CHANGE_SETTING(item.id, value == 1 and {0} or {1})
                end
            end)
            self._options[item.id] = {}
            self._options[item.id].item = item
            self._options[item.id].button = button
        end
    end
end

function MainRootMediator:OnGameSettingInited()
    for _, option in pairs(self._options) do
        local filepath = CHECK_SETTING(option.item.id) == 1 and option.item.brightPath or option.item.normalPath
        if option.item.id == 27 or option.item.id == 52 then
            filepath = CHECK_SETTING(option.item.id) ~= 0 and option.item.brightPath or option.item.normalPath
        end
        option.button:loadTextureNormal(string.format(("res/%s"), filepath))
    end
end

function MainRootMediator:OnGameSettingChange(data)
    local option = self._options[data.id]
    if option then
        local filepath = CHECK_SETTING(option.item.id) == 1 and option.item.brightPath or option.item.normalPath
        if option.item.id == 27 or option.item.id == 52 then
            filepath = CHECK_SETTING(option.item.id) ~= 0 and option.item.brightPath or option.item.normalPath
        end
        option.button:loadTextureNormal(string.format(("res/%s"), filepath))
        if option.item.lid and option.item.off_lid and option.item.off_lid ~= option.item.lid then 
            option.button:retain()
            option.button:removeFromParent()
            self._SetRoots[option.item.off_lid]:addChild(option.button)
            option.button:release()
            option.button:setPosition(cc.p(option.item.off_x, option.item.off_y))
        end
    end
end

function MainRootMediator:OnInitScriptWidgets()
    if not self._layer then
        return nil
    end

    local ScriptWidgetsProxy = global.Facade:retrieveProxy(global.ProxyTable.ScriptWidgetsProxy)
    local UIINDEX = ScriptWidgetsProxy.UIINDEX
    local root = ScriptWidgetsProxy:getWidgetByID(UIINDEX.UI_Main)
    self._layer._layoutAdapet:addChild(root)
    local contentSize = self._layer._layoutAdapet:getContentSize()
    root:setPosition(cc.p(0, contentSize.height))
end

function MainRootMediator:AddChild(data)
    if not self._layer then
        return nil
    end
    if self._layer then
        self._layer:AddChild(data)
        global.mouseEventController:registerAllChilderMouseRButtonEvent( data.child ,{checkIsVisible = true,checkTouchEnable = true, checkSwallowTouches = true})
        
        RefreshPositionByParent(data.child)
    end
    if data.mediator then
        self._mediators[#self._mediators+1] = data.mediator
    end
end

function MainRootMediator:OnShow()
    if not self._layer then
        return nil
    end
    self._layer:setVisible(true)
end

function MainRootMediator:OnHide()
    if not self._layer then
        return nil
    end
    self._layer:setVisible(false)
end


function MainRootMediator:OnWindowResized(data)
    if not self._layer then
        return nil
    end
    return self._layer:UpdateAdapet(data)
end

function MainRootMediator:OnDRotationChanged(data)
    if not self._layer then
        return nil
    end
    return self._layer:UpdateAdapet(data)
end


return MainRootMediator
