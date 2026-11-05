local LoadingPlayManager = class("LoadingPlayManager")

function LoadingPlayManager:ctor()
end

function LoadingPlayManager:OpenLayer()
    if not self._layer then
        self._layer = requireLauncher( "logic/LoadingPlayLayer" ).create()
        self._type  = 5
        global.L_GameLayerManager:OpenLayer(self)
    end
end

function LoadingPlayManager:CloseLayer()
    if not self._layer then
        return nil
    end
    self._layer:CloseLayer()
    self._layer:removeFromParent()
    self._layer = nil
end

function LoadingPlayManager:UpdatePreLoadingPic(ui, path)
    if not self._layer then
        return nil
    end
    self._layer:UpdatePreLoadingPic(ui, path)
end

return LoadingPlayManager
