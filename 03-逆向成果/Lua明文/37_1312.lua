local LoadingBarLayer = class("LoadingBarLayer", function ()
    return cc.Layer:create()
end)

function LoadingBarLayer:ctor()
end

function LoadingBarLayer.create(...)
    local layer = LoadingBarLayer.new()
    if layer:Init(...) then
        return layer
    end
    return nil
end

function LoadingBarLayer:Init(t)
    local visibleSize = cc.Director:getInstance():getVisibleSize()

    local layout = ccui.Layout:create()
    self:addChild(layout)
    layout:setBackGroundColorType(1)
    layout:setBackGroundColor({r = 0, g = 0, b = 0})
    layout:setBackGroundColorOpacity(0)
    layout:setContentSize(visibleSize)
    layout:setTouchEnabled(true)

    local imageBar = ccui.ImageView:create()
    self:addChild(imageBar)
    imageBar:loadTexture("res_launcher/public/bg_load_1.png")
    imageBar:setPosition({x=visibleSize.width/2, y=visibleSize.height/2})
    imageBar:stopAllActions()
    imageBar:runAction(
        cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(0.04), cc.RotateBy:create(0, 30)))
    )

    if t then
        imageBar:runAction(cc.Sequence:create(cc.DelayTime:create(t), cc.CallFunc:create(function()
            global.L_LoadingBarManager:CloseLayer()
        end)))
    end

    return true
end

return LoadingBarLayer
