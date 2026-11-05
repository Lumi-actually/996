local SWidgetCache = class("SWidgetCache")

local SUIHelper = require("sui/SUIHelper")
local SWidget = require("sui/SWidget")
local tremove = table.remove
local tinsert = table.insert

function SWidgetCache:ctor()
    self._renderCache  = {}
    self._renderEmptyImageCache  = {}
    self._renderButtonCache  = {}--按钮单独一缓存
end

function SWidgetCache:releaseAll()
    -- 释放渲染组件
    for _, caches in pairs(self._renderCache) do
        for _, cache in pairs(caches) do
            cache:autorelease()
        end
    end
    for _, caches in pairs(self._renderEmptyImageCache) do
        for _, cache in pairs(caches) do
            cache:autorelease()
        end
    end
    for _, caches in pairs(self._renderButtonCache) do
        for _, cache in pairs(caches) do
            cache:autorelease()
        end
    end
    self._renderCache = {}
    self._renderEmptyImageCache  = {}
    self._renderButtonCache = {}
end

function SWidgetCache:releaseLimit()
    for _, caches in pairs(self._renderCache) do
        while #caches > 100 do
            local cache = tremove(caches, 1)
            cache:autorelease()
        end
    end
    for _, caches in pairs(self._renderEmptyImageCache) do
        while #caches > 100 do
            local cache = tremove(caches, 1)
            cache:autorelease()
        end
    end
    for _, caches in pairs(self._renderButtonCache) do
        while #caches > 100 do
            local cache = tremove(caches, 1)
            cache:autorelease()
        end
    end
end

function SWidgetCache:generateSWidget()
    return SWidget.new()
end

local function clearMouseLastInSideNode(render)
    if global.mouseEventController:GetLastInsideNode() and global.mouseEventController:GetLastInsideNode() == render then
        global.mouseEventController:ClearLastInsideNode()
        print(render, "___clearMouseLastInSideNode")
    end
end

function SWidgetCache:generateRender(classname)
    if self._renderCache[classname] and #self._renderCache[classname] > 0 then
        local render = tremove(self._renderCache[classname], 1)
        render:autorelease()
        render:removeAllChildren()
        return render
    end

    if classname == "ccui.Layout" then
        return ccui.Layout:create()

    elseif classname == "ccui.Text" then
        return ccui.Text:create()

    elseif classname == "ccui.ImageView" then
        return ccui.ImageView:create()

    elseif classname == "ccui.Button" then
        return ccui.Button:create()

    elseif classname == "ccui.ListView" then
        return ccui.ListView:create()

    elseif classname == "ccui.Widget" then
        return ccui.Widget:create()
    end
end

function SWidgetCache:generateEmptyImageRender(classname)
    local render = nil
    if self._renderEmptyImageCache[classname] and #self._renderEmptyImageCache[classname] > 0 then
        render = tremove(self._renderEmptyImageCache[classname], 1)
        render:autorelease()
        render:removeAllChildren()
        return render
    end
    render = ccui.ImageView:create()
    render._isEmptyImage = true
    return render 
end

--1-normalAndPress 2-Normal 3-Press 4-nil
function SWidgetCache:generateButtonRender(Button_Type)
    local render = nil
    if self._renderButtonCache[Button_Type] and #self._renderButtonCache[Button_Type] > 0 then
        render = tremove(self._renderButtonCache[Button_Type], 1)
        render:autorelease()
        render:removeAllChildren()
        clearMouseLastInSideNode(render)
        return render
    end

    render = ccui.Button:create()
    render._Button_Type = Button_Type
    return render 
end

function SWidgetCache:cachingRender(swidget)
    -- can't loaded
    if not swidget.render then
        return false
    end

    local render    = swidget.render
    local etype     = swidget.element.type
    local classname = tolua.type(render)
    local isEmptyImage = render._isEmptyImage--是否是空图片
    local Button_Type = render._Button_Type--按钮类型
    if render.useMetaValue == true then
        return false
    end

    if etype == "Img" then
    elseif etype == "Text" or etype == "COUNTDOWN" then
        if classname == "ccui.Layout" then
            return false
        end   
    elseif etype == "Button" then
    else
        return false
    end

    -- cleanup
    SUIHelper.cleanuprender(render)

    render:retain()
    if swidget.trunk and swidget.trunk.render and swidget.trunk.element.type == "ListView" then
        swidget.trunk.render:removeItem(swidget.trunk.render:getIndex(render))
    else
        render:removeFromParent()
    end
    if etype == "Button" then 
        self._renderButtonCache[Button_Type] = self._renderButtonCache[Button_Type] or {}
        tinsert(self._renderButtonCache[Button_Type], render)
    else
        if isEmptyImage then 
            self._renderEmptyImageCache[classname] = self._renderEmptyImageCache[classname] or {}
            tinsert(self._renderEmptyImageCache[classname], render)
        else
            self._renderCache[classname] = self._renderCache[classname] or {}
            tinsert(self._renderCache[classname], render)
        end
    end

    return true
end

function SWidgetCache:cachingTrunk(trunkSwidget)
    if not trunkSwidget then
        return nil
    end

    -- caching swidgets
    local function solveBranches(trunk)
        if #trunk.branches == 0 then
            self:cachingRender(trunk)
            return nil
        end

        for _, branch in pairs(trunk.branches) do
            solveBranches(branch)
        end
        self:cachingRender(trunk)
    end
    solveBranches(trunkSwidget)
end

return SWidgetCache