--[[
    主要用于 hot-loading, 方便逻辑debug
]]

local DebugProxy = class('DebugProxy', framework.Proxy)
DebugProxy.NAME  = "DebugProxy"


function DebugProxy:ctor()
    DebugProxy.super.ctor(self, self.NAME )
end

return DebugProxy 