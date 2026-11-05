local RemoteProxy = requireProxy("RemoteProxy")
local MetaValueProxy = class("RemoteProxy", RemoteProxy)
MetaValueProxy.NAME = global.ProxyTable.MetaValueProxy

require("config/MetaValueGetDef")
require("config/MetaValueSetDef")

local shareTab = {}

for k, _ in pairs(MetaValueGetDef) do
    local v = string.split(k, ".") or {}
    local n = #v

    local key1 = v[1]
    local key2 = v[2]
    local key3 = v[3]

    if n == 1 then
        _G[key1] = key1
    elseif n == 2 then
        _G[key1] = _G[key1] or {}
        _G[key1][key2] = key2
    elseif n == 3 then
        _G[key1] = _G[key1] or {}
        _G[key1][key2] = _G[key1][key2] or {}
        _G[key1][key2][key3] = key3
    end
end

function MetaValueProxy:ctor()
    MetaValueProxy.super.ctor(self)

    self._cacheFunc = {}

    self._serverCustomVar = {}
end

function MetaValueProxy:ClearData()
    self._cacheFunc = {}
    self._serverCustomVar = {}
end

function MetaValueProxy:RegisterMsgHandler()
    MetaValueProxy.super.RegisterMsgHandler(self)
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_SERVER_CUSTOM_VAR, handler(self, self.handle_MSG_SC_SERVER_CUSTOM_VAR))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_SERVER_BATCH_CUSTOM_VAR, handler(self, self.handle_MSG_SC_SERVER_BATCH_CUSTOM_VAR))
end

-- 元变量替换,将本地元变量替换
function MetaValueProxy:MetaValueFormat(str)
    local source = str

    local results = {}

    while true do
        local sIdx, eIdx, oriStr,param = string.find(source, "(&<(.-)>&)")
        if not (oriStr and param) then
            break
        end
        if self._cacheFunc[oriStr] then 
            results[oriStr] = self._cacheFunc[oriStr]
        else
            -- 本地取元变量
            local tokens = G_GetSplitArray(param, "/")
            local metaKey = tokens[1]
            local successFunc = load(string.format(
            [[
                local metaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
                return metaValueProxy:GetValueByKey('%s', '%s') or ""
            ]], metaKey, tokens[2]))

            if successFunc then
                self._cacheFunc[oriStr] = successFunc
                results[oriStr] = successFunc
            end
        end

        local s1 = string.sub(source, 1, sIdx - 1)
        local s2 = string.sub(source, eIdx + 1, string.len(source))
        source = s1 .. s2
    end

    -- 本地替换一波
    for key, result in pairs(results) do
        while true do
            local sIdx, eIdx = string.find(str, key, 1, true)
            if not sIdx then
                break
            end
            str = string.sub(str, 1, sIdx - 1) .. tostring(result()) .. string.sub(str, eIdx + 1, string.len(str))
        end
    end

    return str
end

function MetaValueProxy:GetValueByKey(key, ...)
    if not key then
        return "invalid key"
    end

    -- 普通变量
    if MetaValueGetDef[key] then
        return MetaValueGetDef[key](...)
    else
        local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
        return ConditionProxy:getConditionValueByKey(key);
    end

    -- 未定义
    return "undefined"
end

function MetaValueProxy:GetConditionValueByKey(key, ...)
    if not key then
        return "invalid key"
    end

    -- 普通变量
    if MetaValueGetDef[key] then
        return MetaValueGetDef[key](...)
    else
        local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
        return ConditionProxy:getConditionValueByKey(key) or "";
    end
end

function MetaValueProxy:PrintMetaKey()
    print("---------------------------------------------")
    SL:print(" Meta Value Get begin --------------------")
    for key, func in pairs(MetaValueGetDef) do
        SL:print(" -----> " .. key)
    end
    SL:print(" Meta Value Get end ----------------------")

    -- Set
    print("")
    print("---------------------------------------------")
    SL:print(" Meta Value Set begin --------------------")
    for key, func in pairs(MetaValueSetDef) do
        SL:print(" -----> " .. key)
    end
    SL:print(" Meta Value Set end ----------------------")
end

function MetaValueProxy:PrintAllMetaValue()
    SL:print(" Meta Value Get begin --------------------")
    for key, func in pairs(MetaValueGetDef) do
        SL:print(key, " -----> ", func())
    end
    SL:print(" Meta Value Get end ----------------------")
end

function MetaValueProxy:SetValueByKey(key, ...)
    if not key then
        return "invalid key"
    end
    local func = MetaValueSetDef[key]
    if not func then
       return "undefined"
    end

    return func(...)
end

-- server custom var
-- CS 622, key = MakeIndex
-- SC 622, param1 = 道具MakeIndex  data = 属性值json格式
function MetaValueProxy:GetCustomVarByKey(key)
    return self._serverCustomVar[key]
end

-- 获取对应装备变量 key: MakeIndex, vName: 变量名
function MetaValueProxy:GetItemCustomVarByVName(key, vName)
    if not key or not vName then
        return nil
    end
    if not self._serverCustomVar[key] then
        return nil
    end

    local data = self._serverCustomVar[key].Var
    if not data or not next(data) then
        return nil
    end

    for i = 1, #data do
        local param = data[i] or {}
        if param.VName and vName == param.VName then
            if param.VType == 1 or param.VType == 3 or param.VType == 5 then
                return param.IntV
            elseif param.VType == 2 or param.VType == 4 or param.VType == 6 then
                return param.StrV
            end
        end
    end

    return nil
end

function MetaValueProxy:SetCustomVar(MakeIndex, data)
    self._serverCustomVar[MakeIndex] = data

    shareTab.MakeIndex = MakeIndex
    shareTab.data = data
    SLBridge:onLUAEvent(LUA_EVENT_ITEM_CUSTOM_ATTR, shareTab)
end

function MetaValueProxy:RequestCustomVar(key)
    if not key or key == "" then
        print("request server custom var ERR, key is empty", key)
        return
    end
    LuaSendMsg(global.MsgType.MSG_CS_SERVER_CUSTOM_VAR, 0, 0, 0, 0, key, string.len(key))
end

function MetaValueProxy:handle_MSG_SC_SERVER_CUSTOM_VAR(msg)
    local jsonData = ParseRawMsgToJson(msg) or {}
    if jsonData.ID then 
        self:SetCustomVar(jsonData.ID, jsonData)
    end
end

function MetaValueProxy:handle_MSG_SC_SERVER_BATCH_CUSTOM_VAR(msg)
    local nCount = msg:GetP1()
    if nCount < 1 then
        return false
    end

    local jsonData = msg:GetJsonData()

    for i = 1, nCount do
        if not jsonData[i] then
            releasePrint("[error] msgData server batch custom var is wrong!! ")
            return
        end
        local v = SL:JsonDecode(jsonData[i])
        if v and v.ID then
            self:SetCustomVar(v.ID, v)
        end
    end
end

return MetaValueProxy
