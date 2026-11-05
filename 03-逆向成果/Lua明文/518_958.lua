local RemoteProxy = requireProxy("RemoteProxy")
local NetworkProxy = class("NetworkProxy", RemoteProxy)
NetworkProxy.NAME = global.ProxyTable.NetworkProxy

function NetworkProxy:ctor()
    NetworkProxy.super.ctor(self)

    self._isDisconnect = false
end

function NetworkProxy:IsDisconnect()
    return self._isDisconnect
end

function NetworkProxy:SetDisconnect(value)
    self._isDisconnect = value
end

function NetworkProxy:handle_MSG_SC_NETWORK_OTHERPLACE_LOGIN(msg)
    self:SetDisconnect(true)
    global.networkCtl:SetIgnoreDisconnect(true)
    global.Facade:sendNotification(global.NoticeTable.OtherClientLogin)
end

function NetworkProxy:RegisterMsgHandler()
    NetworkProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_NETWORK_OTHERPLACE_LOGIN, handler(self, self.handle_MSG_SC_NETWORK_OTHERPLACE_LOGIN)) -- other client login
end

return NetworkProxy