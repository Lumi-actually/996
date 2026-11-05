local skillPresentBase = class("skillPresentBase")

function skillPresentBase:ctor(data, config, root, target, delagate)
    self._next      = {}
    self._delagate  = delagate

    self._data      = data
    self._root      = root
    self._config    = config
    self._target    = target
    self._speed     = 1
    self._isInvalid = false

    -- 游戏速度
    local SkillProxy    = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    local skillConfig   = SkillProxy:FindConfigBySkillID(self._data.srcSkillID)
    local actor         = global.actorManager:GetActor(self._data.launcherID)
    if actor and skillConfig then
        if skillConfig.action == 0 then
            self._speed = actor:GetAttackSpeed()
        else
            self._speed = actor:GetMagicSpeed()
        end

        -- 怪物速度不低于帧速度
        if actor:IsMonster() then
            self._speed = math.max(self._speed, 1)
        end
    end

end

function skillPresentBase:GetType()
    return global.MMO.SKILL_PRESENT_BASE
end

function skillPresentBase:init()
end

function skillPresentBase:launch()
    self._delagate:onLaunch(self)
end

function skillPresentBase:launchNext()
    -- launch next
    for _, v in pairs(self._next) do
        v:launch()
    end

    -- complete
    self._delagate:onFinish(self)
end

function skillPresentBase:setNext(nextP)
    self._next = nextP
end

function skillPresentBase:setNodeParent(root)
end

function skillPresentBase:Tick(dt)
end

function skillPresentBase:isInvalid()
    return self._isInvalid
end

function skillPresentBase:disable()
    self._isInvalid = true
end

return skillPresentBase
