local DebugMediator = requireMediator("DebugMediator")
local SUIManager = class("SUIManager", DebugMediator)
SUIManager.NAME = "SUIManager"

local EventType_PutInItemBox = 1
local EventType_PutOutItemBox = 2
local EventType_UpdateItemBox = 3

function SUIManager:ctor()
    SUIManager.super.ctor(self, self.NAME)

    self._allITEMBOXWidgets     = {}
    self._ITEMBOXItems          = {}
    
    self._allGUIItemBoxWidgets  = {}
    self._GUIItemBoxItems       = {}
end

function SUIManager:destory()
    if SUIManager.instance then
        global.Facade:removeMediator( SUIManager.NAME )
        SUIManager.instance = nil
    end
end

function SUIManager:Inst()
    if not SUIManager.instance then
        SUIManager.instance = SUIManager.new()
        global.Facade:registerMediator(SUIManager.instance)
    end
    return SUIManager.instance
end

function SUIManager:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return 
    {
        noticeTable.SUIITEMBOXWidgetAdd,
        noticeTable.SUIITEMBOXPutoutAll,
        noticeTable.GUI_ITEMBOX_Widget_Add,
        noticeTable.GUI_ITEMBOX_Widget_Remove,
        noticeTable.GUI_ITEMBOX_Widget_Update,
        noticeTable.ReleaseMemory,
    }
end

function SUIManager:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()

    if noticeTable.SUIITEMBOXWidgetAdd == noticeID then
        self:OnSUIITEMBOXWidgetAdd(data)

    elseif noticeTable.SUIITEMBOXPutoutAll == noticeID then
        self:OnSUIITEMBOXPutoutAll(data)

    elseif noticeTable.GUI_ITEMBOX_Widget_Add == noticeID then
        self:OnGUIItemBoxWidgetAdd(data)

    elseif noticeTable.GUI_ITEMBOX_Widget_Remove == noticeID then
        self:OnGUIItemBoxWidgetRemove(data)

    elseif noticeTable.GUI_ITEMBOX_Widget_Update == noticeID then
        self:OnGUIItemBoxWidgetUpdate(data)

    elseif noticeTable.ReleaseMemory == noticeID then
        self:OnReleaseMemory(data)
    end
end

function SUIManager:OnReleaseMemory()
    self._ITEMBOXItems = {}
    
    self._allGUIItemBoxWidgets = {}
    self._GUIItemBoxItems = {}
end

----------------------------
function SUIManager:OnSUIITEMBOXWidgetAdd(data)
    local boxindex = data.boxindex
    local widget   = data.widget

    -- 监听事件;
    widget:registerScriptHandler( function(state)
        if state == "enter" then
            if boxindex then
                self._allITEMBOXWidgets[boxindex] = widget
                self:ReloadITEMBOXWidget(boxindex, false)
            end

        elseif state == "exit" then
            if boxindex then
                self._allITEMBOXWidgets[boxindex] = nil
            end
        end
    end )
end

function SUIManager:OnSUIITEMBOXPutoutAll()
    --
    for boxindex, itembox in pairs(self._ITEMBOXItems) do
        local npcProxy   = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
        local submitData =
        {
            index       = boxindex,
            npcid       = npcProxy:GetCurrentNPCID()
        }
        global.SUIManager:RequestITEMBOXPutout(submitData)
        
    end
end

function SUIManager:ReloadAllITEMBOXWidgets()
    for boxindex, itemboxWidget in pairs(self._allITEMBOXWidgets) do
        self:ReloadITEMBOXWidget(boxindex)
    end
end

