local netActorController = require("logic/netActorController")
local netPlayerController = class("netPlayerController", netActorController)
netPlayerController.NAME = "netPlayerController"

local moveStep = {
    [global.MMO.ACTION_WALK] = 1,
    [global.MMO.ACTION_RUN] = 2,
    [global.MMO.ACTION_RIDE_RUN] = 3
}
local actorIDActT = {}
local SharedInputLaunchData = {}

function netPlayerController:ctor()
    netPlayerController.super.ctor(self)
end

function netPlayerController:destory()
    netPlayerController.super.ctor(self)
end

function netPlayerController:create()
    local _this = netPlayerController.new()
    return _this
end

function netPlayerController:Cleanup()
    netPlayerController.super.Cleanup(self)
end

---------------------------------------------------------------------------
function netPlayerController:handleActionBegin(actor, act)
    netPlayerController.super.handleActionBegin(self, actor, act)

    local actorID = actor:GetID()

    -- 广播
    actorIDActT.actorID = actorID
    actorIDActT.act = act
    SL:onLUAEvent(LUA_EVENT_NET_PLAYER_ACTION_BEGIN, actorIDActT)

    -- 当前攻击目标移动，触发继续释放
    if not SL:GetValue("IS_PC_OPER_MODE") and GUIFunction:IsMoveAction(act) then
        local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        local currMove = inputProxy:GetCurrMovePos()
        if currMove and currMove.targetID == actor:GetID() and currMove.skillID ~= nil then
            local targetID   = inputProxy:GetTargetID()
            local x, y       = inputProxy:GetLaunchTargetPos()
            local priority   = inputProxy:GetLaunchPriority()
            local launchType = inputProxy:GetLaunchType()
            SharedInputLaunchData.skillID    = currMove.skillID
            SharedInputLaunchData.targetID   = targetID
            SharedInputLaunchData.destPosX   = x
            SharedInputLaunchData.destPosY   = y
            SharedInputLaunchData.priority   = priority
            SharedInputLaunchData.launchType = launchType
            global.Facade:sendNotification(global.NoticeTable.InputLaunch, SharedInputLaunchData)
        end
    end
end

-----------------------------------------------------------------------------
function netPlayerController:handleActionCompleted(actor, actCompleted)
    netPlayerController.super.handleActionCompleted(self, actor, actCompleted)

    local actorID = actor:GetID()

    -- 广播
    actorIDActT.actorID = actorID
    actorIDActT.act = actCompleted
    SL:onLUAEvent(LUA_EVENT_NET_PLAYER_ACTION_COMPLETE, actorIDActT)

    -- PC HUD
    if SL:GetValue("IS_PC_OPER_MODE") and GUIFunction:IsMoveAction(actCompleted) then
        local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        if inputProxy:GetMouseOverTargetID() == actorID then
            inputProxy:SetMouseOverTargetID(nil)
            local hudParam = G_ActorUtils.GetActorAttr(actor, global.MMO.ACTOR_ATTR_HUDPARAM)
            if hudParam and next(hudParam) then
                global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabel, actorID)
            end
        end
    end

    -- 位移失败
    if actCompleted == global.MMO.ACTION_DASH_FAIL then
        local wX, wY = global.sceneManager:MapPos2WorldPos(actor:GetMapX(), actor:GetMapY(), true)
        actor:setPosition(wX, wY)
    end
end

function netPlayerController:handleActionProcess(actor, act, dt)
end

function netPlayerController:AddNetPlayerToWorld(actorID)
    local netPlayer = global.actorManager:CreateActor(actorID, global.MMO.ACTOR_PLAYER)
    if nil == netPlayer then
        return nil
    end

    -- bind handler
    netPlayer:SetGameActorActionHandler(self)
    global.Facade:sendNotification(global.NoticeTable.DelayCreateHUDBar, actorID)

    return netPlayer
end

function netPlayerController:handle_Die(actor, msgHdr)
    netPlayerController.super.handle_Die(self, actor, msgHdr)
end

return netPlayerController
