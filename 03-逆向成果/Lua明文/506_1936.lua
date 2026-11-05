local RemoteProxy = requireProxy("RemoteProxy")

local FuncDockProxy = class("FuncDockProxy", RemoteProxy)
FuncDockProxy.NAME = global.ProxyTable.FuncDockProxy
local cjson = require("cjson")

function FuncDockProxy:ctor()
    FuncDockProxy.super.ctor(self)
    SL:Require("GUIData/FuncDockData", true)
    if FuncDockData.Init then 
        FuncDockData.Init()
    end
end

function FuncDockProxy:RequestPermit(data)
    local jsonData = cjson.encode({Setup = data})
    LuaSendMsg(global.MsgType.MSG_CS_PERMIT_REQUEST, 0, 0, 0, 0, jsonData)
end

function FuncDockProxy:RequestLookStatus(uid, isHero)
    LuaSendMsg(global.MsgType.MSG_SC_LOOK_STATUS_REQUEST, uid, isHero and 1 or 0, 0, 0)
end

function FuncDockProxy:handle_MSG_SC_LOOK_STATUS_RESPONSE(msg)
    local uid = msg:GetP0Str()
    local group = msg:GetP1()
    local isOnline = msg:GetP2()
    local guild = msg:GetBodyStr()
    releasePrint("handle_MSG_SC_LOOK_STATUS_RESPONSE", uid, group, isOnline, guild)

    local data = {
        UserID = uid,
        group = group,
        guild = guild,
        isOnline = isOnline ~= -1
    }

    SLBridge:onLUAEvent(LUA_EVENT_FUNC_DOCK_LOOK_PLAYER_INFO, data)
end

function FuncDockProxy:handle_MSG_SC_PERMIT_REPONSE(msg)
    local jsonData = msg:GetJsonData()
    if jsonData and jsonData.Setup then
        SLBridge:onLUAEvent(LUA_EVENT_FUNC_DOCK_OPTION_CHANGE, jsonData.Setup)
    end
end
---------------------------------------------------------------------------------------------------
function FuncDockProxy:RegisterMsgHandler()
    FuncDockProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_LOOK_STATUS_RESPONSE, handler(self, self.handle_MSG_SC_LOOK_STATUS_RESPONSE))
    LuaRegisterMsgHandler(msgType.MSG_SC_PERMIT_REPONSE, handler(self, self.handle_MSG_SC_PERMIT_REPONSE))
end

return FuncDockProxy