function SUIManager:ReloadITEMBOXWidget(boxindex,notCheckHave)
    local itemboxWidget = self._allITEMBOXWidgets[boxindex]
    if nil == itemboxWidget then
        return nil
    end
    local itemData      = self._ITEMBOXItems[boxindex]
    
    local MakeIndex     = itemData and itemData.MakeIndex
    if notCheckHave==false and MakeIndex then
        itemData = BagData.GetItemDataByMakeIndex(MakeIndex)

        if not itemData then
            local ItemManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemManagerProxy)
            local itemType = ItemManagerProxy:GetItemType(itemData)
            if itemType == ItemManagerProxy.ItemType.Equip then
                itemData = EquipData.GetEquipDataByMakeIndex(MakeIndex) 
            end
        end
    end

    if nil == itemData then
        if itemboxWidget:getChildByName("item") then
            itemboxWidget:removeChildByName("item")
        end
        return nil
    end

    local contentSize = itemboxWidget:getContentSize()
    local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
    -- 
    local info = {}
    info.index      = itemData.Index
    info.itemData   = itemData
    info.movable    = true
    info.look       = true
    info.from       = GUIDefine.ItemFrom.ITEMBOX
    local goodItem  = GoodsItem:create(info)
    if itemboxWidget:getChildByName("item") then
        itemboxWidget:removeChildByName("item")
    end
    itemboxWidget:addChild(goodItem)
    goodItem:setName("item")
    goodItem:setPosition(cc.p(contentSize.width/2, contentSize.height/2))
end

function SUIManager:GetITEMBOXIndexByMakeIndex(makeindex)
    for k, v in pairs(self._ITEMBOXItems) do
        if v.MakeIndex == makeindex then
            return k
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- GUI ITEMBOX
function SUIManager:OnGUIItemBoxWidgetAdd(data)
    local boxindex = data.boxindex
    local widget   = data.widget

    -- 监听事件;
    widget:registerScriptHandler(function(state)
        if state == "enter" then
            self._allGUIItemBoxWidgets[boxindex] = widget
            self:ReloadGUIItemBoxWidget(boxindex)

        elseif state == "exit" then
            self:ReturnItemToBag(boxindex)

            self._GUIItemBoxItems[boxindex] = nil
            self:ReloadGUIItemBoxWidget(boxindex)
            self._allGUIItemBoxWidgets[boxindex] = nil

        end
    end)
end

function SUIManager:OnGUIItemBoxWidgetRemove(data)
    local boxindex = data.boxindex
    if data.backBag then
        self:ReturnItemToBag(boxindex)
    end
    local removeItemData = self._GUIItemBoxItems[boxindex]
    self._GUIItemBoxItems[boxindex] = nil

    self:OnGUIItemBoxEvent(EventType_PutOutItemBox, boxindex, removeItemData)

    self:ReloadGUIItemBoxWidget(boxindex)
end

function SUIManager:OnGUIItemBoxWidgetUpdate(data)
    
    if not data or not next(data) then
        return
    end
    local boxindex  = data.boxindex
    local itemData  = data.itemData
    local updateAttr = data.updateData
    local updateSameItem = false
    if updateAttr then
        local oriItemData = self._GUIItemBoxItems[boxindex]
        if oriItemData and oriItemData.MakeIndex then
            itemData = BagData.GetItemDataByMakeIndex(oriItemData.MakeIndex)
        end
        updateSameItem = true
    else
        self:ReturnItemToBag(boxindex)

        local removeItemData = self._GUIItemBoxItems[boxindex]
        self._GUIItemBoxItems[boxindex] = nil
        self:OnGUIItemBoxEvent(EventType_PutOutItemBox, boxindex, removeItemData)
    end

    self._GUIItemBoxItems[boxindex] = itemData
    
    if updateSameItem then
        self:OnGUIItemBoxEvent(EventType_UpdateItemBox, boxindex)
    elseif itemData then
        self:OnGUIItemBoxEvent(EventType_PutInItemBox, boxindex)
    end
    -- 
    self:ReloadGUIItemBoxWidget(boxindex)
end

function SUIManager:ReloadAllGUIItemBoxWidgets()
    for boxindex, itemboxWidget in pairs(self._allGUIItemBoxWidgets) do
        self:ReloadGUIItemBoxWidget(boxindex)
    end
end

