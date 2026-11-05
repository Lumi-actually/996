local RemoteProxy = requireProxy("RemoteProxy")
local RedDotProxy = class("RedDotProxy", RemoteProxy)
RedDotProxy.NAME = global.ProxyTable.RedDotProxy

function RedDotProxy:ctor()
    RedDotProxy.super.ctor(self)
    self:Init()

    self._bagReds = {}
end

function RedDotProxy:onRegister()
    RedDotProxy.super.onRegister(self)
end

function RedDotProxy:Init()
    self.m_data = {}
    Schedule(function()
        if #self.m_data>0 then
            local data = table.remove(self.m_data,1)
            UIOperator:RefreshRedDot(data)
        end
    end,0)
end

function RedDotProxy:GetBagRedDot()
    return self._bagReds
end

function RedDotProxy:SetBagRedDotByData(data)
    if not data or not next(data) then
        return
    end
    if data.mainId and data.mainId == 1 and data.uiId then  -- 
        if data.add and data.add == 1 then
            self._bagReds[data.uiId] = data
        elseif data.add and data.add == 0 then
            self._bagReds[data.uiId] = nil
        end
    end
end

function RedDotProxy:DeleteBagRedDot(makeIndex)
    if not makeIndex then
        return
    end
    self._bagReds[makeIndex] = nil
end

function RedDotProxy:handle_MSG_SC_REDDOT_TIPS(msg)
    local msgLen = msg:GetDataLength()

    local msgHdr = msg:GetHeader()
    local str = ""
    -- dump(str,"handle_MSG_SC_REDDOT_TIPS___")
    -- dump(msgHdr,"msgHdr_____")
    if msgLen ~= 0 then
        str = msg:GetBodyStr()
    end
    local data
    local strs = G_GetSplitArray(str,",")
    local mainId = tonumber(strs[1])
    local uiId = strs[2]
    if msgHdr.recog == 0 then--增加
        local x = tonumber(strs[3])
        local y = tonumber(strs[4])
        local mode = tonumber(strs[5])
        local res = strs[6] 
        data = {add = 1, mainId = mainId, uiId = uiId, x = x, y = y, mode = mode, res = res}
        if mainId and mainId == 1 and uiId then  -- 
            self._bagReds[uiId] = data
        end
    else--删除
        data = {add = 0, mainId = mainId, uiId = uiId}
        self._bagReds[uiId] = nil
    end
    table.insert(self.m_data,data)
end

function RedDotProxy:RegisterMsgHandler()
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_REDDOT_TIPS, handler(self, self.handle_MSG_SC_REDDOT_TIPS))         -- 收到消息
end

return RedDotProxy
