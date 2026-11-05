local RemoteProxy    = requireProxy( "RemoteProxy" )
local EquipRetrieveProxy = class( "EquipRetrieveProxy", RemoteProxy )
EquipRetrieveProxy.NAME  = global.ProxyTable.EquipRetrieveProxy

function EquipRetrieveProxy:ctor()
    EquipRetrieveProxy.super.ctor( self )

    self._retrieve_list = {}
end

--获取回收的makeindex
function EquipRetrieveProxy:GetRetrieveList( )
    return self._retrieve_list or {}
end

--设置回收的makeindex
function EquipRetrieveProxy:SetRetrieveList(retrieve_str)
    self._retrieve_list = {}
    if retrieve_str then
        local parse1 = G_GetSplitArray(retrieve_str, ",")
        for i, v in ipairs(parse1) do
            if v and v ~= "" then
                local makeIndex = v
                if makeIndex then
                    self._retrieve_list[makeIndex] = makeIndex
                end
            end
        end
        return
    end
end

--回收
function EquipRetrieveProxy:handle_MSG_SC_EQUIP_RETRIEVE_RESPONSE(msg)
    local msgLen = msg:GetDataLength()
    local msgHdr = msg:GetHeader()
    local dataString = nil
    if msgLen > 0 then
        dataString = msg:GetBodyStr()
    end
    self:SetRetrieveList(dataString)

    SL:onLUAEvent(LUA_EVENT_EQUIP_RETRIEVE_STATE_CHANGE)
end

function EquipRetrieveProxy:RegisterMsgHandler( )
    EquipRetrieveProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler( msgType.MSG_SC_EQUIP_RETRIEVE_RESPONSE,handler( self, self.handle_MSG_SC_EQUIP_RETRIEVE_RESPONSE) )
end

return EquipRetrieveProxy