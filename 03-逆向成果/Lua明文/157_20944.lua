local UserInputController = class('UserInputController', framework.Mediator)
UserInputController.NAME = "UserInputController"

local sformat = string.format
local DEBUG_TOUCH = false

local function compareKeyCode(k1, k2, checkFullSort)
    if checkFullSort then
        if #k1 == #k2 then
            for i = 1, #k1 do
                local keyCode = k1[i]
                local isEqual = false
                for j = 1, #k2 do
                    if keyCode == k2[j] then
                        isEqual = true
                        break
                    end
                end
                if not isEqual then
                    return false
                end
            end
            return true
        else
            return false
        end
    end
    return (table.concat(k1, "+") == table.concat(k2, "+"))
end

function UserInputController:ctor()
    UserInputController.super.ctor(self, self.NAME)
    
    self._keyboardListener  = nil
    self._keyboardEvents    = {}
    self._keyboardAble      = true
    self._isPressedShift    = false
    self._isPressedCtrl     = false
    self._isPressedAlt      = false

    self._cursorPosition    = {x=0,y=0}
    self._touchListener     = nil
    self._touching          = false
end

function UserInputController:destory()
    if UserInputController.instance then
        global.Facade:removeMediator(UserInputController.NAME)
        UserInputController.instance = nil
    end
end

function UserInputController:Inst()
    if not UserInputController.instance then
        UserInputController.instance = UserInputController.new()
        global.Facade:registerMediator(UserInputController.instance)
    end

    return UserInputController.instance
end

function UserInputController:onRegister()
    UserInputController.super.onRegister(self)
    
    self:RegisterMouseMovingEvent()
end

function UserInputController:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return
    {

    }
end

function UserInputController:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()
end

function UserInputController:RegisterMouseMovingEvent()
    SL:RegisterLUAEvent(LUA_EVENT_LAYER_MOVED_MOVING, "UserInputController", handler(self, self.OnMouseMoved))
end

-------------------------------------------------------------------------------
function UserInputController:InitOnEnterLogin()
    self:ResetKeyboard()
    self:InitKeyCodeLogin()
    self:InitKeyCodeDebug()
end

function UserInputController:InitOnEnterRole()
    self:ResetKeyboard()
    self:InitKeyCodeLogin()
    self:InitKeyCodeDebug()
end

function UserInputController:InitOnEnterWorld()
    self:ResetKeyboard()
    self:InitKeyCodeWorld()
    self:InitKeyCodeDebug()

    self:ResetTouch()
    self:InitTouch()
end

function UserInputController:InitKeyCodeDebug()
    if not (global.isDebugMode or global.isGMMode) then
        return
    end

    -- reload lua files
    local pressedCB = function()
        package.loaded[ "init/initReload" ] = nil
        require("init/initReload")
        reload_script_files()
    end
    local keyCodes = {cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F5}
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB)

    
    -- debug map
    local pressedCB = function()
        global.Facade:sendNotification(global.NoticeTable.DebugMapSwitch)
    end
    local keyCodes = {cc.KeyCode.KEY_0}
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB)
    

    -- test layer
    local pressedCB = function()
        global.Facade:sendNotification(global.NoticeTable.Layer_RichTextTest_Open)
    end
    local keyCodes = {cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F10}
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB)


    -- preview anim
    local pressedCB = function()
        package.loaded["game/view/layersui/test_layer/PreviewAnimMediator"] = nil
        global.Facade:sendNotification(global.NoticeTable.PreviewAnimOpen)
    end
    local keyCodes = {cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F4}
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB)


    -- GUI Ediator
    local pressedCB = function()
        releaseLayerGUI("GUIEditor")
        global.Facade:sendNotification(global.NoticeTable.Layer_GUIEditor_Open)
    end
    local keyCodes = {cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F9}
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB)


    -- restart game
    local pressedCB = function()
        global.Facade:sendNotification(global.NoticeTable.RestartGame)
    end
    local keyCodes = {cc.KeyCode.KEY_SHIFT, cc.KeyCode.KEY_ESCAPE}
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB)


    -- SUIEditor
    local pressedCB = function()
        package.loaded["game/view/layersui/test_layer/SUIEditor"] = nil
        global.Facade:sendNotification(global.NoticeTable.SUIEditorOpen)
    end
    local keyCodes = {cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F11}
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB)


    -- config setting
    local pressedCB = function()
        global.Facade:sendNotification(global.NoticeTable.Layer_ConfigSetting_Open)
    end
    local keyCodes = {cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F6}
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB)

    
    -- node tree
    local pressedCB = function()
        global.Facade:sendNotification(global.NoticeTable.Layer_PreviewNode_Open)
    end
    local keyCodes = {cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F3}
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB)


    -- ExtraColorEditor
    local pressedCB = function()
        global.Facade:sendNotification(global.NoticeTable.Layer_ExtraColorEditor_Open)
    end
    local keyCodes = {cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F7}
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB)


    -- NetLogEnable
    local pressedCB = function()
        G_NetLogEnable = not G_NetLogEnable
    end
    local keyCodes = {cc.KeyCode.KEY_N}
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB)
end

