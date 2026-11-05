local ModuleChooseLayer = class("ModuleChooseLayer", function ()
    return cc.Layer:create()
end)

local cjson = require("cjson")

local tinsert = table.insert
local tremove = table.remove

local fixBtnPos = cc.p(950, 310)

local hasRoleGroup = -99

local boxSignKey = "A2909DBDB94111F0B43D0242AC110009" -- key

ModuleChooseLayer.CountOfPage = 200
ModuleChooseLayer.path = "res_launcher/private/server/"
ModuleChooseLayer.publicPath = "res_launcher/public/"

ModuleChooseLayer.DownloadFlag = 
{
    Logo = 1,
    AgeTips = 2,
    LogoMini = 3,
    LogoMini2 = 4,
}

local function TextCreateRichText(parent, str)
    parent:setString("")
    parent:removeAllChildren()

    local visibleSize   = global.Director:getVisibleSize()
    local RichTextHelp  = requireLauncher( "init/RichTextHelp" )
    local colorRGB      = parent:getTextColor()
    local color         = string.format("#%02x%02x%02x", colorRGB.r, colorRGB.g, colorRGB.b)
    local maxWidth      = global.IS_PORTRAIT and visibleSize.width or 2000
    local richText      = RichTextHelp:CreateRichTextWithXML(str, maxWidth, parent:getFontSize() or 18, color)
    richText:setName("RICH_TEXT_")
    richText:formatText()
    richText:setAnchorPoint({x=0.5, y=0})
    parent:addChild(richText)
    if global.IS_PORTRAIT then
        local pSize = parent:getContentSize()
        richText:setPosition(pSize.width / 2, 0)
    end

    richText:setOpenUrlHandler( function(sender, url)
        cc.Application:getInstance():openURL(url)
    end )
end

local function drawButtonColorStyle(sender, config)
    local labelRenderer = sender:getTitleRenderer()

    -- button
    sender:setTitleFontSize(config.fontSize)

    -- 字体大小
    local lastTTFConfig    = labelRenderer:getTTFConfig()
    lastTTFConfig.fontSize = config.fontSize
    labelRenderer:setTTFConfig( lastTTFConfig )

    -- 字体颜色
    labelRenderer:setTextColor(config.color)

    -- 描边颜色和大小
    if config.outlineColor and config.outlineSize then
        labelRenderer:enableOutline(config.outlineColor, config.outlineSize)
    end
end

local function drawTextColorStyle(sender, config)
    local labelRenderer = sender:getVirtualRenderer()

    sender:setFontSize(config.fontSize)

    -- 字体大小
    local lastTTFConfig    = labelRenderer:getTTFConfig()
    lastTTFConfig.fontSize = config.fontSize
    labelRenderer:setTTFConfig( lastTTFConfig )

    -- 字体颜色
    labelRenderer:setTextColor(config.color)

    -- 描边颜色和大小
    if config.outlineColor and config.outlineSize then
        labelRenderer:enableOutline(config.outlineColor, config.outlineSize)
    end
end

--哈希表转成按数组
local function HashToSortArray(hashTab, sortFunc)
    if hashTab == nil or type(hashTab) ~= "table" then
        return nil
    end

    local sortTable = {}
    for _, v in pairs(hashTab) do
        tinsert(sortTable, v)
    end
    if sortFunc then
        table.sort(sortTable, sortFunc)
    end
    return sortTable
end

local function createQuickCell(data)
    local wid           = data.wid
    local hei           = data.hei
    local callback      = data.callback

    local widget        = ccui.Widget:create()
    widget:setContentSize({width=wid, height=hei})
    widget:setAnchorPoint({x=0, y=0})

    local quickCell     = {}
    quickCell.widget    = widget
    quickCell.callback  = callback
    quickCell.actived   = false

    local visibleSize   = cc.Director:getInstance():getVisibleSize()
    local function refresh()
        local worldPos  = widget:getWorldPosition()
        local active    = (worldPos.y <= visibleSize.height + hei and worldPos.y >= -hei )
        if active then
            if not quickCell.actived then
                quickCell.actived= active

                local cell = quickCell.callback()
                cell:setAnchorPoint({x=0.5, y=0.5})
                cell:setPosition({x=wid/2, y=hei/2})
                widget:removeAllChildren()
                widget:addChild(cell)
            end
        else
            if quickCell.actived then
                quickCell.actived= active
                widget:removeAllChildren()
            end
        end
    end

    quickCell.exit      = function()
        quickCell.actived = false
        refresh()
    end

    local delay = cc.DelayTime:create(0.02)
    local sequence = cc.Sequence:create(delay, cc.CallFunc:create(refresh))
    local action = cc.RepeatForever:create(sequence)
    widget:runAction(action)

    return quickCell
end

local function getAgreementState()
    local launcherModID = global.L_ModuleManager:GetLauncherModuleID()
    local channelID     = tostring(global.L_GameEnvManager:GetChannelID())
    local userData      = UserData:new(launcherModID .. channelID .. "_data")
    local agreement     = userData:getIntegerForKey("agreement", 0)
    return tonumber(agreement) or 0
end

local function isAutoLaunchEnable()
    -- windows平台生效
    if cc.Application:getInstance():getTargetPlatform() ~= cc.PLATFORM_OS_WINDOWS then
        return false
    end

    -- 是否有字段启动的字段
    -- 给qq大厅自动启动
    local autoBoot = global.L_GameEnvManager:GetEnvDataByKey("isAutoBoot")
    if not autoBoot then
        return false
    end
    return true
end

function ModuleChooseLayer:ctor()
    self._subModCells   = {}        -- module
    self._currentModule = nil       -- 当前module
    self._currentSubMod = nil       -- 当前subMod

    self._group         = -1        -- 当前选择组
    self._gservers      = {}        -- 服务器，根据组分开的
    self._groupCells    = {}        -- 组条目
    self._serverCells   = {}        -- 服务器条目
    self._loginedCells  = {}        -- 已登录条目
    self._serverCache   = {}        -- 缓存池

    self._announceUI    = nil
    self._agreementUI   = nil

    self._existLastMod  = false     -- 是否有上次选择模块，用以区分新老用户

    self._releaseFlag   = false

    self._srvlistCount  = 0
    self._customCount  = 0
    self._launchTimerID = nil
    self._srvlistTimerID = nil
    self._srvlistTime    = 10*60
end

function ModuleChooseLayer.create()
    local layer = ModuleChooseLayer.new()
    if layer:Init() then
        return layer
    end
    return nil
end

function ModuleChooseLayer:Init()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    if global.IS_PORTRAIT then
        self._isPortrait = true
        self._root = CreateExport_launcher("server/all_modules_portrait")
    else
        self._root = CreateExport_launcher("server/all_modules")
    end
    if not self._root then
        return false
    end
    self:addChild(self._root)
    self.ui = ui_delegate(self._root)

    
    self.ui.Image_login_bg:setContentSize(visibleSize)

    self.ui.Panel_bg:setVisible(false)

    self:InitCustomUI()
    self:InitCode()
    self:InitLaunch()
    self:InitServers()

    self:InitAllModules()
    self:InitLauncherVersion()

    self:SelectDefaultModule()

    self:ShowLaunch()
    self:HideServers()
    self:UpdateSelected()

    self.ui.Image_icon:setVisible(false)
    self.ui.Panel_agreement:setVisible(false)
    self.ui.Image_age_tips:setVisible(false)
    self.ui.Text_auth_tips:setVisible(false)
    
    self.ui.Panel_launch:setSwallowTouches(false)

    -- logo mini
    self._imageLogoMini = ccui.ImageView:create()
    self.ui.Panel_launch:addChild(self._imageLogoMini)
    self._imageLogoMini:setAnchorPoint(0.5, 0)
    local logoPos = cc.p(330, 460)
    if self._isPortrait then 
        logoPos = cc.p(296,650)
    end
    self._imageLogoMini:setPosition(logoPos)
    self._imageLogoMini:setVisible(false)

    -- logo mini2
    local posx, posy     = self.ui.Button_logout:getPosition()
    self._imageLogoMini2 = ccui.ImageView:create()
    self._imageLogoMini2:loadTexture( imgPath )
    self._imageLogoMini2:setAnchorPoint( 0.5, 0.5 )
    self._imageLogoMini2:setPosition( posx + 50, posy + 60 )
    self.ui.Panel_bg:addChild( self._imageLogoMini2,-1 )
    self._imageLogoMini2:setVisible(false)
    
    if self._isPortrait then 
        fixBtnPos = cc.p(554,710)
    end
    local showResolution = global.L_GameEnvManager:GetEnvDataByKey("showResolution")
    local otherResolution = global.L_GameEnvManager:GetEnvDataByKey("otherResolution")
    if global.isDebugMode or global.isGMMode or showResolution then
        local buttonPlatform = ccui.Button:create()
        self.ui.Panel_launch:addChild(buttonPlatform)
        local platformOffsetY = 140
        if self._isPortrait then 
            platformOffsetY = 350
        end
        buttonPlatform:setPosition(cc.p(fixBtnPos.x, fixBtnPos.y - platformOffsetY))
        buttonPlatform:loadTextureNormal(self.path .. "btn_jryx_02.png",0)
        buttonPlatform:loadTexturePressed(self.path .. "btn_jryx_02_1.png",0)
        buttonPlatform:setTitleFontName("fonts/font.ttf")
        buttonPlatform:setTitleFontSize(18)
        local btnTextStr = global.CURRENT_OPERMODE == global.OPERMODE_WINDOWS and "电脑端" or "手机端"
        btnTextStr       = fixNewLanguageString( btnTextStr )
        buttonPlatform:setTitleText(btnTextStr)
        buttonPlatform:setTouchEnabled(true)
        buttonPlatform:addClickEventListener(function()
            global.CURRENT_OPERMODE = (global.CURRENT_OPERMODE == global.OPERMODE_WINDOWS and global.OPERMODE_MOBILE or global.OPERMODE_WINDOWS)
            buttonPlatform:setTitleText(btnTextStr)

            -- 
            local resolution = (global.CURRENT_OPERMODE == global.OPERMODE_WINDOWS) and "1024x768" or "1136x640"
            global.L_GameEnvManager:SetGameEnvDataByKey("resolution", resolution)
            global.L_GameEnvManager:SetGameEnvDataByKey("oper_mode", global.CURRENT_OPERMODE)
            global.L_GameEnvManager:RestartGame()
        end)
        drawButtonColorStyle(buttonPlatform, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})

        if showResolution then
            buttonPlatform:setVisible(false)
        end
        -- 
        if global.CURRENT_OPERMODE == global.OPERMODE_WINDOWS then
            local buttonResolution = ccui.Button:create()
            self.ui.Panel_launch:addChild(buttonResolution)
            buttonResolution:setPosition(cc.p(fixBtnPos.x-100, fixBtnPos.y - platformOffsetY))
            buttonResolution:loadTextureNormal(self.path .. "btn_jryx_02.png",0)
            buttonResolution:loadTexturePressed(self.path .. "btn_jryx_02_1.png",0)
            buttonResolution:setTitleFontName("fonts/font.ttf")
            buttonResolution:setTitleFontSize(18)
            buttonResolution:setTitleText(string.format("%s x %s", global.DesignSize_Win.width, global.DesignSize_Win.height))
            buttonResolution:setTouchEnabled(true)
            buttonResolution:addClickEventListener(function()
                local resolutions = 
                {
                    {width = 1136, height = 640},
                }

                if otherResolution and string.len( otherResolution ) > 0 then
                    local data = string.split( otherResolution, "|" )
                    for _, v in ipairs(data) do
                        if v and v ~= "" then
                            local size = string.split( v, "x" )
                            if size and tonumber(size[1]) and tonumber(size[2]) then
                                table.insert( resolutions,{width = tonumber(size[1]), height = tonumber(size[2]) } )
                            end
                        end
                    end
                end

                local newresolution = resolutions[1]
                for k, v in pairs(resolutions) do
                    if v.width == global.DesignSize_Win.width and v.height == global.DesignSize_Win.height then
                        local index   = (k == #resolutions and 1 or k+1)
                        newresolution = resolutions[index]
                        break
                    end
                end
                global.L_GameEnvManager:SetGameEnvDataByKey("resolution", string.format("%sx%s", newresolution.width, newresolution.height))
                global.L_GameEnvManager:SetGamePreEnvDataByKey("resolution", string.format("%sx%s", newresolution.width, newresolution.height))
                global.L_GameEnvManager:RestartGame()
            end)
            drawButtonColorStyle(buttonResolution, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})
        end
    end

    -- 监听window size change
    if global.isWindows and not global.isBoxLogin then
        self._windowResizedListener = cc.EventListenerCustom:create("glview_window_resized", handler( self, self.onWindowResized ))
        global.Director:getEventDispatcher():addEventListenerWithFixedPriority(self._windowResizedListener, 1)
    end

    -- 10min，执行退出SDK/返回盒子
    self.ui.Panel_launch:runAction(cc.Sequence:create(cc.DelayTime:create(10*60), cc.CallFunc:create(function()
        if global.isBoxLogin and global.L_NativeBridgeManager.GN_finishGame and not global.isWindows then
            global.L_NativeBridgeManager:GN_finishGame()
            return
        end
        if tonumber(global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin")) == 1 and global.L_GameEnvManager:GetEnvDataByKey("isCloudLogin") then
            return
        end
        global.L_NativeBridgeManager:GN_accountLogout()
        global.L_GameEnvManager:RestartGame()
    end)))

    self:InitGameList()

    return true
end

function ModuleChooseLayer:InitGameList()
    self.ui.Panel_webview:setVisible(false)
    
    local winSize = global.Director:getWinSize()
    self.ui.Panel_webview:setContentSize(winSize.width, winSize.height)
    self.ui.Panel_webview_tips:setPosition(winSize.width / 2 , winSize.height / 2)
    self.ui.Panel_webview_tips:setVisible(false)
    self.ui.Panel_webview:addClickEventListener(function ()
        -- self:HideGameList()
    end)
    self.ui.Button_exit_wait:addClickEventListener(function ()
        self:HideGameList()
    end)

    self.ui.Image_web_wait:runAction(cc.RepeatForever:create(cc.RotateBy:create(1.5, 360)))
end

function ModuleChooseLayer:HideGameList()
    self.ui.Panel_webview:setVisible(false)
    self.ui.Panel_webview_tips:setVisible(false)
    if self._webView then 
        self._webView:removeFromParent()
        self._webView = nil
    end
end

function ModuleChooseLayer:onWindowResized( eventCustom )
    global.L_GameEnvManager:RestartGame()
end

function ModuleChooseLayer:InitCustomUI()
    local lastBtnPosX,lastBtnPosY = nil,nil
    if self.ui.Button_fix then
        lastBtnPosX,lastBtnPosY = self.ui.Button_fix:getPosition()
    end
    local Button_delete_account = ccui.Button:create()
    self.ui.Panel_launch:addChild(Button_delete_account)
    Button_delete_account:setPosition(cc.p(lastBtnPosX or fixBtnPos.x, lastBtnPosY and (lastBtnPosY-70) or fixBtnPos.y))
    Button_delete_account:loadTextureNormal(self.path .. "btn_jryx_02.png",0)
    Button_delete_account:loadTexturePressed(self.path .. "btn_jryx_02_1.png",0)
    Button_delete_account:setTitleFontName("fonts/font.ttf")
    Button_delete_account:setTitleFontSize(18)
    local btnTextStr = fixNewLanguageString( "注销账号" )
    Button_delete_account:setTitleText(btnTextStr)
    Button_delete_account:setTouchEnabled(true)
    Button_delete_account:setVisible(false)
    self.ui.Button_delete_account = Button_delete_account
end

function ModuleChooseLayer:LaunchModule()
    releasePrint("++++++++++++++++++++++++++++launch module")
    -- 
    ShowLoadingBar(1)

    self.ui.Button_launch:setTouchEnabled(false)
    self.ui.Button_launch:runAction(cc.Sequence:create(
        cc.DelayTime:create(3), 
        cc.CallFunc:create(function() self.ui.Button_launch:setTouchEnabled(true) end))
    )

    -- 未勾选用户协议
    if not self.BoxAutoEnterGame  and self.ui.CheckBox_agreement and not self.ui.CheckBox_agreement:isSelected() then
        global.L_SystemTipsManager:ShowTips("请仔细阅读下方协议并勾选")

        -- 弹出用户协议提示  上报自定义事件
        local dataParam = {
            event={time=os.time(),name = "openNotice_agreement",type = "track"}
        }

        local userId = global.L_GameEnvManager:GetEnvDataByKey("user_id") or global.L_GameEnvManager:GetEnvDataByKey("uid")
        if userId and userId ~= "" then
            dataParam.user = {id = userId}
        end

        global.L_DataRePort:SendRePortData( dataParam )
        return
    end
    
    -- 未曾登录
    if not self.BoxAutoEnterGame and global.isMobile and (1 ~= global.L_NativeBridgeManager:GetLoginState()) then
        global.L_NativeBridgeManager:GN_accountLogin()
        return
    end 

    if not self._currentModule or not self._currentSubMod then
        global.L_SystemTipsManager:ShowTips("未选择游戏模块！")
        return
    end

    local modGameEnv        = self._currentSubMod:GetGameEnv()
    local serverData        = modGameEnv:GetServerData()
    local selectedServer    = modGameEnv:GetSelectedServer()
    if modGameEnv:IsNewServerlist() and not modGameEnv:GetCustomIsLoaded() then 
        releasePrint("custom还未获取!")
        return 
    end

    -- 未选择服务器
    if not selectedServer then
        global.L_SystemTipsManager:ShowTips("请选择服务器!")
        return nil
    end

    -- 维护且不是白名单
    if selectedServer.state == 4 and (not modGameEnv:IsWhitelist()) then
        global.L_SystemTipsManager:ShowTips("服务器正在维护中，请选择其它服务器!")
        return
    end

    -- 登录数据
    local username = global.L_NativeBridgeManager:GetUsername()
    local password = global.L_NativeBridgeManager:GetPassword()
    modGameEnv:SetLoginData({username = username, password = password})

    -- 选择的服务器存储到本地
    modGameEnv:SaveLastServers()

    -- 上次选择模块存储本地
    local launcherModID = global.L_ModuleManager:GetLauncherModuleID()
    local channelID     = tostring(global.L_GameEnvManager:GetChannelID())
    local userData      = UserData:new(launcherModID .. channelID .. "_data")
    userData:setStringForKey("last_module", self._currentModule:GetID())
    userData:setStringForKey("last_submod", self._currentSubMod:GetID())
    userData:writeMapDataToFile()

    -- 发起一个请求, 请求启动游戏
    local modGameEnv        = self._currentSubMod:GetGameEnv()
    local serverData        = modGameEnv:GetServerData()
    local selectedServer    = modGameEnv:GetSelectedServer()
    local server_id         = selectedServer.serverId
    local server_name       = selectedServer.serverName

    -- 进入游戏, 上报自定义事件
    local dataParam = {
        event = {
            time = os.time(), name = "clickButton_enter", type = "track"
        },
        properities = {
            servid = tostring(server_id), server_name = tostring(server_name)
        }
    }

    local main_servid  = selectedServer and selectedServer.mainServerId
    local main_server_name = selectedServer and selectedServer.mainServerName
    
    dataParam.properities.main_servid = main_servid and tostring(main_servid) or tostring(server_id)
    dataParam.properities.main_server_name = main_server_name and tostring(main_server_name) or tostring(server_name)

    local userId = global.L_GameEnvManager:GetEnvDataByKey("user_id") or global.L_GameEnvManager:GetEnvDataByKey("uid")
    if userId and userId ~= "" then
        dataParam.user = {id = userId}
    end

    global.L_DataRePort:SendRePortData( dataParam )

    local jData = {}
    jData.gameid        = self._currentSubMod:GetOperID()
    jData.id            = self._currentSubMod:GetID()
    jData.name          = self._currentSubMod:GetName()
    jData.channelID     = tostring(global.L_GameEnvManager:GetChannelID())
    jData.server_id     = server_id
    jData.server_name   = server_name
    jData.userId        = global.L_GameEnvManager:GetEnvDataByKey("user_id") or ""
    global.L_NativeBridgeManager:GN_requestAllowLaunch(jData)


    -- run game
    if self._launchTimerID then
        UnSchedule(self._launchTimerID)
        self._launchTimerID = nil
    end
    local function scheduleCB()
        -- 不允许进入
        if not global.L_NativeBridgeManager:CheckAllowLaunch() then
            return false
        end
    
        -- 未选择模块
        if not self._currentModule or not self._currentSubMod then
            return false
        end

        -- 停止定时器
        if self._launchTimerID then
            UnSchedule(self._launchTimerID)
            self._launchTimerID = nil
        end

        -- 停止srvlist自动刷新定时器
        if self._srvlistTimerID then
            UnSchedule(self._srvlistTimerID)
            self._srvlistTimerID = nil
        end

        -- 数据上报
        local jData = {}
        jData.gameid        = self._currentSubMod:GetOperID()
        jData.id            = self._currentSubMod:GetID()
        jData.name          = self._currentSubMod:GetName()
        jData.subModID      = self._currentSubMod:GetID()
        jData.moduleID      = self._currentModule:GetID()
        jData.version       = self._currentModule:GetVersion()
        jData.originVersion = self._currentModule:GetOriginVersion()
        jData.cacheVersion  = self._currentModule:GetCacheVersion()
        jData.channelID     = tostring(global.L_GameEnvManager:GetChannelID())
        jData.server_id     = selectedServer.serverId
        jData.server_name   = selectedServer.serverName
        global.L_NativeBridgeManager:GN_selectGameMod(jData)

        if self._windowResizedListener then
            global.Director:getEventDispatcher():removeEventListener( self._windowResizedListener )
            self._windowResizedListener = nil
        end
        -- 进入了
        self._currentModule:RegisterSubMod(self._currentSubMod:GetID())
        global.L_ModuleManager:RegisterModuleByID(self._currentModule:GetID())
        global.L_ModuleManager:CheckModuleLocalStorage()
    end
    self._launchTimerID = Schedule(scheduleCB, 0.1)

    -- 停止定时器，目的是为了停止自动执行退出游戏操作
    self.ui.Panel_launch:stopAllActions()
end

function ModuleChooseLayer:checkAutoLaunchGameMod()
    if not isAutoLaunchEnable() then
        return
    end

    if tonumber(global.L_GameEnvManager:GetEnvDataByKey("auto_agreement_select")) == 1 then
        self.ui.CheckBox_agreement:setSelected(true)
    end
    -- 倒计时3s自动登录  新玩家1s   老玩家6s
    local newPlayerDelay = tonumber(global.L_GameEnvManager:GetEnvDataByKey("auto_new_player_delay")) or 1
    local oldPlayerDelay = tonumber(global.L_GameEnvManager:GetEnvDataByKey("auto_old_player_delay")) or 6
    local isNewPlayer = self._existLastMod == false
    local delay = isNewPlayer and newPlayerDelay or oldPlayerDelay
    local function callback()
        self.ui.Button_launch:setTitleText(string.format("进入游戏(%s)", delay))
        delay   = delay - 1
        if delay == 0 then
            self:LaunchModule()
        end
    end

    local action = self.ui.Button_launch.ctdownAction
    self.ui.Button_launch:stopAction( action )
    local sequence = cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(callback))
    action   = cc.RepeatForever:create(sequence)
    self.ui.Button_launch:runAction(action)
    self.ui.Button_launch.ctdownAction = action
    callback()

    self:touchTerminateAutoButton()
