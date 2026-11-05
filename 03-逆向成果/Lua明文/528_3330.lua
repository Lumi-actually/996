local RemoteProxy = requireProxy("RemoteProxy")
local BubbleProxy = class("BubbleProxy", RemoteProxy)
BubbleProxy.NAME = global.ProxyTable.BubbleProxy

function BubbleProxy:ctor()
    BubbleProxy.super.ctor(self)
    self:Init()
end

function BubbleProxy:onRegister()
    BubbleProxy.super.onRegister(self)
end

function BubbleProxy:Init()
    self._configs = {}
    self._valList = {} --触发表
    self._scheduleId = nil

    self._needCheckIDs = {}
    self._needCheckIDsVec = SL:CreateQueue()

    self._activeIDs = {} --激活列表

    self._checkBubbleConfigs = {}    -- 对应条件ID检测的气泡ID列表 

    self._check = false

    self:LoadConfig()
end

function BubbleProxy:LoadConfig()
    self._configs = {}
    SL:Print("[Require game_config] ", "cfg_bubble")
    local configs = SL:RequireFile("game_config/cfg_bubble")
    for k, v in pairs(configs) do
        self._configs[v.id] = v
        if v.Condition then
            self._checkBubbleConfigs[v.Condition] = self._checkBubbleConfigs[v.Condition] or {}
            table.insert(self._checkBubbleConfigs[v.Condition], v.id)
        end
    end
end

function BubbleProxy:GetCheckBubbleTable(conditionID)
    if not conditionID then
        return {}
    end

    return self._checkBubbleConfigs[conditionID] or {}
end

local emptyTab = {}
function BubbleProxy:StartSchedule()
    if self._scheduleId then
        UnSchedule(self._scheduleId)
        self._scheduleId = nil
    end

    self._scheduleId = Schedule(function()
        if self._needCheckIDsVec:size() > 0 then
            local id = self._needCheckIDsVec:pop()
            local config = self._configs[id] or emptyTab
            if self:CheckCondition(config.Condition) then --满足条件
                self:addActiveID(config.id)
            else
                self:rmvActiveID(config.id)
            end
            self._needCheckIDs[id] = false
        end
    end, 1 / 60)
end

function BubbleProxy:addActiveID(id)
    if not self._activeIDs[id] then
        self._activeIDs[id] = true
        local config = self._configs[id]
        local RemindUpgradeProxy = global.Facade:retrieveProxy(global.ProxyTable.RemindUpgradeProxy)
        RemindUpgradeProxy:RefData(id, true, { id = id, name = config.ShowText, link = config.Link })
    end
end

function BubbleProxy:rmvActiveID(id)
    if not self._activeIDs[id] then
        return
    end
    self._activeIDs[id] = false
    local RemindUpgradeProxy = global.Facade:retrieveProxy(global.ProxyTable.RemindUpgradeProxy)
    RemindUpgradeProxy:RefData(id, false)
end

-------------------------------------------------------------
function BubbleProxy:CheckCondition(conditionId)
    local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
    return ConditionProxy:CheckConditionByID(conditionId)
end

function BubbleProxy:StartCheck()
    self._check = true
end

function BubbleProxy:InsertCheckQue(id)
    if not self._needCheckIDs[id] then
        self._needCheckIDs[id] = true
        self._needCheckIDsVec:push(id)
    end
end

function BubbleProxy:AllBubblesInsertCheckQue()
    for id, _ in pairs(self._configs) do
        self:InsertCheckQue(id)
    end
end

return BubbleProxy
