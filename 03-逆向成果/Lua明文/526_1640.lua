local RemoteProxy = requireProxy("RemoteProxy")
local RemindUpgradeProxy = class("RemindUpgradeProxy", RemoteProxy)
RemindUpgradeProxy.NAME = global.ProxyTable.RemindUpgradeProxy

function RemindUpgradeProxy:ctor()
    RemindUpgradeProxy.super.ctor(self)
    self._btns = {}--用键值对吧 防id重复
end

function RemindUpgradeProxy:handle_MSG_SC_BESTRONG_TIPS(msg)
    local msgLen = msg:GetDataLength()
    local msgHdr = msg:GetHeader()
    local str = ""
    if msgLen ~= 0 then
        str = msg:GetBodyStr()
    end

    if msgHdr.recog == 0 then
        -- id name link
        local strs = G_GetSplitArray(str, ",")
        local id = tonumber(strs[1])
        local name = strs[2]
        local link = table.concat(strs, "," , 3, #strs)
        local data = { id = id, name = name, link = link }
        self:RefData(id, true, data)
    else
        local id = msgHdr.param1 or 0
        self:RefData(id, false)
    end
end

--data {id = id,name = name,link = link} 
function RemindUpgradeProxy:RefData(id, status, data)
    if status then
        self._btns[id] = data
    else
        if self._btns[id] then
            self._btns[id] = nil
        end
    end
    SL:onLUAEvent(LUA_EVENT_BESTRONG_BUTTON_REFRESH)
end

function RemindUpgradeProxy:GetButtonData()
    return self._btns
end

function RemindUpgradeProxy:RegisterMsgHandler()
    RemindUpgradeProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(global.MsgType.MSG_SC_BESTRONG_TIPS, handler(self, self.handle_MSG_SC_BESTRONG_TIPS))
end

return RemindUpgradeProxy