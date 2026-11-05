function releasePrint(...)
    if global.isGMMode then
        return
    end
    release_print(...)
end

local languageConf = {}
function loadLanguageConfig( showLanguage )
    if showLanguage and string.len( showLanguage ) then
        local path = "dev/data_config/string_language.json"
        if cc.FileUtils:getInstance():isFileExist(path) == false then
            path = "data_config/string_language.json"
        end
        if cc.FileUtils:getInstance():isFileExist(path) then
            local jsonStr  = global.FileUtilCtl:getDataFromFileEx(path)
            if jsonStr and jsonStr ~= "" then
                local cjson = require("cjson")
                local jsonData = cjson.decode(jsonStr)
                languageConf = jsonData[showLanguage] or {}
            end
        end
    end
end

function fixNewLanguageString( str )
    return languageConf[str] or str
end