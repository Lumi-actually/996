local actorHUDHPManager = class("actorHUDHPManager")
local optionsUtils = requireUtil("optionsUtils")
local Queue = requireUtil("queue")

function actorHUDHPManager:ctor()
    self._queue = Queue.new()
    self._cache = {}
end

function actorHUDHPManager:destory()
end

function actorHUDHPManager:create()
    local _this = actorHUDHPManager.new()
    return _this
end

function actorHUDHPManager:Update(actor)
    if not actor then
        return false
    end
    local actorID = actor:GetID()

    if self._cache[actorID] then
        return false
    end

    self._cache[actorID] = actor

    self._queue:push(actorID)


    if self._timerID then
        return false
    end

    local function callback()
        self:Tick()
    end
    self._timerID = Schedule(callback, 0.01)
    callback()
end

function actorHUDHPManager:UpdateNow(actor)
    if not actor then
        return false
    end
    
    self._cache[actor:GetID()] = nil
    global.Facade:sendNotification(global.NoticeTable.RefreshHUDHP, actor:GetID())
    optionsUtils:RefreshHUDHMpLabelVisible(actor)
end

function actorHUDHPManager:Tick()
    if self._queue:size() > 0 then
        self:UpdateNow(self._cache[self._queue:pop()])
    else
        self:Cleanup()
    end
end

function actorHUDHPManager:DelActor(actor, isUpdate)
    if isUpdate then
        self:UpdateNow(actor)
    else
        self._cache[actor:GetID()] = nil
    end
end

function actorHUDHPManager:Cleanup()
    if self._timerID then
        UnSchedule(self._timerID)
        self._timerID = nil
    end
    self._cache = {}
    self._queue:clear()
end

return actorHUDHPManager
