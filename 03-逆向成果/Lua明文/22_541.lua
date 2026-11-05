local LoadingBarManager = class("LoadingBarManager")

function LoadingBarManager:ctor()
end

function LoadingBarManager:OpenLayer(data)
    if not self._layer then
        self._layer = requireLauncher( "logic/LoadingBarLayer" ).create(data)
        self._type  = 999
        global.L_GameLayerManager:OpenLayer(self, data)
    end
end

function LoadingBarManager:CloseLayer()
    if not self._layer then
        return nil
    end
    self._layer:removeFromParent()
    self._layer = nil
end

return LoadingBarManager
