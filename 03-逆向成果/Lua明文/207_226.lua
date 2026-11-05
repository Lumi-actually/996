local BaseLayer = class("BaseLayer", function()
    return cc.Layer:create()
end)

function BaseLayer:ctor()
end

function BaseLayer.create()
    local layer = BaseLayer.new()
    return layer
end

return BaseLayer