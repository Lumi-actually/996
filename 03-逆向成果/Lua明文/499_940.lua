local RemoteProxy = requireProxy("RemoteProxy")
local GuideProxy = class("GuideProxy", RemoteProxy)
GuideProxy.NAME = global.ProxyTable.GuideProxy


function GuideProxy:ctor()
    GuideProxy.super.ctor(self)
end

function GuideProxy:RegisterMsgHandler()
    GuideProxy.super.RegisterMsgHandler(self)

    local msgType = global.MsgType

    LuaRegisterMsgHandler(global.MsgType.MSG_SC_GUIDE_TIPS, handler(self, self.handle_MSG_SC_GUIDE_TIPS))
end

function GuideProxy:handle_MSG_SC_GUIDE_TIPS(msg)
    local msgLen = msg:GetDataLength()
    if msgLen < 1 then return end
    local msgHdr = msg:GetHeader()
    local str = msg:GetBodyStr()
    local strs = G_GetSplitArray(str, ",")
    --主窗口ID 控件ID 描述
    local mainId = strs[1] or 0
    local uiId = strs[2] or 0
    local desc = strs[3] or ""

    UIOperator:OpenGuideUI({mainId = mainId, uiId = uiId, guideDesc = desc})
end

return GuideProxy