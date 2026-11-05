local RemoteProxy = requireProxy("RemoteProxy")
local CodeDOMUIProxy  = class("CodeDOMUIProxy", RemoteProxy)
CodeDOMUIProxy.NAME   = global.ProxyTable.CodeDOMUIProxy

local cjson = require("cjson")

function CodeDOMUIProxy:ctor()
    CodeDOMUIProxy.super.ctor(self)

    self._txtUIData = {}
    self._txtWinConfig = {}
end

function CodeDOMUIProxy:InitTXTUI(GUINetworkUtil)
    GUINetworkUtil:RegisterNetworkHandler(8888, function (msgID, msgData) self:OpenGUIUI(msgData, true) end)

    SL:RegisterLUAEvent(LUA_EVENT_CLOSEWIN, "CodeDOMUI_TXT", function(ID) self:Hander_CloseWin(ID) end)
end

function CodeDOMUIProxy:Hander_CloseWin(ID)
    if ID and self._txtUIData[tostring(ID)] then
        self._txtUIData[tostring(ID)] = nil
    end
end

function CodeDOMUIProxy:GetSplitList(data)
    local addTab = {}
    for k, v in pairs(data) do
        if type(v) == "string" and k ~= "GUI_ID" and k ~= "exportID" and k ~= "close" then 
            if string.find(v, "|") then
                local tab1 = {}
                tab1 = string.split(v, "|")
                addTab[k.."|tab_temp"] = tab1
                for k2, v2 in pairs(tab1) do
                    if string.find(v2, "#") then
                        tab1[k2] = string.split(v2, "#")
                        for k3, v3 in pairs(tab1[k2]) do
                            if string.find(v3, "&") then
                                tab1[k2][k3] = string.split(v3, "&")
                            end
                        end
                    end
                end
            end
        end
    end
    for k, v in pairs(addTab) do
        data[k] = v
    end
end

function CodeDOMUIProxy:OpenGUIUI(data, json)
    if not data then
        return false
    end

    if json then
        data = cjson.decode(data)
    end

    self:GetSplitList(data)
    dump(data)
    local GUI_ID   = data.GUI_ID
    local exportID = data.exportID
    local close    = data.close

    -- 关闭界面
    if close then
        if GUI_ID then
            return GUI:Win_CloseByID(GUI_ID)
        end
        return GUI:Win_CloseAll()
    end

    if not GUI_ID then
        return false
    end

    if not exportID then
        return false
    end

    self._curUpdateData = self._txtUIData[tostring(GUI_ID)]

    if self._GUI_ID == GUI_ID and self._exportID == exportID then
        -- 更新UI
        local window = GUI:GetWindow(nil, GUI_ID)
        if window then
            data.parent = window
            return CodeDOMMainUI.UpdateGUIUI(data)
        end
    end

    self._GUI_ID = GUI_ID
    self._exportID = exportID

    SL:RequireFile("GUILayout/CodeDOMMainUI")
    CodeDOMMainUI.OpenGUIUI(data)
end

return CodeDOMUIProxy