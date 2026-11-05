local LoadingManager = class("LoadingManager")

function LoadingManager:ctor()
end

function LoadingManager:OpenLayer(data)
    if not self._layer then
        self._layer = requireLauncher( "logic/LoadingLayer" ).create(data)
        self._type  = 1
        global.L_GameLayerManager:OpenLayer(self)
    end
end

function LoadingManager:CloseLayer()
    if not self._layer then
        return nil
    end
    self._layer:CloseLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

function LoadingManager:UpdatePercent(percent, totalSize)
    if not self._layer then
        return nil
    end
    self._layer:UpdatePercent(percent, totalSize)
end

return LoadingManager
