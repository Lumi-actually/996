local Behavior = require("bt/Behavior")
local BehaviorDig = class("BehaviorDig", Behavior)

local facade            = global.Facade
local BehaviorConfig    = global.BehaviorConfig
function BehaviorDig:ctor(data)
    BehaviorDig.super.ctor(self, data)
end

function BehaviorDig:GetType()
    return BehaviorConfig.BehaviorType.BehaviorDig
end

function BehaviorDig:Update(player, actCompleted)
    local inputProxy    = global.Facade:retrieveProxy( global.ProxyTable.PlayerInputProxy )
    local digDest       = inputProxy:GetDigDest()

    local mainPlayer    = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return BehaviorConfig.BTSTATUS_Failure
    end
    if not digDest then
        return BehaviorConfig.BTSTATUS_Failure
    end

    local mapX, mapY = global.sceneManager:WorldPos2MapPos(digDest.x, digDest.y)
    local dX = mapX
    local dY = mapY
    local sX = mainPlayer:GetMapX()
    local sY = mainPlayer:GetMapY()
    local targetID = nil
    local targetActor = global.actorPickerController:Pick(digDest.x, digDest.y)
    
    if targetActor and targetActor:IsDie() then
        targetID = targetActor:GetID()
        dX = targetActor:GetMapX()
        dY = targetActor:GetMapY()
    end

    local dir = G_ActorUtils.CalcMapDirection(dX, dY, sX, sY)
    if not dir or dir == global.MMO.ORIENT_INVAILD then
        dir = mainPlayer:GetDirection()
    end
    mainPlayer:SetAction(global.MMO.ACTION_SITDOWN)
    mainPlayer:SetDirection(dir)

    -- 
    inputProxy:RequestDigCorpse(dir, targetID)
    inputProxy:ClearDigDest()

    return BehaviorConfig.BTSTATUS_Running
end

return BehaviorDig