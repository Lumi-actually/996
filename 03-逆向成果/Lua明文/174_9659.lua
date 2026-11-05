local RemoteProxy = requireProxy("RemoteProxy")
local SUIComponentProxy = class("SUIComponentProxy", RemoteProxy)
SUIComponentProxy.NAME = global.ProxyTable.SUIComponentProxy

local LexicalHelper = require("sui/LexicalHelper")

function SUIComponentProxy:ctor()
    SUIComponentProxy.super.ctor(self)

    self._data          = {}
    for _, v in pairs(global.SUIComponentTable) do
        self._data[v]   = {}
    end

    self._triggers      = {}        -- 触发响应

    -- 自添加UI Lua
    self._WidgetData          = {}
    for _, v in pairs(global.SUIComponentTable) do
        self._WidgetData[v]   = {}
    end

    -- 用于存取脚本拉杆变量数据
    self._sliderWidgets = {}

    -----------------------------------

    self:initTriggers()
end

function SUIComponentProxy:ClearData()
    self._data          = {}
    for _, v in pairs(global.SUIComponentTable) do
        self._data[v]   = {}
    end    

    -- 自添加UI Lua
    self._WidgetData          = {}
    for _, v in pairs(global.SUIComponentTable) do
        self._WidgetData[v]   = {}
    end                 
end

function SUIComponentProxy:LoadConfig()
    -- 快捷键
    SL:Print("[Require game_config] ", "cfg_KeyFunc")
    local config = SL:RequireFile("game_config/cfg_KeyFunc")
    if config then
        for _, v in ipairs(config) do
            local keyCodes = {}
            local slices   = G_GetSplitArray(v.Key, "+")
            for _, key in ipairs(slices) do
                table.insert(keyCodes, cc.KeyCode["KEY_" .. key])
            end
            local pressedCB = function()
                self:onEventKeyCode(v.ID or v.IDX)
            end
            global.userInputController:AddKeyboardListener(keyCodes, pressedCB)
        end
    end
end

function SUIComponentProxy:onEventKeyCode(id)
    print("function SUIComponentProxy:onEventKeyCode(id)", id)
    LuaSendMsg(global.MsgType.MSG_CS_KEYCODE_EVENT, id)
end

-----------------------------------------------------------------------------
-- 挂接组件
function SUIComponentProxy:updateComponent(data)
    if not data.index or not data.subid then
        return
    end
    if not self._data[data.index] then
        return 
    end

    local index         = data.index            -- ui编号
    local subid         = data.subid            -- 内容编号
    local content       = data.content          -- 内容

    -- update
    self._data[index][subid] = data

    -- update
    global.Facade:sendNotification(global.NoticeTable.SUIComponentUpdate, data)
end

function SUIComponentProxy:removeComponent(data)
    if not data.index or not data.subid then
        return
    end
    if not self._data[data.index] then
        return 
    end

    local index         = data.index            -- ui编号
    local subid         = data.subid            -- 内容编号
    local content       = data.content          -- 内容

    -- remove
    self._data[index][subid] = nil

    -- update
    global.Facade:sendNotification(global.NoticeTable.SUIComponentUpdate, data)
end

function SUIComponentProxy:loadSUIRender(index, subid, root)
    if nil == self._data[index] then
        return nil
    end
    if nil == self._data[index][subid] then
        return nil
    end

    local function linkCB(cdata)
        local tdata = clone(cdata)
        tdata.index = index
        tdata.subid = subid
        self:SubmitAct(tdata)
    end
    
    local function closeCB()
    end

    local data          = self._data[index][subid]
    local contentSize   = root:getContentSize()
    local rootRect      = cc.rect(0, 0, contentSize.width, contentSize.height)
    local elements      = LexicalHelper:Parse(data.content)
    local ext           = {isImmediate = true}
    local SUILoader     = require("sui/SUILoader").new()
    local trunk         = SUILoader:loadContent(elements, linkCB, closeCB, rootRect, ext)
    return trunk.render
end

function SUIComponentProxy:loadSUIRenderAll(index, root)
    if nil == self._data[index] then
        return nil
    end

    local data              = self._data[index]
    local renders           = {}
    for _, v in pairs(data) do
        renders[v.subid]    = self:loadSUIRender(v.index, v.subid, root)
    end
    return renders
end

