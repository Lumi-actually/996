local DebugProxy  = requireProxy( "DebugProxy" )
local RemoteProxy = class( "RemoteProxy", DebugProxy )
RemoteProxy.NAME = "RemoteProxy"

function RemoteProxy:ctor( data )
	RemoteProxy.super.ctor( self, self.NAME, data )
end

function RemoteProxy:onRegister()
	self:RegisterMsgHandler()
	RemoteProxy.super.onRegister( self )
end

function RemoteProxy:RegisterMsgHandler()
end

return RemoteProxy