end

function ModuleChooseLayer:terminateAutoLaunchGameMod()
    if not isAutoLaunchEnable() then
        return
    end

    local action = self.ui.Button_launch.ctdownAction
    if action then
        self.ui.Button_launch:stopAction( action )
        action = nil
    end

    self.ui.Button_launch:setTitleText("进入游戏")
end

-- 创建触摸层    用来停止自动按钮
function ModuleChooseLayer:touchTerminateAutoButton()
    if self._tochAutoPanel then
        return
    end

    local panel = ccui.Layout:create()
    panel:setContentSize( global.Director:getVisibleSize() )
    panel:setTouchEnabled( true )
    panel:setSwallowTouches( false )

    self:addChild( panel,999 )

    self._tochAutoPanel = panel

    panel:addClickEventListener( function()
        self:terminateAutoLaunchGameMod()
    end)

end

function ModuleChooseLayer:InitCode()
    local items = {
        ["1212"] = function()
            -- 开启帧率
            global.Director:setDisplayStats(true)
        end,
        ["333333333"] = function()
            -- 开启远程测试
            local console = global.Director:getConsole()
            console:listenOnTCP( 9999 )
        end,
        ["222222"] = function()
            local ipurl = "https://sdkv2.dhsf.xqhuyu.com/api/data/client_ip"
            if self._currentSubMod then
                local modGameEnv    = self._currentSubMod:GetGameEnv()
                local customData    = modGameEnv:GetCustomDataByKey("clientIPUrl")
                if customData and string.len(customData) > 0 then
                    ipurl           = customData
                end
            end

            if ipurl and string.len(ipurl) > 0 then
                HTTPRequest(ipurl, function(success, response)
                    if success then
                        HideLoadingBar()

                        local modGameEnv = self._currentSubMod:GetGameEnv()
                        modGameEnv:SetSelfip(response)

                        global.L_SystemTipsManager:ShowTips(response)
                    end
                end)
            end
            ShowLoadingBar()
        end,
        ["4444"] = function()
            global.L_GameEnvManager:RestartGame()
        end
    }

    local input     = ""
    local viewSize  = global.Director:getVisibleSize()
    local width     = viewSize.width
    local height    = viewSize.height
    local pos       = {cc.p(25, height - 25), cc.p(width - 25, height - 25), cc.p(25, 25), cc.p(width - 25, 25)}
    for index = 1, 4 do
        local layout = ccui.Layout:create()
        self:addChild(layout)
        layout:setTouchEnabled(true)
        
        layout:setContentSize(50, 50)
        layout:setAnchorPoint(cc.p(0.5, 0.5))
        layout:setPosition(pos[index])
        layout:addClickEventListener(
            function()
                input = input .. tostring(index)
                for k, callback in pairs(items) do
                    if string.find(input, k) then
                        global.L_SystemTipsManager:ShowTips(k)
                        input = ""
                        callback()
                        break
                    end
                end
            end
        )
    end
end

function ModuleChooseLayer:InitLaunch()
    -------------------------------------------------------------
    local isBoxLogin = global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin")
    global.isBoxLogin = isBoxLogin == 1

    local isUgc = global.L_GameEnvManager:GetEnvDataByKey("isUgc")
    global.isUgc = isUgc == 1
    self:updateBoxUI()

    -- 切换账号按钮文本可替换
    local buttonName = global.L_GameEnvManager:GetEnvDataByKey("logoutName")
    if buttonName and buttonName ~= "" then
        local btnTextStr = fixNewLanguageString( buttonName )
        self.ui.Button_logout:setTitleText(btnTextStr)
    end
    ----------------------------------------------------------------
    -- 进入游戏
    self.ui.Button_launch:addClickEventListener(function()
        -- 迅雷检测游戏实名
        if global.L_NativeBridgeManager:PCCheckMedthodName("GN_checkRealName") then
            local envMgr = global.L_GameEnvManager
            local env_uid = envMgr:GetEnvDataByKey("user_id") or ""
            local data = {
                userId     = tostring( env_uid )
            }
            global.L_NativeBridgeManager:PCNoticeRequest("GN_checkRealName",data)
            return
        end

        self:LaunchModule()
    end)
    
    local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
    if  shiwan and tonumber(shiwan) == 1 then 
        self.ui.Button_select:setTouchEnabled(false)
    end
    -- 上次区服
    self.ui.Button_select:addClickEventListener(function()
        self:HideLaunch()
        self:ShowServers()
        self:UpdateServers()
    end)


    -- 切换账号/返回盒子
    if not global.isBoxLogin then
        self.ui.Button_logout:setVisible(false)
    end
    self.ui.Button_logout:addClickEventListener(function()
        if (global.isBoxLogin or global.isUgc) and global.L_NativeBridgeManager.GN_finishGame and not global.isWindows then
            global.L_NativeBridgeManager:GN_finishGame()
            return
        end
        global.L_NativeBridgeManager:GN_accountLogout()
        global.L_GameEnvManager:RestartGame()
    end)

    -- 游戏大厅（盒子）
    self.ui.Button_game_list:addClickEventListener(function()
        if global.isBoxLogin and self._supportGameList then
            --游戏大厅
            self:ShowGameList()
        end
    end)

    -- 游戏公告
    self.ui.Button_announce:addClickEventListener(function()

        self:ShowModuleAnnounce()
    end)

    -- 注销账号
    if self.ui.Button_delete_account then
        self.ui.Button_delete_account:setVisible(false)
        self.ui.Button_delete_account:addClickEventListener(function()
            if global.L_NativeBridgeManager.GN_deleteAccount then
                global.L_NativeBridgeManager:GN_deleteAccount()
            end
        end)
    end

    -- 游戏修复
    self.ui.Button_fix:addClickEventListener(function()
        local function callback( aType, custom )
            if aType == 1 then
                -- cleanup
                local fileUtil = cc.FileUtils:getInstance()
                local writePath = fileUtil:getWritablePath()
                fileUtil:removeDirectory( writePath )
                fileUtil:purgeCachedEntries()

                releasePrint("+++++++++++++++++++++++++++++isBoxLogin, isCloudLogin  ", global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin"), global.L_GameEnvManager:GetEnvDataByKey("isCloudLogin"))
                local mode = nil
                if global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin") and global.L_GameEnvManager:GetEnvDataByKey("isCloudLogin") then
                    mode = "cold"
                end
                global.L_NativeBridgeManager:GN_accountLogout()
                global.L_GameEnvManager:RestartGame(mode)
            end
        end
        local tipsData      = {}
        tipsData.str        = "当补丁缺失或其他显示异常问题，可尝试在此进行\n修复。（此操作会清理本地补丁并重新下载，请在\n良好的网络环境下进行）"
        tipsData.btnType    = 2
        tipsData.callback   = callback
        global.L_CommonTipsManager:OpenLayer(tipsData)
    end)

    -- 分享游戏
    self.ui.Button_share:setVisible(false)
    self.ui.Button_share:addClickEventListener(function()

        if not self._currentModule or not self._currentSubMod then
            return nil
        end
        local modGameEnv  = self._currentSubMod:GetGameEnv()
        if not modGameEnv then
            return nil
        end
        local shareUrl    = modGameEnv:GetCustomDataByKey("shareUrl")
        local isShowShare = shareUrl and shareUrl ~= ""
        if not isShowShare then
            return nil
        end
        cc.Application:getInstance():openURL(shareUrl)
    end)

    -- 用户协议
    self.ui.Button_agreement:setVisible(false)
    self.ui.Button_agreement:addClickEventListener(function()

        self:ShowAgreement()
    end)

    -- 用户协议复选框
    self.ui.CheckBox_agreement:addEventListener(function(sender)
        local isSelected = sender:isSelected()
        local userData = UserData:new("agreement_data")
        userData:setIntegerForKey("select", isSelected and 1 or 0)
        userData:writeMapDataToFile()

        -- 用户协议复选框点击  上报自定义事件
        local dataParam = {
            event={time=os.time(),name = "tickNotice_agreement",type = "track"}
        }

        local userId = global.L_GameEnvManager:GetEnvDataByKey("user_id") or global.L_GameEnvManager:GetEnvDataByKey("uid")
        if userId and userId ~= "" then
            dataParam.user = {id = userId}
        end

        global.L_DataRePort:SendRePortData( dataParam )

        if not self._currentModule or not self._currentSubMod then
            return
        end

        local modGameEnv  = self._currentSubMod:GetGameEnv()
        if not modGameEnv then
            return
        end

        local agreementSetURL = modGameEnv:GetCustomDataByKey("agreementSetURL") or ""
        if agreementSetURL and string.len(agreementSetURL) > 0 then
            local userId = global.L_GameEnvManager:GetEnvDataByKey("user_id") or global.L_GameEnvManager:GetEnvDataByKey("uid") or ""
            local gameId = self._currentSubMod:GetOperID() or ""

            local postData = {
                userId = userId,
                gameId = gameId,
                body = {
                    userId = userId,
                    gameId = gameId,
                    action = isSelected and 1 or 0
                },
            }
            -- 协议勾选状态
            HTTPRequestPostByBoxSign(agreementSetURL, postData, boxSignKey, function(success, response, code)
                releasePrint("agreement checkbox change: ", tostring(success), tostring(response), tostring(code))
            end)
        end
    end)

    -- 版号
    local copyright1 = ""
    local copyright2 = ""
    self.ui.Text_copyright:setString(copyright1 .. "\n" .. copyright2)
    self.ui.Text_copyright:setVisible(false)

    -- 健康游戏
    self.ui.Text_health:setVisible(false)
    self.ui.Text_health_tips:setVisible(false)

    -- logo
    self.ui.Image_icon:setVisible(false)

    -- 版本号
    local visibleSize = global.Director:getVisibleSize()
    if self._isPortrait then
        local y = self.ui.ListView_modules:getPositionY() 
        self.ui.Text_ver_launcher:setPositionY(y + 30)
    else
        self.ui.Text_ver_launcher:setPositionY(640-5)
    end
    
    self.ui.Text_ver_launcher:setFontSize(16)
    self.ui.Text_ver_launcher:setVisible(false)
    self.ui.Text_ver_module:setVisible(false)

    drawButtonColorStyle(self.ui.Button_launch, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})
    drawButtonColorStyle(self.ui.Button_logout, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})
    drawButtonColorStyle(self.ui.Button_announce, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})
    drawButtonColorStyle(self.ui.Button_fix, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})
    drawButtonColorStyle(self.ui.Button_share, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})
    drawButtonColorStyle(self.ui.Button_agreement, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)}) 
    drawButtonColorStyle(self.ui.Button_game_list, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})   
    drawButtonColorStyle(self.ui.Button_select, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})     
    drawButtonColorStyle(self.ui.Button_game, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})       
    
    if self.ui.Button_delete_account then
        drawButtonColorStyle(self.ui.Button_delete_account, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})
    end
