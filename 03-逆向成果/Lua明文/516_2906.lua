local RemoteProxy = requireProxy("RemoteProxy")
local LookPlayerProxy = class("LookPlayerProxy", RemoteProxy)
LookPlayerProxy.NAME = global.ProxyTable.LookPlayerProxy

require("GUIData/LookPlayerData")

-- 老三端对应人物界面ID转换
local changeNewPageIDs = {
    [106]   = UIConst.LayerTable.PlayerTitle,
    [1011]  = UIConst.LayerTable.PlayerSuperEquip,
}

function LookPlayerProxy:ctor()
    LookPlayerProxy.super.ctor(self)

    if LookPlayerData.Init then 
        LookPlayerData.Init()
    end
end

function LookPlayerProxy:onRegister()
    LookPlayerProxy.super.onRegister(self)
end

function LookPlayerProxy:handle_MSG_SC_ROLE_INFO_RESPONSE(netPkg)
    local userID = netPkg:GetP0Str()
    local param1 = netPkg:GetP1() or 0
    local pageID = netPkg:GetP2()
    local buffer = netPkg:GetBodyLuaBuffer()

    local data   = {}
    data.userID    = userID
    if changeNewPageIDs[pageID] then
        pageID = changeNewPageIDs[pageID]
    end
    data.pageID    = pageID

    data.embattle  = param1 ~= 0 and {H16Bit(param1), L16Bit(param1)} or {}
    data.userName  = buffer:ReadShortString(30)
    data.userName  = SL:GBKToUTF8(data.userName)
    data.nameColor = buffer:ReadUByte()
    data.warZone   = buffer:ReadByte()

    data.sex       = buffer:ReadByte()
    data.hair      = buffer:ReadUByte()
    data.job       = buffer:ReadByte()
    data.level     = buffer:ReadInt64()
    
    data.SndaItemBoxOpened = buffer:ReadBool()
    
    data.guildName = SL:GBKToUTF8(buffer:ReadShortString(30))
    data.rank      = buffer:ReadInt()
    data.rankName  = SL:GBKToUTF8(buffer:ReadShortString(30))

    data.isHero    = buffer:ReadBool()

    data.activeTittle = buffer:ReadInt()

    local nTitle    = buffer:ReadShort()
    local nItems    = buffer:ReadShort()

    local titles = {}
    for i = 1, nTitle do
        titles[i] = {
            id = buffer:ReadInt(), time = buffer:ReadInt(), index = i
        }
    end
    data.titles = titles

    local items  = {}
    for i = 1, nItems do
        items[i] = ReadItemData(buffer)
    end
    data.items = items

    -- dump(data, "------LookPlayer Items---", 5)

    LookPlayerData.handle_MSG_SC_ROLE_INFO_RESPONSE(data)
end


-- 请求通知脚本查看uid的珍宝
function LookPlayerProxy:RequestLookZhenBao(uid)
    LuaSendMsg(global.MsgType.MSG_CS_SCRIPT_ZHENBAO, 0, 0, 0, 0, uid, string.len(uid))
end


function LookPlayerProxy:RequestPlayerData(uid)
    LuaSendMsg(global.MsgType.MSG_CS_ROLE_EQUIP_INFO_REQUEST, 0, 0, 0, 0, uid, string.len(uid))
end

function LookPlayerProxy:RegisterMsgHandler()
    LookPlayerProxy.super.RegisterMsgHandler(self)
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ROLE_INFO_RESPONSE, handler(self, self.handle_MSG_SC_ROLE_INFO_RESPONSE))       -- 预请求查看数据
end

return LookPlayerProxy