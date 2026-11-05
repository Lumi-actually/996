local Behavior = require("bt/Behavior")
local BehaviorTurn = class("BehaviorTurn", Behavior)

local facade         = global.Facade
local BehaviorConfig = global.BehaviorConfig

function BehaviorTurn:ctor(data)
    BehaviorTurn.super.ctor(self, data)
end

function BehaviorTurn:GetType()
    return BehaviorConfig.BehaviorType.BehaviorTurn
end

function BehaviorTurn:Update(player, actCompleted)
    local inputProxy = facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    local turnDir    = inputProxy:GetMouseTurnDir()

    if not turnDir or turnDir == global.MMO.ORIENT_INVAILD then
        return BehaviorConfig.BTSTATUS_Failure
    end

    if not inputProxy:IsMovePermission() then
        return BehaviorConfig.BTSTATUS_Failure
    end

    player:SetDirection(turnDir)
    player:DirtyAnimFlag()
    player:SetAction(global.MMO.ACTION_TURN)

    inputProxy:RequestActorTurn(turnDir)
    inputProxy:ClearMouseTurnDir()
    
    return BehaviorConfig.BTSTATUS_Running
end

return BehaviorTurn