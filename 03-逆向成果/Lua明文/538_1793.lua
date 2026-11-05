local RemoteProxy = requireProxy("RemoteProxy")
local ItemCompoundProxy = class("ItemCompoundProxy", RemoteProxy)
ItemCompoundProxy.NAME = global.ProxyTable.ItemCompoundProxy
local cjson = require("cjson")

function ItemCompoundProxy:ctor()
    ItemCompoundProxy.super.ctor(self)

    require("GUIData/CompoundItemData")
    if CompoundItemData.Init then
        CompoundItemData.Init()
    end
end

function ItemCompoundProxy:onRegister()
    ItemCompoundProxy.super.onRegister(self)
end

-- 打开不同的合成通知一下脚本
function ItemCompoundProxy:RequestCompoundChangeJson(id)
    local jsonData = 
    {
        action = "G_CompoundItem",
        ex1 = id,
    }
    local jsonStr = cjson.encode(jsonData)
    LuaSendMsg( global.MsgType.MSG_CS_JSON_PROTO_HELPER_REQUEST, 10001, 1, 0, 0, jsonStr, string.len(jsonStr))
end

function ItemCompoundProxy:RequestCompoundJson(id)
    local jsonData = 
    {
        action = "G_CompoundItem",
        ex1 = id,
    }
    local jsonStr = cjson.encode(jsonData)
    LuaSendMsg( global.MsgType.MSG_CS_JSON_PROTO_HELPER_REQUEST, 10000, 1, 0, 0, jsonStr, string.len(jsonStr))
end

function ItemCompoundProxy:handle_JSON_MESSAGE(netPkg)
    local jsonData = netPkg:GetJsonData()
    if not jsonData or not jsonData.data then
        return
    end

    local recog = jsonData.data.recog
    local id = jsonData.data.param1

    SLBridge:onLUAEvent(LUA_EVENT_COMPOUND_ITEM_RESULT, {id = id, code = recog})
end

function ItemCompoundProxy:RegisterMsgHandler()
    ItemCompoundProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    LuaRegisterMsgHandler(msgType.MSG_SC_JSON_PROTO_HELPER_RESPONSE, handler(self, self.handle_JSON_MESSAGE))
end

return ItemCompoundProxy