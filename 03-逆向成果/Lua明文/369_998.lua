local AutoFindBehavior = require("auto_behavior/AutoFindBehavior")
local AutoFindMoveBehavior = class("AutoFindMoveBehavior", AutoFindBehavior)

function AutoFindMoveBehavior:ctor()
    AutoFindMoveBehavior.super.ctor(self)
end

function AutoFindMoveBehavior:Update(player, actCompleted)
    -- offline auto 
    if self:CheckAimlessMove(player, actCompleted) then
        return true
    end

    return false
end

function AutoFindMoveBehavior:CheckAimlessMove(player, actCompleted)
    if actCompleted ~= global.MMO.ACTION_IDLE then
        return false
    end

    local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
    -- 挂机目标死亡，原地等待
    if autoProxy:GetAFKTargetDeath() then
        return true
    end

    local assistProxy = global.Facade:retrieveProxy(global.ProxyTable.AssistProxy)
    if assistProxy:CheckAimlessMove() then
        return true
    end

    return false
end

return AutoFindMoveBehavior
