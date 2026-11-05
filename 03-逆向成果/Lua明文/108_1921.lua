local CacheWidget = class("CacheWidget", function() return ccui.Widget:create() end)

function CacheWidget:ctor()
    self._widgetConfig = nil
    self._widget = nil

    -- 监听事件;
    self:registerScriptHandler(
        function(state)
            if state == "enter" then
                self:onEnter()
            elseif state == "exit" then
                self:onExit()
            end
        end
    )
end

function CacheWidget:InitWidgetConfig(widgetConfig)
    self._widgetConfig = widgetConfig

    -- add by sfy
    self:_InitWidthConfig()

    return true
end

function CacheWidget:_InitWidthConfig()
    if self._widgetConfig then
        self._widget = global.WidgetCacheManager:Create(self._widgetConfig)
        self._widget:setCascadeOpacityEnabled(true)
        if not self._widget then
            print("not widget config : ", self._widgetConfig)
            return
        end

        self:addChild(self._widget)
    end
end

function CacheWidget:_Clear()
    if self._widget and self._widgetConfig then
        -- 未使用会回收
        global.WidgetCacheManager:Destroy(self._widgetConfig, self._widget)

        self._widget:removeFromParent()
        self._widget = nil
        self._widgetConfig = nil
    end
end

function CacheWidget:onEnter()
    self:Enter()
end

function CacheWidget:onExit()
    self:Exit()
end

function CacheWidget:Enter()
    if self._entered then
        return
    end

    if not self._widget then
        self:_InitWidthConfig()
    end

    if self._widget then
        self._entered = true

        self:OnEnter()
    end
end

function CacheWidget:Exit()
    if self._widget then
        self:OnExit()

        self._entered = false

        self:_Clear()
    end
end

function CacheWidget:OnEnter()
end

function CacheWidget:OnExit()
end

return CacheWidget
