local Behavior = require("bt/Behavior")
local BehaviorMining = class("BehaviorMining", Behavior)

local facade         = global.Facade
local BehaviorConfig = global.BehaviorConfig

local skillT = {
    priority = global.MMO.LAUNCH_PRIORITY_USER,
    skillID = global.MMO.SKILL_INDEX_DIG
}

function BehaviorMining:ctor(data)
    BehaviorMining.super.ctor(self, data)
end

function BehaviorMining:GetType()
    return BehaviorConfig.BehaviorType.BehaviorMining
end

function BehaviorMining:Update(player, actCompleted)
    local inputProxy = facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)

    local dir = inputProxy:GetMiningDir()
    local destX, destY = inputProxy:GetMiningDest()

    if not dir or not destX or not destY then
        return BehaviorConfig.BTSTATUS_Failure
    end

    skillT.dir  = dir
    global.Facade:sendNotification(global.NoticeTable.RequestLaunchSkill, skillT)

    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_SKILL_ATTACK
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
    
    inputProxy:ClearMining()

    return BehaviorConfig.BTSTATUS_Running
end

return BehaviorMining