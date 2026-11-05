local WidgetCacheManager = class("WidgetCacheManager")

function WidgetCacheManager:ctor()
    self._widgetPoolGroup = {}
end

function WidgetCacheManager:GetWiget(widgetConfig)
    local widgetPool = self._widgetPoolGroup[widgetConfig]
    if widgetPool then
        local count = #widgetPool

        if count > 0 then
            local widget = widgetPool[count]
            widgetPool[count] = nil
            return widget
        end
    end
end

function WidgetCacheManager:Create(widgetConfig)
    local widget = self:GetWiget(widgetConfig)

    if widget then
        widget:autorelease()
        return widget
    else
        local parent = cc.Node:create()
        GUI:LoadExport(parent, widgetConfig)

        local item = parent:getChildByName("Node")
        item:removeFromParent()

        widget = item
    end

    return widget
end

function WidgetCacheManager:Destroy(widgetConfig, widget)
    if widget and not tolua.isnull(widget) then
        widget:retain()

        self._widgetPoolGroup[widgetConfig] = self._widgetPoolGroup[widgetConfig] or {}
        local widgetPool = self._widgetPoolGroup[widgetConfig]
        widgetPool[#widgetPool + 1] = widget
    end
end

function WidgetCacheManager:Clear()
    for poolName, widgetPool in pairs(self._widgetPoolGroup) do
        for _, widget in pairs(widgetPool) do
            if widget:getReferenceCount() > 2 then
                print("！！！！！缓存泄露,缓存池：", poolName, "对象:", widget, widget:getReferenceCount())
            end

            widget:release()
        end
    end

    self._widgetPoolGroup = {}
end

function WidgetCacheManager:WidgetPoolCapacity(poolName, capacity)
    local widgets = {}
    for i = 1, capacity do
        local widget = self:Create(poolName)
        if widget then
            widgets[#widgets + 1] = widget
        end
    end

    for _, widget in pairs(widgets) do
        self:Destroy(poolName, widget)
    end
end

function WidgetCacheManager:GetCount()
    local count = 0
    for _, widgetPool in pairs(self._widgetPoolGroup) do
        for _, _ in pairs(widgetPool) do
            count = count + 1
        end
    end

    return count
end

function WidgetCacheManager:ShowReferenceCount()
    for poolName, widgetPool in pairs(self._widgetPoolGroup) do
        local count = 0
        for _, widget in pairs(widgetPool) do
            count = count + 1
        end
        print("poolName : " .. poolName, "总缓存数 : " .. count)
    end
end

return WidgetCacheManager
