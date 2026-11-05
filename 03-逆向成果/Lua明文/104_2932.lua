local SUIHelper = {}

SUIHelper.fixImageFileName = function(filename)
    -- 将\转化为/
    -- 将后缀名改为小写
    if nil == filename then
        return ""
    end
    if "" == filename then
        return ""
    end
    
    filename = string.gsub(filename, "\\", "/")

    local pattern = {string.find(filename, "(.+)%.(.+)")}
    if not pattern[3] or not pattern[4] then
        return filename
    end

    -- fix 
    filename = pattern[3] .. "." .. string.lower(pattern[4])

    return filename
end

SUIHelper.getSWidgetsMaxID = function(swidget)
    local maxID = 1

    local function calcMaxID(branches)
        for _, v in pairs(branches) do
            if v.element.attr.id and tonumber(v.element.attr.id) then
                maxID = math.max(tonumber(v.element.attr.id), maxID)
            end

            if v.branches then
                calcMaxID(v.branches)
            end
        end
    end

    calcMaxID(swidget.branches)

    return maxID
end

SUIHelper.getResFile = function(renderer)
    if not renderer then
        return "", 0
    end

    local sprite = renderer:getSprite()
    if not sprite then
        return "", 0
    end

    return sprite:getResourceName(), sprite:getResourceType()
end

SUIHelper.cleanuprender = function(render)
    local classname = tolua.type(render)

    local eventDispatcher = global.EventDispatcher
    if classname == "ccui.Layout" then
        RemoveAllWidgetClickEventListener(render)
        eventDispatcher:removeEventListenersForTarget(render)

    elseif classname == "ccui.Text" then
        RemoveAllWidgetClickEventListener(render)
        eventDispatcher:removeEventListenersForTarget(render)

    elseif classname == "ccui.ImageView" then
        RemoveAllWidgetClickEventListener(render)
        eventDispatcher:removeEventListenersForTarget(render)

    elseif classname == "ccui.Button" then
        RemoveAllWidgetClickEventListener(render)
        eventDispatcher:removeEventListenersForTarget(render)
        render:setBrightStyle(0)
    end

    render:setVisible(true)
    render:stopAllActions()
    render:setRotation(0)
    render:setScale(1)
    render:setFlippedX(false)
    render:setFlippedY(false)
    if render.disableEffect then
        render:disableEffect()
    end

    if classname == "ccui.ImageView" or classname == "ccui.Button" then
        Shader_Normal(render)
    elseif classname == "ccui.Text" then
        local labelRenderer = render:getVirtualRenderer()
        if labelRenderer.underline and (not tolua.isnull(labelRenderer.underline)) then
            labelRenderer.underline:removeFromParent()
            labelRenderer.underline = nil
        end
        labelRenderer:setMaxLineWidth(0)
    elseif classname == "ccui.Layout" then
        render:setClippingEnabled(false)
    end
end

return SUIHelper