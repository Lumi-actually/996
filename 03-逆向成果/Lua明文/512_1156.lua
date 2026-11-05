local RemoteProxy = requireProxy("RemoteProxy")
local AutoUseItemProxy = class("AutoUseItemProxy", RemoteProxy)
AutoUseItemProxy.NAME = global.ProxyTable.AutoUseItemProxy

require("GUIData/AutoUseItemData")

function AutoUseItemProxy:ctor()
    AutoUseItemProxy.super.ctor(self)
    if AutoUseItemData.Init then 
        AutoUseItemData.Init()
    end
end

function AutoUseItemProxy:onRegister()
    AutoUseItemProxy.super.onRegister(self)
end

-- 服务端通知不显示自动穿戴的消息
function AutoUseItemProxy:handle_MSG_SC_NOT_AUTO_TIPS_EQUIPS(msg)
    local header = msg:GetHeader()
    local result = header.recog
    local reason = header.param1

    local len = msg:GetDataLength()
    if len < 1 then
        return false
    end
    AutoUseItemData.handle_MSG_SC_NOT_AUTO_TIPS_EQUIPS({result = result, reason = reason, value = msg:GetBodyStr()})
end

function AutoUseItemProxy:RegisterMsgHandler()
    AutoUseItemProxy.super.RegisterMsgHandler(self)
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NOT_AUTO_TIPS_EQUIPS, handler(self, self.handle_MSG_SC_NOT_AUTO_TIPS_EQUIPS))
end

return AutoUseItemProxy