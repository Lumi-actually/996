local BaseUIMediator = requireMediator("BaseUIMediator")
local GUIMediator = class("GUIMediator", BaseUIMediator)
GUIMediator.NAME = "GUIMediator"

function GUIMediator:ctor(mediatorName)
    GUIMediator.NAME = mediatorName
    GUIMediator.super.ctor( self, mediatorName )
end

return GUIMediator