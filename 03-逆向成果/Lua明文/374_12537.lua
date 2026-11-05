local DebugMediator = requireMediator("DebugMediator")
local ConditionMediator = class("ConditionMediator", DebugMediator)
ConditionMediator.NAME = "ConditionMediator"

-- 优化点
-- 1. 条件结果检测后保存，但是条件配置可能很多，考虑在使用中的实时监测，不使用时自动脱离检测控制
-- 2. 延迟检测，和1不冲突

local CHECK_INTERVAL = 0.03
local CHECK_RELATE_INTERVAL = 0.02  -- 关联气泡用
local CHECK_RELATE_BATCH_NUM = 20   -- 单次间隔检测数量

function ConditionMediator:ctor()
    ConditionMediator.super.ctor(self, self.NAME)

    self._conditionWidgets = {}
    self._conditionValue = {} -- 已经检测的结果
    self._conditionCache = {} -- {gid:conditionId}
    self._checkCache = {}     -- 检测队列
    self._checkLimit = {}     -- 检查限制,避免死循环配置
    self._scheduleID = nil
    
    self._checkEventRelateTimes = 0
    self._checkRelateCache = {}
    self._onEventTimer = {}

    if GUI and GUI._conditionMediator then
        GUI._conditionMediator = nil
        GUI._conditionRedID = 0
    end

    self._conditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)

    SL:RegisterLUAEvent(LUA_EVENT_QUICKUSE_DATA_OPER, "ConditionMediator", handler(self, self.CheckRefresh))
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_CHANGE, "ConditionMediator", handler(self, self.CheckRefresh))
    SL:RegisterLUAEvent(LUA_EVENT_MONEY_CHANGE, "ConditionMediator", handler(self, self.CheckRefresh))
    SL:RegisterLUAEvent(LUA_EVENT_BAG_LOAD_SUCCESS, "ConditionMediator", handler(self, self.CheckRefresh))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_CHANGE, "ConditionMediator", handler(self, self.CheckRefresh))
    SL:RegisterLUAEvent(LUA_EVENT_HERO_BAG_LOAD_SUCCESS, "ConditionMediator", handler(self, self.CheckRefresh))
    SL:RegisterLUAEvent(LUA_EVENT_HERO_EQUIP_CHANGE, "ConditionMediator", handler(self, self.CheckRefresh))
    SL:RegisterLUAEvent(LUA_EVENT_HERO_LOGOUT, "ConditionMediator", handler(self, self.CheckRefresh))
    
    SL:RegisterLUAEvent(LUA_EVENT_EXP_CHANGE, "ConditionMediator", handler(self, self.CheckRefresh))
    SL:RegisterLUAEvent(LUA_EVENT_HERO_EXP_CHANGE, "ConditionMediator", handler(self, self.CheckRefresh))
    
    SL:RegisterLUAEvent(LUA_EVENT_HPMP_CHANGE, "ConditionMediator", handler(self, self.CheckRefresh))
    SL:RegisterLUAEvent(LUA_EVENT_HERO_HPMP_CHANGE, "ConditionMediator", handler(self, self.CheckRefresh))
    
    SL:RegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "ConditionMediator", handler(self, self.CheckRefresh))
    SL:RegisterLUAEvent(LUA_EVENT_REINLEVEL_CHANGE, "ConditionMediator", handler(self, self.CheckRefresh))
    SL:RegisterLUAEvent(LUA_EVENT_HERO_LEVEL_CHANGE, "ConditionMediator", handler(self, self.CheckRefresh))

    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_CHANGE, "ConditionMediator", handler(self, self.CheckRefresh))

    SL:RegisterLUAEvent(LUA_EVENT_CHECK_SERVER_VALUE_CHANGE, "ConditionMediator", handler(self, self.CheckRefresh))

    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "ConditionMediator", handler(self, self.CheckAllBubbles))

    SL:RegisterLUAEvent(LUA_EVENT_MAINPLAYER_BUFF_UPDATE, "ConditionMediator", handler(self, self.OnCheckBuffUpdate))
end

function ConditionMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return
    {
        noticeTable.GameWorldInitComplete,
        noticeTable.SUIConditionWidgetAdd,
        noticeTable.SUIConditionWidgetRemove,
    }
