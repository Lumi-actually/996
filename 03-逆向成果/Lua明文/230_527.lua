local netNpcController = class("netNpcController")

function netNpcController:ctor()
end

function netNpcController:destory()
end

function netNpcController:create()
    local _this = netNpcController.new()
    return _this
end

function netNpcController:Cleanup()
end

function netNpcController:AddNetNpcToWorld(actorID)
    local netNpc = global.actorManager:CreateActor(actorID, global.MMO.ACTOR_NPC)
    if nil == netNpc then
        return nil
    end
    return netNpc
end

return netNpcController