function SUIComponentProxy:RespSUIDataUpdate(msg)
    local header   = msg:GetHeader()
    local jsonData = ParseRawMsgToJson(msg)

    if not jsonData then
        return nil
    end

    if header.recog == 0 then
        self:updateComponent(jsonData)

        -- print(" ++++++++++++++++++++++++ ")
        -- dump(jsonData)
        
    elseif header.recog == 1 then
        self:removeComponent(jsonData)

        -- print(" ------------------------ ")
        -- dump(jsonData)

    end
end

function SUIComponentProxy:SubmitAct(data)
    if not data.Act then
        return nil
    end

    local submitData = 
    {
        index = data.index,
        subid = data.subid,
        npcid = data.npcid,
        act   = data.Act,
        Input = data.Input,
        Slider = data.Slider,
        CheckBox = data.CheckBox,
        MenuItem = data.MenuItem,
    }
    local pattern = {string.find(data.Act, "^&(.+)")}
    if pattern and pattern[3] then
        JUMPTO(tonumber(pattern[3]))
    else
        SendTableToServer(global.MsgType.MSG_CS_SUICOMPONENT_SUBMIT, submitData)
    end
end

function SUIComponentProxy:UpdateAttachComponentByLua(data)
    if not data.index or not data.subid then
        return
    end
    if not self._WidgetData[data.index] then
        return 
    end

    local index         = data.index            -- ui编号
    local subid         = data.subid            -- 内容编号
    local content       = data.content          -- 内容
    local type          = data.type             -- 类型 

    if not type or (type and tonumber(type) == 0 )  then
        if not data.content then
            return
        end
        self._WidgetData[index][subid] = data
        self._WidgetData[index][subid].content:retain()
        
    elseif type and tonumber(type) == 1 then
        self._WidgetData[index][subid] = nil
    end

    -- update
    global.Facade:sendNotification(global.NoticeTable.GUIComponentUpdate, data)
end

function SUIComponentProxy:GetWidgetData( index , subid)
    if not index or not self._WidgetData[index] then
        return nil
    end

    if not subid then
        return self._WidgetData[index]
    else
        return self._WidgetData[index][subid]
    end
end
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- 脚本触发
function SUIComponentProxy:initTriggers()
    -- 背包满
    self._triggers[1] = {
        cValue = nil,
        isAble = false,
        notices = 
        {
            global.NoticeTable.Bag_Oper_Data_Delay
        },
        callback = function()
            return BagData.isToBeFull()
        end
    }
    -- 背包满->空
    self._triggers[2] = 
    {
        cValue = nil,
        isAble = false,
        notices = 
        {
            global.NoticeTable.Bag_Oper_Data_Delay
        },
        callback = function()
            return not BagData.isToBeFull()
        end
    }
end

function SUIComponentProxy:RespTrigger(msg)
    local header    = msg:GetHeader()
    local id        = header.recog
    local isAble    = (header.param1 == 1)
    if not self._triggers[id] then
        return
    end
    self._triggers[id].isAble = isAble

    -- 
    self:checkTrigger(id)
end

function SUIComponentProxy:checkTrigger(id)
    local trigger = self._triggers[id]
    if not trigger then
        return nil
    end
    if not trigger.isAble then
        return nil
    end
    if not trigger.callback then
        return nil
    end
    local enable = trigger.callback()
    if trigger.cValue == enable then
        return nil
    end
    trigger.cValue = enable

    -- 触发了
    if trigger.cValue then
        self:RequestNoticeTrigger(id)
    end
end

function SUIComponentProxy:checkAllTriggers(noticeID)
    for id, trigger in pairs(self._triggers) do
        for _, v in pairs(trigger.notices) do
            if noticeID == v then
                self:checkTrigger(id)
                break
            end
        end
    end
end

function SUIComponentProxy:RequestNoticeTrigger(id)
    print("-------------------SUIComponentProxy:RequestNoticeTrigger", id)
    LuaSendMsg(global.MsgType.MSG_CS_SCRIPT_TRIGGER, id)
end

-----------------------------------------------------------------------------
function SUIComponentProxy:SetSUISliderValueById(sliderid, value)
    self._sliderWidgets[sliderid] = value
end

function SUIComponentProxy:GetSUISliderValueById(sliderid)
    return self._sliderWidgets[sliderid] or 0
end

function SUIComponentProxy:ClearSUISlider()
    self._sliderWidgets = {}
end

-----------------------------------------------------------------------------
function SUIComponentProxy:RegisterMsgHandler()
    SUIComponentProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_SUICOMPONENT_UPDATE, handler(self, self.RespSUIDataUpdate))
    LuaRegisterMsgHandler(msgType.MSG_SC_SCRIPT_TRIGGER, handler(self, self.RespTrigger))
end

return SUIComponentProxy
