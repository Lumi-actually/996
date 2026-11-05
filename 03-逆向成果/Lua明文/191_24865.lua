local LayerFacadeMediator = class("LayerFacadeMediator", framework.Mediator)
LayerFacadeMediator.NAME = "LayerFacadeMediator"

local mmax = math.max
local tremove = table.remove

function LayerFacadeMediator:ctor()
    LayerFacadeMediator.super.ctor(self, self.NAME)

    self._normalMediators   = {}
    self._normalLayerLocalZ = {}
    self._allMediators      = {}
    self._hideMainCounting  = 0
end

function LayerFacadeMediator:Cleanup()
    self._normalMediators   = {}
    self._normalLayerLocalZ = {}
    self._allMediators      = {}
    self._hideMainCounting  = 0
end

function LayerFacadeMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return
    {
        noticeTable.Layer_Open,
        noticeTable.Layer_Close,
        noticeTable.Layer_Close_Current,
        noticeTable.Layer_Enter_Current,
        noticeTable.ReleaseMemory,
        noticeTable.ResolutionSizeChange,
        noticeTable.Layer_SetMoveEnable,
        noticeTable.Layer_HideMainEvent,
        noticeTable.Layer_SetZOrderPanel,
    }
end

function LayerFacadeMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeName = notification:getName()
    local noticeData = notification:getBody()

    if noticeTable.Layer_Open == noticeName then
        self:OpenLayer(noticeData)

    elseif noticeTable.Layer_Close == noticeName then
        self:CloseLayer(noticeData)

    elseif noticeTable.Layer_Close_Current == noticeName then
        self:CloseCurrentLayer()

    elseif noticeTable.Layer_Enter_Current == noticeName then
        self:EnterCurrentLayer()

    elseif noticeTable.Layer_SetMoveEnable == noticeName then
        self:SetLayerMoveEnable(noticeData)

    elseif noticeTable.ReleaseMemory == noticeName then
        self:Cleanup()

    elseif noticeTable.ResolutionSizeChange == noticeName then
        self:OnResolutionSizeChange()

    elseif noticeTable.Layer_HideMainEvent == noticeName then
        self:OnHideMainEvent(noticeData)

    elseif noticeTable.Layer_SetZOrderPanel == noticeName then
        self:SetLayerZPanel(noticeData)
    end
end

function LayerFacadeMediator:OnResolutionSizeChange()
    dispatchCocosCustomEvent(global.NoticeTable.ResolutionSizeChange)
end

function LayerFacadeMediator:resetLayerPos(mediator)
    local moveWidget = mediator._responseMoved or mediator._moveWidget
    if not moveWidget or tolua.isnull(moveWidget) or not mediator._layer then
        return false
    end

    local touchNodeSize = moveWidget:getContentSize()
    local touchNodeAnchor = moveWidget:getAnchorPoint()
    local worldPos = moveWidget:getWorldPosition()
    local winSize = global.Director:getWinSize()
    local offx = 0
    local offy = 0
    if winSize.width - worldPos.x < touchNodeSize.width * (1 - touchNodeAnchor.x) then --超右边
        offx = -(touchNodeSize.width * (1 - touchNodeAnchor.x) - winSize.width + worldPos.x)
    end

    if worldPos.x < touchNodeSize.width * touchNodeAnchor.x then --超左边
        offx = touchNodeSize.width * touchNodeAnchor.x - worldPos.x
    end

    if winSize.height - worldPos.y < touchNodeSize.height * (1 - touchNodeAnchor.y) then --超上边
        offy = -(touchNodeSize.height * (1 - touchNodeAnchor.y) - winSize.height + worldPos.y)
    end

    if worldPos.y < touchNodeSize.height * touchNodeAnchor.y then --超下边
        offy = touchNodeSize.height * touchNodeAnchor.y - worldPos.y
    end
    local layer = mediator._layer
    local pos = cc.p(layer:getPosition())
    layer:setPosition(pos.x + offx, pos.y + offy)
end

