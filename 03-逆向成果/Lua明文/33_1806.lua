local SystemTipsLayer = class("SystemTipsLayer", function ()
    return cc.Layer:create()
end)

function SystemTipsLayer:ctor()
    self._tipsCells = {}
end

function SystemTipsLayer.create()
    local layer = SystemTipsLayer.new()
    if layer:Init() then
        return layer
    end
    return nil
end

function SystemTipsLayer:Init()
    local visibleSize = cc.Director:getInstance():getVisibleSize()

    self._nodeTips = cc.Node:create()
    self:addChild(self._nodeTips)
    self._nodeTips:setAnchorPoint({x=0.5, y=0.5})
    self._nodeTips:setPosition({x=visibleSize.width * 0.5, y=visibleSize.height - 250})

    return true
end

function SystemTipsLayer:AddTips(str)
    local itemHei = 30

    local textTips = ccui.Text:create()
    self._nodeTips:addChild(textTips)
    textTips:setFontName("fonts/font.ttf")
    textTips:setFontSize(18)
    textTips:setString(str)
    textTips:setAnchorPoint({x=0.5, y=0.5})

    -- check count > 7
    table.insert(self._tipsCells, textTips)
    if #self._tipsCells > 7 then
        local cell = table.remove(self._tipsCells, 1)
        cell:removeFromParent()
    end

    local function callback()
        textTips:removeFromParent()
        table.remove(self._tipsCells, 1)
    end
    textTips:runAction(cc.Sequence:create(cc.DelayTime:create(2.0), cc.FadeOut:create(0.8), cc.CallFunc:create(callback)))

    -- 位置
    local actionTag = 999
    for i, cell in ipairs(self._tipsCells) do
        local action = cc.MoveTo:create(0.15, {x=0, y=itemHei * (#self._tipsCells - i + 0.5)})
        action:setTag(actionTag)
        cell:stopActionByTag(actionTag)
        cell:setPositionY(itemHei * (#self._tipsCells - i - 0.5))
        cell:runAction(action)
    end
end

return SystemTipsLayer