end

function ModuleChooseLayer:ShowLaunch()
    self.ui.Panel_launch:setVisible(true)
end

function ModuleChooseLayer:HideLaunch()
    self.ui.Panel_launch:setVisible(false)
end

function ModuleChooseLayer:InitAllModules()
    self.ui.ListView_modules:removeAllItems()

    local allSubMods = {}
    local allModules = global.L_ModuleManager:GetAllModules()
    for _, module in ipairs(allModules) do
        for _, subMod in ipairs(module:GetSubMods()) do
            table.insert(allSubMods, {module = module, subMod = subMod})
        end
    end
    for k, v in ipairs(allSubMods) do
        local key = string.format("%s_%s", v.module:GetID(), v.subMod:GetID())
        local cell = self:CreateModuleCell(v)
        self._subModCells[key] = cell
        self.ui.ListView_modules:pushBackCustomItem(cell.nativeUI)
    end

    self.ui.ListView_modules:setVisible(#allSubMods > 1)

    -- 审核服，隐藏多版本
    if global.L_GameEnvManager:IsReview() then
        self.ui.ListView_modules:setVisible(false)
    end
end

function ModuleChooseLayer:CreateModuleCell(data)
    local root   = CreateExport_launcher("server/module_cell")
    local layout = root:getChildByName("Panel_1")
    layout:removeFromParent()

    local module = data.module
    local subMod = data.subMod

    local cell   = ui_delegate(layout)

    cell.Button_1:setTitleText(subMod.name)
    cell.Button_1:addClickEventListener(function()
        self:OnSelectModule(module, subMod)
    end)
    drawButtonColorStyle(cell.Button_1, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})

    return cell
end

function ModuleChooseLayer:SelectDefaultModule()
    local defaultModule = nil

    -- 存储文件
    local launcherModID = global.L_ModuleManager:GetLauncherModuleID()
    local channelID     = tostring(global.L_GameEnvManager:GetChannelID())
    local userData      = UserData:new(launcherModID .. channelID .. "_data")

    -- env 传入
    if not defaultModule then
        local envModID      = global.L_GameEnvManager:GetEnvDataByKey("modID")
        if envModID and string.len(envModID) > 0 then
            defaultModule   = global.L_ModuleManager:GetModuleByID(envModID)
        end
    end

    -- 上次
    if not defaultModule then
        local lastModuleID  = userData:getStringForKey("last_module", nil)
        if lastModuleID and string.len(lastModuleID) > 0 then
            defaultModule   = global.L_ModuleManager:GetModuleByID(lastModuleID)

            self._existLastMod = true
        end
    end

    -- 推荐
    if not defaultModule then
        local referModuleID = global.L_ModuleManager:GetReferModuleID()
        if referModuleID and string.len(referModuleID) > 0 then
            defaultModule   = global.L_ModuleManager:GetModuleByID(referModuleID)
        end
    end

    -- 第一个
    if not defaultModule then
        local allModule     = global.L_ModuleManager:GetAllModules()
        defaultModule       = allModule[1]
    end


    -- 子模块
    local defaultSubMod = nil

    -- env 传入
    if defaultModule and not defaultSubMod then
        local subModID      = global.L_GameEnvManager:GetEnvDataByKey("subModID", nil)
        if subModID and string.len(subModID) > 0 then
            defaultSubMod   = defaultModule:GetSubModByID(subModID)
        end
    end

    -- 盒子启动的
    local boxConfig = global.L_GameEnvManager:GetEnvDataByKey("boxConfig")
    if not defaultSubMod and boxConfig and boxConfig ~= "" then
        local isJson = false
        local findS, findE = string.find(boxConfig, "^{(.-)}$")
        if findS and findE and findE > findS then
            isJson = true
        end
        local jsonData = isJson and cjson.decode(boxConfig)
        if jsonData and jsonData.gameId then
            local allModules = global.L_ModuleManager:GetAllModules()
            for _, module in ipairs(allModules) do
                for _, subMod in ipairs(module:GetSubMods()) do
                    if subMod:GetOperID() == jsonData.gameId then
                        defaultSubMod = subMod
                        break
                    end
                end

                if defaultSubMod then
                    break
                end
            end
        end
    end

    -- 上次
    if defaultModule and not defaultSubMod then
        local lastSubModID  = userData:getStringForKey("last_submod", nil)
        if lastSubModID and string.len(lastSubModID) > 0 then
            defaultSubMod   = defaultModule:GetSubModByID(lastSubModID)
        end
    end

    -- 推荐
    if defaultModule and not defaultSubMod then
        local referModuleID = defaultModule:GetRefer()
        if referModuleID and string.len(referModuleID) > 0 then
            defaultSubMod   = defaultModule:GetSubModByID(referModuleID)
        end
    end

    -- 第一个
    if defaultModule and not defaultSubMod then
        local subMods       = defaultModule:GetSubMods()
        defaultSubMod       = subMods[1]
    end


    -- 选择
    if defaultModule and defaultSubMod then
        self:OnSelectModule(defaultModule, defaultSubMod)
    end

end

function ModuleChooseLayer:GetServerTime()
    GetModListServerTime(true, self._currentSubMod)
end

function ModuleChooseLayer:OnSelectModule(module, subMod)
    self._currentModule = module
    self._currentSubMod = subMod

    self:GetServerTime()
    
    -- 检测modeInfoURL合法性
    global.L_DataRePort:RequestModeInfoCheck(subMod)

    self:UpdateCurrentModule()

    self:checkAutoLaunchGameMod()

    for k, v in pairs(self._subModCells) do
        local moduleCell = self._subModCells[k]

        local key = string.format("%s_%s", module:GetID(), subMod:GetID())
        local able = (k == key)
        local path = string.format(self.path .. "%s.png", able and "btn_jryx_03" or "btn_jryx_03_1")
        moduleCell.Button_1:loadTextureNormal(path)
        moduleCell.Button_1:setTouchEnabled(not able)
    end

    -- request server data
    local modGameEnv = subMod:GetGameEnv()
    if not modGameEnv:GetServerData() then
        self:RequestModSrvlist(true)
    else
        self:UpdateServers()
        self:UpdateSelected()
        if modGameEnv:GetCustomIsLoaded() then 
            self:OnCustomData(false)
        end
    end

    -- 通知native，当前选择的模块发生改变(注意！！进游戏第一次选择也会通知，比accountLogin更早)
    local jsonData      = {}
    jsonData.channelId  = tostring(global.L_GameEnvManager:GetChannelID())
    jsonData.gameid     = self._currentSubMod:GetOperID()
    jsonData.id         = self._currentSubMod:GetID()
    jsonData.name       = self._currentSubMod:GetName()
    jsonData.subModID   = self._currentSubMod:GetID()
    jsonData.moduleID   = self._currentModule:GetID()
    jsonData.gameidlist = global.L_ModuleManager:GetAllGameID()
    global.L_NativeBridgeManager:GN_SendGameInfo(jsonData)

    -- 获取新app数据通知native
    global.L_MultiVersionData:GetNewAppData( subMod )

    -- 设备登录  上报自定义事件
    global.L_DataRePort:UpDeviceLogin(self._currentSubMod)
end

function ModuleChooseLayer:UpdateCurrentModule()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local channelID         = tostring(global.L_GameEnvManager:GetChannelID())
    local launcherMod       = global.L_ModuleManager:GetLauncherModule()
    local lOringinVersion   = launcherMod:GetOriginVersion()
    local lRemoteVersion    = launcherMod:GetRemoteVersion()
    local originVersion     = self._currentModule:GetOriginVersion()
    local cacheVersion      = self._currentModule:GetCacheVersion()
    local versionStr = string.format("%s (%s/%s) (%s/%s)", channelID, lOringinVersion, lRemoteVersion, originVersion, cacheVersion)
    self.ui.Text_ver_launcher:setString(versionStr)

    -- logo
    self:UpdateLogo()
    local subModInfo    = self._currentSubMod:GetSubModInfo()
    local logoInfo      = subModInfo.logo
    local downloadFlag  = self.DownloadFlag.Logo
    if logoInfo and logoInfo.name and logoInfo.name ~= "" and logoInfo.url and logoInfo.url ~= "" then
        global.L_GameEnvManager:downloadResEasy(logoInfo.url, logoInfo.name, function(isOK, filename)
            if global.L_GameLayerManager._uiNode then
                global.L_ModuleChooseManager:OnDownloadResCB(isOK, filename, downloadFlag)
            end
        end)
    end

    -- logo mini
    local logoInfoMini  = subModInfo.logo_mini
    -- local isBoxLogin = global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin")
    -- if isBoxLogin == 1 then --盒子登录 取对应平台的版号logo
    --     if global.isWindows then
    --         logoInfoMini  = subModInfo.logo_mini_box_pc
    --     else
    --         logoInfoMini  = subModInfo.logo_mini_box
    --     end  
    -- end
    local downloadFlag  = self.DownloadFlag.LogoMini
    if logoInfoMini and logoInfoMini.name and logoInfoMini.name ~= "" and logoInfoMini.url and logoInfoMini.url ~= "" then
        global.L_GameEnvManager:downloadResEasy(logoInfoMini.url, logoInfoMini.name, function(isOK, filename)
            if global.L_GameLayerManager._uiNode then
                global.L_ModuleChooseManager:OnDownloadResCB(isOK, filename, downloadFlag)
            end
        end)
    end

    -- logo mini2
    local logoInfoMini2 = subModInfo.logo_mini2
    local downloadFlag = self.DownloadFlag.LogoMini2
    if logoInfoMini2 and logoInfoMini2.name and logoInfoMini2.name ~= "" and logoInfoMini2.url and logoInfoMini2.url ~= "" then
        global.L_GameEnvManager:downloadResEasy(logoInfoMini2.url, logoInfoMini2.name, function(isOK, filename)
            if global.L_GameLayerManager._uiNode then
                global.L_ModuleChooseManager:OnDownloadResCB(isOK, filename, downloadFlag)
            end
        end)
    end

    --current module 
    -- self.ui.Panel_game:setVisible(false)

    if global.isBoxLogin or global.isUgc then 
        self.ui.Button_game:setTitleText(subModInfo.name or "")
    else
        local modName = ""
        if global.isWindows then 
            modName = global.L_GameEnvManager:GetEnvDataByKey("subModName") or ""
        else
            modName = global.L_GameEnvManager:GetAPKPackageShowName() or ""
        end
        if string.len(modName) == 0 then 
            self.ui.Panel_game:setVisible(false)
        else 
            self.ui.Button_game:setTitleText(modName)
        end
    end
end

function ModuleChooseLayer:decodeBase64(response)
    local Base64 = require("lockbox.util.base64")
    response = Base64.toString(response)
    return response
end

function ModuleChooseLayer:decodeSrvlistXXTEA(response)
    local fileUtil = cc.FileUtils:getInstance()
    local filePath = fileUtil:getWritablePath() .. "temp_decode"
    if fileUtil:isFileExist(filePath) then
        fileUtil:removeFile(filePath)
    end
    fileUtil:writeStringToFile(response, filePath)
    response = fileUtil:getDataFromFileEx(filePath)
    return response
end

function ModuleChooseLayer:decodeSrvlist(response)
    local needDecode = self._currentSubMod:GetIsSign()
    if needDecode then 
        response = self:DecodeServerList(response)
    end
    local jsonData = cjson.decode(response)
    return jsonData
end

function ModuleChooseLayer:AddSrvlistCacheNamePrefix(cacheName)
    if not self._currentModule or not self._currentSubMod then
        return string.format("%s_%s", cacheName, global.L_GameEnvManager:GetChannelID())
    end
    return string.format("%s_%s", cacheName, self._currentSubMod:GetOperID())
end

function ModuleChooseLayer:GetSrvlistCachePath()
    local fileUtil = cc.FileUtils:getInstance()
    local filename = self:AddSrvlistCacheNamePrefix("ResServerlist.txt")
    local filePath = fileUtil:getWritablePath() .. filename
    return filePath
end

function ModuleChooseLayer:CleanupLocalSrvlist()
    local fileUtil = cc.FileUtils:getInstance()

    local filePath = self:GetSrvlistCachePath()
    if fileUtil:isFileExist(filePath) then
        fileUtil:removeFile(filePath)
    end
end

function ModuleChooseLayer:GetLocalRuntime()
    local fileUtil = cc.FileUtils:getInstance()

    local filePath = self:GetSrvlistCachePath()
    if not fileUtil:isFileExist(filePath) then
        return ""
    end
    local response = fileUtil:getDataFromFileEx(filePath)
    local jsonData = self:decodeSrvlist(response)
    if not jsonData then
        return ""
    end
    if not jsonData.runtime then
        return ""
    end
    return "runtime=" .. jsonData.runtime
end