end

function ConditionMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()

    if noticeID == noticeTable.GameWorldInitComplete then
        self:startSchedule()
    elseif noticeID == noticeTable.SUIConditionWidgetAdd then
        self:OnSUIConditionWidgetAdd(data)
    elseif noticeID == noticeTable.SUIConditionWidgetRemove then
        self:OnSUIConditionWidgetRemove(data)
    end
end

function ConditionMediator:startSchedule()
    -- local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
    -- if ConditionProxy then
    --     ConditionProxy:StartSchedule()
    -- end
    local BubbleProxy = global.Facade:retrieveProxy(global.ProxyTable.BubbleProxy)
    if BubbleProxy then
        BubbleProxy:StartSchedule()
    end
end

function ConditionMediator:OnCheckBuffUpdate(eventData, eventTag, eventId)
    -- 增删BUFF时触发
    if eventData and (eventData.type == 0 or eventData.type == 1) then
        self:CheckRefresh(eventData, eventTag, eventId)
    end
end

-- 触发刷新
function ConditionMediator:CheckRefresh(eventData, eventTag, eventId)
    -- 短时间内连续触发仅刷新一次
    if not self._onEventTimer[eventId] then
        self._onEventTimer[eventId] = SL:ScheduleOnce(function()
            self:OnNotification(eventId)
            SL:UnSchedule(self._onEventTimer[eventId])
            self._onEventTimer[eventId] = nil
        end, 0.5)
    end
end

function ConditionMediator:CheckWidgetGIDValid(gid)
    if gid and not self._conditionCache[gid] then
        return true
    end
    return false
end

function ConditionMediator:OnSUIConditionWidgetAdd(data)
    -- 一个组件只能绑定一个conditionID
    local conditionID = data.conditionID
    local widget = data.widget
    if not conditionID or not widget then
        return
    end

    if not widget.gid then
        return
    end

    -- 移除重复注册
    local lastId = self._conditionCache[widget.gid]
    if lastId then
        if lastId ~= conditionID then
            self:RemoveWidget(widget)
        else
            return
        end
    end

    -- 存储
    self._conditionWidgets[conditionID] = self._conditionWidgets[conditionID] or {}
    table.insert(self._conditionWidgets[conditionID], widget)
    self._conditionCache[widget.gid] = conditionID

    -- 加入时使用上次数据
    local conditionValue = self._conditionValue[conditionID] == true
    GUI:setVisible(widget, conditionValue)

    widget:registerScriptHandler(function(state)
        if state == "exit" then
            self:RemoveWidget(widget)
        end
    end)

    -- 默认检测一次
    self:PushCheckConditionID(conditionID)
end

function ConditionMediator:OnSUIConditionWidgetRemove(data)
    local widget = data.widget
    if not widget then
        return
    end

    self:RemoveWidget(widget)
end

function ConditionMediator:RemoveWidget(widget)
    if not widget then return end
    local conditionID = self._conditionCache[widget.gid]
    if not conditionID then return end
    self._conditionCache[widget.gid] = nil
    local widgets = self._conditionWidgets[conditionID]
    if not widgets then return end
    local count = #widgets
    for i = 1, count, 1 do
        if widgets[i].gid == widget.gid then
            table.remove(widgets, i)
            count = count - 1
            if count == 0 then
                self._conditionWidgets[conditionID] = nil
            end
            break
        end
    end
end

