local DebugProxy = requireProxy("DebugProxy")
local StringTableProxy = class("StringTableProxy", DebugProxy)
StringTableProxy.NAME = global.ProxyTable.StringTableProxy

function StringTableProxy:ctor()
    self._data = {}
    self._new_str = {}
    self._language_data = {}
    StringTableProxy.super.ctor(self)
end

function StringTableProxy:GetString(key)
    local str = self._data[key]
    if nil == str then
        PrintTraceback()
        return "ERROR"
    else
        str = self._new_str[str] or str
        return self._language_data[str] or str
    end
end

function StringTableProxy:onRegister()
    self._data = requireConfig("string_table.lua")

    local showLanguage = global.L_GameEnvManager:GetEnvDataByKey("showLanguage")
    if showLanguage and string.len(showLanguage) > 0 then
        local path = "data_config/string_language.json"
        if global.FileUtilCtl:isFileExist(path) then
            local jsonStr = global.FileUtilCtl:getDataFromFileEx(path)
            if jsonStr and jsonStr ~= "" then
                local cjson = require("cjson")
                local jsonData = cjson.decode(jsonStr)
                self._language_data = jsonData[showLanguage] or {}
            end
        end
    end

    local fileName = "cfg_new_string.lua"
    if global.FileUtilCtl:isFileExist("scripts/game_config/" .. fileName) then
        local config = requireGameConfig(fileName)
        for k, v in ipairs(config or {}) do
            if v.key and v.value and v.key ~= "" and v.value ~= "" then
                self._new_str[v.key] = v.value
            end
        end
    end

    StringTableProxy.super.onRegister(self)
end

function StringTableProxy:fixNewLanguageString(str)
    if str then
        return self._language_data[str] or str
    end
end

function GET_STRING(key)
    local stProxy = global.Facade:retrieveProxy(global.ProxyTable.StringTableProxy)
    return stProxy:GetString(key)
end

return StringTableProxy