function ModuleChooseLayer:RequestModSrvlist(showAnnounce)
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local modGameEnv    = self._currentSubMod:GetGameEnv()
    local mmin          = math.min
    local mmax          = math.max

    ----------------------------------------
    local function reportError(str, callback)
        local tipsData = {
            btnType = 1,
            str = str,
            callback = callback
        }
        global.L_CommonTipsManager:OpenLayer( tipsData )
    end

    ----------------------------------------
    local function httpCB(success, response, url, code)
        HideLoadingBar()
        self._srvlistCount = self._srvlistCount + 1

        local function callback()
            self:RequestModSrvlist(showAnnounce)
        end

        -- 拉取失败，网络原因
        if not success then
            if self._srvlistCount >= 3 then
                reportError("[srvlist][0]网络不给力哦！点“确认”重试。", callback)
                -- 上报至服务器
                global.L_DataRePort:ReportErrorModlistURL("SRVLIST_INFO_REQUEST_FAILED", "-3000", "Request srvlist INFO ERROR, CODE ERROR", url, code)
            else
                callback()
            end
            return nil
        end

        -- 拉取失败，内容空
        if not response then
            if self._srvlistCount >= 3 then
                reportError("[srvlist][1]网络不给力哦！点“确认”重试。", callback)
                -- 上报至服务器
                global.L_DataRePort:ReportErrorModlistURL("SRVLIST_INFO_REQUEST_FAILED", "-3001", "Request srvlist INFO ERROR, RESPONSE ERROR", url, code)
            else
                callback()
            end
            return nil
        end

        local isXXTEAEncrypt = global.L_GameEnvManager:GetModlistCustomDataByKey("isEncrypt")
        if not string.find(response, "latestData") and isXXTEAEncrypt and isXXTEAEncrypt == 1  then 
            response = self:decodeBase64(response)
        end

        -- xxtea 解密
        response = self:decodeSrvlistXXTEA(response)

        -- json解析，检测是否解析成功
        local jsonData = self:decodeSrvlist(response)
        if not jsonData then
            self:CleanupLocalSrvlist()
            reportError("[srvlist][2]远端服务器配置格式异常", callback)
            -- 上报至服务器
            global.L_DataRePort:ReportErrorModlistURL("SRVLIST_INFO_REQUEST_FAILED", "-3002", "Request srvlist INFO ERROR, JSON ERROR", url, code)
            return nil
        end

        local fileUtil = cc.FileUtils:getInstance()
        local filePath = ""
        if jsonData.latestData then
            -- 本地是否是最新的
            -- 读取本地
            filePath = self:GetSrvlistCachePath()
            response = fileUtil:getDataFromFileEx(filePath)
            jsonData = self:decodeSrvlist(response)
        else
            -- 不是最新，保存内容至本地，无需再次解析json
            filePath = self:GetSrvlistCachePath()
            if fileUtil:isFileExist(filePath) then
                fileUtil:removeFile(filePath)
            end
            fileUtil:writeStringToFile(response, filePath)
        end

        -- json解析，检测是否解析成功
        if not jsonData then
            self:CleanupLocalSrvlist()
            reportError("[srvlist][3]远端服务器配置格式异常", callback)
            -- 上报至服务器
            global.L_DataRePort:ReportErrorModlistURL("SRVLIST_INFO_REQUEST_FAILED", "-3003", "Request srvlist INFO ERROR, JSON ERROR", url, code)
            return nil
        end

        self._srvlistCount = 0
        global.L_ModuleChooseManager:RespModSrvlist(jsonData, showAnnounce)
    end

    local signKey       = global.L_GameEnvManager:GetModlistSignKey()
    local modInfo       = self._currentSubMod:GetSubModInfo()
    local srvlist       = modInfo.srvlist
    if global.L_GameEnvManager:IsReview() and modInfo.srvlistReview and string.len(modInfo.srvlistReview) > 0 then 
        srvlist = modInfo.srvlistReview
    end
    local srvlistURL    = string.format(srvlist, global.L_GameEnvManager:GetChannelID())
    local srvlistData   = srvlistURL
    srvlistData         = string.gsub(srvlistData, "http://", "")
    srvlistData         = string.gsub(srvlistData, "https://", "")
    srvlistData         = string.gsub(srvlistData, "/gsl/auth/server_list_auth", "")
    srvlistData         = string.gsub(srvlistData, "/gsl/main", "")
    local s             = string.find(srvlistData, "/")
    srvlistData         = string.sub(srvlistData, s+1, string.len(srvlistData))
    local timestamp     = os.time()
    local sign          = get_str_MD5("data=" .. srvlistData .. "&key=" .. signKey .. "&time="..timestamp)
    srvlistURL          = srvlistURL .. "?" .. self:GetLocalRuntime()
    srvlistURL          = srvlistURL .. string.format("&time=%s&sign=%s", timestamp, sign)
    -- debug
    releasePrint( "mod srvlist URL:", srvlistURL )
    if srvlistURL and string.len(srvlistURL) > 0 then
        ShowLoadingBar()
        HTTPRequest(srvlistURL, httpCB)
    end
end

