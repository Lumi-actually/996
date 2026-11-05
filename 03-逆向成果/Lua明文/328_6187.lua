local skillBehavior = require("skill/skillBehavior")
local skillBehaviorSeq = class("skillBehaviorSeq", skillBehavior)

local skillPresentLaunch = require("skill/skillPresentLaunch")
local skillPresentFly    = require("skill/skillPresentFly")
local skillPresentHit    = require("skill/skillPresentHit")

function skillBehaviorSeq:ctor(id, data, config)
    skillBehaviorSeq.super.ctor(self, id, data, config)

    self._tickPresents  = {}
    self._nTickPresent  = 0

    self._launchPresent = nil
    self._flyPresents   = {}
    self._hitPresents   = {}

    self._presentTag    = 0
end

function skillBehaviorSeq:init()
    self._currPresent = nil
end

function skillBehaviorSeq:launch()
    skillBehaviorSeq.super.launch(self)

    if self._data.skillStage == 1 then
        self:joinLaunch()

    elseif self._data.skillStage == 2 then
        self:joinLaunchOver()

    else
        self:joinLaunch()
        self:joinLaunchOver()
    end

    if self._data.needFly then
        self:joinLaunchFly()
    end
    
    -- launch
    self:launchBehavior()
end

function skillBehaviorSeq:launchBehavior()
    if self._launchPresent then
        self._launchPresent:launch()
        return true
    end

    local n = #self._flyPresents

    for i = 1, n do
        self._flyPresents[i]:launch()
    end

    return n > 0
end

function skillBehaviorSeq:joinLaunch()
    if self._launchPresent then
        return nil
    end
    self._launchPresent = skillPresentLaunch.new(self._data, self._config, self._launchRoot, nil, self)
    self._launchPresent:init()

    self._launchPresent.tag = self._presentTag
    self._presentTag        = self._presentTag + 1
end

function skillBehaviorSeq:joinLaunchOver()
    local nFlyPresents = #self._flyPresents
    local nHitPresents = #self._hitPresents

    if nFlyPresents > 0 or nHitPresents > 0 then
        return nil
    end

    if not self._data.hitX or not self._data.hitY then
        return nil
    end

    local targets = {}
    local nTarget = 0
    if self._data.param and self._data.param ~= "" then
        local slices    = G_GetSplitArray(self._data.param, "#")
        for _, v in ipairs(slices) do
            nTarget = nTarget + 1
            targets[nTarget] = {destX = self._data.hitX, destY = self._data.hitY, id = v}
        end
    elseif self._data.targetParam and next(self._data.targetParam) then
        for _, v in ipairs(self._data.targetParam) do
            nTarget = nTarget + 1
            targets[nTarget] = {destX = v.X, destY = v.Y, id = v.ID}
        end
    else
        nTarget = nTarget + 1
        targets[nTarget] = {destX = self._data.hitX, destY = self._data.hitY, id = nil}
    end

    for i = 1, nTarget do
        local target = targets[i]
        local flyPresent = skillPresentFly.new(self._data, self._config, self._flyRoot, target, self)
        flyPresent:init()
        flyPresent.tag   = self._presentTag
        self._presentTag = self._presentTag + 1

        nFlyPresents = nFlyPresents + 1
        self._flyPresents[nFlyPresents] = flyPresent

        if self._config.needTarget ~= 1 or target.id ~= nil then
            local hitPresent = skillPresentHit.new(self._data, self._config, self._hitRoot, target, self)
            hitPresent:init()
            hitPresent.tag   = self._presentTag
            self._presentTag = self._presentTag + 1

            nHitPresents = nHitPresents + 1
            self._hitPresents[nHitPresents] = hitPresent

            flyPresent:setNext({hitPresent})
        end
    end

    -- bind next present
    if self._launchPresent then
        self._launchPresent:setNext(self._flyPresents)
    end
end

local targets = {}
function skillBehaviorSeq:joinLaunchFly()
    local nFlyPresents = #self._flyPresents
    if nFlyPresents > 0  then
        return nil
    end

    if not self._data.hitX or not self._data.hitY then
        return nil
    end

    local nTarget = 0
    if self._data.param and self._data.param ~= "" then
        local slices    = G_GetSplitArray(self._data.param, "#")
        for _, v in ipairs(slices) do
            nTarget = nTarget + 1
            targets[nTarget] = {destX = self._data.hitX, destY = self._data.hitY, id = v}
        end
    elseif self._data.targetParam and next(self._data.targetParam) then -- 带目标ID和坐标的json数组 避免出现目标在视野外取不到位置的情况
        for _, v in ipairs(self._data.targetParam) do
            nTarget = nTarget + 1
            targets[nTarget] = {destX = v.X, destY = v.Y, id = v.ID}
        end

    else
        nTarget = nTarget + 1
        targets[nTarget] = {destX = self._data.hitX, destY = self._data.hitY, id = nil}
    end
    for i = 1, nTarget do
        local target = targets[i]
        local flyPresent = skillPresentFly.new(self._data, self._config, self._flyRoot, target, self)
        flyPresent:init()
        flyPresent.tag   = self._presentTag
        self._presentTag = self._presentTag + 1

        nFlyPresents = nFlyPresents + 1
        self._flyPresents[nFlyPresents] = flyPresent
    end

    -- bind next present
    if self._launchPresent then
        self._launchPresent:setNext(self._flyPresents)
    end
end

function skillBehaviorSeq:onLaunch(skillPB)
    self._nTickPresent = self._nTickPresent + 1
    self._tickPresents[self._nTickPresent] = skillPB
end

function skillBehaviorSeq:onFinish(skillPB)
    for i = 1, self._nTickPresent do
        local v = self._tickPresents[i]
        if v and v.tag == skillPB.tag then
            self._tickPresents[i] = self._tickPresents[self._nTickPresent]
            self._tickPresents[self._nTickPresent] = nil
            self._nTickPresent = self._nTickPresent - 1
        end
    end

    if self._nTickPresent < 1 then
        self:disable()
    end
end

function skillBehaviorSeq:Tick(dt)
    for i = 1, self._nTickPresent do
        if i <= self._nTickPresent then
            self._tickPresents[i]:Tick(dt)
        end
    end
end

return skillBehaviorSeq
