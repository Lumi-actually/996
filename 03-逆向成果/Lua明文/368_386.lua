local AutoFindBehavior = require("auto_behavior/AutoFindBehavior")
local AutoFindSkillBehavior = class("AutoFindSkillBehavior", AutoFindBehavior)

function AutoFindSkillBehavior:ctor()
    AutoFindSkillBehavior.super.ctor(self)
end

function AutoFindSkillBehavior:Update(player, actCompleted)
    return GUIFunction:AutoFindSkillBehavior()
end

return AutoFindSkillBehavior
