--[[
    主要用于 hot-loading, 方便逻辑debug
]]

local DebugMediator = class('DebugMediator', framework.Mediator)
DebugMediator.NAME  = "DebugMediator"


function DebugMediator:ctor()
    DebugMediator.super.ctor(self, self.NAME )
end

function DebugMediator.OnUnloaded()
end

function DebugMediator.Onloaded()
end

return DebugMediator 