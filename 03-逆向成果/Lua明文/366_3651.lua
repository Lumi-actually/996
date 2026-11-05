local AutoFindBehavior = require("auto_behavior/AutoFindBehavior")
local AutoFindActorBehavior = class("AutoFindActorBehavior", AutoFindBehavior)

local proxyUtils = requireUtil("proxyUtils")

function AutoFindActorBehavior:ctor()
    AutoFindActorBehavior.super.ctor(self)
end

function AutoFindActorBehavior:Update(player, actCompleted)
    if self:CheckAutoPick() then
        return true
    end

    if self:CheckAutoFindDropItem() then
        return true
    end

    if self:CheckAutoFindTarget(actCompleted) then
        return true
    end

    return false
end

-- 检测拾取
function AutoFindActorBehavior:IsCanPick()
    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
    if not inputProxy:IsMoving() then
        if autoProxy:GetPickItemID() then
            autoProxy:CheckPickTimeout()
            return true
        end
    end

    if nil == autoProxy:GetPickItemID() then
        global.Facade:sendNotification(global.NoticeTable.AutoFindDropItem)
    end

    if -1 == global.PathFindController:CheckNextMovePosAble() then
        autoProxy:SetPickItemID(nil)
        return false
    end

    if autoProxy:GetPickItemID() then
        return true
    end
    
    return false
end

-- 是否在自动拾取ing
function AutoFindActorBehavior:CheckAutoPick()
    local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
    if not autoProxy:IsPickState() then
        return false
    end
    return self:IsCanPick()
end

-- 查找掉落物
function AutoFindActorBehavior:CheckAutoFindDropItem()
    local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
    if not autoProxy:IsAFKState() and not autoProxy:IsAutoFightState() then
        return false
    end

    if not autoProxy:IsCanAutoPick() then
        return false
    end

    -- 内挂 范围内是否有足够怪物
    if proxyUtils:CheckIsEnoughMonster() then
        return false
    end

    -- 小精灵 如果是一个个拾取模式  需要放弃去拾取
    if proxyUtils:CheckIsPlayerAbandonPickup() then
        return false
    end

    return self:IsCanPick()
end

function AutoFindActorBehavior:CheckAutoFindTarget(actCompleted)
    if actCompleted ~= global.MMO.ACTION_IDLE then
        return false
    end

    local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
    if not autoProxy:IsAFKState() and not autoProxy:IsAutoFightState() then
        return false
    end

    if autoProxy:GetAutoTargetInterruptFlag() then
        return false
    end

    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    if inputProxy:GetTargetID() then
        return false
    end

    -- 1.find current target
    local needTerminate = false
    local targetType = autoProxy:GetTargetType()
    if global.MMO.ACTOR_NPC == targetType then
        global.Facade:sendNotification(global.NoticeTable.AutoFindNPC)
        if inputProxy:GetTargetID() then
            needTerminate = true
        end
    elseif global.MMO.ACTOR_MONSTER == targetType or global.MMO.ACTOR_PLAYER == targetType then
        GUIFunction:OnAutoFindHumanoidFunc()
    elseif global.MMO.ACTOR_COLLECTION == targetType then
        global.Facade:sendNotification(global.NoticeTable.AutoFindCollection)
        if inputProxy:GetTargetID() then
            needTerminate = true
        end
    end

    return needTerminate
end

return AutoFindActorBehavior