function UserInputController:InitKeyCodeLogin()
    self:InitKeyboardListener()
    
    -- ENTER 确认当前界面
    local pressedCB = function()
        global.Facade:sendNotification(global.NoticeTable.Layer_Enter_Current)
    end
    local keyCodes = cc.KeyCode.KEY_ENTER
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB, nil, 0)
    local keyCodes = cc.KeyCode.KEY_KP_ENTER
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB, nil, 0)
end

function UserInputController:InitKeyCodeWorld()
    self:InitKeyboardListener()

    if not global.isWinPlayMode then
        return nil
    end

    ---------------------------------------------------------------------------

    -- shift+左键 持续攻击
    local pressedCB = function()
        self._isPressedShift = true
        global.Facade:sendNotification(global.NoticeTable.UserPressedShift)
    end
    local releaseCB = function()
        self._isPressedShift = false
        global.Facade:sendNotification(global.NoticeTable.UserReleaseShift)
    end
    local keyCodes = cc.KeyCode.KEY_LEFT_SHIFT
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB, releaseCB, -1)


    -- ctrl
    local pressedCB = function()
        self._isPressedCtrl = true
    end
    local releaseCB = function()
        self._isPressedCtrl = false
    end
    local keyCodes = cc.KeyCode.KEY_CTRL
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB, releaseCB, -1)


    -- ALT
    local pressedCB = function()
        self._isPressedAlt = true
    end
    local releaseCB = function()
        self._isPressedAlt = false
    end
    local keyCodes = cc.KeyCode.KEY_ALT
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB, releaseCB)

    -- ENTER 确认当前界面
    local pressedCB = function()
        global.Facade:sendNotification(global.NoticeTable.Layer_Enter_Current)
    end
    local keyCodes = cc.KeyCode.KEY_ENTER
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB, nil, 0)
    local keyCodes = cc.KeyCode.KEY_KP_ENTER
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB, nil, 0)


    -- ESC 关闭当前界面
    local pressedCB = function()
        local isClosedEx = false
        if GUIGlobal_ESCCloseWinEvent then
            isClosedEx = GUIGlobal_ESCCloseWinEvent()
        end
        
        if not isClosedEx then
            global.Facade:sendNotification(global.NoticeTable.Layer_Close_Current)
        end
    end
    local keyCodes = cc.KeyCode.KEY_ESCAPE
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB)

    --截图
    local keyCodes = {cc.KeyCode.KEY_PAUSE}
    local pressedCB = function()
        local FileUtils = global.FileUtilCtl
        local WritablePath = global.WritablePath
        local saveDir = WritablePath.."Images"
        if not  FileUtils:isDirectoryExist(saveDir) then
            FileUtils:createDirectory(saveDir)
        end
        local prepath = saveDir.."/capture"
        local begin = 1
        while(1) do
            local filename = string.format("%s%s.png",prepath,begin)
            if FileUtils:isFileExist(filename) then
                begin = begin + 1
            else
                cc.utils:captureScreen(function(isOK,path)
                    if isOK then
                        ShowSystemTips(string.format(GET_STRING(600000315),path))
                    end
                end, filename)
                break
            end   
        end
    end
    global.userInputController:AddKeyboardListener(keyCodes, pressedCB)


end
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function UserInputController:IsTouching()
    return self._touching
end

function UserInputController:SetIsTouching(t)
    self._touching = t
end

function UserInputController:IsKeyboardAble()
    return self._keyboardAble
end

function UserInputController:SetKeyboardAble(able)
    self._keyboardAble = able
end
-------------------------------------------------------------------------------

----------------------------------- listener ----------------------------------
function UserInputController:OnEventUserInput()
    global.Facade:sendNotification(global.NoticeTable.UserInputEventNotice)
    SLBridge:onLUAEvent(LUA_EVENT_USERINPUT_EVENT_NOTICE)
end
----------------------------------- listener ----------------------------------

