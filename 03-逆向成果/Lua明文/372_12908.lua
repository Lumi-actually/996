local BaseUIMediator = requireMediator("BaseUIMediator")
local SUIComponentMediator = class("SUIComponentMediator", BaseUIMediator)
SUIComponentMediator.NAME = "SUIComponentMediator"

function SUIComponentMediator:ctor()
    SUIComponentMediator.super.ctor(self)

    self._components    = {}
    self._guiComponents = {}
end

function SUIComponentMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return 
    {
        noticeTable.SUIComponentAttach,
        noticeTable.SUIComponentDetach,
        noticeTable.SUIComponentUpdate,
        noticeTable.GUIComponentAttachOrDetch,
        noticeTable.GUIComponentUpdate,
        noticeTable.ReleaseMemory,
        noticeTable.Bag_Oper_Data_Delay,
    }
end

function SUIComponentMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()

    if noticeID == noticeTable.SUIComponentAttach then
        self:onSUIComponentAttach(data)
        self:OnGUIComponentAttach(data)

    elseif noticeID == noticeTable.SUIComponentDetach then
        self:onSUIComponentDetach(data)
        self:OnGUIComponentDetach(data)

    elseif noticeID == noticeTable.SUIComponentUpdate then
        self:onSUIComponentUpdate(data)

    elseif noticeID == noticeTable.GUIComponentAttachOrDetch then
        self:OnGUIComponentDataUpdate(data)

    elseif noticeID == noticeTable.GUIComponentUpdate then
        self:OnGUIComponentUpdate(data)
    
    elseif noticeID == noticeTable.ReleaseMemory then
        self:OnReleaseMemory()
        return
    end

    local SUIComponentProxy = global.Facade:retrieveProxy(global.ProxyTable.SUIComponentProxy)
    SUIComponentProxy:checkAllTriggers(noticeID)
end

-----------------------------------------------------------------------
--- 挂接
function SUIComponentMediator:onSUIComponentAttach(data)
    local root          = data.root
    local index         = data.index

    if nil ~= self._components[index] then
        return nil
    end

    -- 
    self._components[index] = 
    {
        root            = root,
        index           = index,
        renders         = {},
    }

    -- 
    self:onSUIComponentUpdate({index = index})
end

function SUIComponentMediator:onSUIComponentDetach(data)
    local root          = data.root
    local index         = data.index

    if nil == self._components[index] then
        return nil
    end

    -- remove render
    for _, render in pairs(self._components[index].renders) do
        render:removeFromParent()
    end

    self._components[index] = nil
end
-----------------------------------------------------------------------


-----------------------------------------------------------------------
--- 增删改
function SUIComponentMediator:onSUIComponentUpdate(data)
    local index         = data.index
    local subid         = data.subid
    local updateAll     = (subid == nil)

    if nil == self._components[index] then
        return nil
    end
    if nil == self._components[index].root then
        return nil
    end

    local SUIComponentProxy = global.Facade:retrieveProxy(global.ProxyTable.SUIComponentProxy)


    if updateAll then
        -- remove all
        for _, render in pairs(self._components[index].renders) do
            render:removeFromParent()
        end
        self._components[index].renders = {}

        -- load all
        local renders   = SUIComponentProxy:loadSUIRenderAll(index, self._components[index].root)
        for subid, render in pairs(renders) do
            self._components[index].root:addChild(render)
            self._components[index].renders[subid] = render
            render:registerScriptHandler(function(state)
                if state == "exit" then
                    self._components[index].renders[subid] = nil
                end
            end)
        end

        if index == global.SUIComponentTable.MainRootMission and tonumber(SL:GetValue("GAME_DATA", "missionControl") or 0) == 1 then 
            if renders and next(renders) then
                SLBridge:onLUAEvent(LUA_EVENT_ASSIST_MISSION_SHOW, false)
            else
                SLBridge:onLUAEvent(LUA_EVENT_ASSIST_MISSION_SHOW, true)
            end
        end
    else
        -- remove last subid
        if self._components[index].renders[subid] then
            self._components[index].renders[subid]:removeFromParent()
        end
        self._components[index].renders[subid] = nil

        -- load one
        local render    = SUIComponentProxy:loadSUIRender(index, subid, self._components[index].root)
        if render then
            self._components[index].root:addChild(render)
            self._components[index].renders[subid] = render
            render:registerScriptHandler(function(state)
                if state == "exit" then
                    self._components[index].renders[subid] = nil
                end
            end)
        end

        if index == global.SUIComponentTable.MainRootMission and tonumber(SL:GetValue("GAME_DATA", "missionControl") or 0) == 1 then
            if render then
                SLBridge:onLUAEvent(LUA_EVENT_ASSIST_MISSION_SHOW, false)
            else
                SLBridge:onLUAEvent(LUA_EVENT_ASSIST_MISSION_SHOW, true)
            end
        end
    end
end

----------------------------------GUI lua控件
---
function SUIComponentMediator:OnGUIComponentAttach(data)
    local root          = data.root
    local index         = data.index

    if nil ~= self._guiComponents[index] then
        return nil
    end

    -- 
    self._guiComponents[index] = 
    {
        root            = root,
        index           = index,
        renders         = {},
    }

    -- 
    self:OnGUIComponentUpdate({index = index})
