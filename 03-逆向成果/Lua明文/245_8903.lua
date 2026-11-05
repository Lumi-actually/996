local Behavior = require("bt/Behavior")
local BehaviorMove = class("BehaviorMove", Behavior)

local BehaviorConfig = global.BehaviorConfig

local function CheckAbleToWalk(nextPoint)
    return global.PathFindController:CheckAbleToWalk(nextPoint)
end

local function checkOverTarget(nextPoint)
    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    
    -- launch only
    local moveType = inputProxy:GetCurrMoveType()
    if moveType ~= GUIDefine.InputMoveType.LAUNCH then
        return false
    end

    -- can't find target
    local targetID = inputProxy:GetTargetID()
    local target = global.actorManager:GetActor(targetID)
    if not target then
        return false
    end

    if nextPoint.x == target:GetMapX() and nextPoint.y == target:GetMapY() then
        return true
    end

    return false
end

function BehaviorMove:ctor(data)
    BehaviorMove.super.ctor(self, data)
end

function BehaviorMove:GetType()
    return BehaviorConfig.BehaviorType.BehaviorMove
end

local InputMoveT = {
    type = GUIDefine.InputMoveType.JOYSTICK
}
function BehaviorMove:Update(player, actCompleted)
    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)

    if inputProxy:IsLaunchDirty() then
        return BehaviorConfig.BTSTATUS_Failure
    end

    if not inputProxy:IsMovePermission() then
        return BehaviorConfig.BTSTATUS_Failure
    end

    if player:IsHoreseCopilot() then
        return BehaviorConfig.BTSTATUS_Failure
    end

    if inputProxy:GetLaunchNoWalkPos() then
        inputProxy:SetLaunchNoWalkPos(nil)
    end

    local optionRunOne  = CHECK_SERVER_OPTION(global.MMO.SERVER_RUN_ONE) == true  -- 服务器开关控制跑1格
    local isInputMove   = false
    local isRunOne      = false
    
    local isComplete = true
    if GUIFunction.OnCheckInputMoveFunc then
        isComplete, isInputMove, isRunOne = GUIFunction:OnCheckInputMoveFunc()
        if not isComplete then
            -- 移动失败 清除鼠标触摸点
            local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
            inputProxy:ClearMouseTouch()

            return BehaviorConfig.BTSTATUS_Failure
        end
    end

    -- move to next point
    local currPathPoint = inputProxy:GetCurrPathPoint()
    if currPathPoint == 0 then
        if actCompleted == global.MMO.ACTION_WALK or actCompleted == global.MMO.ACTION_RUN or actCompleted == global.MMO.ACTION_RIDE_RUN then
            global.Facade:sendNotification(global.NoticeTable.ActorEnterIdleAction,  player:GetID())

            self:OnMoveFinished(player, actCompleted)
        end
        return BehaviorConfig.BTSTATUS_Failure
    end

    local pathPoints            = inputProxy:GetPathFindPoints()
    local nextPoint, moveStep   = global.PathFindController:CheckNextMovePos(player, pathPoints, currPathPoint)
    if nextPoint then
        -- can launch
        if checkOverTarget(nextPoint) then
            inputProxy:ClearMove()
            global.Facade:sendNotification(global.NoticeTable.ActorEnterIdleAction,  player:GetID())
            return BehaviorConfig.BTSTATUS_Failure
        end

        if not isInputMove and moveStep == 1 and optionRunOne then
            isRunOne = true
        end

        -- walk, check next point has player/monster/npc
        if not isRunOne and moveStep == 1 then
            if not CheckAbleToWalk(nextPoint) then
                -- record move blocked
                inputProxy:SetIsMoveBlocked(true)


                local moveType  = inputProxy:GetCurrMoveType()
                -- move crowded
                if autoProxy:IsAFKState() then
                    if moveType == GUIDefine.InputMoveType.FINDITEM then
                        -- 忽略当前拾取物
                        local autoPickItemID = autoProxy:GetPickItemID()
                        if autoPickItemID then
                            local target = global.actorManager:GetActor(autoPickItemID)
                            if target then
                                target:IgnoreActor(true)
                            end
                        end
                        autoProxy:ClearAutoPick()
                        autoProxy:SetPickItemFlag(true) 

                    elseif moveType == GUIDefine.InputMoveType.LAUNCH then
                        -- 忽略
                        if actCompleted == global.MMO.ACTION_WALK or actCompleted == global.MMO.ACTION_RUN or actCompleted == global.MMO.ACTION_RIDE_RUN then
                        else
                            local targetID = inputProxy:GetTargetID()
                            local target   = nil
                            if targetID then
                                target = global.actorManager:GetActor(targetID)
                                if target then
                                    if not target:IsPauseIgnored() and not target:IsIgnored() then
                                        if autoProxy:IsAutoFightState() and global.PathFindController:CheckActorLimitObstacle(player:GetMapX(), player:GetMapY(), target:GetMapX(), target:GetMapY()) then
                                            target:PauseIgnoredActor(true)
                                        else
                                            target:IgnoreActor(true)
                                        end
                                    end
                                end
                            end
                            -- clear launch data
                            if not target or (not target:IsPauseIgnored() and target:IsIgnored()) then
                                autoProxy:ClearAutoLock()
                                inputProxy:ClearLaunch()
                                inputProxy:ClearTarget()
                            end
                        end
                    end
                    
                    inputProxy:ClearMove()
                    global.Facade:sendNotification(global.NoticeTable.ActorEnterIdleAction, player:GetID())
                else
                    inputProxy:ClearMove()
                    global.Facade:sendNotification(global.NoticeTable.ActorEnterIdleAction, player:GetID())
                    global.Facade:sendNotification(global.NoticeTable.ClearAllAutoState)
                end

                inputProxy:SetLaunchNoWalkPos(nextPoint)

                return BehaviorConfig.BTSTATUS_Failure
            end
        end

        local targetID = inputProxy:GetTargetID()
        if targetID then
            local target = global.actorManager:GetActor(targetID)
            if target and target:IsPauseIgnored() then
                target:PauseIgnoredActor()
            end
        end

        -- move
        player:SetKeyValue(global.MMO.IS_RUN_ONE, false)
        player:SetMoveTo(nextPoint.x, nextPoint.y)
        if moveStep == 3 then
            player:SetAction( global.MMO.ACTION_RIDE_RUN )
        elseif moveStep == 2 then
            player:SetAction( global.MMO.ACTION_RUN )
        else
            local act = global.MMO.ACTION_WALK
            if player:GetValueByKey(global.MMO.ACT_SNEAK) then
                act = global.MMO.ACTION_ASSASSIN_SNEAK
            elseif isRunOne then
                act = global.MMO.ACTION_RUN
                player:SetKeyValue(global.MMO.IS_RUN_ONE, true)
            end
            player:SetAction( act )
        end

        if currPathPoint - moveStep == 0 and not autoProxy:IsAFKState() then
            inputProxy:ClearMove()
        end

        inputProxy:SetCurrPathPoint(currPathPoint - moveStep)
        inputProxy:SetIsMoveBlocked(false)

        return BehaviorConfig.BTSTATUS_Running
    else
        -- move failed
        inputProxy:ClearMove()
        global.Facade:sendNotification(global.NoticeTable.ActorEnterIdleAction,  player:GetID())

        -- 
        if not autoProxy:GetAutoTargetInterruptFlag() then
            if autoProxy:IsAutoFightState() or autoProxy:IsAutoMoveState() then
                autoProxy:PauseAutoTarget()
                autoProxy:ResumeAutoTarget()
            end
        end

        return BehaviorConfig.BTSTATUS_Failure
    end
    
    return BehaviorConfig.BTSTATUS_Failure
end

function BehaviorMove:OnMoveFinished()
    local autoProxy     = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)

    -- auto move end
    if autoProxy:IsMoveCompleted() and autoProxy:IsAutoMoveState() then
        global.Facade:sendNotification(global.NoticeTable.AutoMoveEnd)
    end
end

return BehaviorMove