----------------------------------- keycode -----------------------------------
function UserInputController:IsPressedShift()
    return self._isPressedShift
end

function UserInputController:IsPressedCtrl()
    return self._isPressedCtrl
end

function UserInputController:IsPressedAlt()
    return self._isPressedAlt
end

function UserInputController:ResetKeyboard()
    if not self._keyboardListener then
        return
    end
    local eventDispatcher = global.EventDispatcher
    eventDispatcher:removeEventListener(self._keyboardListener)

    self._keyboardEvents    = {}
    self._keyboardListener  = nil
    self._keyboardAble      = true
    self._isPressedShift    = false
    self._isPressedCtrl     = false
    self._isPressedAlt      = false
end

function UserInputController:InitKeyboardListener()
    local inputKeyCode = {}
    local function onEventPressedCB()
        if not self._keyboardAble then
            return
        end

        global.userInputController:OnEventUserInput()

        local count = #self._keyboardEvents
        for i = count, 1, -1 do
            local v = self._keyboardEvents[i]
            if compareKeyCode(inputKeyCode, v.keyCode, v.checkFullSort) then
                -- auto event pressed callback
                if v.interval and v.interval > 0 then
                    if nil == v.timerID then
                        v.timerID = Schedule(function()
                            global.userInputController:OnEventUserInput()

                            if v.pressedCB then
                                v.pressedCB(true)
                            end
                        end, v.interval)
                    end
                end

                -- 执行
                if v.pressedCB then
                    v.pressedCB()
                end

                break
            end
        end
    end

    local function onEventReleaseCB(keycode)
        global.userInputController:OnEventUserInput()

        -- 
        for _, v in ipairs(self._keyboardEvents) do
            if v.timerID then
                UnSchedule(v.timerID)
                v.timerID = nil
            end
        end

        -- releaseCB
        local count = #self._keyboardEvents
        for i = count, 1, -1 do
            local v = self._keyboardEvents[i]
            if compareKeyCode({keycode}, v.keyCode) then
                if v.releaseCB then
                    v.releaseCB()
                end
                break
            end
        end
    end

    local function pressed_callback(keycode, evt)
        table.insert(inputKeyCode, keycode)
        onEventPressedCB()
    end
    local function released_callback(keycode, evt)
        for k, v in pairs(inputKeyCode) do
            if v == keycode then
                table.remove(inputKeyCode, k)
            end
        end
        onEventReleaseCB(keycode)
    end
    self._keyboardListener = cc.EventListenerKeyboard:create()
    local eventDispatcher = global.EventDispatcher
    self._keyboardListener:registerScriptHandler(pressed_callback, cc.Handler.EVENT_KEYBOARD_PRESSED)
    self._keyboardListener:registerScriptHandler(released_callback, cc.Handler.EVENT_KEYBOARD_RELEASED)
    eventDispatcher:addEventListenerWithFixedPriority(self._keyboardListener, 1)
end

function UserInputController:AddKeyboardListener(keyCode, pressedCB, releaseCB, interval, checkFullSort)
    interval = interval or 1
    if not keyCode then
        print("ERROR++++++++++++++++++++++++, keyCode is empty")
        return
    end
    if type(keyCode) == "number" then
        local t = {}
        table.insert(t, keyCode)
        keyCode = t
    end
    local listener      = {}
    listener.keyCode    = keyCode
    listener.pressedCB  = pressedCB
    listener.releaseCB  = releaseCB
    listener.interval   = interval
    listener.checkFullSort = checkFullSort
    table.insert(self._keyboardEvents, listener)
end

function UserInputController:RmvKeyboardListener(keyCode)
    if type(keyCode) == "number" then
        local t = {}
        table.insert(t, keyCode)
        keyCode = t
    end

    local count = #self._keyboardEvents
    for i = count, 1, -1 do
        local v = self._keyboardEvents[i]
        if compareKeyCode(v.keyCode, keyCode) then
            table.remove(self._keyboardEvents, i)
            return true
        end
    end
    return false
end

function UserInputController:UpdateKeyboardListener(keyCode, pressedCB, releaseCB, interval)
    if not keyCode then
        print("ERROR++++++++++++++++++++++++, keyCode is empty")
        return
    end
    if type(keyCode) == "number" then
        local t = {}
        table.insert(t, keyCode)
        keyCode = t
    end
    for k, v in pairs(self._keyboardEvents) do
        if compareKeyCode(v.keyCode, keyCode, v.checkFullSort) then
            if pressedCB then v.pressedCB = pressedCB end
            if releaseCB then v.releaseCB = releaseCB end
            if interval then v.interval = interval end
            return true
        end
    end
    return false