function SUIManager:ReloadGUIItemBoxWidget(boxindex)
    local itemboxWidget = self._allGUIItemBoxWidgets[boxindex]
    if nil == itemboxWidget then
        return
    end
    local itemData = self._GUIItemBoxItems[boxindex]
    if nil == itemData then
        if itemboxWidget:getChildByName("item") then
            itemboxWidget:removeChildByName("item")
        end
        return
    end

    local contentSize = itemboxWidget:getContentSize()
    -- 
    local info      = {}
    info.index      = itemData.Index
    info.itemData   = itemData
    info.movable    = true
    info.look       = true
    info.from       = GUIDefine.ItemFrom.GUI_ITEMBOX
    local goodItem  = GoodsItem:create(info)
    if itemboxWidget:getChildByName("item") then
        itemboxWidget:removeChildByName("item")
    end
    itemboxWidget:addChild(goodItem)
    goodItem:setName("item")
    goodItem:setPosition(cc.p(contentSize.width / 2, contentSize.height / 2))
end

function SUIManager:GetGUIItemBoxIndexByMakeIndex(makeIndex)
    for k, v in pairs(self._GUIItemBoxItems) do
        if v.MakeIndex == makeIndex then
            return k
        end
    end
    return nil
end

-- 刷回背包
function SUIManager:ReturnItemToBag(boxindex, itemData)
    if not boxindex then
        return
    end
    local boxMakeIndex = self._GUIItemBoxItems[boxindex] and self._GUIItemBoxItems[boxindex].MakeIndex
    if boxMakeIndex then
        if itemData and itemData.MakeIndex == boxMakeIndex then
            return
        end
        local data = {
            storage = {
                MakeIndex = boxMakeIndex,
                state = 1
            }
        }
        SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, data)
    end
end

function SUIManager:GetItemDataByGUIItemBoxIndex(boxindex)
    if not boxindex then 
        return nil 
    end
    return self._GUIItemBoxItems[boxindex]
end

function SUIManager:OnGUIItemBoxEvent(eventType, boxindex, removeItemData)
    if not boxindex then
        return
    end
    local itemboxWidget = self._allGUIItemBoxWidgets[boxindex]
    if nil == itemboxWidget then
        return
    end
    local itemData = self._GUIItemBoxItems[boxindex]
    if itemboxWidget._event and type(itemboxWidget._event) == "function" then
        itemboxWidget._event(eventType, eventType == EventType_PutOutItemBox and removeItemData or itemData)
    end
end

---------------

function SUIManager:onRegister()
    SUIManager.super.onRegister(self)
end

function SUIManager:RegisterMsgHandlerAfterEnterWorld()
    
    local msgType = global.MsgType
    LuaRegisterMsgHandler(msgType.MSG_SC_ITEMBOX_UPDATE, handler(self, self.RespITEMBOXUpdate))
    LuaRegisterMsgHandler(msgType.MSG_SC_ITEMBOX_REMOVE, handler(self, self.RespITEMBOXRemove))
end

function SUIManager:RespITEMBOXUpdate(msg)
    local header    = msg:GetHeader()
    local boxindex  = header.recog
    local buffer    = msg:GetBodyLuaBuffer()
    local itemData  = ReadItemData(buffer)
    -- dump(header)
    -- dump(jsonData)

    self._ITEMBOXItems[boxindex] = itemData

    -- 
    self:ReloadITEMBOXWidget(boxindex)
end

function SUIManager:RespITEMBOXRemove(msg)
    local header    = msg:GetHeader()
    local boxindex  = header.recog
    self._ITEMBOXItems[boxindex] = nil

    -- dump(boxindex)
    -- 
    self:ReloadITEMBOXWidget(boxindex)
end

function SUIManager:RequestITEMBOXPutin(data)
    -- dump(data)
    SendTableToServer(global.MsgType.MSG_CS_ITEMBOX_PUTIN, data)
end

function SUIManager:RequestITEMBOXPutout(data)
    -- dump(data)
    SendTableToServer(global.MsgType.MSG_CS_ITEMBOX_PUTOUT, data)
end

return SUIManager