function LayerFacadeMediator:checkOutScreen(mediator)
    local moveWidget = mediator._responseMoved or mediator._moveWidget
    if not moveWidget or not mediator._layer then
        return false
    end
    local touchNodeSize = moveWidget:getContentSize()
    local touchNodeAnchor = moveWidget:getAnchorPoint()
    local worldPos = moveWidget:getWorldPosition()
    local winSize = global.Director:getWinSize()

    if worldPos.x - touchNodeSize.width * (touchNodeAnchor.x) < 0 then -- 超左边
        return true
    end

    if worldPos.x + touchNodeSize.width * (1 - touchNodeAnchor.x) > winSize.width then -- 超右边
        return true
    end

    if worldPos.y + touchNodeSize.height * (1 - touchNodeAnchor.y) > winSize.height then -- 超上边
        return true
    end

    if worldPos.y - touchNodeSize.height * (touchNodeAnchor.y) < 0 then   --超下边
        return true
    end

    return false
end

function LayerFacadeMediator:InitOnEnterActive(root)
    self.UINode = cc.Layer:create()
    root:addChild(self.UINode)

    self.UINodeNormal = cc.Layer:create()
    self.UINode:addChild(self.UINodeNormal, global.UIZ.UI_NORMAL)
end

function LayerFacadeMediator:InitOnEnterWorld()
    -- create game world scene
    global.sceneGraphCtl:LoadGraph("scene/game_world")
    local scene = global.sceneGraphCtl:GetC2dxScene()
    global.Director:replaceScene(scene)
    scene:addChild(global.gameWorldController)

    -- ui
    self.mainRoot = global.sceneGraphCtl:GetUiNormal() -- 主界面 root
    local cppUINode = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_UI_TOPMOST) -- ui root
    self.UINode = cc.Layer:create()
    cppUINode:addChild(self.UINode)

    self.UINodeNormal = cc.Layer:create()
    self.UINode:addChild(self.UINodeNormal, global.UIZ.UI_NORMAL)

    -- game world camera
    self:InitGameWorldCamera()

    global.Facade:sendNotification(global.NoticeTable.InitedWorldTree)

    GUI:SetGUIParent(0, self.UINodeNormal)
end

function LayerFacadeMediator:InitGameWorldCamera()
    local fov          = 60
    local zEye         = global.Director:getZEye()
    zEye = (global.isWinPlayMode and (zEye > global.MMO.CAMERA_Z_MAX_WIN)) and global.MMO.CAMERA_Z_MAX_WIN or zEye
    local winSize      = global.Director:getWinSize()
    local up           = cc.vec3( 0, 1, 0 )
    local center       = cc.vec3( winSize.width * 0.5, winSize.height * 0.5, 0 )
    local pos          = cc.vec3( center.x, center.y, zEye )
    local centerOfView = cc.p( winSize.width * 0.5, winSize.height * 0.5 )
    local aspectRatio  = winSize.width / winSize.height
    local cameraFar    = math.max(global.MMO.CAMERA_FAR, zEye / global.MMO.VIEW_SCALE_MIN + 1)
    local camera       = cc.Camera:createPerspective(fov, aspectRatio, global.MMO.CAMERA_NEAR, cameraFar)
    camera:setPosition3D( pos )
    camera:lookAt( center, up )
    camera:setCameraFlag( cc.CameraFlag.USER1 )

    local rootNode     = global.sceneGraphCtl:GetSceneNode( global.MMO.NODE_ROOT )
    local wordRootNode = global.sceneGraphCtl:GetSceneNode( global.MMO.NODE_GAME_WORLD )
    rootNode:addChild( camera )
    wordRootNode:setCameraMask( cc.CameraFlag.USER1, true )
    global.gameCameraController:SetViewCamera( camera )

    global.MMO.CAMERA_Z_DEFAULT = zEye
end

