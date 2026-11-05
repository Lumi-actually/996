local skillBehavior = require("skill/skillBehavior")
local skillBehaviorDartle = class("skillBehaviorDartle", skillBehavior)

local skillPresentLaunch = require("skill/skillPresentLaunch")
local skillPresentFly    = require("skill/skillPresentFly")

local TIMER_INTERVAL = 0.02

function skillBehaviorDartle:ctor(id, data, config)
    skillBehaviorDartle.super.ctor(self, id, data, config)

    self._launchPresent = nil
    self._flyJoined     = false

    self._count         = 4
    self._flyEnable     = false
    self._finished      = 0
    self._delayTime     = TIMER_INTERVAL
    self._flyPresents   = {}
end

function skillBehaviorDartle:init()
end

function skillBehaviorDartle:launch()
    skillBehaviorDartle.super.launch(self)

    if self._data.skillStage == 1 then
        self:joinLaunch()

    elseif self._data.skillStage == 2 then
        self:joinLaunchOver()

    else
        self:joinLaunch()
        self:joinLaunchOver()
    end

    
    -- launch
    self:launchBehavior()
end

function skillBehaviorDartle:launchBehavior()
    if self._launchPresent then
        self._launchPresent:launch()
        return true
    end

    self._flyEnable = true

    return false
end

function skillBehaviorDartle:joinLaunch()
    if self._launchPresent then
        return nil
    end
    self._launchPresent = skillPresentLaunch.new(self._data, self._config, self._launchRoot, nil, self)
    self._launchPresent:init()
end

function skillBehaviorDartle:joinLaunchOver()
    self._flyJoined = true
end

function skillBehaviorDartle:onLaunch(skillPB)
end

function skillBehaviorDartle:onFinish(skillPB)
    if skillPB:GetType() == global.MMO.SKILL_PRESENT_LAUNCH then
        self._flyEnable = true
        self._launchPresent = nil

        if not self._flyJoined then
            self:disable()
        end

    elseif skillPB:GetType() == global.MMO.SKILL_PRESENT_FLY then
        self._finished = self._finished + 1
        if self._finished >= self._count then
            self:disable()
        end
    end
end

function skillBehaviorDartle:Tick(dt)
    if self._launchPresent then
        self._launchPresent:Tick(dt)
    end

    local nCount = #self._flyPresents
    for i = 1, nCount do
        self._flyPresents[i]:Tick(dt)
    end

    if self._flyEnable and nCount < self._count then
        if self._delayTime >= TIMER_INTERVAL then
            self._delayTime = 0

            local target  = {destX = self._data.hitX, destY = self._data.hitY, id = (self._data.param and self._data.param ~= "") and self._data.param or nil}
            local present = skillPresentFly.new(self._data, self._config, self._flyRoot, target, self)
            
            nCount = nCount + 1
            self._flyPresents[nCount] = present

            present:init()
            present:launch()
        else
            self._delayTime = self._delayTime + dt
        end
    end
end

return skillBehaviorDartle
