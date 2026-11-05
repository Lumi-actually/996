local CommonTipsManager = class("CommonTipsManager")

function CommonTipsManager:ctor()
end

function CommonTipsManager:InitLayer(data)
    if self._layer ~=nil then
        self._layer:SetLayerType(data)        
    end
end

function CommonTipsManager:OpenLayer(data)
    if not ( self._layer ) then
        self._layer = requireLauncher( "logic/CommonTipsLayer" ).create(data)
        self._type  = 5
        global.L_GameLayerManager:OpenLayer(self)
    end

    self:InitLayer(data)
end

function CommonTipsManager:CloseLayer()
    if not self._layer then
        return nil
    end
    self._layer:removeFromParent()
    self._layer = nil
end

return CommonTipsManager