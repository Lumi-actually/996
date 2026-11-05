local RemoteProxy = requireProxy("RemoteProxy")
local MoneyProxy = class("MoneyProxy", RemoteProxy)
MoneyProxy.NAME = global.ProxyTable.MoneyProxy

function MoneyProxy:ctor()
    MoneyProxy.super.ctor(self)
    self._isInit            = true
    self._moneyData         = {}
    self._moneyConfig       = {}
    self._moneyConfigByName = {}
    self._noShowList        = {}
    self._noSoundList       = {}
end

function MoneyProxy:InitMoneyConfig(data)
    for k, v in ipairs(data) do
        self._moneyData[v.Id] = v
        self._moneyConfig[v.Id] = v
        self._moneyConfigByName[v.Name] = v
    end
end

function MoneyProxy:GetMoneyNameById(id)
    local config = self._moneyConfig[id]
    if not config then
        return ""
    end
    return config.Name or ""
end

function MoneyProxy:GetMoneyIdByName(name)
    local config = self._moneyConfigByName[name]
    if not config then
        return nil
    end
    return config.Id
end

function MoneyProxy:GetMoneyDataById(id)
    return self._moneyData[id]
end

function MoneyProxy:GetMoneyCountById(id, famlilar)
    local data = self:GetMoneyDataById(id)
    if not data then
        print("*************************")
        print("  money Type is nil ")
        print("*************************")
        return 0
    end
    local count = data.Count or 0
    if famlilar then
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        local moneys = ItemConfigProxy:GetSameReservedByMoneyIndex(id)
        for i, v in ipairs(moneys) do
            local otherMoney = self:GetMoneyDataById(v)
            count = count + (otherMoney.Count or 0)
        end
    end
    return count
end

local SharedUpdateData = {}
local SharedDiffData = {}
function MoneyProxy:UpdateMoneyData(jsonData)
    local moneyID    = nil
    local moneyValue = nil
    local lastValue  = 0
    local diffValue  = 0

    for _, v in ipairs(jsonData) do
        moneyID = v.ID
        moneyValue = v.Value or 0

        if self._moneyData[moneyID] then
            lastValue = self._moneyData[moneyID].Count or 0
            diffValue = moneyValue - lastValue
            self._moneyData[moneyID].Count = moneyValue

            -- 广播货币刷新
            if diffValue ~= 0 then
                SharedUpdateData.id = moneyID
                SharedUpdateData.count = moneyValue
                global.Facade:sendNotification(global.NoticeTable.PlayerMoneyChange, SharedUpdateData)
                SLBridge:onLUAEvent(LUA_EVENT_MONEY_CHANGE, SharedUpdateData)
            end

            if not self._isInit and diffValue ~= 0 then
                -- 提醒货币改变文本
                if not self._noShowList[moneyID] then
                    SharedDiffData.name = self:GetMoneyNameById(moneyID)
                    SharedDiffData.num = math.abs(diffValue)
                    if diffValue > 0 then
                        global.Facade:sendNotification(global.NoticeTable.ShowGetBagItem, SharedDiffData)
                    else
                        global.Facade:sendNotification(global.NoticeTable.ShowCostItem, SharedDiffData)
                    end
                end
    
                -- 提醒货币改变音效
                if not self._noSoundList[moneyID] then
                    local slt = global.SLT.AudioPlayTable1
                    slt.type = global.MMO.SND_TYPE_MONEY
                    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
                end
            end
        end
    end
end

function MoneyProxy:InitNoShowItemList()
    if not SL:GetValue("GAME_DATA", "currency_shield") or SL:GetValue("GAME_DATA", "currency_shield") == "" then
        return
    end

    local noShowString = G_GetSplitArray(SL:GetValue("GAME_DATA", "currency_shield"), "#")
    if noShowString[1] and noShowString[1] ~= "" then
        local shield_list = G_GetSplitArray(noShowString[1], "|")
        for k, v in ipairs(shield_list) do
            if tonumber(v) then
                self._noShowList[tonumber(v)] = 1
            end
        end
    end

    -- no sound 
    if noShowString and noShowString[2] and noShowString[2] ~= "" then
        local no_sound_list = G_GetSplitArray(noShowString[2], "|")
        for k, v in ipairs(no_sound_list) do
            if tonumber(v) then
                self._noSoundList[tonumber(v)] = 1
            end
        end
    end
end

function MoneyProxy:handle_MSG_SC_INIT_MONEY_INFO(msg)
    local data = msg:GetJsonData()
    if not data then
        return
    end
    self:InitMoneyConfig(data)
    self:InitNoShowItemList()
end

function MoneyProxy:handle_MSG_SC_UPDATA_MONEY_NUMBER(msg)
    local jsonData = msg:GetJsonData()
    if not jsonData then
        return
    end

    -- dump(jsonData)

    self:UpdateMoneyData(jsonData)
    self._isInit = false
end

function MoneyProxy:ResetInitStatus()
    self._isInit = true
end

function MoneyProxy:RegisterMsgHandler()
    MoneyProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    -- 根据页签返回页签数据
    LuaRegisterMsgHandler(msgType.MSG_SC_INIT_MONEY_INFO, handler(self, self.handle_MSG_SC_INIT_MONEY_INFO))
    -- 刷新角色货币
    LuaRegisterMsgHandler(msgType.MSG_SC_UPDATA_MONEY_NUMBER, handler(self, self.handle_MSG_SC_UPDATA_MONEY_NUMBER))
end

return MoneyProxy
