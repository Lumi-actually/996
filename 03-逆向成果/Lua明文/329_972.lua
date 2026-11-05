local skillBehavior = class("skillBehavior")

function skillBehavior:ctor(id, data, config)
    self._id = id
    self._data = data
    self._config = config
    self._isInvalid = false
end

function skillBehavior:init()
end

function skillBehavior:launch()
end

function skillBehavior:joinLaunch()
end

function skillBehavior:joinLaunchOver()
end

function skillBehavior:onLaunch(skillPB)
end

function skillBehavior:onFinish(skillPB)
end

function skillBehavior:setNodeParent(launchRoot, flyRoot, hitRoot)
    self._launchRoot = launchRoot
    self._flyRoot    = flyRoot
    self._hitRoot    = hitRoot
end

function skillBehavior:Tick(dt)
end

function skillBehavior:GetID()
    return self._id
end

function skillBehavior:setData(data)
    self._data = data
end

function skillBehavior:isInvalid()
    return self._isInvalid
end

function skillBehavior:disable()
    self._isInvalid = true
end

return skillBehavior