function ModuleChooseLayer:RespModSrvlist(jsonData, showAnnounce)
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local modGameEnv    = self._currentSubMod:GetGameEnv()
    local mmin          = math.min
    local mmax          = math.max

    -- clean
    modGameEnv:Cleanup()

    ------------------------------------------
    local serverData    = {}
    serverData.source   = jsonData

    -- 推荐服
    local referArrAble = false
    local refer     = jsonData.refer
    local referArr  = jsonData.referArr
    local referOnlyOne  = jsonData.referOnlyOne
    if referArr and next(referArr) then
        referArrAble = true
        local randIndex = math.random(1, #referArr)
        refer = referArr[randIndex]
    end
    modGameEnv:SetRefer(refer)

    -- 服务器组
    serverData.srvgroup     = jsonData.serverGroup

    ------------------------------------------
    local function parseSrvitem(data, srvRoot)
        if not data then
            return nil
        end

        local function fixSrvip(srvid, srvRoot)
            if srvRoot then
                return string.format("s%s-%s", srvid, srvRoot)
            end
            return ""
        end

        -- 拼接服务器ip
        local srvid     = data.srvid
        local srvip     = fixSrvip(srvid, srvRoot)
        local mainsrvid = data.mainsrvid
        if mainsrvid and string.len(mainsrvid) > 0 and tonumber(mainsrvid) then
            srvip       = fixSrvip(mainsrvid, srvRoot)
        end
        srvip           = data.srvip or srvip

        -- srvitem
        local srvitem = {}
        srvitem.serverId        = srvid                                     -- 服务器id
        srvitem.ip              = srvip                                     -- 服务器ip
        srvitem.port            = tonumber(data.port)                       -- 端口
        srvitem.stab            = data.beta == "1" and "beta" or "stab"     -- 先行服
        srvitem.state           = mmax(mmin(tonumber(data.state), 5), 1)    -- 状态 1新服,2畅通,3爆满,4维护,5隐藏
        srvitem.serverName      = data.srvname or srvid                     -- 服务器名
        srvitem.urlSuffix       = data.urlsuffix                            -- 资源URL 后缀
        srvitem.mainServerId    = mainsrvid                                 -- 主服id，拼接ip
        srvitem.tag             = data.tag                                  -- 所属服务器组tag
        srvitem.gmurlsuffix     = data.gmurlsuffix                          -- 先行服版本号
        srvitem.proxyport       = data.proxyport                            -- 代理端口
        srvitem.oriState        = srvitem.state
        srvitem.bg              = data.bg                                   -- 冠名

        return srvitem
    end
    ------------------------------------------
    
    -- 服务器列表
    local function isValid(v)
        if v.srvid == 0 or v.port == nil then
            return false
        end
        return true
    end
    local isReview      = global.L_GameEnvManager:IsReview()
    local srvData       = isReview and jsonData.serverDataReview or jsonData.serverData or {}
    local srvRoot       = isReview and jsonData.srvRootReview or jsonData.srvRoot
    serverData.srvlist  = {}
    local mainServerNameData = {}
    for _, v in ipairs(srvData) do
        --精简
        v.srvid           = v.d or v.srvid                                     
        v.port            = v.p or v.port                       
        v.state           = v.s or v.state    
        v.urlsuffix       = v.u or v.urlsuffix               
        v.mainsrvid       = v.m or v.mainsrvid                               
        v.tag             = v.t or v.tag                                  
        v.srvname         = v.n or v.srvname 
        v.gmurlsuffix     = v.g or v.gmurlsuffix
        v.srvip           = v.i or v.srvip                 
        v.proxyport       = v.x or v.proxyport
        v.beta            = v.b or v.beta                     
        if isValid(v) then
            local srvitem = parseSrvitem(v, srvRoot)
            tinsert(serverData.srvlist, srvitem)

            mainServerNameData[srvitem.serverId] = srvitem.serverName
        end
    end

    -- 加载主服名字  区服列表那精简不好再加字段了
    for i,v in ipairs(serverData.srvlist) do
        v.mainServerName = mainServerNameData[v.mainServerId]   --主服名
    end

    -- 
    -- 安卓/ios 分平台读取
    local resURL        = jsonData.resURL
    local resURL_win    = jsonData.resURL_win
    local resURL_ios    = jsonData.resURL_ios
    local resURL_ad     = jsonData.resURL_ad
    local gmResURL      = jsonData.gmResURL
    local gmResURL_win  = jsonData.gmResURL_win
    local gmResURL_ad   = jsonData.gmResURL_ad
    local gmResURL_ios  = jsonData.gmResURL_ios
    resURL_ios          = (resURL_ios and resURL_ios ~= "") and resURL_ios or resURL
    resURL_ad           = (resURL_ad and resURL_ad ~= "") and resURL_ad or resURL
    resURL_win          = (resURL_win and resURL_win ~= "") and resURL_win or resURL_ad
    gmResURL_ad         = (gmResURL_ad and gmResURL_ad ~= "") and gmResURL_ad or gmResURL
    gmResURL_ios        = (gmResURL_ios and gmResURL_ios ~= "") and gmResURL_ios or gmResURL
    gmResURL_win        = (gmResURL_win and gmResURL_win ~= "") and gmResURL_win or gmResURL_ad


    --备份cdn
    local resURL2        = jsonData.resURL2
    local resURL_win2    = jsonData.resURL_win2
    local resURL_ios2    = jsonData.resURL_ios2
    local resURL_ad2     = jsonData.resURL_ad2
    local gmResURL2      = jsonData.gmResURL2
    local gmResURL_win2  = jsonData.gmResURL_win2
    local gmResURL_ad2   = jsonData.gmResURL_ad2
    local gmResURL_ios2  = jsonData.gmResURL_ios2
    resURL_ios2          = (resURL_ios2 and resURL_ios2 ~= "") and resURL_ios2 or resURL2
    resURL_ad2           = (resURL_ad2 and resURL_ad2 ~= "") and resURL_ad2 or resURL2
    resURL_win2          = (resURL_win2 and resURL_win2 ~= "") and resURL_win2 or resURL_ad2
    gmResURL_ad2         = (gmResURL_ad2 and gmResURL_ad2 ~= "") and gmResURL_ad2 or gmResURL2
    gmResURL_ios2        = (gmResURL_ios2 and gmResURL_ios2 ~= "") and gmResURL_ios2 or gmResURL2
    gmResURL_win2        = (gmResURL_win2 and gmResURL_win2 ~= "") and gmResURL_win2 or gmResURL_ad2

    if global.isWindows then
        resURL          = resURL_win
        resURL2         = resURL_win2
        gmResURL        = gmResURL_win
        gmResURL2       = gmResURL_win2
    elseif global.isAndroid or global.isOHOS then
        resURL          = resURL_ad
        resURL2         = resURL_ad2
        gmResURL        = gmResURL_ad
        gmResURL2       = gmResURL_ad2
    elseif global.isIOS then
        resURL          = resURL_ios
        resURL2         = resURL_ios2
        gmResURL        = gmResURL_ios
        gmResURL2       = gmResURL_ios2
    end
    serverData.resURL       = resURL
    serverData.resURL2      = resURL2
    serverData.whitelist    = jsonData.whitelist
    serverData.resVer       = jsonData.resVer
    serverData.sceneURL     = jsonData.sceneURL
    serverData.sceneResVer  = jsonData.sceneResVer
    serverData.gmResVer     = jsonData.gmResVer
    serverData.gmResURL     = gmResURL
    serverData.gmResURL2    = gmResURL2
    serverData.gmInitResVer = jsonData.gmInitResVer
    serverData.gmInitResURL = jsonData.gmInitResURL
    serverData.gmInitResURL2 = jsonData.gmInitResURL2
    serverData.gmWebResURL  = jsonData.gmWebResURL
    serverData.gmWebResURL2 = jsonData.gmWebResURL2
    serverData.gmWebResVer  = jsonData.gmWebResVer
    serverData.uidWhiteList = jsonData.uidWhiteList

    -- custom
    local customURL = jsonData.custom and jsonData.custom.custom_url
	local newServerList = false
    modGameEnv:SetCustomData(jsonData.custom or {})
    if customURL and string.len(customURL) > 0 then 
		newServerList = true
		modGameEnv:SetCustomUrl(customURL)
		modGameEnv:SetIsNewServerlist(true)
		self:RequestCustomURL(customURL)
    end

    modGameEnv:SetServerData(serverData)

    --新用户 推荐服等设置
    self:ParseShowHideSrvitem()

    modGameEnv:ReadLastServers()
    --------------------

    -- 自动弹出用户协议
    local agreement     = modGameEnv:GetCustomDataByKey("agreement")
    local autoAgreement = getAgreementState() == 0 and agreement and string.len(agreement) > 0
    
    -- 请求公告
    -- 非审核服状态生效
    if not isReview then
        local announceURL       = jsonData.custom and jsonData.custom.announceUrl
        if announceURL and string.len(announceURL) > 0 then
            releasePrint("announceURL", announceURL)
            HTTPRequest(announceURL, function(success, response)
                if success then
                    local jsonData = cjson.decode(response)
                    if jsonData and next(jsonData) then
                        serverData.announce = jsonData
    
                        -- find announce
                        if showAnnounce and not autoAgreement then
                            global.L_ModuleChooseManager:ShowAnnounce()
                        end
                    end
                end
            end)
        end
    end

    
    self:UpdateServers()
    self:UpdateSelected()
    -- 显示用户协议
    if not isReview then
        if autoAgreement then
            self:ShowAgreement()
        end
    end
    if not newServerList then 
        self:OnCustomData(true)
    end

end

function ModuleChooseLayer:OnCustomData(isCheckAutoEnterGame)
    self:CheckLoadRoleinfo()
    self:UpdateShareBtn()
    self:UpdateCopyright()
    self:UpdateHealthGame()
    self:UpdateLicense()
    self:UpdateLogo()
    self:UpdateAgreementBtn()
    self:UpdateAgreementTips()
    self:UpdateVersion()
    self:UpdateAgeTipsImage()
    self:UpdateAuthTips()
    self:UpdateDeleteAccountBtn()
    self:UpdateChangeAccountBtn()
    if isCheckAutoEnterGame then 
        self:checkAutoLaunchGameMod()
        self:CheckAutoEnterGame()
        self:CheckShiWanAutoEnterGame()
    end
end

function ModuleChooseLayer:InitLauncherVersion()
    local channelID     = tostring(global.L_GameEnvManager:GetChannelID())
    local module        = global.L_ModuleManager:GetLauncherModule()
    local originVersion = module:GetOriginVersion()
    local remoteVersion = module:GetRemoteVersion()
    self.ui.Text_ver_launcher:setString(string.format("%s (%s/%s)", channelID, originVersion, remoteVersion))
end

function ModuleChooseLayer:UpdateSelected()
    local btnTextStr = fixNewLanguageString("未选择线路")
    if not self._currentModule or not self._currentSubMod then
        self.ui.Button_select:setTitleText(btnTextStr)
        self.ui.Image_select_state:setVisible(false)
        self.ui.Image_select_new:setVisible(false)
        return nil
    end

    local modGameEnv = self._currentSubMod:GetGameEnv()
    local serverData = modGameEnv:GetServerData()
    if not serverData then
        self.ui.Button_select:setTitleText(btnTextStr)
        self.ui.Image_select_state:setVisible(false)
        self.ui.Image_select_new:setVisible(false)
        return nil
    end

    local selectedServer = modGameEnv:GetSelectedServer()
    if not selectedServer then
        self.ui.Button_select:setTitleText(btnTextStr)
        self.ui.Image_select_state:setVisible(false)
        self.ui.Image_select_new:setVisible(false)
        return nil
    end

    -- 服务器名
    local statePath = self.path .. "fuguchuanqi.apk_000870.png"
    if selectedServer.state == 1 then
        -- 新服 绿色
        statePath = self.path .. "fuguchuanqi.apk_000870.png"
    elseif selectedServer.state == 2 then
        -- 普通 绿色
        statePath = self.path .. "fuguchuanqi.apk_000870.png"
    elseif selectedServer.state == 3 then
        -- 爆满
        statePath = self.path .. "fuguchuanqi.apk_000872.png"
    elseif selectedServer.state == 4 then
        -- 维护
        statePath = self.path .. "fuguchuanqi.apk_000873.png"
    elseif selectedServer.state == 5 then
        -- 隐藏服 隐藏字
        statePath = self.path .. "fuguchuanqi.apk_000873.png"
    end

    -- 任务活动
    -- 是否开启活动
    local boxScene = tonumber(global.L_GameEnvManager:GetEnvDataByKey("scene"))
    if boxScene == 9 then
        local isShowActivityIcon = false
        local activitySevId = global.L_GameEnvManager:GetEnvDataByKey("serverId")
        activitySevId       = activitySevId and tostring(activitySevId)
        if activitySevId and tostring(selectedServer.serverId) == activitySevId then
            isShowActivityIcon = true
            if not self.ui.activityIcon then
                -- 显示活动icon
                local bttonSizeW   = self.ui.Button_select:getContentSize().width
                local activityIcon = ccui.ImageView:create()
                activityIcon:loadTexture(self.path .. "box_activity_icon.png")
                activityIcon:setAnchorPoint(1, 0.5)
                activityIcon:setPosition(bttonSizeW-18, 37)
                self.ui.Button_select:addChild(activityIcon)
                self.ui.activityIcon = activityIcon
            end
        end

        if self.ui.activityIcon then
            self.ui.activityIcon:setVisible(isShowActivityIcon)
        end
    end

    local suffix = ""
    if selectedServer.state == 1 then
        suffix = ""
    elseif selectedServer.state == 3 then
        suffix = ""
    elseif selectedServer.state == 5 then
        suffix = "(隐)"
    end
    self.ui.Button_select:setTitleText(selectedServer.serverName ..  suffix)
    self.ui.Image_select_new:setVisible(selectedServer.state == 1)
    self.ui.Image_select_state:setVisible(true)
    self.ui.Image_select_state:loadTexture(statePath)
end

function ModuleChooseLayer:CheckShiWanAutoEnterGame()
    --试玩直接启动游戏
    local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
    if  shiwan and tonumber(shiwan) == 1 then
        if global.L_NativeBridgeManager:PCCheckMedthodName("GN_checkRealName") then
            local envMgr = global.L_GameEnvManager
            local env_uid = envMgr:GetEnvDataByKey("user_id") or ""
            local data = {
                userId     = tostring( env_uid )
            }
            global.L_NativeBridgeManager:PCNoticeRequest("GN_checkRealName",data)
            return
        end
        self:LaunchModule()
    end
end

function ModuleChooseLayer:UpdateLogo()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local directoryPath = global.FileUtilCtl:getWritablePath()
    local modInfo       = self._currentSubMod:GetSubModInfo()
    local logoInfo      = modInfo.logo
    local showlogo      = modInfo.showlogo
    local logoInfoMini  = modInfo.logo_mini
    local logoInfoMini2 = modInfo.logo_mini2
    
    if logoInfo and logoInfo.name and logoInfo.name ~= "" and logoInfo.url and logoInfo.url ~= "" then
        local filePath  = directoryPath .. logoInfo.name
        if cc.FileUtils:getInstance():isFileExist(filePath) then
            self.ui.Image_icon:setVisible(true)
            self.ui.Image_icon:loadTexture(filePath)
            self.ui.Image_icon:ignoreContentAdaptWithSize(true)
        else
            self.ui.Image_icon:setVisible(false)
        end
    elseif showlogo and tonumber(showlogo) == 1 then
        self.ui.Image_icon:setVisible(true)
        self.ui.Image_icon:loadTexture(self.path .. "logo_1.png")
        self.ui.Image_icon:ignoreContentAdaptWithSize(true)
    else
        self.ui.Image_icon:setVisible(false)
    end

    -- local isBoxLogin = global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin")
    -- if isBoxLogin == 1 then --盒子登录 取对应平台的版号logo
    --     if global.isWindows then
    --         logoInfoMini  = modInfo.logo_mini_box_pc
    --     else
    --         logoInfoMini  = modInfo.logo_mini_box
    --     end  
    -- end
    -- logo mini
    if logoInfoMini and logoInfoMini.name and logoInfoMini.name ~= "" and logoInfoMini.url and logoInfoMini.url ~= "" then
        local filePath  = directoryPath .. logoInfoMini.name
        if cc.FileUtils:getInstance():isFileExist(filePath) then
            self._imageLogoMini:setVisible(true)
            self._imageLogoMini:loadTexture(filePath)
            self._imageLogoMini:ignoreContentAdaptWithSize(true)
        else
            self._imageLogoMini:setVisible(false)
        end
    else
        self._imageLogoMini:setVisible(false)
    end


    if logoInfoMini2 and logoInfoMini2.name and logoInfoMini2.name ~= "" and logoInfoMini2.url and logoInfoMini2.url ~= "" then
        local filePath  = directoryPath .. logoInfoMini2.name
        if cc.FileUtils:getInstance():isFileExist(filePath) then
            self._imageLogoMini2:setVisible(true)
            self._imageLogoMini2:loadTexture(filePath)
            self._imageLogoMini2:ignoreContentAdaptWithSize(true)
        else
            self._imageLogoMini2:setVisible(false)
        end
    else
        self._imageLogoMini2:setVisible(false)
    end
end

function ModuleChooseLayer:UpdateShareBtn()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local modGameEnv  = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end

    -- 分享游戏
    local shareUrl    = modGameEnv:GetCustomDataByKey("shareUrl")
    local isShowShare = shareUrl and shareUrl ~= ""
    self.ui.Button_share:setVisible(isShowShare)
end

function ModuleChooseLayer:UpdateCopyright()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local modGameEnv  = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end

    -- 版号
    local hideCopyright = (tonumber(modGameEnv:GetCustomDataByKey("hideCopyright")) == 1)
    self.ui.Text_copyright:setVisible(hideCopyright == false)

    local copyright1 = modGameEnv:GetCustomDataByKey("copyright1")
    local copyright2 = modGameEnv:GetCustomDataByKey("copyright2")

    local copyrightStr = nil
    if copyright1 and copyright2 and string.len(copyright1) > 0 and string.len(copyright2) > 0 then
        TextCreateRichText(self.ui.Text_copyright, copyright1 .. "\n" .. copyright2)
    end
    
    -- 特殊处理PC端的版号问题
    if global.isWindows  then
        local copyright1_pc = modGameEnv:GetCustomDataByKey("copyright1_pc")
        local copyright2_pc = modGameEnv:GetCustomDataByKey("copyright2_pc")
        if copyright1_pc and copyright2_pc and string.len(copyright1_pc) > 0 and string.len(copyright2_pc) > 0 then
            TextCreateRichText(self.ui.Text_copyright, copyright1_pc .. "\n" .. copyright2_pc)
        end
    end

    self:UpdateCopyright360()
end

-- 360过白版号
function ModuleChooseLayer:UpdateCopyright360()
    local modGameEnv  = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end
    local isSwithch = tonumber(modGameEnv:GetCustomDataByKey("cprh")) == 1
    local whiteFileName = "CHxAY7FThcchFK2dmR2j.txt"
    local fileUtil  = cc.FileUtils:getInstance()
    if fileUtil:isFileExist(whiteFileName) or isSwithch then
        local filename  = "cright.txt"
        local isExist   = fileUtil:isFileExist(filename)
        if not fileUtil:isFileExist(filename) then
            return nil
        end
        local fileData = fileUtil:getDataFromFileEx(filename)
        local dataArray = string.split(fileData or "", "\n")
        local copyright1_pc = dataArray[1]
        local copyright2_pc = dataArray[2]
        if copyright1_pc and copyright2_pc and string.len(copyright1_pc) > 0 and string.len(copyright2_pc) > 0 then
            TextCreateRichText(self.ui.Text_copyright, copyright1_pc .. "\n" .. copyright2_pc)
        end
    end
end

function ModuleChooseLayer:UpdateHealthGame()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local modGameEnv  = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end

    self.ui.Text_health:setVisible(true)
    self.ui.Text_health_tips:setVisible(true)

    -- 健康游戏内容
    local customData = modGameEnv:GetCustomDataByKey("healthtips")
    if customData then
        TextCreateRichText(self.ui.Text_health, customData)
    end

    -- 适龄提醒
    local customData = modGameEnv:GetCustomDataByKey("agetips")
    if customData then
        TextCreateRichText(self.ui.Text_health_tips, customData)
    end
end

function ModuleChooseLayer:UpdateAgeTipsImage()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local modGameEnv  = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end

    self.ui.Image_age_tips:setVisible(false)
    self.ui.Image_age_tips:setTouchEnabled(false)

    -- 适龄提醒
    local customData = modGameEnv:GetCustomDataByKey("agetipsImage")
    if customData then
        -- 显示
        if tostring(customData.visible) == "1" then
            self.ui.Image_age_tips:setVisible(true)
        end
        
        -- 图标
        if customData.name and customData.url then
            self.ui.Image_age_tips:setVisible(false)
            local directoryPath = global.FileUtilCtl:getWritablePath()
            local filePath = directoryPath ..  string.format("%s", customData.name)
            if cc.FileUtils:getInstance():isFileExist(filePath) then
                self.ui.Image_age_tips:setVisible(true)
                self.ui.Image_age_tips:loadTexture(filePath)
                self.ui.Image_age_tips:ignoreContentAdaptWithSize(true)
            else
                local downloadFlag = self.DownloadFlag.AgeTips
                global.L_GameEnvManager:downloadResEasy(customData.url, customData.name, function(isOK, filename)
                    if global.L_GameLayerManager._uiNode then
                        global.L_ModuleChooseManager:OnDownloadResCB(isOK, filename, downloadFlag)
                    end
                end)
            end
        end

        if customData.hyperlink and customData.hyperlink ~= "" then
            -- 跳转链接
            self.ui.Image_age_tips:setTouchEnabled(true)
            self.ui.Image_age_tips:addClickEventListener(function()
                cc.Application:getInstance():openURL(customData.hyperlink)
            end)
        elseif customData.clickTips and customData.clickTips ~= "" then
            -- 跳转提醒框
            self.ui.Image_age_tips:setTouchEnabled(true)
            self.ui.Image_age_tips:addClickEventListener(function()
                local visibleSize = global.Director:getVisibleSize()
                local layout = ccui.Layout:create()
                self._root:addChild(layout)
                layout:setContentSize(visibleSize)
                layout:setTouchEnabled(true)
                layout:setBackGroundColor(cc.c3b(0, 0, 0))
                layout:setBackGroundColorType(1)
                layout:setBackGroundColorOpacity(80)
                
                local csize = {width=600, height=400}

                -- 背景图
                local imageBG = ccui.ImageView:create()
                layout:addChild(imageBG)
                imageBG:setPosition({x=visibleSize.width/2, y=visibleSize.height/2})
                imageBG:loadTexture(self.publicPath .. "1900000600.png")
                local x             = 30
                local y             = 30
                local width         = 452-60
                local height        = 179-60
                imageBG:setScale9Enabled(true)
                imageBG:setCapInsets({x = x, y = y, width = width, height = height})
                imageBG:setContentSize(csize)


                -- 确认按钮
                local buttonConfirm = ccui.Button:create()
                imageBG:addChild(buttonConfirm)
                buttonConfirm:setPosition({x=csize.width/2, y=40})
                buttonConfirm:loadTextureNormal(self.publicPath .. "1900001022.png")
                buttonConfirm:loadTexturePressed(self.publicPath .. "1900001022.png")
                buttonConfirm:setTouchEnabled(true)
                buttonConfirm:setTitleFontName("fonts/font.ttf")
                buttonConfirm:setTitleFontSize(18)
                buttonConfirm:setTitleText("确 认")
                buttonConfirm:addClickEventListener(function()
                    layout:removeFromParent()
                end)

                -- 内容
                local scrollview = ccui.ScrollView:create()
                imageBG:addChild(scrollview)
                scrollview:setContentSize({width=550, height=300})
                scrollview:setInnerContainerSize({width = 500, height = 300})
                scrollview:ignoreContentAdaptWithSize(false)
                scrollview:setClippingEnabled(true)
                scrollview:setAnchorPoint({x=0.5, y=1})
                scrollview:setPosition({x=csize.width/2, y=380})
                scrollview:setTouchEnabled(true)

                local RichTextHelp  = requireLauncher( "init/RichTextHelp" )
                local innerSize     = scrollview:getInnerContainerSize()
                local richText      = RichTextHelp:CreateRichTextWithXML(customData.clickTips, innerSize.width, 18, "#c9b39c")
                scrollview:addChild( richText )
                richText:formatText()
                richText:setAnchorPoint({x=0.5, y=1})
                richText:setPosition({x=innerSize.width/2, y=300})
                richText:setOpenUrlHandler( function(sender, str)
                    cc.Application:getInstance():openURL(str)
                end )
            
                local textContentSize   = richText:getContentSize()
                local scrollContentSize = scrollview:getContentSize()
                local newContentSize    = {width=textContentSize.width, height=math.min(scrollContentSize.height, textContentSize.height)}
                local newInnerSize      = {width=textContentSize.width, height=math.max(newContentSize.height, textContentSize.height)}
                newInnerSize.width = math.max(550, newInnerSize.width)
                newInnerSize.height = math.max(300, newInnerSize.height)
                scrollview:setInnerContainerSize( newInnerSize )
                richText:setPosition({x=newInnerSize.width/2, y=newInnerSize.height})
            end)
        end
    end
end

function ModuleChooseLayer:UpdateAuthTips()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local modGameEnv  = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end

    self.ui.Text_auth_tips:setVisible(true)

    -- 账号安全提醒
    local customData = modGameEnv:GetCustomDataByKey("authtips")
    if customData then
        TextCreateRichText(self.ui.Text_auth_tips, customData)
    end
end

function ModuleChooseLayer:UpdateLicense()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local modGameEnv  = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end

    -- 正版
    local hideLicense = (tonumber(modGameEnv:GetCustomDataByKey("hideLicense")) == 1)
end

function ModuleChooseLayer:UpdateAgreementBtn()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local modGameEnv  = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end

    -- 用户协议
    local isShowBtn = (modGameEnv:GetCustomDataByKey("agreement") and string.len(modGameEnv:GetCustomDataByKey("agreement")) > 0)
    self.ui.Button_agreement:setVisible(isShowBtn)
end

function ModuleChooseLayer:UpdateChangeAccountBtn()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local modGameEnv  = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end
    --盒子登录显示的是返回盒子不要隐藏
    if global.isBoxLogin then
        return 
    end
    -- 切换账号
    local isHideBtn = tonumber(modGameEnv:GetCustomDataByKey("hideChangeAccountBtn")) == 1
    self.ui.Button_logout:setVisible(not isHideBtn)
end

function ModuleChooseLayer:UpdateDeleteAccountBtn()
    local module = self._currentSubMod
    if not module then
        return nil
    end

    local modGameEnv  = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end
    
    if not self.ui.Button_delete_account then
        return nil
    end

    -- 注销账号
    local isShowBtn = tonumber(modGameEnv:GetCustomDataByKey("showDeleteAccount")) == 1
    self.ui.Button_delete_account:setVisible(isShowBtn)
end

function ModuleChooseLayer:UpdateAgreementTips()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local modGameEnv  = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end

    if not self.ui.Panel_agreement then
        return nil
    end

    local discardAgreementBSwitch = modGameEnv:GetCustomDataByKey("discardAgreementBSwitch") == 1
    -- 用户协议
    local agreementB = (modGameEnv:GetCustomDataByKey("agreementB"))
    if not agreementB or agreementB == "" then
        self.ui.Panel_agreement:setVisible(false)
        self.ui.CheckBox_agreement:setSelected(true)
        return nil
    end
    self.ui.Panel_agreement:setVisible(true)
    self.ui.CheckBox_agreement:setSelected(true)

    -- 默认状态
    local userData = UserData:new("agreement_data")
    local localData = discardAgreementBSwitch and 0 or userData:getIntegerForKey("select", 0)
    local selectStatus = localData == 1
    self.ui.CheckBox_agreement:setSelected(selectStatus)

    local isInsideShow  = tonumber(modGameEnv:GetCustomDataByKey("showInside")) == 1
    local RichTextHelp = requireLauncher( "init/RichTextHelp" )
    local richText = RichTextHelp:CreateRichTextWithXML( agreementB, 2000, 18, "#ffffff" ) 
    self.ui.Node_agreement:removeAllChildren()
    self.ui.Node_agreement:addChild( richText )
    richText:formatText()
    richText:setOpenUrlHandler( function(sender, str)
        if isInsideShow then
            local httpRequest = cc.XMLHttpRequest:new()
            httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
            httpRequest.timeout = 100000 -- 10 s
            httpRequest:open("GET", str)

            httpRequest:registerScriptHandler(function()
                local code = httpRequest.status
                local success = code >= 200 and code < 300
                local response = httpRequest.response
                self:InsideShowNoticeContent( response )
            end)
            httpRequest:send()
            return
        end
        cc.Application:getInstance():openURL(str)
    end )

    local contentSize = richText:getContentSize()
    local width = contentSize.width + 50
    self.ui.Panel_agreement:setContentSize({width=width, height=35})
    self.ui.Node_agreement:setPositionX(width / 2 + 15)
    self.ui.CheckBox_agreement:setPositionX(20)

    local agreementGetURL = modGameEnv:GetCustomDataByKey("agreementGetURL") or ""
    if agreementGetURL and string.len(agreementGetURL) > 0 then
        self.ui.CheckBox_agreement:setVisible(false)
        self.ui.Panel_agreement:setVisible(false)

        local userId = global.L_GameEnvManager:GetEnvDataByKey("user_id") or global.L_GameEnvManager:GetEnvDataByKey("uid") or ""
        local gameId = self._currentSubMod:GetOperID() or ""

        local getData = { userId = userId, gameId = gameId }

        local requestScheduleId = nil
        requestScheduleId = PerformWithDelayGlobal(function ()
            if not requestScheduleId then
                return
            end
            HideLoadingBar()
            self.ui.CheckBox_agreement:setVisible(true)
            self.ui.Panel_agreement:setVisible(true)
        end, 3)
        
        ShowLoadingBar()

        -- 读取协议状态
        HTTPRequestByBoxSign(agreementGetURL, getData, boxSignKey, function(success, response)
            requestScheduleId = nil
            HideLoadingBar()
            self.ui.CheckBox_agreement:setVisible(true)
            self.ui.Panel_agreement:setVisible(true)
            releasePrint("agreement checkbox state: ", tostring(success), tostring(response))
            if not success then
                return
            end

            if not response then
                return
            end

            local jsonData = cjson.decode(response)
            local data = jsonData and jsonData.data or {}
            if data.processCode == 0 then
                local agreed = data.agreed == true
                if agreed then
                    self.ui.CheckBox_agreement:setVisible(false)
                    self.ui.Panel_agreement:setVisible(false)
                    self.ui.CheckBox_agreement:setSelected(true)
                end
            elseif jsonData and jsonData.msg and string.len(jsonData.msg) > 0 then
                local processCode = data.processCode and "[" .. data.processCode .. "]" or ""
                global.L_SystemTipsManager:ShowTips(jsonData.msg .. processCode)
            end
        end)
    end
end

function ModuleChooseLayer:UpdateVersion()
    local modGameEnv  = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end
    
    -- 自定义版本号显示
    self.ui.Text_ver_launcher:setVisible(true)
    local launcherVer = modGameEnv:GetCustomDataByKey("launcherVer")
    local moduleVer = modGameEnv:GetCustomDataByKey("moduleVer")
    if launcherVer and moduleVer then
        self.ui.Text_ver_launcher:setString(launcherVer)
    end
end

function ModuleChooseLayer:InitServers()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    self.ui.Panel_hide:setContentSize(visibleSize)
    self.ui.Panel_hide:addClickEventListener(function()
        self:ShowLaunch()
        self:HideServers()
    end)
    
    self.ui.ListView_groups:setBounceEnabled(true)
    self.ui.ListView_servers:setBounceEnabled(true)
    self.ui.Button_more:addClickEventListener(function()
        self:SelectSGroup(hasRoleGroup)
    end)
end

function ModuleChooseLayer:ShowServers()
    self.ui.Panel_servers:setVisible(true)
end

function ModuleChooseLayer:HideServers()
    self.ui.Panel_servers:setVisible(false)
end

function ModuleChooseLayer:UpdateServers()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end
    local modGameEnv    = self._currentSubMod:GetGameEnv()
    local srvData       = modGameEnv:GetServerData()
    if not srvData then
        return false
    end

    if not self.ui.Panel_servers:isVisible() then
        return false
    end

    self.ui.ListView_groups:removeAllItems()
    self.ui.ListView_servers:removeAllItems()
    self.ui.ListView_logined:removeAllItems()
    self._group         = -1
    self._gservers      = {}
    self._groupCells    = {}
    self._serverCells   = {}
    self._loginedCells  = {}

    -- 筛选服务器
    local function filterServers()
        local tservers = {}
        local srvlist  = clone(modGameEnv:GetSrvlist())
    
        -- 组
        -- 先tag为key，方便快速存储，再使用table.sort
        -- 服务器列表倒序遍历
        -- 问题1，没配置tag
        -- 问题2，配置tag但是不存在该tag组
        -- normalsrvlist 剩余正常列表

        -- hash
        local groupSrvlist  = {}
        if srvData.srvgroup and type(srvData.srvgroup) == "table" then
            for i, v in ipairs(srvData.srvgroup) do
                groupSrvlist[v.tag] = {index = i, name = v.name, tag = v.tag, items = {}}
            end
        end
        -- 筛选出组列表和普通列表
        local normalsrvlist = {}
        for i, v in ipairs(srvlist) do
            local srvitem = v
            if srvitem.tag and groupSrvlist[srvitem.tag] then
                tinsert(groupSrvlist[srvitem.tag].items, srvitem)
            else
                tinsert(normalsrvlist, srvitem)
            end
        end
        -- 排序
        groupSrvlist = HashToSortArray(groupSrvlist, function(a, b)
            return a.index < b.index
        end)

        for i, v in ipairs(groupSrvlist) do
            if #v.items > 0 then
                local item = {}
                item.index = #tservers+1
                item.name  = v.name
                item.items = v.items
                tinsert(tservers, item)
            end
        end

        -- 正常区服
        local pageCount = math.ceil(#normalsrvlist / self.CountOfPage)
        local function calcServersByPage(page)
            local begin = (page - 1) * self.CountOfPage + 1
            local ended = begin + self.CountOfPage - 1
    
            local servers = {}
            for i = begin, ended do
                tinsert(servers, normalsrvlist[i])
            end
            return servers
        end
        for page = pageCount, 1, -1 do
            local items = calcServersByPage(page)
    
            local item = {}
            item.index = #tservers+1
            item.name  = string.format("%s-%s区", (page - 1) * self.CountOfPage + 1, (page - 1) * self.CountOfPage + #items)
            item.items = items
            tinsert(tservers, item)
        end

        return tservers
    end

    -- 组
    self._gservers = filterServers()
    for _, v in ipairs(self._gservers) do
        local cell = self:CreateSGroupCell(v)
        self._groupCells[v.index] = cell
        self.ui.ListView_groups:pushBackCustomItem(cell.nativeUI)
    end

    -- 已经登录的
    local lastervers = modGameEnv:GetLastservers()
    for i, v in ipairs(lastervers) do
        local server = modGameEnv:GetServerByID(v)
        if server then
            local cell = self:CreateServerCell(server)
            self.ui.ListView_logined:pushBackCustomItem(cell.nativeUI)

            self._loginedCells[server.serverId] = cell
        end
    end

    self:SelectSGroup(1)
end

function ModuleChooseLayer:SelectSGroup(g)
    self._group = g

    for k, cell in pairs(self._groupCells) do
        if self._group == k then
            cell.Button_group:loadTextureNormal(self.path .. "fuguchuanqi.apk_000858.png")
        else
            cell.Button_group:loadTextureNormal(self.path .. "fuguchuanqi.apk_000857.png")
        end
    end

    self._serverCells = {}
    self.ui.ListView_servers:removeAllItems()
    self.ui.ListView_servers:jumpToTop()

    local servers = {}
    if self._group == hasRoleGroup then --玩过的区服
        servers = self:GetHasRoleSrvItems()
    else
        local gservers = self._gservers[self._group]
        if not gservers then
            return nil
        end
        servers  = clone(gservers.items)
    end
    if not servers then 
        return nil
    end
    print("count ", #servers)
    while next(servers) do
        local batchServers = {}

        tinsert(batchServers, servers[#servers])
        tremove(servers, #servers)

        if next(servers) then
            tinsert(batchServers, servers[#servers])
            tremove(servers, #servers)
        end

        local cell = self:CreateBatchServerCell(batchServers)
        self.ui.ListView_servers:pushBackCustomItem(cell)
    end
end

function ModuleChooseLayer:GetHasRoleSrvItems()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end
    local modGameEnv    = self._currentSubMod:GetGameEnv()
    if not modGameEnv then 
        return nil
    end

    local items  = modGameEnv:GetHasRoleSrvItems()
    return items
end

function ModuleChooseLayer:CreateSGroupCell(data)
    local root   = CreateExport_launcher("server/group_cell")
    local layout = root:getChildByName("Panel_bg")
    layout:removeFromParent()

    local cell   = ui_delegate(layout)

    cell.Button_group:setTitleText(data.name)
    drawButtonColorStyle(cell.Button_group, {fontSize=20, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})

    -- 选择
    local function callback()
        self:SelectSGroup(data.index)
    end
    cell.Button_group:addClickEventListener(callback)
    cell.nativeUI:addClickEventListener(callback)

    return cell
end

function ModuleChooseLayer:CreateBatchServerCell(data)
    local widget = ccui.Widget:create()
    widget:setContentSize({width = 264*2, height = 49})

    if data[1] then
        local cell_data = {}
        cell_data.wid = 264
        cell_data.hei = 49
        cell_data.callback = function()
            local cell = self:CreateServerCell(data[1])
            return cell.nativeUI
        end
        local quickCell = createQuickCell(cell_data)
        widget:addChild(quickCell.widget)
        quickCell.widget:setPositionX(0)

        self._serverCells[data[1].serverId] = quickCell
    end

    if data[2] then
        local cell_data = {}
        cell_data.wid = 264
        cell_data.hei = 49
        cell_data.callback = function()
            local cell = self:CreateServerCell(data[2])
            return cell.nativeUI
        end
        local quickCell = createQuickCell(cell_data)
        widget:addChild(quickCell.widget)
        quickCell.widget:setPositionX(264)

        self._serverCells[data[2].serverId] = quickCell
    end

    return widget
end

function ModuleChooseLayer:CreateServerCell(data)
    local cell = self:GetServerCache()

    -- 选服
    local function callback()
        if not self._currentModule or not self._currentSubMod then
            return nil
        end

        local modGameEnv    = self._currentSubMod:GetGameEnv()
        local serverData    = modGameEnv:GetServerData()

        -- 维护，且不是白名单
        if data.state == 4 and (not modGameEnv:IsWhitelist()) then
            global.L_SystemTipsManager:ShowTips("服务器正在维护中，请选择其它服务器!")
            return nil
        end

        -- 隐藏服给提醒
        if data.state == 5 then
            global.L_SystemTipsManager:ShowTips("正在进入隐藏服!")
        end

        modGameEnv:SetSelectedServer(data)

        -- 选择的服务器存储到本地
        modGameEnv:SaveLastServers()

        self:ShowLaunch()
        self:HideServers()
        self:UpdateSelected()
    end
    cell.nativeUI:addClickEventListener(callback)
    cell.Button_server:addClickEventListener(callback)
    cell.Button_server:setZoomScale(0.05)

    -- 服务器名
    local suffix = ""
    if data.state == 1 then
        suffix = ""
    elseif data.state == 3 then
        suffix = ""
    elseif data.state == 5 then
        suffix = "(隐)"
    end
    -- 白名单显示服务器id
    local modGameEnv = self._currentSubMod:GetGameEnv()
    if modGameEnv:IsWhitelist() then
        suffix = suffix .. string.format("(%s)", data.serverId)
    end
    cell.Button_server:setTitleText(data.serverName ..  suffix)
    cell.Image_new:setVisible(data.state == 1)
    drawButtonColorStyle(cell.Button_server, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})

    -- 服务器状态
    if data.state == 1 then
        -- 新服 绿色
        cell.Image_state:loadTexture(self.path .. "fuguchuanqi.apk_000870.png")
    elseif data.state == 2 then
        -- 普通 绿色
        cell.Image_state:loadTexture(self.path .. "fuguchuanqi.apk_000870.png")
    elseif data.state == 3 then
        -- 爆满
        cell.Image_state:loadTexture(self.path .. "fuguchuanqi.apk_000872.png")
    elseif data.state == 4 then
        -- 维护
        cell.Image_state:loadTexture(self.path .. "fuguchuanqi.apk_000873.png")
        cell.Button_server:setTitleColor(cc.c3b(0xbf, 0xbf, 0xbf))
    elseif data.state == 5 then
        -- 隐藏服 隐藏字
        cell.Image_state:loadTexture(self.path .. "fuguchuanqi.apk_000873.png")
    end

    -- 冠名
    local titleBgPath = self.path .. "fuguchuanqi.apk_000853.png"
    if data.bg and tonumber(data.bg) then
        local bgPath = self.path .. "title/" .. data.bg .. ".png"
        if cc.FileUtils:getInstance():isFileExist(bgPath) then
            titleBgPath = bgPath
        end
    end
    cell.Button_server:loadTextureNormal(titleBgPath)

    -- 服务器是否有角色
    local module        = self._currentSubMod
    local modGameEnv    = module:GetGameEnv()
    local roleCount     = modGameEnv:GetRoleInfoByServerID(data.serverId)
    cell.Image_role:setVisible(roleCount and roleCount > 0)

    -- 任务活动
    -- 是否开启活动
    local boxScene = tonumber(global.L_GameEnvManager:GetEnvDataByKey("scene"))
    if boxScene == 9 then
        local isShowActivityIcon = false
        local activitySevId = global.L_GameEnvManager:GetEnvDataByKey("serverId")
        activitySevId       = activitySevId and tostring(activitySevId)
        if activitySevId and tostring(data.serverId) == activitySevId then
            isShowActivityIcon = true
            if not cell.activityIcon then
                -- 显示活动icon
                local offX = -24
                if roleCount and roleCount > 0 then
                    offX = -40
                end
                local bttonSizeW    = cell.Button_server:getContentSize().width
                local activityIcon  = ccui.ImageView:create()
                activityIcon:loadTexture(self.path .. "box_activity_icon.png")
                activityIcon:setAnchorPoint(1, 0.5)
                activityIcon:setPosition(bttonSizeW+offX, 26)
                cell.Button_server:addChild(activityIcon)
                cell.activityIcon = activityIcon
            end
        end

        if cell.activityIcon then
            cell.activityIcon:setVisible(isShowActivityIcon)
        end
    end

    return cell
end

function ModuleChooseLayer:GetServerCache()
    if #self._serverCache > 0 then
        local cache = tremove(self._serverCache)
        cache.nativeUI:autorelease()
        return cache
    end

    local root   = CreateExport_launcher("server/server_cell")
    local layout = root:getChildByName("Panel_bg")
    layout:removeFromParent()
    local cell = ui_delegate(layout)

    layout:registerScriptHandler( function(state)
        if state == "exit" then
            if false == self._releaseFlag then
                self:AddServerCache(cell)
            end
        end
    end )

    return cell
end

function ModuleChooseLayer:AddServerCache(cache)
    cache.nativeUI:retain()
    tinsert(self._serverCache, cache)
end

function ModuleChooseLayer:ReleaseServerCache()
    for k, v in pairs(self._serverCache) do
        v.nativeUI:autorelease()
    end
    if self._windowResizedListener then
        global.Director:getEventDispatcher():removeEventListener( self._windowResizedListener )
        self._windowResizedListener = nil
    end
    self._serverCache = {}
    self._releaseFlag = true
end

function ModuleChooseLayer:OnLoginSuccessResp()
    self:CheckLoadRoleinfo()

    self:UpdateAgreementTips()

    --强更
    self:CheckApkUpdate()
end

--强更 因为996sdk 有一部分包去掉权限了  得通过登录之后的NG_SDKLoginCB sdkver和  NG_recvData code_java来判断是不是没权限的包
--存在sdkver和code_java 并且code_java<=10000的为没权限的包
function ModuleChooseLayer:CheckApkUpdate()
    if not global.isAndroid then
        return 
    end

    if global.isBoxLogin then 
        return 
    end

    if global.L_GameEnvManager:GetEnvDataByKey("isCloudLogin") then 
        return 
    end

    local hasPermission = true
    local sdkInfo = global.L_NativeBridgeManager:GetLoginDataByKey("sdkInfo")
    local sdkver = nil
    if sdkInfo then 
        local sdkInfoT = cjson.decode(sdkInfo)
        if sdkInfoT and sdkInfoT.sdkver then 
            sdkver = sdkInfoT.sdkver
        end
    end
    local javaVersion = global.L_GameEnvManager:GetJavaVersionCode()
    javaVersion = tonumber(javaVersion)
    if sdkver and javaVersion and javaVersion <=10000 then 
        hasPermission = false
    end

    global.L_GameEnvManager:SetHasInstallPermission(hasPermission)
    
    local apkUpdateInfoUrl =  global.L_GameEnvManager:GetAPKUpdateInfoUrl()
    if not apkUpdateInfoUrl then 
        releasePrint("not apkUpdateUrl")
        return 
    end

    HTTPRequest(apkUpdateInfoUrl, function (success, response)
        if not success then 
            releasePrint("get apkInfo fail!")
            return 
        end
        if not response then
            releasePrint("get apkInfo empty fail!")
        end

        local jsonData = cjson.decode(response)
        local versionCode = jsonData.update_ver_code
        global.L_GameEnvManager:SetAPKUpdateInfo(jsonData)

        local userData = UserData:new("update_ver_code")
        local lastCode = userData:getStringForKey("lastCode", "-1")
        if versionCode and lastCode ~= tostring(versionCode) then 
            if hasPermission then
                userData:setStringForKey("lastCode", tostring(versionCode))
                userData:writeMapDataToFile()
                local urlInfo = {}
                urlInfo.apkVerUrl = apkUpdateInfoUrl
                global.L_NativeBridgeManager:GN_checkApkUpdate(urlInfo)
            end
        end
    end)

end

function ModuleChooseLayer:CheckLoadRoleinfo()
    if nil == self._currentModule or not self._currentSubMod then
        return false
    end
    
    local modGameEnv = self._currentSubMod:GetGameEnv()
    local exist = modGameEnv:GetRoleinfo()

    if not exist then 
        modGameEnv:RequestRoleInfo(function(jsonData)
            if not (global.L_ModuleChooseManager and global.L_ModuleChooseManager._layer) then 
                return 
            end
            if jsonData then 
                modGameEnv:SetRoleinfo(jsonData) 
                -- 保存至本地
                modGameEnv:savelocalRoleinfo()

                modGameEnv:SetSelectedServer(nil)

                global.L_ModuleChooseManager:UpdateServersWhenRoleInfoGet()
                global.L_ModuleChooseManager:OnServerRoleInfoResp()
            else 
                -- 本地读取
                modGameEnv:readLocalRoleinfo()
            end
        end)
    end
end

function ModuleChooseLayer:UpdateServerRoleInfo()
    if not self._currentModule or not self._currentSubMod then
        return false
    end
    local modGameEnv    = self._currentSubMod:GetGameEnv()
    for serverId, cell in pairs(self._serverCells) do
        cell.exit()
    end
    for serverId, cell in pairs(self._loginedCells) do
        local roleCount = modGameEnv:GetRoleInfoByServerID(serverId)
        cell.Image_role:setVisible(roleCount and roleCount > 0)
    end
    modGameEnv:ReadLastServers()
    self:UpdateSelected()
end

function ModuleChooseLayer:OnAlreadyUpToDate()
    self.ui.Panel_bg:setVisible(true)

    self:InitAllModules()
    self:InitLauncherVersion()

    self:SelectDefaultModule()

    self:ShowLaunch()
    self:HideServers()
    self:UpdateSelected()

    -- 为防止界面等太久导致的服务器列表有问题，30分钟刷一次
    if self._srvlistTimerID then
        UnSchedule(self._srvlistTimerID)
        self._srvlistTimerID = nil
    end
    self._srvlistTimerID = Schedule(function()
        self:RequestModSrvlist(false)
    end, self._srvlistTime)
end

function ModuleChooseLayer:ShowModuleAnnounce()
    if self.BoxAutoEnterGame then 
        return 
    end
    if self._announceUI then
        self._announceUI.nativeUI:removeFromParent()
        self._announceUI = nil
    end
    self._announceGroupCells = {}

    if nil == self._currentModule or not self._currentSubMod then
        return
    end
    local root = nil
    if self._isPortrait then 
        root = CreateExport_launcher("server/module_announce_portrait")
    else
        root = CreateExport_launcher("server/module_announce")
    end
    
    self:addChild(root)
    self._announceUI = ui_delegate(root)

    -- close
    local function closeCB()
        self._announceUI.nativeUI:removeFromParent()
        self._announceUI = nil

        -- 公告关闭  上报自定义事件
        local dataParam = {
            event={time=os.time(),name = "closeNotice",type = "track"}
        }

        local userId = global.L_GameEnvManager:GetEnvDataByKey("user_id") or global.L_GameEnvManager:GetEnvDataByKey("uid")
        if userId and userId ~= "" then
            dataParam.user = {id = userId}
        end

        global.L_DataRePort:SendRePortData( dataParam )
    end
    self._announceUI.Panel_1:addClickEventListener(closeCB)
    self._announceUI.Button_sure:addClickEventListener(closeCB)
    self._announceUI.Button_close:addClickEventListener(closeCB)
    drawButtonColorStyle(self._announceUI.Button_sure, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=2, outlineColor=cc.c3b(0x11,0x11,0x11)})

    -- desc 
    local function showDesc(data)
        for k, v in pairs(self._announceGroupCells) do
            if k == data.index then
                v.Button_group:loadTextureNormal(self.path .. "announce/1900000662.png")
                v.Button_group:loadTexturePressed(self.path .. "announce/1900000662.png")
                v.Button_group:setTouchEnabled(false)
                drawButtonColorStyle(v.Button_group, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=2, outlineColor=cc.c3b(0x11,0x11,0x11)})
            else
                v.Button_group:loadTextureNormal(self.path .. "announce/1900000663.png")
                v.Button_group:loadTexturePressed(self.path .. "announce/1900000662.png")
                v.Button_group:setTouchEnabled(true)
                drawButtonColorStyle(v.Button_group, {fontSize=18, color=cc.c3b(0x80, 0x72, 0x56), outlineSize=2, outlineColor=cc.c3b(0x11,0x11,0x11)})
            end
        end

        local RichTextHelp = requireLauncher( "init/RichTextHelp" )

        -- 公告标题
        local textTitle = RichTextHelp:CreateRichTextWithXML(data.title, 500, 18, "#43d849" ) 
        self._announceUI.Node_title:removeAllChildren()
        self._announceUI.Node_title:addChild(textTitle)

        -- 公告内容
        local scrollview = self._announceUI.ScrollView_content
        scrollview:setContentSize({width=500, height=220})
        scrollview:setInnerContainerSize({width=500, height=220})
        scrollview:removeAllChildren()
        local textAnnounce = RichTextHelp:CreateRichTextWithXML( data.desc, scrollview:getContentSize().width, 18, "#c9b39c" ) 
        scrollview:addChild( textAnnounce )
        textAnnounce:formatText()
        textAnnounce:setAnchorPoint({x=0.5, y=1})

        local textContentSize   = textAnnounce:getContentSize()
        local scrollContentSize = scrollview:getContentSize()
        local newContentSize    = {width=textContentSize.width, height=math.min(scrollContentSize.height, textContentSize.height)}
        local newInnerSize      = {width=textContentSize.width, height=math.max(newContentSize.height, textContentSize.height)}
        scrollview:setContentSize( newContentSize )
        scrollview:setInnerContainerSize( newInnerSize )
        textAnnounce:setPosition({x=newContentSize.width/2, y=textContentSize.height})
    end

    -- group cell
    local function createGroup(data)
        local root = CreateExport_launcher("server/module_announce_cell")
        local layout = root:getChildByName("Panel_1")
        layout:removeFromParent()
        local ui = ui_delegate(layout)
        
        -- 特性
        local trait = tonumber(data.typename) or 1
        ui.Image_trait:loadTexture(string.format(self.path .. "announce/word_hefubq_0%s.png", trait))

        -- 查看
        ui.Button_group:setTitleText(data.name)
        ui.Button_group:addClickEventListener( function()
            showDesc(data)
        end )

        return ui
    end

    local modGameEnv = self._currentSubMod:GetGameEnv()
    local serverData = modGameEnv:GetServerData()
    if nil == serverData then
        return
    end
    local announce   = serverData.announce
    if nil == announce then
        return
    end

    -- filter
    local items = {}
    for i, v in ipairs(announce) do
        if v.type and tonumber(v.type) == 1 then
            tinsert(items, 1, v)
        else
            tinsert(items, v)
        end
    end
    for i, v in ipairs(items) do
        v.index = i
        local cell = createGroup(v)
        self._announceUI.ListView_group:pushBackCustomItem(cell.nativeUI)
        self._announceGroupCells[v.index] = cell
    end
    if #items > 0 then
        showDesc(items[1])
    end
end

function ModuleChooseLayer:OnClose()
    self:ReleaseServerCache()
end

function ModuleChooseLayer:OnDownloadResCB(isOK, filename, downloadFlag)
    if not isOK then
        return nil
    end

    if downloadFlag == self.DownloadFlag.Logo then
        self:UpdateLogo()

    elseif downloadFlag == self.DownloadFlag.AgeTips then
        self:UpdateAgeTipsImage()

    elseif downloadFlag == self.DownloadFlag.LogoMini then
        self:UpdateLogo()

    elseif downloadFlag == self.DownloadFlag.LogoMini2 then
        self:UpdateLogo()

    end
end

function ModuleChooseLayer:ShowAgreement()
    if self._agreementUI then
        self._agreementUI.nativeUI:removeFromParent()
        self._agreementUI = nil
    end

    if nil == self._currentModule or not self._currentSubMod then
        return
    end

    local modGameEnv  = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end

    local content = modGameEnv:GetCustomDataByKey("agreement")
    if not content or string.len(content) == 0 then
        return nil
    end
    content = string.gsub(content, "<%s-br%s->", "<br></br>")
    content = string.gsub(content, "<%s-br%s-/>", "<br></br>")


    local root = CreateExport_launcher("server/agreement")
    self:addChild(root)
    self._agreementUI = ui_delegate(root)
    drawButtonColorStyle(self._agreementUI.Button_refuse, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})
    drawButtonColorStyle(self._agreementUI.Button_agree, {fontSize=18, color=cc.c3b(0xf8, 0xe6, 0xc6), outlineSize=3, outlineColor=cc.c3b(0x11,0x11,0x11)})

    -- agree
    local function agreeCB()
        self._agreementUI.nativeUI:removeFromParent()
        self._agreementUI = nil

        local launcherModID = global.L_ModuleManager:GetLauncherModuleID()
        local channelID     = tostring(global.L_GameEnvManager:GetChannelID())
        local userData      = UserData:new(launcherModID .. channelID .. "_data")
        userData:setIntegerForKey("agreement", 1)
        userData:writeMapDataToFile()
    end
    self._agreementUI.Button_agree:addClickEventListener(agreeCB)

    -- refuse
    local function refuseCB()
        local launcherModID = global.L_ModuleManager:GetLauncherModuleID()
        local channelID     = tostring(global.L_GameEnvManager:GetChannelID())
        local userData      = UserData:new(launcherModID .. channelID .. "_data")
        userData:setIntegerForKey("agreement", 0)
        userData:writeMapDataToFile()

        if global.isIOS then
            global.L_NativeBridgeManager:GN_accountLogout()
            global.L_GameEnvManager:RestartGame()
        else
            global.Director:endToLua()
        end
    end
    self._agreementUI.Button_refuse:addClickEventListener(refuseCB)

    -- 公告内容
    local RichTextHelp  = requireLauncher( "init/RichTextHelp" )
    local scrollview    = self._agreementUI.ScrollView_content
    local innerSize     = scrollview:getInnerContainerSize()
    local richText      = RichTextHelp:CreateRichTextWithXML(content, innerSize.width, 18, "#c9b39c")
    scrollview:addChild( richText )
    richText:formatText()
    richText:setAnchorPoint({x=0.5, y=1})
    richText:setOpenUrlHandler( function(sender, str)
        cc.Application:getInstance():openURL(str)
    end )

    local textContentSize   = richText:getContentSize()
    local scrollContentSize = scrollview:getContentSize()
    local newContentSize    = {width=textContentSize.width, height=math.min(scrollContentSize.height, textContentSize.height)}
    local newInnerSize      = {width=textContentSize.width, height=math.max(newContentSize.height, textContentSize.height)}
    scrollview:setContentSize( newContentSize )
    scrollview:setInnerContainerSize( newInnerSize )
    richText:setPosition({x=newContentSize.width/2, y=textContentSize.height})
end

-- 内部显示隐私内容
function ModuleChooseLayer:InsideShowNoticeContent( content )
    content = tostring(content) or ""
    -- root
    local visibleSize   = cc.Director:getInstance():getVisibleSize()
    local Panel_1       = ccui.Layout:create()
    Panel_1:setName( "NOTICE_CONTENT" )
    Panel_1:setContentSize(visibleSize)
    Panel_1:setTouchEnabled( true )
    Panel_1:setSwallowTouches( true )
    self:addChild( Panel_1 )

    local clickCount = 0       --点击的内容url数量
    local clickUrl = false     --是否是点击超链接进入的内容

    local clickCountUrls = {}  --记录点击的内容的超链

    -- 背景图
    local csize = {width=600, height=400}
    local innerSize         = {width=500,height=300}
    local Image_bg = ccui.ImageView:create()
    Image_bg:loadTexture(self.publicPath .. "1900000600.png",0)
    Image_bg:setPosition( visibleSize.width/2, visibleSize.height/2 )
    Image_bg:setTouchEnabled( true )
    Image_bg:setSwallowTouches( true )
    local x             = 30
    local y             = 30
    local width         = 452-60
    local height        = 179-60
    Image_bg:setScale9Enabled(true)
    Image_bg:setCapInsets({x = x, y = y, width = width, height = height})
    Image_bg:setContentSize(csize)
    Panel_1:addChild( Image_bg )

    local RichTextHelp  = requireLauncher( "init/RichTextHelp" )
    local function UpdateContent( newContent )
        local listview = Image_bg:getChildByName("LISTVIEW_CONTENT")
        if listview then
            listview:removeAllChildren()
            -- 内容RichText
            local richText      = RichTextHelp:CreateRichTextWithXML(newContent, innerSize.width, 18, "#FFFFFF")
            richText:formatText()
            listview:pushBackCustomItem( richText )

            richText:setOpenUrlHandler(function(sender,str)
                HTTPRequest(str, function(success,response)
                    if success and response and string.len(response) > 0 then
                        if success and response and string.len(response) > 0 then
                            table.insert( clickCountUrls,str )
                            clickCount = #clickCountUrls
                            clickUrl = true
                            UpdateContent( response )
                        end
                    end
                end)
            end)
        end
    end

    -- 确认按钮
    local Button_confirm = ccui.Button:create()
    Button_confirm:setPosition({x=csize.width/2, y=40})
    Button_confirm:loadTextureNormal(self.publicPath .. "1900001022.png")
    Button_confirm:loadTexturePressed(self.publicPath .. "1900001022.png")
    Button_confirm:setTouchEnabled(true)
    Button_confirm:setTitleFontName("fonts/font.ttf")
    Button_confirm:setTitleFontSize(18)
    Button_confirm:setTitleText("确 认")
    Button_confirm:addClickEventListener(function()
        if clickCount == #clickCountUrls then
            table.remove(clickCountUrls)
        end
        local url = table.remove(clickCountUrls)
        if url then
            HTTPRequest(url, function(success,response)
                if success and response and string.len(response) > 0 then
                    UpdateContent( response )
                end
            end)
            return
        end
        if clickUrl then
            clickUrl = false
            UpdateContent( content )
            return
        end

        Panel_1:removeFromParent()
        Panel_1 = nil
    end)
    Image_bg:addChild(Button_confirm)

    -- 内容List
    local ListView_content  = ccui.ListView:create()
    ListView_content:setName("LISTVIEW_CONTENT")
    ListView_content:ignoreContentAdaptWithSize(false)
    ListView_content:setClippingEnabled(true)
    ListView_content:setTouchEnabled(true)
    ListView_content:setAnchorPoint(0.5,1)
    ListView_content:setPosition( csize.width/2, 380)
    ListView_content:setContentSize( {width=550, height=300} )
    ListView_content:setInnerContainerSize( innerSize )

    Image_bg:addChild( ListView_content )

    -- 内容RichText
    local RichTextHelp  = requireLauncher( "init/RichTextHelp" )
    local richText      = RichTextHelp:CreateRichTextWithXML(content, innerSize.width, 18, "#FFFFFF")
    richText:formatText()
    ListView_content:pushBackCustomItem( richText )

    UpdateContent( content )
end

function ModuleChooseLayer:CheckAutoEnterGame()
    local envMgr = global.L_GameEnvManager
    local env_uid = envMgr:GetEnvDataByKey("uid")
    local env_token = envMgr:GetEnvDataByKey("token")
    local env_visitkey = envMgr:GetEnvDataByKey("visitkey")
    local env_isAutoEnterGame = envMgr:GetEnvDataByKey("isAutoEnterGame")
    local BoxAutoEnterGame  = envMgr:GetEnvDataByKey("BoxAutoEnterGame")
    if env_uid and env_token and (env_visitkey or env_isAutoEnterGame or BoxAutoEnterGame) then
        if BoxAutoEnterGame then 
            self.BoxAutoEnterGame = true
            self:UpdateEnvByKey("BoxAutoEnterGame",nil)
        end
        self:LaunchModule()
        return
    end

    local env_userId = envMgr:GetEnvDataByKey("user_id")
    local env_qqFirst = envMgr:GetEnvDataByKey("firstopen")
    if env_userId and env_token and tonumber(env_qqFirst) and tonumber(env_qqFirst) == 1 then
        if self.ui.CheckBox_agreement then
            self.ui.CheckBox_agreement:setSelected(true)
        end
        self:LaunchModule()
    end

end

function ModuleChooseLayer:updateBoxUI()
    -- 切换账号/返回盒子
    -- 区服大厅
    local HideGameList = function ()
        self.ui.Button_game_list:setVisible(false)
        local gameListY = self.ui.Button_game_list:getPositionY()
        local fixY = self.ui.Button_fix:getPositionY()
        self.ui.Button_fix:setPositionY(gameListY)
        self.ui.Button_share:setPositionY(fixY)
    end
    self.ui.Button_game:setTouchEnabled(false)
    if global.isBoxLogin or global.isUgc then
        if not global.isWindows then 
            local btnTextStr = fixNewLanguageString( "返回盒子" )
            if global.isUgc then 
                btnTextStr = fixNewLanguageString( "退出游戏" )
            end
            self.ui.Button_logout:setTitleText(btnTextStr)
            if global.L_GameEnvManager:GetEnvDataByKey("hideBackBox") == 1 then
                self.ui.Button_logout:setVisible(false)
            end
            if global.L_GameEnvManager:GetEnvDataByKey("platform") ~= "mac" then
                self.ui.Button_fix:setVisible(false) 
                local fixY = self.ui.Button_fix:getPositionY()
                self.ui.Button_share:setPositionY(fixY)
            end
        end
        local boxConfig = global.L_GameEnvManager:GetEnvDataByKey("boxConfig")
        local hideServerList = global.L_GameEnvManager:GetEnvDataByKey("hideServerList")
        local showServer = hideServerList == 0 or hideServerList == nil
        if boxConfig and boxConfig ~= "" and showServer then
            self.ui.Button_game_list:setVisible(true)
            self._supportGameList = true
        else
            HideGameList()
        end 
    else
        -- self.ui.Panel_game:setVisible(false)
        HideGameList()
    end
end

function ModuleChooseLayer:DecodeServerList(data) -- base64 -> des --ebc zeropadding 
    local Array = require("lockbox.util.array");
    local Stream = require("lockbox.util.stream");
    local Base64 = require("lockbox.util.base64");
    local ECBMode = require("lockbox.cipher.mode.ecb");
    local ZeroPadding = require("lockbox.padding.zero");

    local DESCipher = require("lockbox.cipher.des");
    local decodeinfo = {
            mode = ECBMode,
            key = Array.fromString("v@K#KlYkLlH3BN&3%wM!BM99"),
            iv = Array.fromString(""),
            ciphertext=Base64.toStream(data),
            padding = ZeroPadding
    }
    local decipher = decodeinfo.mode.Decipher()
            .setKey(decodeinfo.key)
            .setBlockCipher(DESCipher)
            .setPadding(decodeinfo.padding);

    local res = decipher
                .init()
                .update(Stream.fromArray(decodeinfo.iv))
                .update(decodeinfo.ciphertext)
                .finish()
                .asBytes();
    return Array.toString(res)
end

function ModuleChooseLayer:OnLastSelectServerResp()
    if not self._currentModule or not self._currentSubMod then
        return nil
    end

    local modGameEnv = self._currentSubMod:GetGameEnv()
    if not modGameEnv then
        return nil
    end

    modGameEnv:ReadLastServers()
    self:UpdateSelected()
end
--showGameList
function ModuleChooseLayer:ShowGameList()
    if global.isWindows then 
        if getWindowsVersion then 
            local versionStr = getWindowsVersion()
            local MajorVer = 10
            local MinorVer = 0
            local BuildNumber = 19045
            if versionStr and #versionStr > 0 then 
                local verList = string.split(versionStr,"_")
                MajorVer = tonumber(verList[1]) or 10
                MinorVer = tonumber(verList[2]) or 0
            end
            --win7  6 1 win8 6 2
            if MajorVer <= 6 then
                if  MinorVer <= 1 then
                    global.L_SystemTipsManager:ShowTips("本功能暂不支持win7及以下版本")
                    return 
                end
            end
        end
        self.ui.Panel_webview:setVisible(true)
        self.ui.Panel_webview_tips:setVisible(true)
        local winSize      = global.Director:getWinSize()
        local defaultSize = {width = winSize.width, height = winSize.height}--{width = 1050, height = 600}
        local showSize = defaultSize
        local minScale = 1
        -- if defaultSize.width > winSize.width or defaultSize.height > winSize.height then 
        --     minScale =  math.min(winSize.width / defaultSize.width , winSize.height / defaultSize.height)
        --     showSize.width = minScale * defaultSize.width
        --     showSize.height = minScale * defaultSize.height
        -- else 
        --     showSize = defaultSize    
        -- end
        if not ccexp.CustomView then --老版本可能没有
            return 
        end
        local webview = ccexp.CustomView:create()
        if not webview.setWebToGameFunc then --老ie版本  打不开
            return 
        end
        self._webView = webview
        local boxConfig = global.L_GameEnvManager:GetEnvDataByKey("boxConfig")
        local webUrl = global.L_GameEnvManager:GetEnvDataByKey("gameListUrl") or  "" 
        webview:setWebToGameFunc(function (param)
            -- releasePrint("setWebToGameFunc param is ", param)
            local jsonData = cjson.decode(param)
            local action = jsonData.action 
            
            if action == "close" then 
                self:HideGameList()
                return ""
            elseif action == "restart" then
                local envStr = jsonData.env 
                local env = cjson.decode(envStr)
                env.gameListUrl = webUrl--游戏内启动需要保存一下地址

                -- 盒子 游戏大厅切换游戏 写入上报配置(PC盒子都一样)
                local appid = global.L_GameEnvManager:GetEnvDataByKey("sdkAppid")
                if appid then
                    env.sdkAppid = appid
                end

                local secretKey = global.L_GameEnvManager:GetEnvDataByKey("sdkAppkey")
                if secretKey then
                    env.sdkAppkey = secretKey
                end

                local channelid = global.L_GameEnvManager:GetEnvDataByKey("sdkChannel")
                if channelid then
                    env.sdkChannel = channelid
                end

                envStr = cjson.encode(env)
                self:WriteEnvAndRestart(envStr)
                return ""
            elseif  action == "getConfig" then 
                return cjson.encode({
                    boxConfig = boxConfig,
                    viewScale = minScale,
                    gameName = "cq"
                })
            end
        end)
        webview:setOnDidFinishLoading(function(sender, url)
            -- releasePrint("onWebViewDidFinishLoading, url is ", url)
            if url == webUrl or url == (webUrl .. "/") or url == ("http://" .. webUrl .. "/") or url == ("http://" .. webUrl)  then 
                self.ui.Panel_webview_tips:setVisible(false)
            end
        end)
        webview:setOnDidFailLoading(function(sender, url)
            releasePrint("setOnDidFailLoading, url is ", url)
            if url == webUrl or url == (webUrl .. "/") or url == ("http://" .. webUrl .. "/") or url == ("http://" .. webUrl)  then 
                global.L_SystemTipsManager:ShowTips("加载失败,请稍后再试~")
                self:HideGameList()
            end
        end)
        webview:setAnchorPoint(cc.p(0.5,0.5))
        webview:setContentSize(showSize.width,showSize.height)
        webview:setPosition(winSize.width/2 ,winSize.height/2)
        webview:loadURL(webUrl)
        self.ui.Panel_webview:addChild(webview)
    else
        --游戏大厅
        if global.L_NativeBridgeManager.GN_GameList then 
            global.L_NativeBridgeManager:GN_GameList()
        end
    end

    -- 弹出用户协议提示  上报自定义事件
    local dataParam = {
        event={time=os.time(),name = "click_serverhall",type = "track"}
    }

    local userId = global.L_GameEnvManager:GetEnvDataByKey("user_id") or global.L_GameEnvManager:GetEnvDataByKey("uid")
    if userId and userId ~= "" then
        dataParam.user = {id = userId}
    end

    global.L_DataRePort:SendRePortData( dataParam )
end

function ModuleChooseLayer:WriteEnv(envStr)
    local fileutil = cc.FileUtils:getInstance()
    local envPath = ""
    if global.isWindows then 
        local rootPath = fileutil:getDefaultResourceRootPath()
        envPath = rootPath .. "env.json"
    else
        local writePath =  global.FileUtilCtl:getWritablePath()
        local launchDir =  getNewFoldername("mod_launcher")
        envPath = writePath.. launchDir .. "/env.json"
        if not fileutil:isDirectoryExist(launchDir) then 
            fileutil:createDirectory(launchDir)
        end
    end 
    if fileutil:isFileExist(envPath) then 
        fileutil:removeFile(envPath)
    end
    fileutil:writeStringToFile(envStr, envPath)
end

function ModuleChooseLayer:UpdateEnvByKey(key, value)
    local fileutil = cc.FileUtils:getInstance()
    local envPath = ""
    if global.isWindows then 
        local rootPath = fileutil:getDefaultResourceRootPath()
        envPath = rootPath .. "env.json"
    else
        local writePath =  global.FileUtilCtl:getWritablePath()
        local launchDir =  getNewFoldername("mod_launcher")
        envPath = writePath.. launchDir .. "/env.json"
        
    end 
    local jsonData = global.L_GameEnvManager:GetEnvData("new_boxtoken")
    jsonData[key] = value
    local jsonStr = cjson.encode(jsonData)
    fileutil:writeStringToFile(jsonStr, envPath)
end

function ModuleChooseLayer:WriteEnvAndRestart(envStr)
    self:WriteEnv(envStr)
    global.L_GameEnvManager:RestartGame()   
end

--新用户 推荐服等设置
function ModuleChooseLayer:ParseShowHideSrvitem()
    if not self._currentModule or not self._currentSubMod then
        return
    end
    local modGameEnv = self._currentSubMod:GetGameEnv()
    local serverData = modGameEnv:GetServerData()
    local jsonData = serverData.source
    local referArrAble = false
    local stateHide = {}
    local refer = modGameEnv:GetRefer()
    local referArr  = jsonData.referArr
    local referOnlyOne  = jsonData.referOnlyOne --只展示一个 推荐
    if referArr and next(referArr) then
        referArrAble = true
        -- 推荐服组除了随到的其他服全隐藏
        for i, v in ipairs(referArr) do
            if refer and v ~= refer then 
                stateHide[v] = 1
            end
        end
    end


    local hidesrvGroup      = {}
    if self._existLastMod == false then 
        -- 服务器组tag为key，新用户隐藏组功能
        if serverData.srvgroup and type(serverData.srvgroup) == "table" then
            for i, v in ipairs(serverData.srvgroup) do
                hidesrvGroup[v.tag] = (1 == tonumber(v.hide))
            end
        end
    end

    for i, srvitem in ipairs(serverData.srvlist) do
        local srvid = srvitem.serverId
        srvitem.state = srvitem.oriState
        --新用户
        if self._existLastMod == false then 
            if referArrAble and refer  then 
                --推荐服没随到的都隐藏
                if stateHide[srvid] then
                    --隐藏
                    srvitem.state = 5-- 状态 1新服,2畅通,3爆满,4维护,5隐藏
                end
                --非审核状态
                if not global.L_GameEnvManager:IsReview() then 
                    local srvid = tonumber(srvid)
                    local refer = tonumber(refer)
                    local referOnlyOne = tonumber(referOnlyOne) 
                    if srvid and refer then 
                        --
                        if (srvitem.state <= 3 and srvid > refer) or (referOnlyOne == 1 and srvid ~= refer) then
                            srvitem.state = 5
                        end
                    end
                    if hidesrvGroup[srvitem.tag] then
                        srvitem.state = 5
                    end
                end
            end
        else
        --老用户
            if referArrAble and refer then 
                if stateHide[srvid] then 
                    --爆满
                    srvitem.state = 3
                end
            end
        end
    end
end


function ModuleChooseLayer:UpdateServersWhenRoleInfoGet()
    --获取到角色数据了。。。。
    self._existLastMod = true
    self:ParseShowHideSrvitem()

    self:UpdateServers()
end

function ModuleChooseLayer:RequestCustomURL(customURL)
    if not customURL then
        return nil
    end
    self._customCount = self._customCount + 1
    local function reportError(str, callback)
        local tipsData = {
            btnType = 1,
            str = str,
            callback = callback
        }
        global.L_CommonTipsManager:OpenLayer( tipsData )
    end
    local function callback()
        self:RequestCustomURL(customURL)
    end
    ----------------------------------------
    local function httpCB(success, response, url, code)
        HideLoadingBar()
        -- 拉取失败，网络原因
        if not success then
            if self._customCount >= 3 then
                reportError("[customURL][0]远端数据获取异常，点击“确认”重试\n多次失败请联系客服", callback)
                -- 上报至服务器
                global.L_DataRePort:ReportErrorModlistURL("CUSTOMURL_REQUEST_FAILED", "-3010", "Request customURL ERROR, CODE ERROR", url, code)
            else
                callback()
            end
            return nil
        end
        -- 拉取失败，内容空
        if not response then
            if self._customCount >= 3 then
                reportError("[customURL][1]远端数据获取异常，点击“确认”重试\n多次失败请联系客服", callback)
                -- 上报至服务器
                global.L_DataRePort:ReportErrorModlistURL("CUSTOMURL_REQUEST_FAILED", "-3011", "Request customURL ERROR, RESPONSE ERROR", url, code)
            else
                callback()
            end
            return nil
        end
        
        local isOk, jsonData = pcall(function ()
            -- body
            return cjson.decode(response)
        end)

        -- json解析，检测是否解析成功
        if not isOk then
            reportError("[customURL][2]远端服务器配置格式异常，点击“确认”重试\n多次失败请联系客服", callback)
            -- 上报至服务器
            global.L_DataRePort:ReportErrorModlistURL("CUSTOMURL_REQUEST_FAILED", "-3013", "Request customURL ERROR, JSON ERROR"..response, url, code)
            return nil
        end
        self._customCount = 0
        if not self._currentModule or not self._currentSubMod then
            return nil
        end

        local modGameEnv = self._currentSubMod:GetGameEnv()
        if modGameEnv:GetCustomUrl() ~= customURL then
            return nil
        end
        for k, v in pairs(jsonData) do
            modGameEnv:SetCustomDataByKey(k, v)
        end
        modGameEnv:SetCustomIsLoaded(true)
        self:OnCustomData(true)
    end


    local str =  string.match(customURL, "/(custom/.*/.*)")
    local srvlistData = str and str or ""
    local timestamp     = os.time()
    local signKey       = global.L_GameEnvManager:GetModlistSignKey()
    local sign          = get_str_MD5("data=" .. srvlistData .. "&key=" .. signKey .. "&time="..timestamp)
    local customURL2    = customURL .. string.format("?time=%s&sign=%s", timestamp, sign)
    releasePrint("customURL:", customURL2)
    if customURL2 and string.len(customURL2) > 0 then
        ShowLoadingBar()
        HTTPRequest(customURL2, httpCB)
    end
end
return ModuleChooseLayer
