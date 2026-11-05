local RemoteProxy = requireProxy("RemoteProxy")
local ChatProxy = class("ChatProxy", RemoteProxy)
ChatProxy.NAME = global.ProxyTable.ChatProxy

local cjson     = require("cjson")

local sformat   = string.format
local slen      = string.len

require("GUIData/ChatData")
function ChatProxy:ctor()
    ChatProxy.super.ctor(self)

    if ChatData.Init then 
        ChatData.Init()
    end
end

function ChatProxy:onRegister()
    ChatProxy.super.onRegister(self)
end

function ChatProxy:SendMsg(data)
    if data.ChannelId then
        data.Type = data.ChannelId
    end

    if data and data.sensitiveWords and not next(data.sensitiveWords) then
        data.sensitiveWords = nil
    end

    local jsonStr = cjson.encode(data)
    if global.MMO.GAME_STATE_WORLD == GET_GAME_STATE() then
        local sendStr, sendLen = jsonStr, slen(jsonStr)
        LuaSendMsg(global.MsgType.MSG_CS_PLAYER_SAY, 0, 0, 0, 0, sendStr, sendLen)
    end
end

function ChatProxy:handle_MSG_SC_CHAT_MESSAGE(msg)
    local jsonData = msg:GetJsonData()
    -- dump(jsonData, "ChatProxy:__handle_MSG_SC_CHAT_MESSAGE__")
    if not jsonData then
        return
    end
    -- ReceiveID 私聊接收者ID ReceiveName 私聊接收者Name
    -- UserID 消息发送者ID UserName 消息发送者Name

    -- NPC名字特殊处理
    if jsonData.Npc == 1 and jsonData.UserName then
        local _, _, showName = string.find(jsonData.UserName, ".-%#(.-)%#")
        if showName then
            jsonData.UserName = showName
        end
    end

    if jsonData.Type then
        jsonData.ChannelId = jsonData.Type
    end
    if jsonData.UserID then
        jsonData.SendId = jsonData.UserID
    end
    if jsonData.UserName then
        jsonData.SendName = jsonData.UserName
    end
    if jsonData.ReceiveID then
        jsonData.ReceiveID = tonumber(jsonData.ReceiveID)
    end
    jsonData.MT = tonumber(jsonData.MT) or 0

    SLBridge:onLUAEvent(LUA_EVENT_CHAT_MSG_ADD, jsonData)
end

--自动喊话时间
function ChatProxy:handle_SC_CHAT_AUTO_DELAY(msg)
    local jsonData = msg:GetJsonData()
    if not jsonData then
        return
    end
    local sayMsgCD = tonumber(jsonData.SayMsgCD)
    if sayMsgCD and sayMsgCD > 0 then
        sayMsgCD = sayMsgCD / 1000
        SLBridge:onLUAEvent(LUA_EVENT_CHAT_AUTO_SHOUT_DELAY_TIME, sayMsgCD)
    end
end

-- 通知开关假掉落
local sharedFakeDropTab = {}
function ChatProxy:handle_MSG_SC_SWITCH_FAKE_DROP(msg)
    local recog = msg:GetP0()
    local type = msg:GetP1()
    sharedFakeDropTab.status = recog 
    sharedFakeDropTab.type = type > 0 and type or nil
    SLBridge:onLUAEvent(LUA_EVENT_CHAT_FAKE_DROP_OPEN_STATUS, sharedFakeDropTab)
end

-- 掉落消息参数
function ChatProxy:handle_MSG_SC_ITEM_DROP_MSG_NEW(msg)
    local jsonData = msg:GetJsonData()
    if not jsonData then
        return
    end

    local mapX = msg:GetP0()
    local mapY = msg:GetP1()
    local itemID = msg:GetP2()
    local dropType = msg:GetP3()
    if dropType == 0 then
        return
    end

    local param = jsonData.Params
    local playerName = param[1] or ""
    local monsterName = param[2] or ""
    local mapName = param[3] or ""
    local g_itemName = param[4] or ""

    SLBridge:onLUAEvent(LUA_EVENT_CHAT_DROP_MSG_ADD, {
        playerName = playerName,
        monsterName = monsterName,
        mapName = mapName,
        g_itemName = g_itemName,
        mapX = mapX, 
        mapY = mapY,
        itemID = itemID,
        dropType = dropType, 
        BColor = jsonData.BColor,
        FColor = jsonData.FColor
    })
end

function ChatProxy:handle_MSG_SC_FAKE_DROP_SPEED_UP(msg)
    local limitLowTimes = msg:GetP0()
    local limitHighTimes = msg:GetP1()
    SLBridge:onLUAEvent(LUA_EVENT_CHAT_FAKE_DROP_MSG_SPEED, {limitLowTimes = limitLowTimes, limitHighTimes = limitHighTimes})
end

function ChatProxy:RegisterMsgHandler()
end

--改为进入游戏世界之后再注册 有时候没进入世界就收到消息了
function ChatProxy:RegisterMsgHandlerAfterEnterWorld()
    local msgType = global.MsgType
    
    -- 收到消息
    LuaRegisterMsgHandler(msgType.MSG_SC_CHAT_MESSAGE, handler(self, self.handle_MSG_SC_CHAT_MESSAGE))
    --自动喊话时间
    LuaRegisterMsgHandler(msgType.MSG_SC_CHAT_AUTO_DELAY, handler(self, self.handle_SC_CHAT_AUTO_DELAY))
    -- 移除假掉落
    LuaRegisterMsgHandler(msgType.MSG_SC_STOP_FAKE_DROP, handler(self, self.handle_MSG_SC_SWITCH_FAKE_DROP))
    -- 物品掉落消息
    LuaRegisterMsgHandler(msgType.MSG_SC_ITEM_DROP_MSG_NEW, handler(self, self.handle_MSG_SC_ITEM_DROP_MSG_NEW))
    -- 假掉落速度改变
    LuaRegisterMsgHandler(msgType.MSG_SC_FAKE_DROP_SPEED_UP, handler(self, self.handle_MSG_SC_FAKE_DROP_SPEED_UP))
end

return ChatProxy