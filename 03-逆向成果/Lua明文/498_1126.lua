local RemoteProxy = requireProxy("RemoteProxy")
local ServerOptionsProxy = class("ServerOptionsProxy", RemoteProxy)
ServerOptionsProxy.NAME = global.ProxyTable.ServerOptionsProxy

function ServerOptionsProxy:ctor()
    ServerOptionsProxy.super.ctor(self)

    self._data = {}
end

function ServerOptionsProxy:SetOptions(data)
    if not data then
        return
    end

    self._data = data
    self._moveActionForbidDash = 0 -- 移动状态禁止野蛮
end

function ServerOptionsProxy:SetOptionByKey(k, v)
    self._data[k] = v
end

function ServerOptionsProxy:CheckOption(id)
    return self._data[id]
end

function ServerOptionsProxy:SetMoveActionForbidDash(state)
    self._moveActionForbidDash = state
end

function ServerOptionsProxy:GetMoveActionForbidDash()
    return self._moveActionForbidDash 
end

function CHECK_SERVER_OPTION(id)
    local ServerOptionsProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerOptionsProxy)
    if not ServerOptionsProxy then
        return false
    end
    return ServerOptionsProxy:CheckOption(id)
end

return ServerOptionsProxy