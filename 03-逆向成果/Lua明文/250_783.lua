local Behavior = require("bt/Behavior")
local BehaviorKLaunch = class("BehaviorKLaunch", Behavior)

local BehaviorConfig  = global.BehaviorConfig

function BehaviorKLaunch:ctor(data)
    BehaviorKLaunch.super.ctor(self, data)
end

function BehaviorKLaunch:GetType()
    return BehaviorConfig.BehaviorType.BehaviorKLaunch
end

function BehaviorKLaunch:Update(player, actCompleted)
    -- launch
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    local launchAble = global.actorSkillController:CheckKLaunchAble()
    if launchAble and mainPlayer then
        global.actorSkillController:RequestLaunchServerSkill()
        return BehaviorConfig.BTSTATUS_Running
    end

    return BehaviorConfig.BTSTATUS_Failure
end

return BehaviorKLaunch