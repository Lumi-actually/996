local DebugMediator = requireMediator("DebugMediator")
local MetaValueMediator = class("MetaValueMediator", DebugMediator)
MetaValueMediator.NAME = "MetaValueMediator"

function MetaValueMediator:ctor()
    MetaValueMediator.super.ctor(self, self.NAME)

    self._elements  = {}
    self._attrElements = {}
    self._equipElements = {}

    self._itemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)

    -- 消息响应
    local noticeTable   = global.NoticeTable
    self._observers     = 
    {
        [noticeTable.PlayerMoneyChange]   = {"MONEY"},
        [noticeTable.Bag_Oper_Data_Delay] = {"ITEMCOUNT"},
        [noticeTable.Server_Var_Change]   = {"REDKEY"},
        [noticeTable.SUISlider_Value_Change] = {"SLIDERV"},
    }

    SL:RegisterLUAEvent(LUA_EVENT_TAKE_ON_EQUIP, "MetaValueMediator", function (data)
        self:UpdateEquipShowWidget(data, false) 
    end)

    SL:RegisterLUAEvent(LUA_EVENT_TAKE_OFF_EQUIP, "MetaValueMediator", function (data)
        self:UpdateEquipShowWidget(data, false) 
    end)


    SL:RegisterLUAEvent(LUA_EVENT_HERO_TAKE_ON_EQUIP, "MetaValueMediator", function (data)
        self:UpdateEquipShowWidget(data, true) 
    end)

    SL:RegisterLUAEvent(LUA_EVENT_HERO_TAKE_OFF_EQUIP, "MetaValueMediator", function (data)
        self:UpdateEquipShowWidget(data, true) 
    end)

    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_CHANGE, "MetaValueMediator", function(data)
        self:HandleEquipDataChange(data, false)
    end)

    SL:RegisterLUAEvent(LUA_EVENT_HERO_EQUIP_CHANGE, "MetaValueMediator", function(data)
        self:HandleEquipDataChange(data, true)
    end)
end

function MetaValueMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return 
    {
        noticeTable.SUIMetaWidgetAdd,
        noticeTable.CustomAttrWidgetAdd,
        noticeTable.AutoEquipShowWidgetAdd,
        noticeTable.PlayerMoneyChange,
        noticeTable.Bag_Oper_Data_Delay,
        noticeTable.PlayerPropertyChange,
        noticeTable.Server_Var_Change,
        noticeTable.SUISlider_Value_Change,
    }
end

function MetaValueMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()

    if noticeTable.SUIMetaWidgetAdd == noticeID then
        self:OnSUIMetaWidgetAdd(data)
    elseif noticeTable.CustomAttrWidgetAdd == noticeID then
        self:OnCustomAttrWidgetAdd(data)
        return 
    elseif noticeTable.AutoEquipShowWidgetAdd == noticeID then
        self:OnAutoEquipShowWidgetAdd(data)
        return
    end

    self:OnObserverEvent(noticeID, data)
end

function MetaValueMediator:OnSUIMetaWidgetAdd(data)
    local widget = data and data.widget
    if not widget then
        return false
    end
    self._elements[widget] = data

    -- 监听事件;
    widget:registerScriptHandler(function(state)
        if state == "exit" then
            self._elements[widget] = nil
        end
    end)

    self:loadAllWidget()
end

function MetaValueMediator:OnObserverEvent(noticeID, data)
    if noticeID ~= global.NoticeTable.PlayerPropertyChange and not self._observers[noticeID] then
        return nil
    end

    self:loadAllWidget()
    self:loadAttrWidgetUpdate()
end

function MetaValueMediator:loadAllWidget()
    local MetaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
    for _, element in pairs(self._elements) do
        local value = ""
        for _, v in ipairs(element.metaValue) do
            if type(v) == "table" then
                value = value .. (MetaValueProxy:GetValueByKey(v.key, v.param) or "")
            else
                value = value .. v
            end
        end

        local value2 = ""
        if element.metaValue2 then
            for _, v in ipairs(element.metaValue2) do
                if type(v) == "table" then
                    value2 = value2 .. (MetaValueProxy:GetValueByKey(v.key, v.param) or "")
                else
                    value2 = value2 .. v
                end
            end
        end

        if element.simplenum and element.simplenum == 1 then
            if value and tonumber(value) then
                value = SL:GetSimpleNumber(tonumber(value))
            end
        end

        if not tolua.isnull(element.lifewidget) then
            local classname = tolua.type(element.lifewidget)
            if classname == "ccui.Text" then
                element.widget:setString(value)
                
            elseif classname == "ccui.Button" then
                element.widget:setTitleText(value)
                
            elseif classname == "ccui.TextAtlas" then
                element.widget:setString(value)

            elseif classname == "ccui.LoadingBar" then
                local min = tonumber(value) or 100
                local max = tonumber(value2) or 100
                local percent = max == 0 and 0 or math.floor( min/max * 100)
                element.widget:setPercent(percent)
            end
        end
    end
