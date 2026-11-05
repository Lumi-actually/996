local tconcat   = table.concat
local tinsert   = table.insert

local tostring  = tostring
local pairs     = pairs
local type      = type
local next      = next

local sformat   = string.format
local sfind     = string.find
local sgsub     = string.gsub
local ssub      = string.sub
local srep      = string.rep
local slen      = string.len
local ssplit    = string.split

local expPng = string.format("%slizi.png", global.MMO.PATH_RES_PUBLIC)
local zeroP = cc.p(0, 0)

local globalSchedule = {} -- 全局函数回调

local preDevScheduleID  = nil       -- 预加载Dev文件的ScheduleID

_DEBUG = global.isDebugMode

local original_release_print = release_print
function release_print(...)
    local args = {...}
    -- 转换所有参数为字符串
    local fmtParts = {}
    -- 处理每个参数并生成格式字符串
    for i = 1, select('#', ...) do
        local arg = args[i]
        if arg == nil then
            fmtParts[#fmtParts + 1] = "nil"
        else
            fmtParts[#fmtParts + 1] = tostring(arg)
        end
    end

    -- 时间格式  时:分:秒-毫秒
    local t = os.date("*t")
    local clock = os.clock()
    local ms =  math.floor((clock - math.floor(clock)) * 1000)
    local formatTime = string.format("[%02d:%02d:%02d-%03d]", t.hour, t.min, t.sec, ms)
    original_release_print(string.format("%s %s", formatTime, table.concat(fmtParts, " ")))
end

function releasePrint(...)
    if global.isGMMode then
        return
    end
    release_print(...)
end

function Print(...)
    if _DEBUG then
        release_print(...)
    end
end
rawset(_G, "print", Print)

function PrintTableByTree(root)
    if not _DEBUG then
        return nil
    end

    if nil == root then
        release_print("nil")
        return nil
    end

    local cache = {[root] = "."}
    local function _dump(t, space, name)
        local temp = {}
        local value = ""
        local tempStr = ""
        local endPos = nil
        for k, v in pairs(t) do
            local key = tostring(k)
            if cache[v] then
                tinsert(temp, "+" .. key .. " {" .. cache[v] .. "}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
                tinsert(temp, "+" .. key .. _dump(v, space .. (next(t, k) and "|" or " ") .. srep(" ", #key), new_key))
            else
                value = tostring(v)
                if nil == value then
                    tempStr = "nil"
                else
                    endPos = sfind(value, "\0")
                    if endPos == nil then
                        tempStr = value
                    elseif endPos == 1 then
                        tempStr = ""
                    else
                        tempStr = ssub(value, 1, endPos)
                    end
                end

                tinsert(temp, "+" .. key .. " : " .. tempStr)
            end
        end
        return tconcat(temp, "\n" .. space)
    end
    release_print("Table:" .. tostring(root) .. "\n" .. _dump(root, "", ""))
end
PrintTable = PrintTableByTree

-- print call traceback
function PrintTraceback()
    local traceback = ssplit(debug.traceback("", 2), "\n")
    PrintTable(traceback)
end

function CreateExport(fileName)
    local ui = requireExport(fileName).create()
    if ui.root then
        local new_widget = ccui.Widget:create()
        new_widget:setAnchorPoint(zeroP)

        local children = ui.root:getChildren()
        for _, child in pairs(children) do
            child:removeFromParent()
        end
        for _, child in pairs(children) do
            new_widget:addChild(child)
        end

        local name = ui.root:getName()
        -- 自适应代码
        if name ~= "Layer" and name ~= "Node" then
            local visible = global.Director:getVisibleSize()
            new_widget:setContentSize(visible)
            ccui.Helper:doLayout(new_widget)
        else
            new_widget:setContentSize(ui.root:getContentSize())
        end

        rawset(ui, "root", new_widget)
        return new_widget, ui
    end
    return nil
end

function requireCommand(path)
    return require("game/command/" .. path)
end

function requireMediator(path)
    return require("game/mediator/" .. path)
end

function requireProxy(path)
    return require("game/proxy/" .. path)
end

function requireView(path)
    return require("game/view/" .. path)
end

function requireLayerUI(path)
    return require("game/view/layersui/" .. path)
end

function requireMainUI(path)
    return require("game/view/mainui/" .. path)
end

function requireMainUIWIN32(path)
    return require("game/view/mainui-win32/" .. path)
end

function requireExport(path)
    return require("game/view/export/" .. path)
end

-- value object
function requireVO(path)
    return require("game/valueobject/" .. path)
end

function requireUtil(path)
    return require("util/" .. path)
end

function requireConfig(path)
    return require("config/" .. path)
end

function requireGameConfig(path)
    SL:Print("[Require game_config] ", path)
    return require("game_config/" .. path)
end

function requireSUI(path)
    return require("GUI/sui/" .. path)
end

function requireCUI(path)
    return require("GUI/CUI/" .. path)
end

function requireGuide(path)
    return require("GUI/guide/" .. path)
end

function requireLayerGUI(path)
    return require("game/view/layersui/gui_layer/" .. path)
end

function releaseLayerGUI(path)
    package.loaded["game/view/layersui/gui_layer/" .. path] = nil
end

function requireNetwork(path)
    return require("network/" .. path)
end

function LoadTxt(path, delimiter, callback)
    if nil == path or nil == callback then
        print("LoadText error")
        return
    end

    local fileUtil = global.FileUtilCtl
    local strBuffer = fileUtil:getDataFromFileEx(path)
    strBuffer = sgsub(strBuffer, "\r", "")
    local lineBreak = "\n"

    local lines = G_GetSplitArray(strBuffer, lineBreak)
    local len = 0
    local pos1 = nil
    for k, v in ipairs(lines) do
        len = slen(v)
        if len > 0 then
            pos1, _ = sfind(v, "//")
            if not pos1 then -- skip //
                local dataTable
                if delimiter == nil or delimiter == "" or delimiter == "\n" then -- ignore "" \n
                    dataTable = {}
                    dataTable[1] = v
                else
                    dataTable = G_GetSplitArray(v, delimiter)
                end

                callback(dataTable)
            end
        end
    end
end

function Random(b, e) -- 简单随机
    if nil == e then
        return math.random(b)
    end
    return math.random(b, e)
end

function Schedule(callback, interval)
    local entryId = global.Scheduler:scheduleScriptFunc(callback, interval, false)
    LuaProfiler.BeginGlobalSchedule(entryId)
    return entryId
end

function UnSchedule(scheduleID)
    global.Scheduler:unscheduleScriptEntry(scheduleID)
    LuaProfiler.EndGlobalSchedule(scheduleID)
end

--[[--

计划一个全局延时回调，并返回该计划的句柄。
-- @function [parent=#scheduler] PerformWithDelayGlobal
-- @param function listener 回调函数
-- @param number time 延迟时间
-- @return mixed#mixed ret (return value: mixed)  schedule句柄
scheduler.performWithDelayGlobal() 会在等待指定时间后执行一次回调函数，然后自动取消该计划。

]]
function PerformWithDelayGlobal(listener, time)
    local handle
    handle =
        global.Scheduler:scheduleScriptFunc(
        function()
            global.Scheduler:unscheduleScriptEntry(handle)
            listener()
        end,
        time,
        false
    )
    return handle
end

function Shader_Grey(node)
    if not node then
        return
    end

    ShaderUtils.SetTypeShader(node, SLDefine.SHADER_TYPE.SHADER_TYPE_GRAY)
end

function Shader_Normal(node)
    if not node then
        return
    end

    ShaderUtils.SetTypeShader(node, SLDefine.SHADER_TYPE.SHADER_TYPE_NORMAL)
end

function HTTPRequest(url, callback)
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("GET", url)

    if callback then
        local function HttpResponseCB()
            local code = httpRequest.status
            local success = code >= 200 and code < 300
            local response = httpRequest.response

            release_print("Http Request Code:" .. tostring(code))
            callback(success, response)
        end

        httpRequest:registerScriptHandler(HttpResponseCB)
    end

    httpRequest:send()
end

function HTTPRequestPost(url, callback, data, header, notForce)
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("POST", url)
    if header then
        for k, v in pairs(header) do
            httpRequest:setRequestHeader(k, v)
        end
    end

    if callback then
        local function HttpResponseCB()
            local code = httpRequest.status
            local success = code >= 200 and code < 300
            local response = httpRequest.response

            release_print("Http Request Code:" .. tostring(code))
            callback(success, response, code)
        end
        if not notForce then
            httpRequest:setRequestHeader("Content-type", "application/x-www-form-urlencoded")
        end
        httpRequest:registerScriptHandler(HttpResponseCB)
    end

    --httpRequest:setRequestHeader
    httpRequest:send(data)
end

--
local Color3BCache = {}
function ConvertHexNumToColor3B(hexadecimalCode)
    if  not Color3BCache[hexadecimalCode] then
        hexadecimalCode = tonumber(hexadecimalCode) or global.MMO.DefaultColor
        local B = bit.band(hexadecimalCode, 0xff)
        local G = bit.band(bit.rshift(hexadecimalCode, 8), 0xff)
        local R = bit.band(bit.rshift(hexadecimalCode, 16), 0xff)
        Color3BCache[hexadecimalCode] = cc.c3b(R, G, B)
    end
    return Color3BCache[hexadecimalCode]
end

-- "#FFFFFF"  --> cc.c3b( 0xff, 0xff, 0xff )
local ColorHexNumCache = {}
local defaultColor = cc.Color3B.WHITE
function ConvertHexStrToColor3B(hexString)
    if not ColorHexNumCache[hexString] then
        hexString = tostring(hexString)
        local hex = sgsub(hexString, "#", "0x")
        ColorHexNumCache[hexString] = tonumber(hex)
    end
    if not ColorHexNumCache[hexString] then
        return defaultColor
    end

    return ConvertHexNumToColor3B(ColorHexNumCache[hexString])
end

-- cc.c3b( 0xff, 0xff, 0xff )  --> 0xFFFFFF
local ColorHexStrCache = {}
function ConvertColor3BToHexStr(rgb)
    if not ColorHexStrCache[rgb] then
        ColorHexStrCache[rgb] = sformat("#%02x%02x%02x", rgb.r, rgb.g, rgb.b)
    end
    return ColorHexStrCache[rgb]
end

GoodsItem = {}
GoodsItem.create = function(self, data)
    -- self不能使用
    local GoodsItem = require("util/GoodsItem")
    local item = GoodsItem.new()
    item._isGood = true
    item:init(data)
    return item
end

function CheckBit(num, pos)
    return bit.band(bit.rshift(num, pos), 0x1) == 1
end

function SetBit(num, pos, v)
    local b = bit.lshift(0x1, pos)
    if v > 0 then
        return bit.bor(num, b)
    else
        b = bit.bnot(b)
        return bit.band(num, b)
    end
end

function H16Bit(value)
    if not value then
        return 0
    end

    return bit.band(bit.rshift(value, 16), 0xffff)
end

function L16Bit(value)
    if not value then
        return 0
    end
    return bit.band(value, 0xffff)
end

function Merge16Bit(v1, v2)
    local ret = bit.lshift(v2, 16)
    ret = bit.bor(ret, v1)
    return ret
end

function H8Bit(value)
    if not value then
        return 0
    end
    return bit.band(bit.rshift(value, 8), 0xff)
end

function L8Bit(value)
    if not value then
        return 0
    end
    return bit.band(value, 0xff)
end

function Merge8Bit(v1, v2)
    local ret = bit.lshift(v2, 8)
    ret = bit.bor(ret, v1)
    return ret
end

function DelayTouchEnabled(target, delay)
    delay = delay or 0.2

    target:stopActionByTag(10999)
    target:setTouchEnabled(false)
    local action = performWithDelay(
        target,
        function()
            target:setTouchEnabled(true)
        end,
        delay
    )
    action:setTag(10999)
end

function GetFrameAnimIndex(act, dir)
    return act * 8 + dir
end

function GetFrameAnimConfigID( rawAnimID, sex, animType )
    -- 0xfffff   f     f     f
    -- animID    type  sex   act
    return animType * 10000000 + sex * 5000000 + rawAnimID
end

function ErrorReport(tag, content)
    local tagStr = tostring(tag)
    local contentStr = tostring(content)
    if not tagStr or not contentStr then
        return
    end

    local contentLen = slen(contentStr)
    local reportContent = contentLen <= 512 and contentStr or ssub(contentStr, 1, 512)

    if cc.PLATFORM_OS_ANDROID == global.Platform then
        buglyLog(1, tagStr, reportContent)
        buglyReportLuaException(tagStr, tagStr, false)
    else
        local data = {}
        data.ChannelId = GUIDefine.ChatChannel.SYSTEM
        data.Msg = tagStr .. " : " .. reportContent
        global.Facade:sendNotification(global.NoticeTable.SystemTips, "ERROR! " .. data.Msg)
        SLBridge:onLUAEvent(LUA_EVENT_CHAT_MSG_ADD, data)
    end
end

function RecordBuglyLogIm(index, value)
    if not index or not value then
        return
    end

    if cc.PLATFORM_OS_ANDROID == global.Platform then
        buglyLog(1, tostring(index), tostring(value))
    else
        release_print(tostring(index) .. ":" .. tostring(value))
    end
end

function RemoveAllWidgetClickEventListener(widget)
    if not widget then
        return
    end

    global.ScriptHandlerMgr:removeObjectAllHandlers(widget)
    widget:addClickEventListener(
        function()
        end
    )
end

function RemoveAllWidgetTouchEventListener(widget)
    if not widget then
        return
    end

    global.ScriptHandlerMgr:removeObjectAllHandlers(widget)
    widget:addTouchEventListener(
        function()
        end
    )
end

function CreateEditBoxByTextField(textField)
    local inputStr = textField:getString()
    local textColor = textField:getColor()
    local placeHolderColor = textField:getPlaceHolderColor()
    local placeHolder = textField:getPlaceHolder()
    local contentSize = textField:getContentSize()
    local fontSize = textField:getFontSize()
    local fontName = textField:getFontName()
    local parent = textField:getParent()
    local anchorPoint = textField:getAnchorPoint()
    local positionX = textField:getPositionX()
    local positionY = textField:getPositionY()
    local maxLength = textField:getMaxLength()
    local maxLengthEnable = textField:isMaxLengthEnabled()
    local horizontalAlignment = textField:getTextHorizontalAlignment()
    local name = textField:getName()
    textField:removeFromParent()
    textField = nil

    local fontPath = global.MMO.PATH_FONT2
    local editBox = ccui.EditBox:create(contentSize, global.MMO.PATH_RES_ALPHA)
    parent:addChild(editBox)
    if global.isMobile then
        editBox:setFontName(fontPath)
    end
    editBox:setFontSize(fontSize)
    editBox:setFontColor(textColor)
    editBox:setColor(textColor)
    editBox:setAnchorPoint(anchorPoint)
    
    if global.Platform == cc.PLATFORM_OS_ANDROID then
        positionX = positionX + 1
        positionY = positionY + 1
        editBox:setNativeOffset(cc.p(0, -13))
    end
    
    editBox:setPosition(cc.p(positionX, positionY))

    if maxLengthEnable then
        editBox:setMaxLength(maxLength)
    end
    editBox:setPlaceHolder(placeHolder)
    editBox:setPlaceholderFontColor(placeHolderColor)
    editBox:setPlaceholderFontSize(fontSize)
    editBox:setTextHorizontalAlignment(horizontalAlignment)
    editBox:setText(inputStr)
    editBox:setName(name)
    return editBox
end

local EditBox = ccui.EditBox
function EditBox:getString()
    return self:getText()
end
function EditBox:setString(input)
    self:setText(input)
end
function EditBox:addEventListener(callback)
    self:onEditHandler(
        function(event)
            local name = event.name
            local sender = event.target
            if name == "began" then
                callback(sender, 0)
            elseif name == "ended" then
                callback(sender, 1)
            elseif name == "changed" then
                callback(sender, 2)
            elseif name == "return" then
                callback(sender, 3)
            elseif name == "send" then
                callback(sender, 4)
            end
        end
    )
end

----------------------------------------------------------------------------
local Text = ccui.Text
local Label = cc.Label
local Widget = ccui.Widget
local Button = ccui.Button
local CheckBox = ccui.CheckBox
local RichText = ccui.RichText
function CheckBox:addClickEventListener(callback)
    self._clickCallBack_ = callback
    local backup = getmetatable(getmetatable(self))[".backup"]
    backup.addClickEventListener(self, callback)
end

function Widget:addTouchBeganEventListener(callback)
    self:addTouchEventListener(
        function(_, eventType)
            if eventType == 0 then
                callback()
            end
        end
    )
end

function Widget:addClickEventListener(callback)
    local backup = nil
    if tolua.type(self) == "ccui.Widget" then
        backup = getmetatable(self)[".backup"]
    elseif tolua.type(self) == "ccui.ListView" then
        backup = getmetatable(getmetatable(getmetatable(self)))[".backup"]
    else
        backup = getmetatable(getmetatable(self))[".backup"]
    end
    if backup then
        if type(backup.onEvent) == "function" then
            backup.onEvent(self, callback)
            self._clickCallBack_ = callback
        elseif type(backup.addClickEventListener) == "function" then
            backup.addClickEventListener(self, callback)
            self._clickCallBack_ = callback
        end
    end
end

function Widget:addTouchEventListener(...)
    local params = {...}
    if #params == 1 then
        self._touchCallBack_ = ...
    else
        self._touchCallBack_ = params[2]
    end

    local backup = nil
    if tolua.type(self) == "ccui.Widget" then
        backup = getmetatable(self)[".backup"]
    elseif tolua.type(self) == "ccui.ListView" then
        backup = getmetatable(getmetatable(getmetatable(self)))[".backup"]
    else
        backup = getmetatable(getmetatable(self))[".backup"]
    end
    backup.addTouchEventListener(self, ...)
end

function Widget:_addClickEventListener(callback)
    self:addClickEventListener(
        function()
            if not self.longTouchEvent then
                callback(self)
            end
        end
    )
end

function Widget:_addLongTouchEventListener(callback)
    local actionTAG = 123321
    self:addTouchEventListener(
        function(_, eventType)
            if eventType == 0 then
                self.longTouchEvent = false
                self:stopActionByTag(actionTAG)
                local action =
                    performWithDelay(
                    self,
                    function()
                        self.longTouchEvent = true
                        callback(self)
                    end,
                    0.7
                )
                action:setTag(actionTAG)
            elseif eventType == 2 or eventType == 3 then
                self:stopActionByTag(actionTAG)
            end
        end
    )
end

function Widget:addMouseOverTips(tips, offset, anchor, param, show)
    local checkCallback = param and param.checkCallback
    global.mouseEventController:registerMouseMoveEvent(
        self,
        {
            enter = function(touchPos)
                if not global.userInputController:IsTouching() and self:isVisible() then
                    if not checkCallback or checkCallback(touchPos) then
                        ShowMouseOverTips(self, tips, offset, anchor)
                    end
                end
            end,
            leave = function()
                HideMouseOverTips()
            end,
            show = show,
            checkIsVisible = true,
            needCover = true,
        }
    )
end

function Button:loadTextureMouseOver(nfileName, mfileName, enterCB, leaveCB)
    local function checkResType(path)
        if global.SpriteFrameCache:getSpriteFrame(path) then
            return 1
        end
        if global.FileUtilCtl:isFileExist(path) then
            return 0
        end
        return 0
    end
    local function checkRes(path)
        local resType = checkResType(path)
        self:loadTextureNormal(path, resType)
    end

    self:setSwallowMouse(true)
    self:setMouseEnabled(true)
    self:addMouseEventListener(function(sender, eventType)
        if eventType == 1 then
            checkRes(mfileName)
            if enterCB then
                enterCB()
            end
            
        elseif eventType == 2 then
            checkRes(nfileName)
            if leaveCB then
                leaveCB()
            end
        end
    end)
end

function Button:setTitleText(str)
    local stProxy = global.Facade:retrieveProxy( global.ProxyTable.StringTableProxy )
    local newStr = stProxy:fixNewLanguageString(str) or ""
    getmetatable(self)[".backup"].setTitleText(self, newStr)
end

function Widget:setString(str)
    local stProxy = global.Facade:retrieveProxy( global.ProxyTable.StringTableProxy )
    local newStr = stProxy:fixNewLanguageString(str) or ""
    getmetatable(self)[".backup"].setString(self, newStr)
end

function Widget:createWithXML(str,data)
    local stProxy = global.Facade:retrieveProxy( global.ProxyTable.StringTableProxy )
    local newStr = stProxy:fixNewLanguageString(str) or ""
    return getmetatable(self)[".backup"].createWithXML(self, newStr, data or {})
end

function Label:setString(str)
    local stProxy = global.Facade:retrieveProxy( global.ProxyTable.StringTableProxy )
    local newStr = stProxy:fixNewLanguageString(str) or ""
    getmetatable(self)[".backup"].setString(self, newStr)
end

-- 调用来自 C++
function g_OnEnterForColor(sender, param)
    -- 自动设置按钮下压效果
    if sender:getDescription() == "Button" and not sender.invalidZoomScale then
        local scale = tonumber(SL:GetValue("GAME_DATA", "ButtonClickZoomScale")) or -0.05
        scale = scale == 0 and -0.05 or scale
        sender:setZoomScale(scale)
    end
end

-- 调用来自 C++
function g_ColorStyleRichText(sender, colorStyleID)
end
----------------------------------------------------------------------------
local Widget = ccui.Widget
function Widget:cloneEx()
    local ret = self:clone()
    ret.UserData = self.UserData

    local function setChildrenUserData(targetNode, originNode)
        local targetChildren = targetNode:getChildren()
        local originChildren = originNode:getChildren()
        if #targetChildren == 0 or #originChildren == 0 then
            return nil
        end

        for key, value in pairs(targetChildren) do
            targetChildren[key].UserData = originChildren[key].UserData

            setChildrenUserData(targetChildren[key], originChildren[key])
        end
    end

    setChildrenUserData(ret, self)
    cloneLabelRender(self,ret)
    return ret
end
function cloneLabelRender(originNode,targetNode)
    if originNode:getDescription() == "BmpText" then 
        GUI:SetBmpTextProperties(targetNode)
        local originNodeRenderer =  originNode:getVirtualRenderer()
        local fontColor = originNodeRenderer:getColor()
        targetNode:setBMFontFilePath()
        targetNode:setFontSize(12)
        targetNode:setTextColor(fontColor)
    end

    local targetChildren = targetNode:getChildren()
    local originChildren = originNode:getChildren()
    if #targetChildren == 0 or #originChildren == 0 then
        return nil
    end
    for i,ch in ipairs(targetChildren) do
        local orich = originChildren[i]
        cloneLabelRender(orich,ch)
    end
end

function SetRichText(txtObj, richText, color, bAutoLine)
    if bAutoLine == nil then
        bAutoLine = true
    end
    local RichHelp = require("util/RichTextHelp")
    txtObj:setVisible(false)
    local resName = txtObj:getName()
    local richName = resName .. "__rich"
    local richObj = txtObj:getParent():getChildByName(richName)
    if richObj then
        richObj:removeFromParent()
        richObj = nil
    end
    local fontSize = txtObj:getFontSize()
    color = color or ConvertColor3BToHexStr(txtObj:getTextColor())
    local size = txtObj:getLayoutSize()
    if size.width == 0 then
        print(">>>>>>>SetRichText err!!" .. richText, richName)
        return
    end
    local width = size.width
    if not bAutoLine then
        width = 9999
    end
    local richObj = RichHelp:CreateRichTextWithXML(richText, width, fontSize, color)
    if richObj then
        local ap = txtObj:getAnchorPoint()
        local posX = txtObj:getPositionX()
        local posY = txtObj:getPositionY()
        txtObj:getParent():addChild(richObj)
        richObj:setAnchorPoint(ap)
        richObj:formatText()
        richObj:setPosition(cc.p(posX, posY))
        richObj:setName(richName)
    else
        print("!!!!!!!!!!!!!!richText error", richText)
    end
    return richObj
end

--哈希表转成按数组
function HashToSortArray(hashTab, sortFunc)
    if hashTab == nil or type(hashTab) ~= "table" then
        return nil
    end

    local sortTable = {}
    for _, v in pairs(hashTab) do
        table.insert(sortTable, v)
    end
    if sortFunc then
        table.sort(sortTable, sortFunc)
    end
    return sortTable
end

local function getChildInSubNodes(node, key)
    local child = GUI:getChildByName(node, key)
    if child then
        return child
    end

    local subNodes = GUI:getChildren(node)
    if #subNodes ~= 0 then
        for _, v1 in ipairs(subNodes) do
            local child = getChildInSubNodes(v1, key)
            if child then
                return child
            end
        end
    end
    return nil
end

local function getChildByKey(parent, key)
    return getChildInSubNodes(parent, key)
end

function ui_delegate(nativeUI)
    if (nativeUI == nil) then
        return nil
    end

    local tt = {
        __index = function(t, k)
            local u = getChildByKey(t.nativeUI, k)
            rawset(t, k, u)
            return u
        end
    }
    local r = {["nativeUI"] = nativeUI}
    setmetatable(r, tt)
    return r
end

function CheckNotchPhone()
    local visibleSize    = SL:GetValue("SCREEN_SIZE")
    local glView         = global.OpenGLView
    local viewRect       = glView:getVisibleRect()
    local safeRect       = global.Director:getSafeAreaRect()
    local notch          = (math.abs(viewRect.width - safeRect.width) > 5)
    local deviceRotation = global.L_GameEnvManager:GetDeviceRotation()
    
    if notch then
        local notchWidth    = 50
        viewRect.x          = (deviceRotation == 1 and notchWidth or 0)
        viewRect.y          = 0
        viewRect.width      = viewRect.width - notchWidth
        viewRect.height     = visibleSize.height
    end
    return notch, viewRect
end

--划线
function CreateDrawLine(size, beginPos, endPos, color)
    size = size or 1
    color = color or cc.c4f(1, 0, 0, 1)

    local drowRoot = cc.DrawNode:create(size)
    drowRoot:drawLine(beginPos, endPos, color)
    return drowRoot
end

--[[
    README:
    data.dataLength 总长度
    或者data.items长度
    data.pageLength 每页长度
    data.isShowLat 是否显示上页最后一项
]]
function GetPageData(data)
    if not data then
        return nil
    end
    local length = 0
    if data.dataLength then
        length = data.dataLength
    end
    if data.items then
        length = #data.items
    end
    local pageData = {}
    local page = 1
    local pageLength = data.pageLength or global.MMO.NPC_STORE_LIST_LENGTH
    local isShowLastItem = data.isShowLast

    if isShowLastItem then
        pageLength = pageLength - 1
    end
    local maxPage = math.ceil(length/pageLength)
    for index=page,maxPage do
        local beginItem = (index - 1)*pageLength + 1
        local endItem = index*pageLength
        if isShowLastItem then
            endItem = index*pageLength + 1
        end
        if index == maxPage then
            endItem = length
        end
        pageData[index] = {
            beginItem = beginItem,
            endItem = endItem
        }
    end

    return pageData
end

--文本提示框
function GetWordTips(data)
    local str = data.str or "" --文本
    local width = data.width or 800 --文本宽度
    local richTextHelp = require("util/RichTextHelp")

    local tips = ccui.Layout:create()
    tips:setBackGroundImage(global.MMO.PATH_RES_PRIVATE .. "item_tips/bg_tipszy_05.png")
    tips:setBackGroundImageCapInsets({x = 16, y = 16, width = 103, height = 141})
    tips:setBackGroundImageScale9Enabled(true)
    tips:setAnchorPoint(0, 0)

    local richText = richTextHelp:CreateRichTextWithXML(str, width, 16, "#ffffff")
    richText:formatText()
    richText:setAnchorPoint(0, 1)
    richText:setName("richText")
    tips:addChild(richText)
    local textSize = richText:getContentSize()
    richText:setPosition(10, textSize.height + 10)

    if textSize.width < width then
        width = textSize.width
    end
    tips:setContentSize(cc.size(width + 20, textSize.height + 20))
    return tips
end

local zeroPoint = cc.p(0, 0)
local rtPoint = cc.p(0, 0)
function CalcCameraZoom( camera )
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    rtPoint.x = screenW
    rtPoint.y = screenH
    local rtPosGL = camera:projectGL( rtPoint )
    local lbPosGL = camera:projectGL( zeroPoint )

    local zoomWidth = rtPosGL.x - lbPosGL.x
    local zoomHeight = rtPosGL.y - lbPosGL.y

    local scaleX = screenW / zoomWidth
    local scaleY = screenH / zoomHeight

    return scaleX, scaleY
end

function Screen2World( srcPos )
    local camera = global.gameCameraController:GetViewCamera()
    if not camera then
        return nil
    end

    local scaleX, scaleY = CalcCameraZoom( camera )

    local px = srcPos.x * scaleX
    local py = srcPos.y * scaleY

    local cameraPosX, cameraPosY = camera:getPosition()

    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local centerOfViewX = screenW * 0.5 * scaleX
    local centerOfViewY = screenH * 0.5 * scaleY
    local worldX = cameraPosX + px - centerOfViewX
    local worldY = cameraPosY + py - centerOfViewY
    
    return worldX, worldY
end

function World2Screen( srcPos )
    local camera = global.gameCameraController:GetViewCamera()
    if not camera then
        return nil
    end

    local scaleX, scaleY = CalcCameraZoom( camera )

    local cameraPosX, cameraPosY = camera:getPosition()
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local centerOfViewX = screenW * 0.5 * scaleX
    local centerOfViewY = screenH * 0.5 * scaleY 
    local screenX = srcPos.x + centerOfViewX - cameraPosX
    local screenY = srcPos.y + centerOfViewY - cameraPosY

    screenX = screenX / scaleX
    screenY = screenY / scaleY

    return screenX, screenY
end

function RegisterNodeMovable( node, param )
    local itemMoveState = {
        begin = 1,
        moving = 2,
        end_move = 3,
    }
    local pressCallBack = param.pressCallBack
    local clickCallBack = param.clickCallBack
    local replaceClick = param.replaceClick
    local replacePress = param.replacePress
    local doubleEventCallBack = param.doubleEventCallBack
    local nodeFrom = param.nodeFrom
    local beginMoveCallBack = param.beginMoveCall
    local endMoveCallBack = param.endMoveCall
    local cancelMoveCallBack = param.cancelMoveCall
    local itemData = param.itemData
    local isNeedItemData = param.dataNeed
    local isNode = param.moveNode
    local skillId  = param.skillId

    local function ResetMoveState( mySelf, bool )
        if mySelf and not tolua.isnull(mySelf) then
            mySelf._movingState = bool
            if bool then
                if beginMoveCallBack then
                    beginMoveCallBack( mySelf, bool )
                end
            else
                if endMoveCallBack then
                    endMoveCallBack( mySelf, bool )
                end
            end
        end
    end

    local function SetGoodItemState(state, movePos)
        if isNeedItemData and not itemData then
            return
        end

        if itemMoveState.begin == state then
            ResetMoveState(node,true)
            UIOperator:CloseItemTips()
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_BEGIN, {
                pos = movePos,
                itemData = itemData,
                cancelCallBack = cancelMoveCallBack,
                from = nodeFrom,
                movingNode = isNode:clone(),
                skillId = skillId
            })
        elseif itemMoveState.moving == state then
    
        elseif itemMoveState.end_move == state then
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END, movePos)
        end
    end

    local function clickEventCallBack(clickNode, eventtype)
        --不在道具移动
        if clickNode._movingState then
            return
        end
        local panelPos = clickNode:getWorldPosition()
        if global.isWinPlayMode then
            SetGoodItemState(itemMoveState.begin, panelPos)
        end
        if clickCallBack then
            clickCallBack(clickNode)
        end
    end

    local function pressEventCallBack()
        --不在道具移动
        if node._movingState then
            return
        end
        local panelPos = node:getWorldPosition()
        if global.isWinPlayMode then
            SetGoodItemState(itemMoveState.begin, panelPos)
        end
        if pressCallBack then
            pressCallBack(node)
        end
    end

    local clickEventCallBack = replaceClick or clickEventCallBack

    local pressEventCallBack = replacePress or pressEventCallBack

    local isEventPress = false
    local isMoved = true
    local hasEventCallOnTouchBegin = false        --只有在响应了touchbegin 时才会去响应延时方法 因为在延时后 鼠标事件的 状态已经被置掉
    local isMobile = not global.isWinPlayMode

    local function delayCallback()
        isEventPress = true

        if pressEventCallBack then
            if not pressEventCallBack then
                return false
            end

            if not isMoved then
                pressEventCallBack()
                return false
            end

            local movedPos = node:getTouchMovePosition()
            local beganPos = node:getTouchBeganPosition()

            local diff = cc.pSub(movedPos, beganPos)
            local distSq = cc.pLengthSQ(diff)
            if distSq <= 100 then
                pressEventCallBack()
            end
        end
    end

    local function touchEvent( touch, eventType )
        if global.isWinPlayMode then
            local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
            local itemMoving = ItemMoveProxy:GetMovingItemState()
            if itemMoving then --在道具移动中
                return
            end
        end
        if eventType == 0 then
            isEventPress = false
            isMoved = false
            hasEventCallOnTouchBegin = true

            if pressEventCallBack then
                performWithDelay(node, delayCallback, global.MMO.CLICK_DOUBLE_TIME)
            end
        elseif eventType == 1 then
            
            local movedPos = node:getTouchMovePosition()
            local beganPos = node:getTouchBeganPosition()

            local diff = cc.pSub(movedPos, beganPos)
            local distSq = cc.pLengthSQ(diff)
            if not isMoved and distSq > 100 then
                isMoved = true
                if isMobile then
                    local beginMovePos = node:getWorldPosition()
                    SetGoodItemState(itemMoveState.begin, beginMovePos)
                end
            end
            if isMobile then
                local movedPos = node:getTouchMovePosition()
                SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_MOVING, {pos = movedPos})
            end
        elseif eventType == 2 then
            node:stopAllActions()

            if not isMoved then
                if not isEventPress then
                    -- 判断是否有双击事件
                    if doubleEventCallBack then
                        -- 记录上一次点击时间
                        if not node._lastClickTime then
                            node._lastClickTime = true
                            -- 记录单击触发
                            -- 记录进入此处时的状态，避免在延时操作后状态被改变
                            local stateOnbegin = hasEventCallOnTouchBegin
                            node._clickDelayHandler =
                                PerformWithDelayGlobal(
                                function()
                                    if clickEventCallBack and stateOnbegin then
                                        clickEventCallBack(node, eventType)
                                    end

                                    node._lastClickTime = nil
                                end,
                                global.MMO.CLICK_DOUBLE_TIME
                            )
                        else
                            if node._clickDelayHandler then
                                UnSchedule(node._clickDelayHandler)
                                node._clickDelayHandler = nil
                            end

                            if doubleEventCallBack then
                                doubleEventCallBack()
                            end

                            node._lastClickTime = nil
                        end
                    else
                        local stateOnbegin = hasEventCallOnTouchBegin
                        if clickEventCallBack and stateOnbegin then
                            clickEventCallBack(node, eventType)
                        end
                    end
                end
            else
                if isMobile then
                    local endPos = node:getTouchEndPosition()
                    SetGoodItemState(itemMoveState.end_move, endPos)
                end
            end
            hasEventCallOnTouchBegin = false
        elseif eventType == 3 then
            if isMobile then
                local endPos = node:getTouchEndPosition()
                SetGoodItemState(itemMoveState.end_move, endPos)
            end
            hasEventCallOnTouchBegin = false
        end
    end
    node:addTouchEventListener( touchEvent )
end

function CreateStaticUIModel(sex, feature, scale, params)
    SL:RequireFile(UIConst.LUAFile.LUA_FILE_UIMODEL)
    return UIModel.main(sex, feature, scale, params)
end

-- 特效ID#层级#手机X#手机Y#PC缩放#手机缩放#PCX#PCY|...
function ParseModelEffect(effect)
    local effectSet = {}
    if not effect then
        return effectSet
    end
    if type(effect) == "number" then
        effect = effect .. "#0"
    end
    
    local effectArry = G_GetSplitArray(effect or "","&")
    local isShowLook = tonumber(effectArry[2]) ~= 0
    local effectList = G_GetSplitArray(effectArry[1] or "", "|")
    for i = 1, #effectList do
        local effectParam = effectList[i]
        local effectParamPar = G_GetSplitArray(effectParam or "", "#")
        local effectData = {
            effectId = effectParamPar[1] and tonumber(effectParamPar[1]) or 0,
            zOrder = effectParamPar[2] and tonumber(effectParamPar[2]) or 0,
            offX = effectParamPar[3] and tonumber(effectParamPar[3]) or 0,
            offY = effectParamPar[4] and tonumber(effectParamPar[4]) or 0,
            scale = effectParamPar[6] and tonumber(effectParamPar[6]) or 1 --"PC缩放#手机缩放"
        }
        if global.isWinPlayMode then
            effectData.scale = effectParamPar[5] and tonumber(effectParamPar[5]) or 1
            effectData.offX = effectParamPar[7] and tonumber(effectParamPar[7]) or effectData.offX
            effectData.offY = effectParamPar[8] and tonumber(effectParamPar[8]) or effectData.offY
        end
        table.insert(effectSet, effectData)
    end
    return effectSet, isShowLook
end

local CHECK_TYPE = {
    AND = 1,
    OR = 2
}
-- articleType: 禁止类型(有些绑定可以进行操作)
function CheckItemisBind(itemData, articleType)
    if not itemData then
        return false, false
    end

    -- release_print("===CheckItemisBind: ", itemData.Bind, itemData.Article, global.ConstantConfig.bangdingguize or "")
    local cfgArticle = tonumber(itemData.Article) or 0    -- 表配置
    local itemBind = tonumber(itemData.Bind) or 0         -- 脚本设置
    if itemBind > 0 or cfgArticle > 0 then
        local isMeetType = false
        if articleType and articleType > 0 then
            isMeetType = CheckBit(itemBind, articleType - 1) or CheckBit(cfgArticle, articleType - 1)
        end

        local bindParam = SL:GetValue("GAME_DATA","bangdingguize") or "" -- 1#xxx与  2#xxx或
        local bindArticles = G_GetSplitArray(bindParam,"#")
        local type = tonumber(bindArticles[1]) 
        local bitArticles = tonumber(bindArticles[2]) 

        if not type or not bitArticles then 
            return false, isMeetType
        end

        if type ~= CHECK_TYPE.AND and type ~= CHECK_TYPE.OR then 
            return false, isMeetType
        end
        
        local isBind = false
        local rshift = 0
        local ArticleCount = table.nums(GUIDefine.ItemArticleType) 
        while (bit.rshift(bitArticles, rshift) > 0 and rshift < ArticleCount) do
            if CheckBit(bitArticles, rshift) then
                isBind = CheckBit(itemBind, rshift) or CheckBit(cfgArticle, rshift)
                if type == CHECK_TYPE.AND then 
                    if not isBind then 
                        break
                    end
                else 
                    if isBind then
                        break
                    end
                end
            end
            rshift = rshift + 1
        end

        return isBind, isMeetType
    else
        return false, false
    end
end

function ShowSystemTips(str)
    global.Facade:sendNotification(global.NoticeTable.SystemTips, str)
end

function ShowDebugSystemTips(data)
    global.Facade:sendNotification(global.NoticeTable.DebugSystemTips, data)
end

function ShowSystemChat(str, FColor, BColor)
    local mdata     = {
        Msg         = str,
        FColor      = FColor or 249,
        BColor      = BColor or 255,
        ChannelId   = GUIDefine.ChatChannel.SYSTEM,
        textType    = GUIDefine.ChatTextType.SYSTEMTIPS,
    }
    SLBridge:onLUAEvent(LUA_EVENT_CHAT_MSG_ADD, mdata)
end

local ListView = ccui.ListView
function ListView:paintItems()
    local items      = self:getItems()
    local direction  = self:getDirection()

    local lowerBound = #items - 1
    local upperBound = 0
    
    if (direction ~= 1)  then
        lowerBound = self:getIndex(self:getRightmostItemInCurrentView())
        upperBound = self:getIndex(self:getLeftmostItemInCurrentView())
    end
    
    if (direction ~= 2) then
        lowerBound = math.min(self:getIndex(self:getTopmostItemInCurrentView()), lowerBound)
        upperBound = math.max(self:getIndex(self:getBottommostItemInCurrentView()), upperBound)
    end
    
    for i, item in ipairs(items) do
        item:setVisible(lowerBound <= (i-1) and (i-1) <= upperBound)
    end
end

local ScrollView = ccui.ScrollView
function ScrollView:addMouseScrollPercent(callback)
    self:setMouseEnabled(true)
    self:setSwallowMouse(false)
    self:addMouseEventListener(function(sender, eventType)
        if eventType == 1 then
        elseif eventType == 3 then
            local speed         = 30
            local param         = self:getMouseScrollPosition()
            local scorllX       = param.x
            local scorllY       = param.y
            local contentSize   = self:getContentSize()
            local innerSize     = self:getInnerContainerSize()
            if innerSize.height > contentSize.height then
                local innerPos      = self:getInnerContainerPosition()
                local vHeight       = innerSize.height - contentSize.height
                local dis           = speed * scorllY
                local percent       = (vHeight + innerPos.y + dis) / vHeight * 100
                percent             = math.min(math.max(0, percent), 100)
                self:scrollToPercentVertical(percent, 0.03, false)
                if callback then
                    callback(percent)
                end
            end
        end
    end)
end

function CreateScrollLabel(txt, config)
    local anchorPoint = {0, 0}
    if config and config.anchorPoint then
        anchorPoint = config.anchorPoint
    end
    local layoutName = ccui.Layout:create()
    layoutName:setClippingEnabled(true)
    layoutName:setLayoutComponentEnabled(true)
    layoutName:setAnchorPoint(anchorPoint[1], anchorPoint[2])

    local componentSize = {
        width = 80,
        height = 20
    }
    if config and config.visibleSize then
        componentSize = {
            width = config.visibleSize[1],
            height = config.visibleSize[2]
        }
    end

    local layout = ccui.LayoutComponent:bindLayoutComponent(layoutName)
    layout:setSize(
        {
            width = componentSize.width,
            height = componentSize.height
        }
    )
    local string = txt or ""
    local nameLabel = ccui.Text:create(txt, config and config.fontName or global.MMO.PATH_FONT2, config.fontSize or 18)
    nameLabel:setAnchorPoint(anchorPoint[1], anchorPoint[2])

    if config and config.labelColour then
        nameLabel:setTextColor(config.labelColour)
    end

    if config and config.colorId then
        nameLabel:setTextColor(GET_COLOR_BYID_C3B(config.colorId))
    end

    local maxSize = componentSize.width or 80
    local function StartNameAction(cell)
        local textWid = cell:getContentSize().width
        if textWid > maxSize then
            cell:runAction(
                cc.RepeatForever:create(
                    cc.Sequence:create(cc.MoveBy:create(4, cc.p(-textWid, 0)), cc.MoveBy:create(0, cc.p(textWid, 0)))
                )
            )
        end
    end

    StartNameAction(nameLabel)

    nameLabel:setPosition(cc.p(componentSize.width*anchorPoint[1], componentSize.height*anchorPoint[2]))
    layoutName:addChild(nameLabel)

    return layoutName
end

-- 用于检测goodsitem 是否在listview 并且可视
function CheckNodeCanCallBack( node, mousePos, checkLevel )
    local child = node
    local times = 0
    local checkEnable = true
    local maxTimes = checkLevel or 6
    local function GetParentAndCheck(childNode)
        if times >= maxTimes then
            checkEnable = true
            return
        end
        if not tolua.isnull(childNode) then
            local parent = childNode:getParent()
            if not tolua.isnull(parent) then
                if not parent:isVisible() then
                    checkEnable = false
                    return
                end
                if tolua.iskindof(parent,"ccui.ListView") or tolua.iskindof(parent,"ccui.ScrollView") or (tolua.iskindof(parent, "ccui.Layout") and parent:isClippingEnabled()) then
                    local contentSize = parent:getContentSize()
                    local parentPos = parent:getWorldPosition()
                    local anchorPoint = parent:getAnchorPoint()
                    local width = contentSize.width
                    local height = contentSize.height
                    local minX = parentPos.x - width*anchorPoint.x
                    local maxX = parentPos.x + width*(1-anchorPoint.x)
                    local minY = parentPos.y - height*anchorPoint.y
                    local maxY = parentPos.y + height*(1-anchorPoint.y)
                    if mousePos.x < minX or maxX < mousePos.x or mousePos.y < minY or maxY < mousePos.y then
                        checkEnable = false
                        return
                    end
                end
                times = times + 1
                GetParentAndCheck(parent)
            end
        end
    end

    GetParentAndCheck(child)

    return checkEnable
end

function PlayEffectOnScreen(data)
    local effectId = data.effectId
    local x = data.x
    local y = data.y
    local playSpeed = data.speed
    local playTimes = data.times
    local playMode = data.mode  --2行会 3地图 4组队
    local isLoop = false

    if playTimes == 0 then
        isLoop = true
    end

    -- 播放特效
    local sfxAnim = global.FrameAnimManager:CreateSFXAnim(effectId)
    sfxAnim:setPosition( x, y)
    sfxAnim:Play(0, 0, true, playSpeed)
    local count  = 0
    local function removeEvent()
        count = count + 1
        if playTimes == count then
            sfxAnim:removeFromParent() 
        end
    end
    sfxAnim:SetAnimEventCallback( removeEvent )

    if data.id then
        sfxAnim:setName(tostring(data.id))
    end 

    local mediator = global.Facade:retrieveMediator("NoticeMediator")

    dump(data)
    if mediator._layer and mediator._layer._root:getChildByName(tostring(data.id)) then
        global.Facade:sendNotification(global.NoticeTable.Layer_Notice_RemoveChild, tostring(data.id))
    end

    if tonumber(playMode) > 1 and tonumber(playMode) < 5 then
        table.insert(mediator._typeEffects[playMode - 1], tostring(data.id))
        dump(mediator._typeEffects[playMode - 1])
    end

    global.Facade:sendNotification(global.NoticeTable.Layer_Notice_AddChild, {child = sfxAnim})
end

function SHOW_SUI_DESCTIP(widget, str, width, offset, anchorPoint)
    local btnAnchor     = widget:getAnchorPoint()
    local contentSize   = widget:getContentSize()
    local worldPos      = widget:getWorldPosition()
    --anchorPoint此时为SUI组件设置锚点
    local fixWorldPos   = cc.pAdd(worldPos, cc.p((anchorPoint.x-btnAnchor.x)*contentSize.width, (anchorPoint.y-btnAnchor.y)*contentSize.height))

    offset = offset or {x=0, y=0}
    width = width or 1136

    local tempWorldPos = cc.pAdd(fixWorldPos, offset)
    anchorPoint = cc.p(0.5,0.5)
    UIOperator:OpenCommonDescTipsUI({str = str, worldPos = tempWorldPos, width = width, anchorPoint = anchorPoint, isSUI = true})
end

function SHOW_DESCTIP( str, width, worldPos, anchorPoint, swallowType)
    worldPos = worldPos or zeroP
    width = width or 1136
    UIOperator:OpenCommonDescTipsUI({str = str, worldPos = worldPos, width = width, anchorPoint = anchorPoint, swallowType = swallowType})
end

--飞向人物
local SharedPoint = {}
function ShowFakeDropItemsJustFly(targetID, items)
    local ServerTimeProxy = global.Facade:retrieveProxy( global.ProxyTable.ServerTimeProxy )
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    local sceneRoot = global.sceneGraphCtl:GetSceneNode( global.MMO.NODE_ACTOR_SPRITE )

    local target = global.actorManager:GetActor(targetID)
    if not target then
        return nil
    end
    local DROPITEM_RES_PATH   = "res/item"
    local DROPITEM_GROUND_RES_PATH   = "res/item_ground"
    local PUBLIC_UNDEFINE     = "un_define.pvr.ccz"
    local function createDropItem(index, item)
        local itemIndex = item.id or 1
        if not tonumber(itemIndex) or tonumber(itemIndex) < 100 then
            return nil
        end

        local itemData  = ItemConfigProxy:GetItemDataByIndex(itemIndex)
        local itemName  = ItemConfigProxy:GetItemNameByIndex(itemIndex)
        if not itemData or not next(itemData) then
            return nil
        end

        -- 资源路径
        local itemLooks = itemData.Looks or 1
        local groundFile = global.dropItemController:GetItemGroundFile(itemLooks)
        local dropItemTexc = global.CustomCache:GetImage(groundFile)
    
        local itemScale = SL:GetValue("GAME_DATA","itemGroundSacle") or (global.isWinPlayMode and 0.5 or 0.8)
    
        if not dropItemTexc then
            groundFile = string.format("%s/%s",DROPITEM_RES_PATH,PUBLIC_UNDEFINE) 
            dropItemTexc = global.CustomCache:GetImage(groundFile)
            print( "Failed to load drop item avatar:"..fileName.."\n" )
        end

        local dropItemSprite   = cc.Sprite:createWithTexture( dropItemTexc )
        dropItemSprite:setScale(itemScale)
        dropItemSprite.GetBoundingBox = dropItemSprite.getBoundingBox
        --------------
        -- 计算初始坐标和目标坐标
        local pX, pY = global.sceneManager:MapPos2WorldPos(item.mapX, item.mapY, true)
        SharedPoint.x = pX
        SharedPoint.y = pY
        -- 创建道具图标
        local imageItem = dropItemSprite--ccui.ImageView:create()
        sceneRoot:addChild(dropItemSprite)
        imageItem:setPosition(SharedPoint)
        imageItem:setTag(index)
        imageItem:setVisible(false)

        ------------
        local function moveToTarget()
            local speed = 400
            local interval = 1/60
            local function callback()
                local target = global.actorManager:GetActor(targetID)
                if not target then
                    global.CustomCache:RmImage(imageItem)
                    return nil
                end
                local targetPos = target:getPosition()
                local curItemPos = cc.p(imageItem:getPosition())

                local distance  = speed * interval
                local destSub   = cc.pSub(targetPos, curItemPos)
                local flyDir    = cc.pNormalize(destSub)
                local displ     = cc.pMul(flyDir, distance)
                local posNew    = cc.pAdd(curItemPos, displ)

                imageItem:setPosition(posNew)

                local destSub   = cc.pSub(targetPos, curItemPos)
                local destDist  = cc.pGetLength(destSub)
                if destDist <= distance*3 then
                    global.CustomCache:RmImage(imageItem)
                end
            end
            
            schedule(imageItem, callback, interval)
            performWithDelay(imageItem, function()
                global.CustomCache:RmImage(imageItem)
            end, 1)
        end
        
        imageItem:runAction(cc.Sequence:create(
            cc.Show:create(),
            cc.CallFunc:create(moveToTarget)
        ))
    end

    -- 
    for index, item in ipairs(items) do
        createDropItem(index, item)
    end
end

--飘经验特效
local sharedAnchorPoint = {}
function EXPFly(actorID,effectID)
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    local widget = (MainProperty and MainProperty._ui) and MainProperty._ui.LoadingBar_exp
    if not widget then
        return nil
    end

    local X = actor:GetMapX()
    local Y = actor:GetMapY()
    -- 计算初始坐标和目标坐标
    local pX, pY = global.sceneManager:MapPos2WorldPos(X, Y)
    SharedPoint.x = pX
    SharedPoint.y = pY

    local sceneRoot = global.sceneGraphCtl:GetSceneNode( global.MMO.NODE_UI_NORMAL )
    local sfxRoot = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_ACTOR_SFX_FRONT)
    if effectID == 0 then 
        effectID= 5057
    end
    local anim =  global.CustomCache:GetSFXAnim( effectID )
    if not anim then
        return nil
    end

    local Percentage = widget:getPercent()
    local targetPos =  widget:convertToWorldSpace(zeroP)
    local box = widget:getBoundingBox()

    targetPos.y = 0.5 * box.height + targetPos.y
    targetPos.x = targetPos.x + Percentage / 100 * box.width
    sfxRoot:addChild(anim)
    anim:setLocalZOrder(effectID)
    anim:Play(0, 0, true)
    anim:setPosition(SharedPoint)
    anim:setVisible(true)
    sharedAnchorPoint.x = anim:GetStandPointX()
    sharedAnchorPoint.y = anim:GetStandPointY()
    anim:setAnchorPoint(sharedAnchorPoint)
    anim:SetAnimEventCallback(function()
        global.CustomCache:RmSFXAnim(anim)
        local worldposX, worldposY = World2Screen(SharedPoint)
        local count = math.random(3,5)
        for i = 1,count do
            local lz =  global.CustomCache:GetImage(expPng)  
            lz:setPosition(worldposX + math.random(-50, 50), worldposY + math.random(-50,50) + 180)
            sceneRoot:addChild(lz)
            lz:runAction(cc.Sequence:create(
                cc.MoveTo:create(1, targetPos),
                cc.CallFunc:create(function(sender) 
                    global.CustomCache:RmImage(lz)
                    if i == count then 
                        local anim2 = global.CustomCache:GetSFXAnim( 5058 ) 
                        if not anim2 then 
                            return 
                        end
                        sceneRoot:addChild(anim2)
                        anim2:setPosition(targetPos)
                        anim2:Play( 0, 0, false)
                        anim2:SetAnimEventCallback(function()
                            global.CustomCache:RmSFXAnim(anim2)
                        end)
                    end
                end )
            ))
        end
    end)
end

--飞向指定按钮
function ShowFakeDropItemsJustFly2(targetPos, items)
    local sceneRoot = global.sceneGraphCtl:GetSceneNode(SL:GetValue("GAME_DATA", "ItemFlyInTop") == 1 and global.MMO.NODE_UI_TOPMOST or global.MMO.NODE_UI_NORMAL)
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    local DROPITEM_RES_PATH   = "res/item"
    local DROPITEM_GROUND_RES_PATH   = "res/item_ground"
    local PUBLIC_UNDEFINE     = "un_define.pvr.ccz"
    local function createDropItem(index, item)
        local itemIndex = item.id or 1

        local itemData  = ItemConfigProxy:GetItemDataByIndex(itemIndex)
        local itemName  = ItemConfigProxy:GetItemNameByIndex(itemIndex)
        if not itemData then
            return nil
        end

        -- 资源路径
        local itemLooks = itemData.Looks or 1
        local groundFile = global.dropItemController:GetItemGroundFile(itemLooks)
        local dropItemTexc = global.CustomCache:GetImage(groundFile)
        local itemScale = SL:GetValue("GAME_DATA","itemGroundSacle") or (global.isWinPlayMode and 0.5 or 0.8)
    
        if not dropItemTexc then
            groundFile = string.format("%s/%s",DROPITEM_RES_PATH,PUBLIC_UNDEFINE) 
            dropItemTexc     = global.CustomCache:GetImage(groundFile)
            print( "Failed to load drop item avatar:"..fileName.."\n" )
        end

        local dropItemSprite   = dropItemTexc
        dropItemSprite:setScale(itemScale)
        --------------
        -- 计算初始坐标和目标坐标
        local pX, pY = global.sceneManager:MapPos2WorldPos(item.mapX, item.mapY, true)
        SharedPoint.x = pX
        SharedPoint.y = pY
        local worldposX, worldposY = World2Screen(SharedPoint)
        -- 创建道具图标
        local imageItem = dropItemSprite
        sceneRoot:addChild(imageItem)
        imageItem:setPosition(worldposX, worldposY)
        imageItem:setTag(index)
        imageItem:setVisible(false)
        ------------
        local function moveToTarget()
            local speed = 600
            local interval = 1/60
            local function callback()
                local curItemPos = cc.p(imageItem:getPosition())
                local distance  = speed * interval
                local destSub   = cc.pSub(targetPos, curItemPos)
                local flyDir    = cc.pNormalize(destSub)
                local displ     = cc.pMul(flyDir, distance)
                local posNew    = cc.pAdd(curItemPos, displ)
                imageItem:setPosition(posNew)

                local destDist  = cc.pGetLength(destSub)
                if destDist <= 3*distance then
                    global.CustomCache:RmImage(imageItem)
                    SLBridge:onLUAEvent(LUA_EVENT_FLYIN_BTN_ITEM_COMPLETE, {itemIndex = itemIndex})
                end
            end
            
            schedule(imageItem, callback, interval)
        end

        imageItem:runAction(cc.Sequence:create(cc.Show:create(), cc.CallFunc:create(moveToTarget)))
    end

    local scheduleNode = sceneRoot:getChildByName("SCHEDULE_NODE")
    if scheduleNode then
        scheduleNode:removeFromParent()
        scheduleNode = nil
    end
    scheduleNode = cc.Node:create()
    scheduleNode:setName("SCHEDULE_NODE")
    sceneRoot:addChild(scheduleNode)

    local starIndex = 0
    local maxCount = #items
    -- 间隔加载
    local function scheduleCreate(callfunc,delayTime)
        local oneTimeCount = 15
        starIndex = starIndex + 1
        if not callfunc or starIndex > maxCount then
            local scheduleNode = sceneRoot:getChildByName("SCHEDULE_NODE")
            if scheduleNode then
                scheduleNode:removeFromParent()
                scheduleNode = nil
            end
            return
        end
        local endIndex = math.min(starIndex+oneTimeCount-1,maxCount)
        performWithDelay(scheduleNode,function()
            for i = starIndex, endIndex, 1 do
                local item = items[i]
                if item then
                    callfunc(i, item)
                end
            end
            starIndex = endIndex
            scheduleCreate(callfunc)
        end,delayTime or 0.5)
    end

    scheduleCreate(createDropItem,0)
end

function ResetBagPos()
    local bagData = BagData.GetBagData()
    for k,v in pairs(bagData) do
        if v.StdMode == 2 then
            local isCanAddToQuick = QuickUseData.CheckItemCanAddToQuickUse(v)
            local quickUsePos = QuickUseData.CheckQuickUseHasEmpty()
            if isCanAddToQuick and quickUsePos then --快捷栏道具
                QuickUseData.AutoAddBagItemToQuick(v, quickUsePos)
            end
        end
    end
    local newData = BagData.GetBagData()
    BagData.AmendHistoryPos(true, newData)
    
    SL:onLUAEvent(LUA_EVENT_BAG_ITEM_LIST_REFRESH)
end

-- 添加全局回调事件
function AddGlobalScheduleFunc(funcMethodName, callback, interval)
    RmoveGlobalScheduleFunc(funcMethodName)
    interval = interval or 1
    globalSchedule[funcMethodName] = {
        sFunc =callback
    }
    globalSchedule[funcMethodName].scheuleId = Schedule( function()
        if globalSchedule[funcMethodName].sFunc then
            globalSchedule[funcMethodName]:sFunc()
        end
    end, interval)

    if callback then
        callback()
    end
end

-- 移除单个全局事件( funcMethodName: 函数名   没参数就删除所有的)
function RmoveGlobalScheduleFunc(funcMethodName)
    if funcMethodName then
        if globalSchedule[funcMethodName] then
            local scheuleId = globalSchedule[funcMethodName].scheuleId
            UnSchedule(scheuleId)
            globalSchedule[funcMethodName] = nil
        end
        return
    end
    globalSchedule = globalSchedule or {}
    for k,v in pairs(globalSchedule) do
        local scheuleId = v.scheuleId
        UnSchedule(scheuleId)
    end
    globalSchedule = {}
end

function SetCustomCursor(CursorType)
    if CursorType ~= global.CurrentCurSorType  then
        local path = ""
        if CursorType == global.MMO.CURSOR_TYPE_NORMAL then
            path = global.MMO.PATH_RES_PUBLIC.."CustomCursor1.png"
        elseif CursorType == global.MMO.CURSOR_TYPE_PK then
            path = global.MMO.PATH_RES_PUBLIC.."CustomCursor2.png"
        elseif CursorType == global.MMO.CURSOR_TYPE_NPC then 
            path = global.MMO.PATH_RES_PUBLIC.."CustomCursor3.png"
        end
        if setCustomCursor and cc.FileUtils:getInstance():isFileExist(path) then
            setCustomCursor(path) 
        end
        global.CurrentCurSorType = CursorType
    end
end

--刷新坐标变整数
function RefreshPositionByParent(layer)
    if global.isWinPlayMode then 
        local visitChildren
        local refPos = function(v)
            if not v.CheckAndLoadRes then
                local worldpos = v:convertToWorldSpace(zeroP)
                local newpos = cc.p(math.floor(worldpos.x), math.floor(worldpos.y))
                local pos = cc.p(v:getPosition())
                v:setPosition(cc.pAdd(pos, cc.pSub(newpos, worldpos)))
                local needRefChild = true
                if (v.InitWidgetConfig and tolua.type(v) == "ccui.Widget") or (v._unRefPos and tolua.type(v) == "ccui.ListView") then
                    needRefChild = false
                end
                -- UIModel
                if needRefChild and v:getName() == "baseNode" then
                    needRefChild = false
                end
                if needRefChild then
                    if #v:getChildren() > 0  then 
                        visitChildren(v)
                    end
                end
            end
        end
        visitChildren = function (parent) 
            for i,v in pairs(parent:getChildren()) do
                refPos(v)
            end
        end
        refPos(layer)
    end
end

-- 禁止聊天
function IsForbidSay(autoTaost)
    local envProxy = global.Facade:retrieveProxy( global.ProxyTable.GameEnvironmentProxy )
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local forbidChat = tonumber(envProxy:GetCustomDataByKey("forbidSay")) == 1 or LoginProxy:IsForbidChat() == true
    if forbidChat and autoTaost then
        ShowSystemTips(GET_STRING(30103600))
    end
    return forbidChat
end

-- 禁止取名
function IsForbidName(autoTaost)
    local envProxy = global.Facade:retrieveProxy( global.ProxyTable.GameEnvironmentProxy )
    local LoginProxy = global.Facade:retrieveProxy( global.ProxyTable.LoginProxy )
    local forbidName = tonumber(envProxy:GetCustomDataByKey("forbidName")) == 1 or LoginProxy:IsForbidName()
    if forbidName and autoTaost then
        ShowSystemTips(GET_STRING(30103600))
    end
    return forbidName
end


function IterAllChild(root, widget)
    for k,v in pairs(widget:getChildren()) do
        local name = v:getName()
        root[name] = v
        IterAllChild(root, v)
    end
end

-- 检测节点是否在容器内
function CheckNodeInInside(node, list)
    local visiblesize = list:getContentSize()
    local worSpacePos = list:getWorldPosition()
    local anchorPoint = list:getAnchorPoint()
    local lowPos = worSpacePos.y - visiblesize.height * anchorPoint.y
    local uprPos = lowPos + visiblesize.height
    local worldPos = node:getWorldPosition()
    if worldPos.y > lowPos and worldPos.y < uprPos then
        return true
    end
    return false
end

-- 获取控件可见状态
function GetWidgetVisible(widget)
    local isVisible = widget:isVisible()
    if not isVisible then
        return false
    end
    local parent = widget:getParent()
    if not parent then
        return true
    end
    return GetWidgetVisible(parent)
end

-- 校验对象合法性
function CheckObjValid(widget)
    if not widget then
        return false
    end
    if tolua.isnull(widget) then
        return false
    end
    return true
end

function GetReportUrl()
    local url = "https://juhe-h5.dhsf.xqhuyu.com/GB/index.html#/"
    local envProxy   = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    if envProxy then 
        local ReportDoamin = envProxy:GetCustomDataByKey("ReportDoamin")
        if ReportDoamin and string.len(ReportDoamin) > 0 then 
            url = ReportDoamin .. "/GB/index.html#/"
        end
    end
    local loginProxy    = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local AuthProxy     = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local envProxy      = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local currentModule = global.L_ModuleManager:GetCurrentModule()
    local currentSubMod = currentModule:GetCurrentSubMod()
    local userId        = AuthProxy:GetUID()
    local roleName      = loginProxy:GetSelectedRoleName()
    local roleId		= loginProxy:GetSelectedRoleID()
    local serverName    = loginProxy:GetSelectedServerName()
    local serverId      = loginProxy:GetSelectedServerId()
    local gameName      = currentModule:GetName()
    local subName       = currentSubMod:GetName() or ""
    local gameId        = currentModule:GetOperID()
    local channelId     = envProxy:GetChannelID()
    local showName      = string.len(subName) > 0 and ( gameName .. "_" .. subName ) or gameName
    local param =
        string.format("?uid=%s&rolename=%s&gamename=%s&gameid=%s&servername=%s&channelid=%s&roleid=%s&serverid=%s",
        EncodeToJP(userId),
        roleName,
        showName,
        gameId,
        serverName,
        channelId,
        EncodeToJP(roleId),
        EncodeToJP(serverId)
    )
    if global.isIOS then
        param = urlencodeT(param)
    end
    url = url..param
    return url
end

function IsInSideNode(node, touchPos)
    if tolua.isnull(node) or not next(touchPos) then
        return false
    end
    
    local size = node:getContentSize()
    local anr  = node:getAnchorPoint()
    local pos  = node:getWorldPosition()
    local boundBox = {x = pos.x - size.width * anr.x, y = pos.y - size.height * anr.y, width = size.width, height = size.height}
    
    return cc.rectContainsPoint(boundBox, touchPos)
end

function RestrictCapInsetRect(capInsets, textureSize)
    local x = capInsets.x;
    local y = capInsets.y;
    local width = capInsets.width
    local height = capInsets.height
    
    if textureSize.width < width then
        x = textureSize.width / 2
        width = textureSize.width > 0 and 1 or 0
    end

    if textureSize.height < height then
        y = textureSize.height / 2
        height = textureSize.height > 0 and 1 or 0
    end

    return {x = x, y = y, width = width, height = height}
end

-- 转换成偶数
function ConvertToEven(num, up)
    num = tonumber(num)
    if not num then
        return 0
    end
    return num % 2 == 1 and (up and num + 1 or num - 1) or num
end

--获取函数参数个数
function GetFucArgNums(fun)
    local num = 0
    local func = function()
        local hook = function( ... )
            local info = debug.getinfo(2)
            if not info.name then return end
            num = info.nparams
            debug.sethook()
        end
        debug.sethook(hook, "c")
        fun()
    end
    pcall(func)
    return num
end

--增加cocos自定义事件 跟node绑定 
function addCocosCustomEventListener(node, EventName, func)
    if not node then
        return 
    end 
    local customEventListener = cc.EventListenerCustom:create(EventName, func)
    global.EventDispatcher:addEventListenerWithSceneGraphPriority(customEventListener, node)
end

--派发cocos自定义事件
function dispatchCocosCustomEvent(EventName)
    global.EventDispatcher:dispatchCustomEvent(EventName)
end

--文件存在判断缓存
local _fileExistCache = {}
function G_GetFileExistCache(filePath)
    if _fileExistCache[filePath] == nil then
        _fileExistCache[filePath] = global.FileUtilCtl:isFileExist(filePath)
    end
    return _fileExistCache[filePath]
end


local _splitCache = {}
function G_GetSplitArray(oriStr, splitStr)
    if not splitStr or not oriStr then 
        return {}
    end
    _splitCache[splitStr] = _splitCache[splitStr] or {}
    local splitArray = _splitCache[splitStr]
    if not splitArray[oriStr] then 
        splitArray[oriStr] = ssplit(oriStr, splitStr)
    end
    return splitArray[oriStr]
end

-- 检查是否SL添加的地图特效
function CheckIsSLAddMapEffect(actorID, mapID)
    if not mapID or not actorID then
        return false
    end

    local data = SL.CustomMapEffects
    if not data or not next(data) then
        return false
    end

    local effectData = data[mapID] and data[mapID][actorID]
    if effectData then
        return true
    end

    return false
end

-- 检查是否需要添加SL加的地图特效
function CheckNeedAddSLMapEffect(lastMapID, mapID)
    local data = SL.CustomMapEffects
    if not data or not next(data) then
        return 
    end

    if data[lastMapID] and next(data[lastMapID]) then
        for id, data in pairs(data[lastMapID]) do
            global.sceneEffectManager:RmvSceneEffect(id)
            global.actorManager:RemoveActor(id)
        end
    end

    if data[mapID] and next(data[mapID]) then
        for id, item in pairs(data[mapID]) do
            local isInit  = false
            local actorID = id
            local mapX = item.x
            local mapY = item.y
            local sfxActor = global.actorManager:GetActor(actorID)
            if not sfxActor then
                isInit = true
                local paramSfx  = {}
                paramSfx.sfxId  = item.sfxId
                paramSfx.isLoop = item.loop
                paramSfx.type   = global.MMO.EFFECT_TYPE_SFX
                paramSfx.num    = item.num
                sfxActor = global.actorManager:CreateActor(actorID, global.MMO.ACTOR_SEFFECT, paramSfx, item.isBehind, item.isFront)
            end

            local pX, pY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
            sfxActor:setPosition(pX, pY)
            global.actorManager:SetActorMapXY(sfxActor, mapX, mapY)

            global.Facade:sendNotification( global.NoticeTable.DelayDirtyFeature, actorID)

            if isInit then
                global.sceneEffectManager:AddSceneEffect(sfxActor)
            end
        end
    end
end

-- 检查添加表配置的地图连接点特效
function CheckAddMapLinkEffect(lastMapID, mapID)
    local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    local data = mapProxy:GetMapLinkEffects(mapID)
    if not data or not next(data) then
        return 
    end

    if data[lastMapID] and next(data[lastMapID]) then
        for _, data in ipairs(data[lastMapID]) do
            local id = data.id
            global.sceneEffectManager:RmvSceneEffect(id)
            global.actorManager:RemoveActor(id)
        end
    end

    if data[mapID] and next(data[mapID]) then
        for _, param in ipairs(data[mapID]) do
            local isInit  = false
            local actorID = param.id
            local mapX = param.mapX
            local mapY = param.mapY
            local sfxActor = global.actorManager:GetActor(actorID)
            if not sfxActor then
                isInit = true
                local paramSfx  = {}
                paramSfx.sfxId  = param.effectID
                paramSfx.isLoop = true
                paramSfx.type   = global.MMO.EFFECT_TYPE_NORMAL
                sfxActor = global.actorManager:CreateActor(actorID, global.MMO.ACTOR_SEFFECT, paramSfx, false, true)
            end

            local pX, pY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
            sfxActor:setPosition(pX, pY)
            global.actorManager:SetActorMapXY(sfxActor, mapX, mapY)

            global.Facade:sendNotification(global.NoticeTable.DelayDirtyFeature, actorID)

            if isInit then
                global.sceneEffectManager:AddSceneEffect(sfxActor)
            end
        end
    end
end

function DeMix(script)
    local Is = type(script) == "table" and script.CMIX
    if not Is then
        return false, script
    end

    local content, num, _keys = script[1], script[2] or 0, script[3] or {}
    local Utf8len = UTF8.length
    local Utf8sub = UTF8.sub

    if global.FileUtilCtl:isFileExist("GUILayout/mixpack.lua") then
        SL.MixCfg = require("GUILayout/mixpack")
    else
        SL.MixCfg = {}
    end

    local keys = {
        "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"
    }
    local n = #keys
    for i = 1, #_keys do
        keys[n + i] = _keys[i]
    end

    local function Ugsub(str, find, replace)
        local have = function (char)
            local len = Utf8len(self, find)
            for i = 1, len do
                if Utf8sub(self, find, i, 1) == char then
                    return true
                end
            end
        end

        local strs = {}

        local len = Utf8len(self, str)
        for i = 1, len do
            local char = Utf8sub(self, str, i, 1)
            strs[i] = have(char) and replace or char
        end
        
        return tconcat(strs)
    end

    local len = Utf8len(self, content)
    local i = 1

    local cchar = string.cchar
    local cbyte = string.cbyte

    local pattern = nil
    for i = num, num + #keys do
        pattern = pattern and pattern .. cchar(i) or cchar(i)
    end

    pattern = pattern and "[" .. pattern .. "]"

    local strs = {}
    while i <= len do
        local s = Utf8sub(self, Utf8sub(self, content, i, len), 1, 1)
        local k = cbyte(s) or 0

        if k > 173 and k < 256 then
            strs[i] = Ugsub(s, pattern, keys[k - num])
        else
            strs[i] = s
        end

        i = i + 1
    end

    local result = tconcat(strs)

    result = sgsub(result, "(0xferrari)(%d+)", function (_, k)
        return tconcat({"[===[", SL.MixCfg[tonumber(k)], "]===]"})
    end)

    return true, result
end

function PrevewDevFile()
    local fileUtil = global.FileUtilCtl
    local load     = load
    local loaded   = package.loaded
    
    local filePath = "GUILayout/devpack.json"

    if not fileUtil:isFileExist(filePath) then
        return false
    end

    local jsonData = ReadJsonFile(filePath)
    if not jsonData then
        return false
    end

    local preLoad = function (file)
        local isMix, script = DeMix(require(file))
        if isMix and script then
            loaded[file] = load(script)
        end
    end

    local function update()
        local idx = 0
        local len = #jsonData

        preDevScheduleID = SL:Schedule(function ()
            idx = idx + 1

            if idx > len then
                return SL:UnSchedule(preDevScheduleID)
            end

            local file = jsonData[idx]

            if file and not loaded[file] and fileUtil:isFileExist(file .. ".lua") then
                preLoad(file) 
            end
            
        end, 0.01, false)
    end
    update()
end

function GetJoinNetTypeIndex(type, idx)
    return type * 10000 + idx
end

--小于version 返回小于0  等于返回0  大于返回大于0
function compareBoxVersion(version)
    if not version then 
        return -1
    end
    local boxVersion = global.L_GameEnvManager:GetEnvDataByKey("boxVersion")
    if not boxVersion then 
        return -1
    end
    if type(boxVersion) ~= "string" or type(version) ~= "string" then 
        return -1
    end
    local boxVArr = string.split(boxVersion, ".")
    local vArr = string.split(version, ".")
    local res = 0
    local v = 0
    local bv = 0
    for i,ver in ipairs(boxVArr) do
        v = tonumber(vArr[i]) or -1
        bv = tonumber(ver) or -1
        if v > bv then 
            return -1
        elseif v < bv then
            return 1 
        end  
    end
    return res
end

function ErrorDebugPrint(msg)
    SL:Print("----------------------------------------")
    SL:Print(msg)
    SL:Print(debug.traceback("", 2))
    SL:Print("----------------------------------------")
end