end

function SUIComponentMediator:OnGUIComponentDetach(data)
    local root          = data.root
    local index         = data.index

    if nil == self._guiComponents[index] then
        return nil
    end

    -- remove render
    for _, render in pairs(self._guiComponents[index].renders) do
        if render.Stop then
            render:Stop()
        end
        render:removeFromParent()
    end

    self._guiComponents[index] = nil
end

function SUIComponentMediator:OnGUIComponentUpdate( data )
    local index         = data.index
    local subid         = data.subid
    local updateAll     = (subid == nil)

    if nil == self._guiComponents[index] then
        return nil
    end
    if nil == self._guiComponents[index].root then
        return nil
    end

    local SUIComponentProxy = global.Facade:retrieveProxy(global.ProxyTable.SUIComponentProxy)

    if updateAll then
        -- remove all
        for _, render in pairs(self._guiComponents[index].renders) do
            if render.Stop then
                render:Stop()
            end
            render:removeFromParent()
        end
        self._guiComponents[index].renders = {}

        -- load all
        local data      = SUIComponentProxy:GetWidgetData(index) 
        local renders   = data 
        if renders and next(renders) then
            for subid, render in pairs(renders) do
                if render and render.content and not tolua.isnull(render.content) then
                    self._guiComponents[index].root:addChild(render.content)
                    
                    -- 重新初始化GoodsItem/刷新特效
                    local function reInitItem(item)
                        if item._isGood then
                            if item._Clear then
                                item:_Clear()
                            end
                            if item.init and item._data then
                                local _replaceClickEvent = item._replaceClickEvent
                                local _pressCallback = item._pressCallback
                                local _doubleEvent = item._doubleEvent
                                local _itemData = item._itemData
                                local _extraLockStatus = item._extraLockStatus
                                local _greyStatus      = item._greyStatus

                                item:init(item._data)
                                item:AddReplaceClickEventListener(_replaceClickEvent)
                                item:AddPressCallBack(_pressCallback) 
                                item:AddDoubleEventListener(_doubleEvent)
                                item:UpdateGoodsItem(_itemData)
                                item:SetItemTouchSwallow(not item._noSwallow)
                                if type(_extraLockStatus) == "boolean" then
                                    item:setItemExtraLockStatus(_extraLockStatus)
                                end
                                if type(_greyStatus) == "boolean" then
                                    item:SetIconGrey(_greyStatus)
                                end
                            end
                        end

                        if item.Replay then
                            item:Replay()
                        end
                    end

                    local function foreachChildren(parent)
                        reInitItem(parent)
                        local children = parent:getChildren()
                        if #children > 0 then
                            for _, child in ipairs(children) do
                                foreachChildren(child)
                            end
                        end
                    end
                    foreachChildren(render.content)
                    
                    self._guiComponents[index].renders[subid] = render.content
                    render.content:registerScriptHandler(function(state)
                        if state == "exit" then
                            self._guiComponents[index].renders[subid] = nil
                        end
                    end)
                end
            end
        end

        if index == global.SUIComponentTable.MainRootMission and tonumber(SL:GetValue("GAME_DATA", "missionControl") or 0) == 1 then 
            if renders and next(renders) then
                SLBridge:onLUAEvent(LUA_EVENT_ASSIST_MISSION_SHOW, false)
            else
                SLBridge:onLUAEvent(LUA_EVENT_ASSIST_MISSION_SHOW, true)
            end
        end
    else
        -- remove last subid
        if self._guiComponents[index].renders[subid] then
            self._guiComponents[index].renders[subid]:release()
            self._guiComponents[index].renders[subid]:removeFromParent()
        end
        self._guiComponents[index].renders[subid] = nil

        -- load one
        local data      = SUIComponentProxy:GetWidgetData(index, subid)
        local render    = data and data.content
        if render and not tolua.isnull(render) then
            self._guiComponents[index].root:addChild(render)
            self._guiComponents[index].renders[subid] = render
            render:registerScriptHandler(function(state)
                if state == "exit" then
                    self._guiComponents[index].renders[subid] = nil
                end
            end)
        end

        if index == global.SUIComponentTable.MainRootMission and tonumber(SL:GetValue("GAME_DATA", "missionControl") or 0) == 1 then
            if render and not tolua.isnull(render) then
                SLBridge:onLUAEvent(LUA_EVENT_ASSIST_MISSION_SHOW, false)
            else
                SLBridge:onLUAEvent(LUA_EVENT_ASSIST_MISSION_SHOW, true)
            end
        end
    end
end

function SUIComponentMediator:OnGUIComponentDataUpdate( data )
    local SUIComponentProxy = global.Facade:retrieveProxy(global.ProxyTable.SUIComponentProxy)
    SUIComponentProxy:UpdateAttachComponentByLua(data)
end

function SUIComponentMediator:OnReleaseMemory( ... )
    if self._guiComponents and next(self._guiComponents) then
        for _, component in pairs(self._guiComponents) do
            if component and component.renders and next(component.renders) then
                for subid, render in pairs(component.renders) do
                    if component.renders[subid] then
                        component.renders[subid]:release()
                        component.renders[subid] = nil
                    end
                end
            end
        end
        self._guiComponents = {}
    end
end
-----------------------------------------------------------------------


return SUIComponentMediator
