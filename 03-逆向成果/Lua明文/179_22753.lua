local RemoteProxy    = requireProxy("RemoteProxy")
local ConditionProxy = class("ConditionProxy", RemoteProxy)
ConditionProxy.NAME  = global.ProxyTable.ConditionProxy

local cjson          = require("cjson")
local sgsub          = string.gsub
local sformat        = string.format
local sfind          = string.find
local smatch         = string.match
local tonumberType   = {
    MONEY = 1,
    MONEY_ASSOCIATED = 2
}

local function parseConditionOne(condition, isSpecial)
    return sgsub(condition, "(%b<>)%s*(.*)", function(v1, v2)
        local metaValue = string.sub(v1, 2, #v1 - 1)
        local index = string.find(metaValue, ",")
        local metaKey, metaParam
        if index then
            metaKey = string.sub(metaValue, 1, index - 1)
            metaParam = string.sub(metaValue, index + 1)
            v1 = sformat("('%s',%s)", metaKey, metaParam)
        else
            metaKey = metaValue
            v1 = sformat("('%s')", metaValue)
        end
        -- local valueData = string.split(metaValue, ",")

        if tonumberType[metaKey] then
            v1 = sformat("tonumber(metaValueProxy:GetConditionValueByKey%s)", v1)
        else
            v1 = "metaValueProxy:GetConditionValueByKey" .. v1
        end
        if isSpecial then
            v1 = sformat("((%s == nil or tonumber(%s) == nil) and 0 or tonumber(%s))", v1, v1, v1)
        end
        if v2 == "" then return v1 end

        local hasNil = sfind(v2, "nil")
        v2 = sgsub(v2, "(%s*[~<>=]=?)([^|&]+)", function(v21, v22)
            -- 处理数值引号问题
            -- v221 = '1' 数字值就去掉''
            -- v221 = abc 非数字值就补''
            -- v221 = 1   数字值不处理
            v22 = sgsub(v22, "^%s*'?(.-)'?%s*$", function(v221)
                if tonumber(v221) then
                    return v221
                elseif v221 == "true" or v221 == "false" then
                    return v221
                elseif hasNil then
                    return v221
                else
                    return sformat("'%s'", v221)
                end
            end)
            return sformat(" %s %s ", v21, v22)
        end)
        local conditionStr = sformat("%s ~= nil and %s ~= '' and %s%s", v1, v1, v1, v2)
        if hasNil then
            if sfind(v2, "~=") then
                conditionStr = sformat("%s%s and %s ~= ''", v1, v2, v1)
            else
                conditionStr = sformat("%s%s or %s == ''", v1, v2, v1)
            end

        end

        if isSpecial then
            conditionStr = sformat("%s%s", v1, v2)
        end

        return conditionStr
    end)
end

local function splitCondition(str)
    if not str or str == "" then
        return nil
    end
    local conditions = {}
    local idx = 0
    while 1 do
        idx = idx + 1
        if str == "" or idx > 100 then
            break
        end
        local condition = nil
        local len = string.len(str)
        local addIdx = sfind(str, "+")
        local reduceIdx = sfind(str, "-")
        local min = math.min(addIdx or #str + 1, reduceIdx or #str + 1)
        if addIdx or reduceIdx then
            condition = splitCondition(string.sub(str, 1, min - 1))
            if addIdx ~= nil and addIdx == min then
                table.insert(condition, #condition + 1, " + ")
            elseif reduceIdx ~= nil and reduceIdx == min then
                table.insert(condition, #condition + 1, " - ")
            end
            conditions[idx] = condition
            str = string.sub(str, min + 1)
        else
            local splitIdx = math.min(addIdx or len + 1, reduceIdx or len + 1)
            addIdx = addIdx or len
            reduceIdx = reduceIdx or len
            local conditionStr = string.sub(str, 1, splitIdx - 1)
            -- print("idx", andIdx, orIdx, len, str, conditionStr)
            condition = parseConditionOne(conditionStr, true)

            if addIdx < reduceIdx then
                condition = sformat("%s + ", condition)
            elseif addIdx > reduceIdx then
                condition = sformat("%s - ", condition)
            end
            conditions[idx] = condition
            str = string.sub(str, splitIdx + 1)
        end
    end
    if #conditions == 0 then
        return nil
    end

    return conditions
end

local function compareBracket(str)
    local offset = 1
    local strIdx = 2
    local len = string.len(str)
    local IDX = 1
    while 1 do
        IDX = IDX + 1
        local lIdx = sfind(str, "%(", strIdx) or len
        local rIdx = sfind(str, "%)", strIdx) or len
        if lIdx < rIdx then
            strIdx = lIdx + 1
            offset = offset + 1
        else
            strIdx = rIdx + 1
            offset = offset - 1
        end
        if offset == 0 then
            strIdx = strIdx - 1
            break
        end
        if strIdx > string.len(str) then
            print(">>>>>>>condition () not compare", str, IDX)
            return nil
        end
    end
    return strIdx
end

local function concatStr(conditionTable)
    local conditions = { "(", ")" }
    for index, value in ipairs(conditionTable) do
        if type(value) == "table" then
            local str = concatStr(value)
            if str ~= nil then
                table.insert(conditions, #conditions, str)
            end
        elseif type(value) == "string" then
            -- if value == " or " or value == " and " then
            --     table.insert(conditions, #conditions, value)
            -- else
            table.insert(conditions, #conditions, value)
            -- end
        end
    end
    if #conditions == 0 then
        return nil
    elseif #conditions == 1 then
        return conditions[1]
    else
        return table.concat(conditions)
    end
end

local function concatStr2(conditionTable)
    local conditions = {}
    for index, value in ipairs(conditionTable) do
        if type(value) == "table" then
            local str = concatStr2(value)
            if str ~= nil then
                table.insert(conditions, str)
            end
        elseif type(value) == "string" then
            -- if value == " or " or value == " and " then
            --     table.insert(conditions, #conditions, value)
            -- else
            table.insert(conditions, value)
            -- end
        end
    end
    if #conditions == 0 then
        return nil
    elseif #conditions == 1 then
        return conditions[1]
    else
        return table.concat(conditions)
    end
end

local function ParseConditionStr(str)
    if not str or str == "" then
        return nil
    end
    local conditions = {}
    local idx = 0
    while 1 do
        idx = idx + 1
        if str == "" or idx > 100 then
            break
        end
        local condition = nil
        local len = string.len(str)
        local andIdx = sfind(str, "&")
        local orIdx = sfind(str, "|")
        local fchar = string.sub(str, 0, 1)
        if fchar == "(" then
            local rightBracketIdx = compareBracket(str)
            if not rightBracketIdx then
                rightBracketIdx = string.len(str)
                print(">>Bracket compare error:", str)
                break
            end
            condition = ParseConditionStr(string.sub(str, 2, rightBracketIdx - 1))
            -- if andIdx ~= nil and andIdx == rightBracketIdx + 1 then
            --     table.insert(condition, #condition + 1, " and ")
            -- elseif orIdx ~= nil and orIdx == rightBracketIdx + 1 then
            --     table.insert(condition, #condition + 1, " or ")
            -- -- elseif  then
            -- end
            conditions[idx] = condition
            local fchar = string.sub(str, rightBracketIdx + 1, rightBracketIdx + 1)
            str = string.sub(str, rightBracketIdx + 1)
            andIdx = sfind(fchar, "&")
            orIdx = sfind(fchar, "|")
        else
            local splitIdx = math.min(andIdx or len + 1, orIdx or len + 1)
            andIdx = andIdx or len
            orIdx = orIdx or len
            local conditionStr = string.sub(str, 1, splitIdx - 1)
            local addIdx = sfind(conditionStr, "+")
            local reduceIdx = sfind(conditionStr, "-")
            -- print("idx", addIdx, reduceIdx, len, str, conditionStr)
            condition = parseConditionOne(conditionStr)
            if addIdx or reduceIdx then
                local splitCondition = splitCondition(conditionStr)
                if splitCondition then
                    condition = concatStr2(splitCondition)
                end
            end
            if condition ~= "" and condition ~= " " then
                condition = sformat("(%s)", condition)
            end
            
            if andIdx < orIdx then
                condition = sformat("%s and ", condition)
            elseif andIdx > orIdx then
                condition = sformat("%s or ", condition)
            end
            conditions[idx] = condition
            str = string.sub(str, splitIdx + 1)
        end
    end

    if #conditions == 0 then
        return nil
    end

    return conditions
end

local function parseCondition(conditions)
    local conditionTable = ParseConditionStr(conditions)
    return concatStr(conditionTable)
end

local function calcNoticeTable(str)
    local t = {}
    local i = 1
    -- 暂判断服务端变量、后续有需要再补
    if string.find(str, "%<U%d+") or string.find(str, "%<T%d+") or string.find(str, "%<J%d+") or string.find(str, "%<Z%d+")
        or string.find(str, "%<G%d+") or string.find(str, "%<A%d+") or string.find(str, "%<B%d+")
        or string.find(str, "%<HUMAN") or string.find(str, "%<GLOBAL")
        or string.find(str, "%<GUILD") or string.find(str, "%<NATION")
        or string.find(str, "%<N%$") or string.find(str, "%<S%$") or string.find(str, "%{%d+%}") then
        t[i] = LUA_EVENT_CHECK_SERVER_VALUE_CHANGE
        i=i+1
    end
    if string.find(str, "%<LEVEL") then
        t[i] = LUA_EVENT_LEVEL_CHANGE
        i = i + 1
    end
    if string.find(str, "%<H.LEVEL") then
        t[i] = LUA_EVENT_HERO_LEVEL_CHANGE
        i = i + 1
    end
    if string.find(str, "%<RELEVEL") then
        t[i] = LUA_EVENT_REINLEVEL_CHANGE
        i = i + 1
    end
    if string.find(str, "%<HP") or string.find(str, "%<MP") or string.find(str, "%<MAXHP") or string.find(str, "%<MAXMP") then
        t[i] = LUA_EVENT_HPMP_CHANGE
        i = i + 1
    end
    if string.find(str, "%<H.HP") or string.find(str, "%<H.MP") or string.find(str, "%<H.MAXHP") or string.find(str, "%<H.MAXMP") then
        t[i] = LUA_EVENT_HERO_HPMP_CHANGE
        i = i + 1
    end
    if string.find(str, "%<EXP") or string.find(str, "%<MAXEXP") then
        t[i] = LUA_EVENT_EXP_CHANGE
        i = i + 1
    end
    if string.find(str, "%<H.EXP") or string.find(str, "%<H.MAXEXP") then
        t[i] = LUA_EVENT_HERO_EXP_CHANGE
        i = i + 1
    end
    if string.find(str, "%<CUR_ABIL") or string.find(str, "%<MAX_ABIL") then
        t[i] = LUA_EVENT_ROLE_PROPERTY_CHANGE
        i = i + 1
    end
    if string.find(str, "%<ITEM") then
        t[i] = LUA_EVENT_BAG_ITEM_CHANGE
        i = i + 1
        t[i] = LUA_EVENT_QUICKUSE_DATA_OPER
        i = i + 1
        t[i] = LUA_EVENT_MONEY_CHANGE
        i = i + 1
    end
    if string.find(str, "%<MONEY") then
        t[i] = LUA_EVENT_MONEY_CHANGE
        i = i + 1
    end
    if string.find(str, "%<EQUIP") then
        t[i] = LUA_EVENT_PLAYER_EQUIP_CHANGE
        i = i + 1
    end
    if string.find(str, "%<H.EQUIP") then
        t[i] = LUA_EVENT_HERO_EQUIP_CHANGE
        i = i + 1
    end

    if string.find(str, "%<BAG") or string.find(str, "%<MAX_BAG") then
       t[i] = LUA_EVENT_BAG_ITEM_LIST_REFRESH
       i = i + 1
       t[i] = LUA_EVENT_BAG_ITEM_CHANGE
       i = i + 1
    end

    if string.find(str, "%<H.BAG") or string.find(str, "%<HERO_MAX_BAG") then
       t[i] = LUA_EVENT_HERO_BAG_ITEM_LIST_REFRESH
       i = i + 1
       t[i] = LUA_EVENT_HERO_BAG_ITEM_CHANGE
       i = i + 1
    end

    if string.find(str, "%<MAIN_ACTOR_HAS_ONE_BUFF") then
        t[i] = LUA_EVENT_MAINPLAYER_BUFF_UPDATE
        i = i + 1
    end

    return t
end

local function isJsonStr(str)
    if not str or str == "" then
        return false
    end
    local status, result = pcall(cjson.decode, str)
    return status, result
end

function ConditionProxy:ctor()
    ConditionProxy.super.ctor(self)
    self._cacheCondition = {}
    self._configCondition = {}
    self._conditionNoticeTable = {}
    self._conditionRelateTable = {}
    self._checkNoticeConIDMap = {}

    self._scheduleId = nil
    self._check = false
    self._ServerVars = {}

    self._conditions = {}

    self:LoadConfig()
end

function ConditionProxy:ClearData()
    self._cacheCondition = {}

    self._scheduleId = nil
    self._check = false
    self._ServerVars = {}

    self._conditions = {}
end

-- T10 -> T10
-- T10#转生 -> T10,转生
-- $str(T10)#转生 -> T10,转生
-- $custom(T10)#转生 -> custom(T10),转生
-- N$哈哈->N$哈哈
function ConditionProxy:ParseVar(var)
    if not var then
        return ""
    end
    local value, attr
    if sfind(var, "#") then
        local vars = SL:Split(var, "#")
        value = vars[1]
        attr = vars[2]
    else
        value = var
    end
    value = string.upper(value)
    if value then
        if sfind(value, "$STR%(.+%)") then
            value = smatch(value, "$STR%((.+)%)")
        elseif sfind(value, "%a$.+") then
            value = smatch(value, "%a$.+")
        elseif sfind(value, "$.+") then
            value = smatch(value, "$(.+)")
        end
    end
    return value, attr
end

function ConditionProxy:TransValueByKey(key)
    local k1, v1 = self:ParseVar(key)
    if self._ServerVars[k1] and v1 and self._ServerVars[k1][v1] then
        return self._ServerVars[k1][v1]
    end
    return self._ServerVars[k1] and self._ServerVars[k1].value or ""
end

function ConditionProxy:InsertNoticeCondition(noticeID, conditionId)
    self._conditionNoticeTable[noticeID] = self._conditionNoticeTable[noticeID] or {}
    self._checkNoticeConIDMap[noticeID] = self._checkNoticeConIDMap[noticeID] or {}
    if not self._checkNoticeConIDMap[noticeID][conditionId] then
        table.insert(self._conditionNoticeTable[noticeID], conditionId)
        self._checkNoticeConIDMap[noticeID][conditionId] = true
    end
end

function ConditionProxy:LoadConfig()
    SL:Print("[Require game_config] ", "cfg_condition")
    local config = SL:RequireFile("game_config/cfg_condition")
    for k, v in pairs(config) do
        local id = v.ID
        local conditionStr = v.Condition

        self._configCondition[v.ID] =
        {
            ID = id,
            Condition = conditionStr
        }

        local t = calcNoticeTable(conditionStr)
        for _, noticeID in ipairs(t) do
            self:InsertNoticeCondition(noticeID, id)
        end
        if v.tag and string.len(v.tag) > 0 then
            local tagList = SL:Split(v.tag, ",")
            for index, tag in ipairs(tagList) do
                if tag and string.len(tag) > 0 then
                    self:InsertNoticeCondition(tag, id)
                end
            end
        end
        -- 关联condition注册
        for id in string.gmatch(conditionStr, "<CONDITION,%s*(%d+)%s*>") do
            local id = tonumber(id)
            if id and id ~= v.ID then
                local list = self._conditionRelateTable[id]
                if not list then
                    list = {}
                    self._conditionRelateTable[id] = list
                end
                list[#list + 1] = v.ID
            end
        end
    end

    -- for _, t in pairs(self._conditionNoticeTable) do
    --     if #t > 0 then
    --         print("##############", _, #t)
    --     end
    -- end
end

function ConditionProxy:ReloadConfig()
    self._configCondition = {}
    self._conditionNoticeTable = {}
    self._checkNoticeConIDMap = {}
    self._conditionRelateTable = {}

    self:LoadConfig()
end

-- <LEVEL> >= 26 | <LEVEL> <= 10 $ <ITEM_COUNT,10> == 10
function ConditionProxy:LoadConditionStr(conditionStr)
    if not conditionStr or conditionStr == "" then
        return nil
    end

    --args todo
    local luaStr = sformat(
        [[
        local metaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
        if (%s) then
            return true
        else
            return false
        end
    ]], parseCondition(conditionStr))
    local successFunc = load(luaStr)
    if not successFunc then
        SL:Print(sformat("Parse Condition Error！！ %s", conditionStr))
        return nil
    end
    return successFunc
end

---$(LEVEL)
---$(ITEM_COUNT,99)
function ConditionProxy:CheckCondition(conditionStr)
    if not conditionStr or conditionStr == "" then
        return true
    end

    if not self._cacheCondition[conditionStr] then
        self._cacheCondition[conditionStr] = self:LoadConditionStr(conditionStr)
    end

    if self._cacheCondition[conditionStr] then
        return self._cacheCondition[conditionStr]()
    end

    return true
end

function ConditionProxy:CheckConditionByID(conditionID)
    conditionID = tonumber(conditionID)
    if not conditionID then
        return false
    end
    local config = self._configCondition[conditionID]
    if not config then
        return false
    end
    return self:CheckCondition(config.Condition)
end

function ConditionProxy:GetConditionTableByNoticeID(noticeID)
    return self._conditionNoticeTable[noticeID]
end

function ConditionProxy:GetRelateTableByConditionID(conditionID)
    return self._conditionRelateTable[conditionID]
end

function ConditionProxy:StartSchedule()
    if self._scheduleId then
        UnSchedule(self._scheduleId)
        self._scheduleId = nil
    end

    self._scheduleId = Schedule(function()
        if self._check then
        end
        self._check = false
    end, 1 / 60)
end

function ConditionProxy:handle_MSG_SC_REDPOINTVARCHANGE(msg)
    local jsonData = ParseRawMsgToJson(msg)
    for i, v in ipairs(jsonData) do
        local key      = v.Var

        local txtKey   = key
        local txtValue = v.Value

        local IsTable  = false

        sgsub(txtValue, "^{(.+)}$", function(s)
            local Tabs = {}
            sgsub(sgsub(sformat("%s,", s), ",,", ","), "(.-),", function(s)
                Tabs[#Tabs + 1] = string.trim(s)
            end)

            txtKey = sformat("<V_%s>", sgsub(txtKey, "%$", ""))
            txtValue = Tabs

            IsTable = true
        end)

        if not IsTable then
            sgsub(txtValue, "^%^(.+)%^$", function(s)
                local Tabs = {}
                sgsub(sgsub(sformat("%s,", s), ",,", ","), "(.-),", function(s)
                    Tabs[#Tabs + 1] = string.trim(s)
                end)

                txtKey = sformat("<T_%s>", sgsub(txtKey, "%$", ""))
                txtValue = Tabs
            end)
        end
        local var = {
            var = key, _originValue_ = v.Value
        }
        local value = v.Value

        if string.find(value, ",") then
            local exp = G_GetSplitArray(value, ",")
            for i, v in ipairs(exp) do
                local property, res = string.match(v, "(.+)%s-=%s-(.+)")
                if property and res then
                    var[property] = tonumber(res) or res
                end
            end
        else
            var.value = tonumber(value) or value
            if string.find(value, "=") then
                local property, res = string.match(value, "(.+)%s-=%s-(.+)")
                if property and res then
                    var[property] = tonumber(res) or res
                end
            end
        end

        -- 解析后的值
        self._ServerVars[key] = var
        self._conditions[key] = tonumber(v.Value) or v.Value

        -- json数据转化为table
        if IsTable and isJsonStr(v.Value) then
            self._conditions[key] = SL:JsonDecode(v.Value)
        end

        SL:onLUAEvent(LUA_EVENT_SERVER_VALUE_CHANGE, { key = key, value = v.Value })

        self._check = true
    end
    global.Facade:sendNotification(global.NoticeTable.Server_Var_Change)
    SLBridge:onLUAEvent(LUA_EVENT_CHECK_SERVER_VALUE_CHANGE)

end

function ConditionProxy:getOriginValueByKey(key)
    return self._ServerVars[key] and self._ServerVars[key]._originValue_ or ""
end

function ConditionProxy:getConditionValueByKey(key)
    -- json数据
    if string.find(key, "%:") then
        local data = string.split(key, ":")
        local key = table.remove(data, 1)
        local value = self._conditions[key]
        local val = nil
        if value and type(value) == "table" then
            for i = 1, #data do
                local k = data[i]
                if k ~= "" then
                    if not val then
                        val = value[k]
                    else
                        val = val[k]
                    end
                end
            end
            return val or ""
        end
    end

    if string.find(key, "#") then
        local data = G_GetSplitArray(key, "#")
        local value = self._conditions[data[1]]
        local valueList = G_GetSplitArray(value, ",")
        for k, v in ipairs(valueList) do
            local val = G_GetSplitArray(v, "=")
            if val[1] == data[2] then
                if tonumber(val[2]) then
                    return tonumber(val[2])
                end
                return val[2]
            end
        end
    else
        if tonumber(self._conditions[key]) then
            return tonumber(self._conditions[key])
        end
        return self._conditions[key]
    end
end

function ConditionProxy:RegisterMsgHandler()
    local msgType = global.MsgType
    LuaRegisterMsgHandler(msgType.MSG_SC_REDPOINTVARCHANGE, handler(self, self.handle_MSG_SC_REDPOINTVARCHANGE)) -- 变量变动
end

function ConditionProxy:StartCheck()
    -- self._check = true
end

return ConditionProxy