function ConditionMediator:OnNotification(noticeID)
    -- 当前没有组件
    -- if not next(self._conditionWidgets) then
    --     return
    -- end

    -- 检测所有该event触发的条件ID
    if not self._conditionProxy then
        self._conditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
    end
    local conditionTable = self._conditionProxy:GetConditionTableByNoticeID(noticeID)
    -- print(noticeID, "_____________", conditionTable and #conditionTable)
    if conditionTable then
        for _, conditionID in ipairs(conditionTable) do
            self._checkEventRelateTimes = 0
            while self._checkEventRelateTimes <= 5 do
                local isStop = self:OnCheckRelateCondition(conditionID, noticeID)
                if isStop then
                    break
                end
            end
        end
    end
end

function ConditionMediator:OnCheckRelateCondition(conditionID, noticeID)
    if self._checkEventRelateTimes > 5 then
        return true, true
    end
    self._checkEventRelateTimes = self._checkEventRelateTimes + 1
    -- print("OnCheckRelateCondition______", noticeID, conditionID, "次数——————", self._checkEventRelateTimes)
    if self._conditionWidgets[conditionID] then
        -- print("trigger CondtionID", noticeID, conditionID)
        self:PushCheckConditionID(conditionID)
    end
    self:PushCheckRelateConditionID(conditionID)

    local relateTable = self._conditionProxy:GetRelateTableByConditionID(conditionID)
    if relateTable and #relateTable > 0 then
        local len = #relateTable
        for i = 1, len do
            local id = relateTable[i]
            local isStop, isOut = self:OnCheckRelateCondition(id, noticeID)
            if isStop and (isOut or i == len) then
                return true
            end
        end
    else
        return true
    end
end

function ConditionMediator:CheckRelateBubble(conditionID)
    local BubbleProxy = global.Facade:retrieveProxy(global.ProxyTable.BubbleProxy)
    local checkBubbleTab = BubbleProxy:GetCheckBubbleTable(conditionID)
    if checkBubbleTab and #checkBubbleTab > 0 then
        for _, bubbleId in ipairs(checkBubbleTab) do
            BubbleProxy:InsertCheckQue(bubbleId)
        end 
    end
end

function ConditionMediator:CheckAllBubbles()
    local BubbleProxy = global.Facade:retrieveProxy(global.ProxyTable.BubbleProxy)
    BubbleProxy:AllBubblesInsertCheckQue()
end

function ConditionMediator:OnConditionValueUpdate(conditionID)
    local conditionValue = self._conditionValue[conditionID] == true

    if self._conditionWidgets[conditionID] then
        for i, widget in ipairs(self._conditionWidgets[conditionID]) do
            GUI:setVisible(widget, conditionValue)
        end
    end
end

function ConditionMediator:CheckConditionValue(conditionID)
    local time = self._checkLimit[conditionID] or 0
    if time >= 5 then return end
    time = time + 1
    self._checkLimit[conditionID] = time
    self._conditionValue[conditionID] = self._conditionProxy:CheckConditionByID(conditionID)

    -- 更新关联condition
    -- local relateTable = self._conditionProxy:GetRelateTableByConditionID(conditionID)
    -- if relateTable then
    --     local len = #relateTable
    --     for i = 1, len do
    --         local id = relateTable[i]
    --         self:CheckConditionValue(id)
    --     end
    -- end
    -- 触发组件刷新
    self:OnConditionValueUpdate(conditionID)
end

function ConditionMediator:PushCheckConditionID(conditionID)
    self._checkCache[conditionID] = 1

    self:StartTimer()
end

function ConditionMediator:StartTimer()
    if self._scheduleID then
        return
    end

    self._scheduleID = Schedule(function()
        local conditionID, _ = next(self._checkCache)
        if conditionID then
            self._checkCache[conditionID] = nil
            self._checkLimit = {}
            self:CheckConditionValue(conditionID)
        else
            self:StopTimer()
        end
    end, CHECK_INTERVAL)
end

function ConditionMediator:StopTimer()
    if not self._scheduleID then
        return
    end
    UnSchedule(self._scheduleID)
    self._scheduleID = nil
end

function ConditionMediator:PushCheckRelateConditionID(conditionID)
    self._checkRelateCache[conditionID] = 1

    self:StartRelateTimer()
end

function ConditionMediator:StartRelateTimer()
    if self._scheduleRelateID then
        return
    end

    self._scheduleRelateID = Schedule(function()
        for i = 1, CHECK_RELATE_BATCH_NUM do
            local conditionID, _ = next(self._checkRelateCache)
            if conditionID then
                self._checkRelateCache[conditionID] = nil
                self:CheckRelateBubble(conditionID)
            else
                self:StopRelateTimer()
            end
        end
    end, CHECK_RELATE_INTERVAL)
end

function ConditionMediator:StopRelateTimer()
    if not self._scheduleRelateID then
        return
    end
    UnSchedule(self._scheduleRelateID)
    self._scheduleRelateID = nil
end

return ConditionMediator