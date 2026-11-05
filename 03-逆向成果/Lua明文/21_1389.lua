local GameLayerManager = class("GameLayerManager")

local tremove = table.remove

function GameLayerManager:ctor()
end

function GameLayerManager:Init()
    local scene     = cc.Scene:create()
    local currScene = global.Director:getRunningScene()
    if not currScene then
        global.Director:runWithScene( scene )
    else
        global.Director:replaceScene( scene )
    end

    self._uiNode = cc.Node:create()
    scene:addChild(self._uiNode)
    self._uiNode:retain()
end

function GameLayerManager:Close()
    if nil == self._uiNode then
        return nil
    end
    
    self._uiNode:autorelease()
    self._uiNode = nil
end

function GameLayerManager:OpenLayer(data)
    if not self._uiNode then
        data._layer = nil
        return nil
    end
    if not data._layer or not data._type then
        data._layer = nil
        print("Openlayer args: data._layer, data._type")
        return nil
    end

    local layer = data._layer
    local ltype = data._type

    self._uiNode:addChild(layer, ltype)
end

function GameLayerManager:CloseLayer(data)
    if not self._uiNode then
        data._layer = nil
        return nil
    end

    if not data._layer then
        data._layer = nil
        return nil
    end
    
    data._layer:removeFromParent()
    data._layer = nil
end

return GameLayerManager