function LayerFacadeMediator:OpenLayer(data)
    local ltype     = data.ltype
    local layer     = data.layer
    local mediator  = data.mediator


    if ltype == global.UIZ.UI_NORMAL then
        -- hide last
        local mediatorCount = #self._normalMediators
        if mediator._hideLast and mediatorCount > 0 then
            local lastMediator = self._normalMediators[mediatorCount]
            lastMediator._layer:setVisible(false)
        end
        self._normalMediators[mediatorCount + 1] = mediator

        -- hide main
        if mediator._hideMain then
            if self._hideMainCounting == 0 then
                global.Facade:sendNotification(global.NoticeTable.Layer_Main_Hide)
            end
            self._hideMainCounting = self._hideMainCounting + 1
        end

        -- audio
        if mediator._voice then
            local slt = global.SLT.AudioPlayTable1
            slt.type = global.MMO.SND_TYPE_LAYER_CLICK
            global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
        end

        -- 点击浮起
        self:CreateSetZPanel(mediator)

        -- 设置坐标
        mediator._layer:setPosition(mediator:getResetPosition())
        mediator._layer:setLocalZOrder(mediatorCount + 1)

        -- addChild
        self.UINodeNormal:addChild(layer)

    elseif ltype == global.UIZ.UI_MAIN then
        self.mainRoot:addChild(layer, global.UIZ.UI_MAIN)
        if mediator._GUI_ID then
            -- 设置坐标
            mediator._layer:setPosition(mediator:getResetPosition())
        end

    elseif ltype == global.UIZ.UI_RTOUCH then
        self.mainRoot:addChild(layer, ltype)
        if global.mouseEventController and mediator._mouseBtnEvent then
            local children = layer:getChildren()
            for k, v in pairs(children) do
                local target = v:getChildByName("Panel_1")
                if target then
                    global.mouseEventController:registerMouseButtonEvent(target, mediator._mouseBtnParam)
                    break
                end
            end
        end

    elseif ltype then
        self.UINode:addChild(layer, ltype)
        if ltype == global.UIZ.UI_NOTICE and mediator._GUI_ID then
            -- 设置坐标
            mediator._layer:setPosition(mediator:getResetPosition())
        end
        if global.mouseEventController and mediator._mouseBtnEvent then
            local children = layer:getChildren()
            for k, v in pairs(children) do
                local target = v:getChildByName("Panel_1")
                if target then
                    global.mouseEventController:registerMouseButtonEvent(target, mediator._mouseBtnParam)
                    break
                end
            end
        end
    end

    -- for GUI
    if mediator._GUI_ID then
        mediator._layer.ID = mediator._GUI_ID
        mediator._layer.mediator = mediator

        GUI.WinLayers[mediator._GUI_ID] = mediator._layer
        GUI.ATTACH_PARENT = mediator._layer
        SLBridge:onLUAEvent(LUA_EVENT_OPENWIN, mediator._GUI_ID)
    end

    self._allMediators[#self._allMediators + 1] = mediator
end

function LayerFacadeMediator:CloseLayer(data)
    local ltype = data.ltype
    local layer = data.layer
    local mediator = data.mediator

    -- for GUI
    if mediator._GUI_ID then
        GUI.WinLayers[mediator._GUI_ID] = nil
        GUI.ATTACH_PARENT = nil
    end

    if ltype == global.UIZ.UI_NORMAL then
        -- remove from items
        local index = nil
        for k, v in pairs(self._normalMediators) do
            if mediator._mediatorName == v._mediatorName then
                tremove(self._normalMediators, k)
                index = k
                break
            end
        end

        -- 重新计算界面 Z 轴
        for k, v in pairs(self._normalMediators) do
            v:SetLocalZOrder(k)
        end

        -- for GUI
        -- 找到最后一个GUI，并设置为当前挂节点
        for i = #self._normalMediators, 1, -1 do
            local mediator = self._normalMediators[1]
            if mediator._GUI_ID then
                GUI.ATTACH_PARENT = mediator._layer
            end
        end

        -- show last
        if mediator._hideLast and index and (index - 1 > 0) then
            local lastMediator = self._normalMediators[index - 1]
            lastMediator._layer:setVisible(true)
        end

        -- show main
        if mediator._hideMain then
            self._hideMainCounting = self._hideMainCounting - 1
            self._hideMainCounting = mmax(self._hideMainCounting, 0)
            if self._hideMainCounting == 0 then
                global.Facade:sendNotification(global.NoticeTable.Layer_Main_Show)
            end
        end

        -- audio
        if mediator._voice then
            local slt = global.SLT.AudioPlayTable1
            slt.type = global.MMO.SND_TYPE_LAYER_CLOSE
            global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
        end
    end


    for k, v in pairs(self._allMediators) do
        if mediator._mediatorName == v._mediatorName then
            tremove(self._allMediators, k)
            break
        end
    end

    if not layer or tolua.isnull(layer) then
        if mediator._GUI_ID then
            releasePrint("[ERROR] GUI: " .. mediator._GUI_ID .. " Layer is Removed Before CloseLayer!  ")
        end
        return
    end
    layer:removeFromParent()
end

function LayerFacadeMediator:CloseCurrentLayer()
    local mediators = self._normalMediators
    if #mediators > 0 then
        local mediator = mediators[#mediators]
        if mediator._escClose then
            self:SetOnMovingOpacity(false)
            if mediator._GUI_ID and GUI.WinLayers[mediator._GUI_ID] then
                GUI:Win_Close(GUI.WinLayers[mediator._GUI_ID])
            else
                mediator:CloseLayer()
            end
        end
    end
end

function LayerFacadeMediator:EnterCurrentLayer()
    for i = #self._allMediators, 1, -1 do
        local mediator = self._allMediators[i]
        if mediator:handlePressedEnter() then
            return
        elseif mediator._handlePressedEnterFunc then
            return mediator._handlePressedEnterFunc()
        end
    end
    
    -- 主界面
    if SL:GetValue("IS_PC_OPER_MODE") then
        SLBridge:onLUAEvent(LUA_EVENT_MAIN_PROPERTY_ON_KEY_ENTER)
    end
end

function LayerFacadeMediator:ResetMediatorOrder(mediator)
    local mediatorCount = #self._normalMediators

    if mediatorCount == 0 then
        return
    end

    if self._normalMediators[mediatorCount]._mediatorName == mediator._mediatorName then
        return
    end

    -- 放到最后一个
    for k, v in pairs(self._normalMediators) do
        if mediator._mediatorName == v._mediatorName then
            tremove(self._normalMediators, k)
            break
        end
    end
    table.insert(self._normalMediators, mediator)

    -- 刷新 Z 轴
    for k, v in pairs(self._normalMediators) do
        v:SetLocalZOrder(k)
    end

    -- for GUI
    -- 找到最后一个GUI，并设置为当前挂节点
    for i = #self._normalMediators, 1, -1 do
        local mediator = self._normalMediators[1]
        if mediator._GUI_ID then
            GUI.ATTACH_PARENT = mediator._layer
        end
    end

    UIOperator:CloseItemTips()
end

function LayerFacadeMediator:UpdateLayerPosition(mediator)

    local historyPos = mediator:getResetPosition()
    if mediator._moveWidget then
        local touchNodeSize = mediator._moveWidget:getContentSize()
        local touchNodeAnchor = mediator._moveWidget:getAnchorPoint()
        local worldPos = mediator._moveWidget:getWorldPosition()
        local winSize = global.Director:getWinSize()
        local overx = false
        local overy = false
        if winSize.width - (worldPos.x) < touchNodeSize.width * (1 - touchNodeAnchor.x) then --超右边
            overx = true
        end

        if worldPos.x < touchNodeSize.width * touchNodeAnchor.x then --超左边
            overx = true
        end

        if winSize.height - (worldPos.y) < touchNodeSize.height * (1 - touchNodeAnchor.y) then --超上边
            overy = true
        end

        if worldPos.y < touchNodeSize.height * touchNodeAnchor.y then --超下边
            overy = true
        end

        if overx or overy then
            mediator._layer:setPosition(0, 0)
        end
    end

end

function LayerFacadeMediator:InitLayerPostionLimit(mediator, moveWidget)
    -- 预留rect 50 50
    local minRect = { width = 80, height = 80 }
    local maxX = 0
    local minX = 0
    local maxY = 0
    local minY = 0

    if moveWidget and not tolua.isnull(moveWidget) then
        local touchNodeSize = moveWidget:getContentSize()
        local touchNodeAnchor = moveWidget:getAnchorPoint()
        local worldPos = moveWidget:getWorldPosition()
        local winSize = global.Director:getWinSize()

        maxX = winSize.width + touchNodeSize.width * touchNodeAnchor.x - minRect.width - worldPos.x
        minX = -(worldPos.x + touchNodeSize.width * (1 - touchNodeAnchor.x) - minRect.width)

        maxY = winSize.height + touchNodeSize.height * touchNodeAnchor.y - minRect.height - worldPos.y
        minY = -(worldPos.y + touchNodeSize.height * (1 - touchNodeAnchor.y) - minRect.height)
    end

    mediator.maxX = maxX or 0
    mediator.minX = minX or 0
    mediator.maxY = maxY or 0
    mediator.minY = minY or 0

    ----
    local originPosX, originPosY
    if mediator._layer then
        originPosX, originPosY = mediator._layer:getPosition()
    end
    mediator.originPosX = originPosX or 0
    mediator.originPosY = originPosY or 0

end

function LayerFacadeMediator:CreateSetZPanel(mediator)
    local layer = mediator._layer
    local children = layer:getChildren()
    local panel = nil
    local parent = nil
    for k, v in pairs(children) do
        local target = v:getChildByName("Panel_1")
        if target then
            panel = target
            parent = v
            break
        end
    end
    if parent and panel and global.mouseEventController then
        global.mouseEventController:registerMouseMoveEvent(panel)

        if mediator._mouseBtnEvent then
            global.mouseEventController:registerMouseButtonEvent(panel, mediator._mouseBtnParam)
        end

        local size = panel:getContentSize()
        local anchor = panel:getAnchorPoint()
        local posx = panel:getPositionX()
        local posy = panel:getPositionY()
        local settingZ = ccui.Widget:create()
        settingZ:setAnchorPoint(anchor)
        settingZ:setContentSize(size)
        settingZ:setPosition(posx, posy)
        settingZ:setTouchEnabled(true)
        settingZ:addTouchEventListener(
        function(sender, event)
            if event == ccui.TouchEventType.began then
                self:ResetMediatorOrder(mediator)
            end
        end
        )
        settingZ:setSwallowTouches(false)
        parent:addChild(settingZ)
    end
end

function LayerFacadeMediator:SetLayerZPanel(data)
    local mediator = data.mediator
    local panel = data.zPanel
    local parent = panel:getParent()
    if parent and panel and global.mouseEventController then
        global.mouseEventController:registerMouseMoveEvent(panel)

        if mediator._mouseBtnEvent then
            global.mouseEventController:registerMouseButtonEvent(panel, mediator._mouseBtnParam)
        end

        local size = panel:getContentSize()
        local anchor = panel:getAnchorPoint()
        local posx = panel:getPositionX()
        local posy = panel:getPositionY()
        local settingZ = ccui.Widget:create()
        settingZ:setAnchorPoint(anchor)
        settingZ:setContentSize(size)
        settingZ:setPosition(posx, posy)
        settingZ:setTouchEnabled(true)
        settingZ:addTouchEventListener(
        function(sender, event)
            if event == ccui.TouchEventType.began then
                self:ResetMediatorOrder(mediator)
            end
        end
        )
        settingZ:setSwallowTouches(false)
        parent:addChild(settingZ)
    end
end

function LayerFacadeMediator:SetLayerMoveEnable(data)
    local layer = data.layer
    local mediator = data.mediator
    local moveWidget = data.moveWidget
    if not layer or not mediator or not moveWidget then
        return nil
    end

    mediator._moveWidget = moveWidget
    self:UpdateLayerPosition(mediator)
    self:InitLayerPostionLimit(mediator, moveWidget)

    local function checkPos(x, y)
        if x >= mediator.maxX then
            x = mediator.maxX
        elseif x <= mediator.minX then
            x = mediator.minX
        end
        if y >= mediator.maxY then
            y = mediator.maxY
        elseif y <= mediator.minY then
            y = mediator.minY
        end
        return x, y
    end

    local isMoved = false
    local isPressed = false
    local function delayCallback()
        if not moveWidget or isPressed then
            return
        end

        if not isMoved then
            self:SetOnMovingOpacity(true)
            return
        end
        local sPos = moveWidget:getTouchBeganPosition()
        local ePos = moveWidget:getTouchMovePosition()

        local diff = cc.pSub(ePos, sPos)
        local distSq = cc.pLengthSQ(diff)
        if distSq <= 100 then
            isPressed = true
            self:SetOnMovingOpacity(true)
        end
    end

    local function ontouch(sender, event)
        if event == ccui.TouchEventType.began then
            mediator.basePosX, mediator.basePosy = layer:getPosition()
            isMoved = false
            isPressed = false
            sender:stopAllActions()
            performWithDelay(sender, delayCallback, 2)
            -- 设置当前界面为层级最高
            self:ResetMediatorOrder(mediator)
        elseif event == ccui.TouchEventType.moved then
            local sPos = sender:getTouchBeganPosition()
            local ePos = sender:getTouchMovePosition()
            local x = mediator.basePosX + ePos.x - sPos.x - mediator.originPosX
            local y = mediator.basePosy + ePos.y - sPos.y - mediator.originPosY
            x, y = checkPos(x, y)
            layer:setPosition(x + mediator.originPosX, y + mediator.originPosY)

            local diff = cc.pSub(ePos, sPos)
            local distSq = cc.pLengthSQ(diff)
            if not isMoved and distSq > 100 then
                isMoved = true
                self:SetOnMovingOpacity(true)
            end
        elseif event == ccui.TouchEventType.ended or event == ccui.TouchEventType.canceled then
            sender:stopAllActions()

            local endPosX, endPosY = layer:getPosition()
            endPosX, endPosY = checkPos(endPosX, endPosY)
            mediator.__savedPosX = endPosX
            mediator.__savedPosY = endPosY
            self:SetOnMovingOpacity(false)
        end
    end
    moveWidget:setTouchEnabled(true)
    moveWidget:addTouchEventListener(ontouch)
    addCocosCustomEventListener(moveWidget, global.NoticeTable.ResolutionSizeChange, function()
        self:resetLayerPos(mediator)
    end)
end

function LayerFacadeMediator:SetOnMovingOpacity(isBegin)
    if CHECK_SETTING and CHECK_SETTING(global.MMO.SETTING_IDX_LAYER_OPACITY) ~= 1 then
        return
    end
    if isBegin == self.OnMovingOpacity then
        return
    end
    self.OnMovingOpacity = isBegin
    local node_list = {}
    local function seach_child(parente)
        local childCount = parente:getChildrenCount()
        if childCount >= 1 then
            for i = 1, childCount do
                seach_child(parente:getChildren()[i])
            end
        end
        table.insert(node_list, parente)
    end
    seach_child(self.UINodeNormal)

    for i, v in ipairs(node_list) do
        v:setCascadeOpacityEnabled(isBegin)
    end
    self.UINodeNormal:setOpacity(isBegin and 150 or 255)
end

function LayerFacadeMediator:GetLayerLocalZorder(mediator)
    local removeKey = nil
    local maxn = table.maxn(self._normalLayerLocalZ)
    for k, v in pairs(self._normalLayerLocalZ) do
        if v == mediator._mediatorName then
            removeKey = k
            break
        end
    end
    if removeKey and maxn and removeKey == maxn then
        return -1
    elseif removeKey then
        self._normalLayerLocalZ[removeKey] = nil
    end
    local newLayerZorder = maxn + 1
    self._normalLayerLocalZ[newLayerZorder] = mediator._mediatorName
    return newLayerZorder
end

function LayerFacadeMediator:OnHideMainEvent(mediator)
    if mediator._hideMain then
        if self._hideMainCounting == 0 then
            global.Facade:sendNotification(global.NoticeTable.Layer_Main_Hide)
        end
        self._hideMainCounting = self._hideMainCounting + 1
    else
        self._hideMainCounting = self._hideMainCounting - 1
        self._hideMainCounting = mmax(self._hideMainCounting, 0)
        if self._hideMainCounting == 0 then
            global.Facade:sendNotification(global.NoticeTable.Layer_Main_Show)
        end
    end
end

function LayerFacadeMediator:resetLayerPostion(mediator)
    if mediator and mediator._layer then
        mediator._layer:setPosition(mediator:getResetPosition())
    end
end

return LayerFacadeMediator