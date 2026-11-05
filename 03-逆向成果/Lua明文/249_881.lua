local Behavior = require("bt/Behavior")
local BehaviorLaunch = class("BehaviorLaunch", Behavior)

local facade            = global.Facade
local BehaviorConfig    = global.BehaviorConfig
local skillT = {}

function BehaviorLaunch:ctor(data)
    BehaviorLaunch.super.ctor(self, data)
end

function BehaviorLaunch:GetType()
    return BehaviorConfig.BehaviorType.BehaviorLaunch
end

function BehaviorLaunch:Update(player, actCompleted)
    local inputProxy = facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)

    -- launch
    local skillID = inputProxy:GetLaunchSkillID()
    if skillID then
        skillT.skillID = skillID
        global.Facade:sendNotification(global.NoticeTable.RequestLaunchSkill, skillT)
        
        return BehaviorConfig.BTSTATUS_Running
    end

    return BehaviorConfig.BTSTATUS_Failure
end

return BehaviorLaunch