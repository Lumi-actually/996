local RemoteProxy   = requireProxy("RemoteProxy")
local TitleProxy = class("TitleProxy", RemoteProxy)
TitleProxy.NAME  = global.ProxyTable.TitleProxy

-- 获取称号列表
local Msg_TitleList = {
    [GUIDefine.TitleType.PLAYER] = global.MsgType.MSG_CS_TITLE_REQUEST,
    [GUIDefine.TitleType.HERO]   = global.MsgType.MSG_CS_TITLE_REQUEST_HERO
}

require("GUIData/TitleData")

function TitleProxy:ctor()
    TitleProxy.super.ctor(self)

    if TitleData.Init then 
        TitleData.Init()
    end
end

function TitleProxy:onRegister()
    TitleProxy.super.onRegister(self)
end

------------------------------------------------请求消息--------------------------------------------------------------
-- 获取称号列表
function TitleProxy:ResquestTitleList(type)
    LuaSendMsg(Msg_TitleList[type], 1)
end

-- 激活称号
function TitleProxy:ResquestActivateTitle(type, id)
    LuaSendMsg(Msg_TitleList[type], 4, id)
end

-- 卸下称号
function TitleProxy:ResquestDisboardTitle(type)
    LuaSendMsg(Msg_TitleList[type], 5)
end
----------------------------------------------------------------------------------------------------------------------

function TitleProxy:handle_MSG_SC_TITLE_REPONSE(netPkg)
    local header   = netPkg:GetHeader()
    local jsonData = ParseRawMsgToJson(netPkg)
    TitleData.handle_MSG_SC_TITLE_REPONSE( header, jsonData, GUIDefine.TitleType.PLAYER)
end

function TitleProxy:handle_MSG_SC_TITLE_REPONSE_HERO(netPkg)
    local header   = netPkg:GetHeader()
    local jsonData = ParseRawMsgToJson(netPkg)
    TitleData.handle_MSG_SC_TITLE_REPONSE( header, jsonData, GUIDefine.TitleType.HERO)
end

function TitleProxy:RegisterMsgHandler()
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_TITLE_REPONSE,      handler(self, self.handle_MSG_SC_TITLE_REPONSE))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_TITLE_REPONSE_HERO, handler(self, self.handle_MSG_SC_TITLE_REPONSE_HERO))
    TitleProxy.super.RegisterMsgHandler(self)
end

return TitleProxy