end
----------------------------------- keycode -----------------------------------

----------------------------------- touch   -----------------------------------
function UserInputController:ResetTouch()
    if not self._touchListener then
        return nil
    end
    local eventDispatcher = global.EventDispatcher
    eventDispatcher:removeEventListener(self._touchListener)

    self._cursorPosition    = {x=0,y=0}
    self._touchListener     = nil
    self._touching          = false
end

function UserInputController:InitTouch()
    local labelDebug = nil
    if DEBUG_TOUCH then
        --********* Debug
        local visibleSize = global.Director:getVisibleSize()
        local origin = global.Director:getVisibleOrigin()
        local label = cc.Label:createWithTTF("", "fonts/font2.ttf", 24)
        labelDebug = label
        
        -- position the label on the center of the screen
        label:enableOutline(cc.Color4B.BLACK, 1)
        label:setAnchorPoint(cc.p(0.5, 1.0))
        label:setPosition(origin.x + visibleSize.width / 2, origin.y + visibleSize.height)
        global.sceneGraphCtl:GetUiNormal():addChild(label, 9991)
    end
    
    local function updateDebugInfoStr(position)
        if (labelDebug) then
            local touchPosX, touchPosY = Screen2World(position)
            if not touchPosX then
                return nil
            end
            -- [Debug] grid pos
            local mapX, mapY = global.sceneManager:WorldPos2MapPos(touchPosX, touchPosY)
            local wX, wY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
            
            local debugInfo = string.format("[Mx%d,My:%d][tx:%d,ty:%d]", mapX, mapY, wX, wY)
            labelDebug:setString(debugInfo)
        end
    end
    
    
    --********* Input (touch)
    local function began(touch, event)
        if not global.gamePlayerController:GetMainPlayer() then
            return false
        end

        local touchPos  = touch:getLocation()
        local touchWay  = global.MMO.MOVE_EVENT_TOUCH_AND_MOUSE_L
        local eventType = cc.Handler.EVENT_TOUCH_BEGAN
        global.actorPickerController:HandleTouchEndEvent(touchPos, touchWay, eventType)

        local data = {
            way = global.MMO.MOVE_EVENT_TOUCH_AND_MOUSE_L,
            pos = touch:getLocation()
        }
        global.Facade:sendNotification(global.NoticeTable.keepMovingBegin, data)
        return true
    end
    local function moved(touch, event)
        if (DEBUG_TOUCH) then
            updateDebugInfoStr(touch:getLocation())
        end
        
        if not global.gamePlayerController:GetMainPlayer() then
            return
        end
        
        local data = {
            way = global.MMO.MOVE_EVENT_TOUCH_AND_MOUSE_L,
            pos = touch:getLocation()
        }
        global.Facade:sendNotification(global.NoticeTable.keepMovingUpdate, data)
    end
    local function ended(touch, event)
        if (DEBUG_TOUCH) then
            updateDebugInfoStr(touch:getLocation())
        end
        
        if not global.gamePlayerController:GetMainPlayer() then
            return
        end
        global.Facade:sendNotification(global.NoticeTable.keepMovingEnded)
    end
    local function cancelled(touch, event)
        if (DEBUG_TOUCH) then
            updateDebugInfoStr(touch:getLocation())
        end
        
        if not global.gamePlayerController:GetMainPlayer() then
            return
        end
        global.Facade:sendNotification(global.NoticeTable.keepMovingEnded)
    end
    local dispatcher = global.EventDispatcher
    self._touchListener = cc.EventListenerTouchOneByOne:create()
    self._touchListener:registerScriptHandler(began, cc.Handler.EVENT_TOUCH_BEGAN)
    self._touchListener:registerScriptHandler(moved, cc.Handler.EVENT_TOUCH_MOVED)
    self._touchListener:registerScriptHandler(ended, cc.Handler.EVENT_TOUCH_ENDED)
    self._touchListener:registerScriptHandler(cancelled, cc.Handler.EVENT_TOUCH_CANCELLED)
    dispatcher:addEventListenerWithSceneGraphPriority(self._touchListener, global.gameWorldController)
end
----------------------------------- touch   -----------------------------------

----------------------------------- mouse event -------------------------------
function UserInputController:OnMouseMoved(data)
    self._cursorPosition = data.pos
end

function UserInputController:GetCursorPos()
    return self._cursorPosition
end
----------------------------------- mouse event -------------------------------

return UserInputController
