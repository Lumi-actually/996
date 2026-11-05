local Behavior = class("Behavior")
local BehaviorConfig = global.BehaviorConfig

function Behavior:ctor(data)
end

function Behavior:GetType()
    return BehaviorConfig.BehaviorType.BehaviorBase
end

function Behavior:Process(player, actCompleted)
end

function Behavior:Update(player, actCompleted)
end

return Behavior