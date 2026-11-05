local BaseUIMediator = requireMediator("BaseUIMediator")
local NoticeMediator = class("NoticeMediator", BaseUIMediator)
NoticeMediator.NAME = "NoticeMediator"

local sformat = string.format

function NoticeMediator:ctor()
    NoticeMediator.super.ctor(self)

    self._typeEffects = {{}, {}, {}}
end

function NoticeMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_Notice_Open,
        noticeTable.Layer_Notice_Close,
        noticeTable.Layer_Notice_AddChild,
        noticeTable.Layer_Notice_RemoveChild,
        noticeTable.SystemTips,
        noticeTable.ShowServerNotice,
        noticeTable.ShowSystemNotice,
        noticeTable.ShowTimerNotice,
        noticeTable.DeleteTimerNotice,
        noticeTable.UserInputEventNotice,
        noticeTable.ShowCostItem,
        noticeTable.ShowGetBagItem,
        noticeTable.ShowCostItem_Hero,
        noticeTable.ShowGetBagItem_Hero,
        noticeTable.ShowSystemNoticeXY,
        noticeTable.ServerNoticeEvent,
        noticeTable.Layer_Main_Init,
        noticeTable.ShowSystemNoticeScale,
        noticeTable.ShowPlayerEXPNotice,
        noticeTable.ShowTimerNoticeXY,
        noticeTable.DeleteTimerNoticeXY,
        noticeTable.ShowItemDropNotice
    }
end

function NoticeMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local id = notification:getName()
    local data = notification:getBody()

    if noticeTable.Layer_Notice_Open == id then
        self:OnOpen()
    elseif noticeTable.Layer_Notice_Close == id then
        self:OnClose(data)
    elseif noticeTable.Layer_Notice_AddChild == id then
        self:OnAddChild(data)
    elseif noticeTable.Layer_Notice_RemoveChild == id then
        self:OnRemoveChild(data)
    elseif noticeTable.ShowServerNotice == id then
        self:OnShowServerNotice(data)
    elseif noticeTable.ShowSystemNotice == id then
        self:OnShowSystemNotice(data)
    elseif noticeTable.SystemTips == id then
        self:OnSystemTips(data)
    elseif noticeTable.ShowTimerNotice == id then
        self:OnShowTimerNotice(data)
    elseif noticeTable.DeleteTimerNotice == id then
        self:OnDeleteTimerNotice(data)
    elseif noticeTable.UserInputEventNotice == id then
        self:onUserInputEventNotice()
    elseif noticeTable.ShowGetBagItem == id then
        self:OnShowGetBagItem(data)
    elseif noticeTable.ShowGetBagItem_Hero == id then
        self:OnShowGetBagItem_Hero(data)
    elseif noticeTable.ShowCostItem == id then
        self:OnShowCostBagItem(data)
    elseif noticeTable.ShowCostItem_Hero == id then
        self:OnShowCostBagItem_Hero(data)
    elseif noticeTable.ShowSystemNoticeXY == id then
        self:OnShowSystemNoticeXY(data)
    elseif noticeTable.ServerNoticeEvent == id then
        self:OnServerNoticeEvent(data)
    elseif noticeTable.ShowPlayerEXPNotice == id then
        self:OnShowPlayerEXPNoticeXY(data)
    elseif noticeTable.ShowSystemNoticeScale == id then
        self:OnShowSystemNoticeScale(data)
    elseif noticeTable.ShowTimerNoticeXY == id then
        self:OnShowTimerNoticeXY(data)
    elseif noticeTable.DeleteTimerNoticeXY == id then
        self:OnDeleteTimerNoticeXY(data)
    elseif noticeTable.ShowItemDropNotice == id then
        self:OnShowItemDropNoticeXY(data)
    end
end

function NoticeMediator:OnOpen()
    if not self._layer then
        self._layer = requireLayerUI("message_layer/NoticeLayer").create()
        self._type = global.UIZ.UI_NOTICE

        NoticeMediator.super.OpenLayer(self)

        GUI.ATTACH_PARENT = self._layer
        GUI.ATTACH_PARENT_UITOP = self._layer
        self._layer:InitGUI()
    end
end

function NoticeMediator:OnClose(data)
    if not self._layer then
        return
    end
    self._layer:OnClose(data)
    NoticeMediator.super.CloseLayer(self)
end

function NoticeMediator:OnAddChild(data)
    SLBridge:onLUAEvent(LUA_EVENT_NOTICE_CHILD_ADD, data and data.child)
end

function NoticeMediator:OnRemoveChild(name)
    SLBridge:onLUAEvent(LUA_EVENT_NOTICE_CHILD_REMOVE, name)