end

function MetaValueMediator:OnCustomAttrWidgetAdd( data )
    local widget = data and data.widget
    if not widget then
        return false
    end
    self._attrElements[widget] = data

    -- 监听事件;
    widget:registerScriptHandler(function(state)
        if state == "exit" then
            self._attrElements[widget] = nil
        end
    end)

    self:loadAttrWidgetUpdate()
end

function MetaValueMediator:loadAttrWidgetUpdate( ... )
    local MetaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
    for _, element in pairs(self._attrElements) do
        local value = ""
        if element.metaValue then
            value = MetaValueProxy:MetaValueFormat(element.metaValue)
        end

        if element.simplenum and element.simplenum == 1 then
            if value and tonumber(value) then
                value = SL:GetSimpleNumber(tonumber(value))
            end
        end

        if not tolua.isnull(element.widget) then
            local classname = tolua.type(element.widget)
            if classname == "ccui.Text" then
                element.widget:setString(value)
            elseif classname == "ccui.TextAtlas" then
                element.widget:setString(value)
                element.widget._stringValue = value
            end
        end
    end
end

-----------------------
function MetaValueMediator:OnAutoEquipShowWidgetAdd(data)
    local widget = data and data.widget
    if not widget or not widget._EQUIP_POS then
        return false
    end

    local key = string.format("%s_%s", widget._isHero and "Hero" or "Player", widget._EQUIP_POS)
    if not self._equipElements[key] then
        self._equipElements[key] = {}
    end
    self._equipElements[key][widget] = widget

    -- 监听事件;
    widget:registerScriptHandler(function(state)
        if state == "exit" then
            if self._equipElements[key] then
                self._equipElements[key][widget] = nil
            end
        end
    end)

    self:loadEquipWidgetShow(widget)
end

function MetaValueMediator:loadEquipWidgetShow(widget)
    if not tolua.isnull(widget) then
        local pos = widget._EQUIP_POS
        local isHero = widget._isHero
        self:UpdateEquipItem(widget, pos, isHero)
    end
end

function MetaValueMediator:UpdateEquipShowWidget(data, isHero)
    if not data or not data.isSuccess or not data.pos then
        return
    end
    local pos = data.pos
    local key = string.format("%s_%s", isHero and "Hero" or "Player", pos)
    if not self._equipElements[key] or not next(self._equipElements[key]) then
        return
    end
    for _, widget in pairs(self._equipElements[key]) do
        if widget._EQUIP_POS and widget._EQUIP_POS == pos and not tolua.isnull(widget) then
            self:UpdateEquipItem(widget, pos, isHero)
        end
    end
end

function MetaValueMediator:UpdateEquipItem(widget, pos, isHero)
    widget:removeAllChildren()
    local equipData = nil
    if isHero then
        equipData = SL:GetValue("H.EQUIP_DATA", pos)
    else
        equipData = SL:GetValue("EQUIP_DATA", pos)
    end
    if equipData then
        local size      = widget:getContentSize()
        local info      = widget._param or {}
        info.index      = equipData.Index
        info.itemData   = equipData
        info.from       = isHero and GUIDefine.ItemFrom.HERO_EQUIP or GUIDefine.ItemFrom.PLAYER_EQUIP
        if (widget._param and widget._param.showModelEffect) == nil then
            info.showModelEffect = true
        end
        local item      = GoodsItem:create(info)
        item:setPosition(cc.p(size.width / 2, size.height / 2))
        widget:addChild(item)

        if info.doubleTakeOff then
            if not (info.look) then
                item:AddLookItemInfoEvent(nil, 2)
            end
            if not global.isWinPlayMode then
                item:AddDoubleEventListener(function()
                    local takeOffEquipData = {
                        itemData = equipData,
                        pos = equipData.Where
                    }
                    if isHero then
                        self._itemMoveProxy:TakeOffEquip_Hero(takeOffEquipData)
                    else
                        self._itemMoveProxy:TakeOffEquip(takeOffEquipData)
                    end
                end)
            else
                item:SetItemTouchSwallow(false)
            end
        end

        if global.isWinPlayMode and info.rightTakeOff then
            global.mouseEventController:registerMouseButtonEvent(item, {down_r = function()
                UIOperator:CloseItemTips()
                local takeOffEquipData = {
                    itemData = equipData,
                    pos = equipData.Where
                }
                if isHero then
                    self._itemMoveProxy:TakeOffEquip_Hero(takeOffEquipData)
                else
                    self._itemMoveProxy:TakeOffEquip(takeOffEquipData)
                end
            end,
            checkIsVisible = true})
        end
    end
end

local shareT = {}
function MetaValueMediator:HandleEquipDataChange(data, isHero)
    if not data or data.opera ~= GUIDefine.OperateType.CHANGE then
        return
    end
    shareT.pos = data.Where
    shareT.isSuccess = true
    self:UpdateEquipShowWidget(shareT, isHero)
end

return MetaValueMediator
