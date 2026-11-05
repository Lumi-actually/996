local SystemTipsManager = class("SystemTipsManager")

function SystemTipsManager:ctor()
end

function SystemTipsManager:OpenLayer()
    if not self._layer then
        self._layer = requireLauncher( "logic/SystemTipsLayer" ).create()
        self._type  = 2
        global.L_GameLayerManager:OpenLayer(self)
    end
end

function SystemTipsManager:CloseLayer()
    if not self._layer then
        return nil
    end
    self._layer:removeFromParent()
    self._layer = nil
end

function SystemTipsManager:ShowTips(str)
    if not self._layer then
        return nil
    end
    self._layer:AddTips(str)
end

return SystemTipsManager