end

function NoticeMediator:OnShowServerNotice(data)
    if self._layer then
        SLBridge:onLUAEvent("LUA_EVENT_NOTICE_SERVER", data)
        --self._layer:OnShowServerNotice(data)
    end
end

function NoticeMediator:OnServerNoticeEvent(data)
    if self._layer then
        SLBridge:onLUAEvent("LUA_EVENT_NOTICE_SERVER_EVENT", data)
        --self._layer:OnServerNoticeEvent(data)
    end
end

function NoticeMediator:OnShowSystemNotice(data)
    if self._layer then
        SLBridge:onLUAEvent("LUA_EVENT_NOTICE_SYSYTEM", data)
        --self._layer:OnShowSystemNotice(data)
    end
end

function NoticeMediator:OnSystemTips(data)
    if self._layer then
        SLBridge:onLUAEvent("LUA_EVENT_NOTICE_SYSYTEM_TIPS", data)
        --self._layer:AddSystemTips(data)
    end

    if _DEBUG and data == "ERROR" then
        release_print("++++++++++++++++++++++++++++++++++++++++")
        local trace = debug.traceback()
        release_print(trace)
        release_print("++++++++++++++++++++++++++++++++++++++++")
    end
end

function NoticeMediator:OnShowSystemNoticeXY(data)
    if self._layer then
        SLBridge:onLUAEvent("LUA_EVENT_NOTICE_SYSYTEM_XY", data)
        --self._layer:OnShowSystemNoticeXY(data)
    end
end

function NoticeMediator:OnShowSystemNoticeScale(data)
    if self._layer then
        SLBridge:onLUAEvent("LUA_EVENT_NOTICE_SYSYTEM_SCALE", data)
        --self._layer:OnShowSystemNoticeScale(data)
    end
end

function NoticeMediator:OnShowTimerNotice(data)
    if self._layer then
        SLBridge:onLUAEvent("LUA_EVENT_NOTICE_TIMER", data)
        --self._layer:OnShowTimerNotice(data)
    end
end

function NoticeMediator:OnDeleteTimerNotice(data)
    if self._layer then
        SLBridge:onLUAEvent("LUA_EVENT_NOTICE_DELETE_TIMER", data)
        --self._layer:OnDeleteTimerNotice(data)
    end
end

function NoticeMediator:OnShowTimerNoticeXY(data)
    if self._layer then
        SLBridge:onLUAEvent("LUA_EVENT_NOTICE_TIMER_XY", data)
        --self._layer:OnShowTimerNoticeXY(data)
    end
end

function NoticeMediator:OnDeleteTimerNoticeXY(data)
    if self._layer then
        SLBridge:onLUAEvent("LUA_EVENT_NOTICE_DELETE_TIMER_XY", data)
        --self._layer:OnDeleteTimerNoticeXY(data)
    end
end

function NoticeMediator:OnShowItemChangeTips(data)
    if self._layer then
        SLBridge:onLUAEvent(LUA_EVENT_NOTICE_ITEM_TIPS, data)
    end
end

function NoticeMediator:onUserInputEventNotice(data)
    global.Facade:sendNotification(global.NoticeTable.Layer_Notice_RemoveChild, "__MouseTips")
end

function NoticeMediator:OnShowGetBagItem(data)
    if not data or not data.name or not data.num then
        return
    end

    self:OnShowItemChangeTips({type = 1, name = data.name, num = data.num})
end
function NoticeMediator:OnShowGetBagItem_Hero(data)
    if not data or not data.name or not data.num then
        return
    end
    
    self:OnShowItemChangeTips({type = 1, name = data.name, num = data.num, isHero = true})
end

function NoticeMediator:OnShowCostBagItem(data)
    if not data or not data.name or not data.num then
        return
    end
    
    self:OnShowItemChangeTips({type = 2, name = data.name, num = data.num})
end
function NoticeMediator:OnShowCostBagItem_Hero(data)
    if not data or not data.name or not data.num then
        return
    end
    
    self:OnShowItemChangeTips({type = 2, name = data.name, num = data.num, isHero = true})
end

function NoticeMediator:OnShowPlayerEXPNoticeXY(data)
    if self._layer then
        SLBridge:onLUAEvent("LUA_EVENT_NOTICE_EXP", data)   
    end
end

function NoticeMediator:OnShowItemDropNoticeXY(data)
    if self._layer then
        SLBridge:onLUAEvent("LUA_EVENT_NOTICE_DROP", data)   
    end
end

function NoticeMediator:GetEffectsData()
    return self._typeEffects
end

return NoticeMediator
