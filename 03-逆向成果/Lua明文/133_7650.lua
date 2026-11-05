local gameStateActive = class('gameStateActive')

function gameStateActive:ctor()
end

function gameStateActive:getStateType()
    return global.MMO.GAME_STATE_ACTIVE
end

function gameStateActive:onEnter()
    package.loaded["LuaExtend"] = nil

    self:InitController()
    self:InitUserData()
    self:InitPlatform()
    self:Init3rdparty()

    -- goto init
    global.Facade:sendNotification( global.NoticeTable.ChangeGameState, global.MMO.GAME_STATE_INIT )
    return 1
end

function gameStateActive:onEnd()--重启
    return 1
end

function gameStateActive:onExit()
    return 1
end

function gameStateActive:InitPlatform()
    global.OperatingMode        = (global.CURRENT_OPERMODE == global.OPERMODE_WINDOWS and global.MMO.OPERATING_MODE_WINDOWS or global.MMO.OPERATING_MODE_MOBILE)
    global.MouseEventOpen       = global.isWinPlayMode

    if GUIDefine.DESIGN_SIZE_MOBILE and next(GUIDefine.DESIGN_SIZE_MOBILE) then
        local size = {width = ConvertToEven(GUIDefine.DESIGN_SIZE_MOBILE.width), height = ConvertToEven(GUIDefine.DESIGN_SIZE_MOBILE.height)}
        global.DesignSize_Oth = size
    end

    if SL._DEBUG then
        SL._debugTTFScaleFactor = nil
        local userData = UserData:new("phone_mode_device")
        local cjson    = require("cjson")
        local key      = global.isWinPlayMode and "pc" or "phone"
        local jsonStr  = userData:getStringForKey(key, "")
        if jsonStr and string.len(jsonStr) > 0 then
            local size = cjson.decode(jsonStr)

            size = {width = ConvertToEven(size.width), height = ConvertToEven(size.height)}
            global.DeviceSize_Win = size
            global.DesignSize_Win = not global.isWinPlayMode and global.DesignSize_Oth or size 
        elseif not global.isWinPlayMode then
            global.DeviceSize_Win = global.DesignSize_Oth
            global.DesignSize_Win = global.DesignSize_Oth
        end

        local glview = global.Director:getOpenGLView()
        glview:setFrameSize(global.DeviceSize_Win.width, global.DeviceSize_Win.height)
        glview:setFrameZoomFactor(global.DeviceZoom_Win)
    elseif cc.PLATFORM_OS_WINDOWS == global.Platform then
        global.DeviceSize_Win = {width = ConvertToEven(global.DeviceSize_Win.width), height = ConvertToEven(global.DeviceSize_Win.height)}
        local glview = global.Director:getOpenGLView()
        glview:setFrameSize(global.DeviceSize_Win.width, global.DeviceSize_Win.height)
        glview:setFrameZoomFactor(global.DeviceZoom_Win)
    end

    local frameSize   = global.Director:getOpenGLView():getFrameSize()
    local frameFactor = frameSize.width / frameSize.height
    if frameFactor > 1.8 then       -- 17:9 = 1.889
        global.DesignPolicy = cc.ResolutionPolicy.FIXED_HEIGHT
    else                            -- 16:9 = 1.778
        global.DesignPolicy = cc.ResolutionPolicy.FIXED_WIDTH
    end

    local rData = {}
    rData.rType = global.DesignPolicy
    if global.isWindows then
        rData.size  = global.DesignSize_Win
    else
        rData.size  = global.DesignSize_Oth
    end
    global.Facade:sendNotification( global.NoticeTable.ChangeResolution, rData )

    -- 输入法禁用
    if global.isWindows and disableIME then
        disableIME()
    end

    -- 下划线偏移
    if global.Director.setUnderlineOffsetY then
        global.Director:setUnderlineOffsetY(0)
    end

    -- 富文本对齐方式
    if global.Director.setRichTextVerticalAlignment then
        global.Director:setRichTextVerticalAlignment(1)
    end

    -- 文件不存在提醒
    global.FileUtilCtl:setPopupNotify(false)


    -- 窗口名
    if global.isWindows then
        local currentModule = global.L_ModuleManager:GetCurrentModule()
        local moduleGameEnv = currentModule:GetGameEnv()
        local server        = moduleGameEnv:GetSelectedServer()
        local glview        = global.Director:getOpenGLView()
        local viewName = global.L_GameEnvManager:GetEnvDataByKey("viewName")
        if viewName then
            local nameStr = string.format( "%s-%s", viewName, server.serverName)
            glview:setViewName(nameStr)
        else
            glview:setViewName(server.serverName)
        end
    end

    ----------ttfScale-----
    -- c++版本大于等于1
    if LuaBridgeCtl:Inst():GetModulesSwitch(global.MMO.Modules_Index_Cpp_Version) >= global.MMO.CPP_VERSION_LABEL_TTF then 
        local glview     = global.Director:getOpenGLView()
        local frameSize  = glview:getFrameSize()
        local DesignSize = glview:getDesignResolutionSize()
        local ttfscale   = 1
        if global.DesignPolicy == cc.ResolutionPolicy.FIXED_HEIGHT then 
            ttfscale = frameSize.height/DesignSize.height
        elseif global.DesignPolicy == cc.ResolutionPolicy.FIXED_WIDTH then 
            ttfscale = frameSize.width/DesignSize.width
        end
        cc.Label:setTTFAliasTexParameters(true)
        cc.Label:setTTFScaleFactor(ttfscale)
        if SL._DEBUG then
            SL._debugTTFScaleFactor = ttfscale
        end
    end

    -- 
    cc.Texture2D.setDefaultAlphaPixelFormat( cc.TEXTURE2_D_PIXEL_FORMAT_AUTO )
    global.Director:setProjection( cc.DIRECTOR_PROJECTION2_D )
end

function gameStateActive:Init3rdparty()
    local luaBridge = LuaBridgeCtl:Inst()
    local inited    = luaBridge:IsInit3rdparty()
    if not inited then
        print( "init 3rdparty")

        if cc.PLATFORM_OS_ANDROID == global.Platform then
            -- init bugly
            local config = require( "config/ThirdPartyConfig" )
            initCrashReport( config.BuglyID, config.BuglyDebug )
        end

        luaBridge:Set3rdpartyInited( true )
    else
        print( "3rdparty inited")
    end
end

function gameStateActive:InitController()
    -- NativeBridgeCtl
    if not global.NativeBridgeCtl then
        global.NativeBridgeCtl = NativeBridgeCtl:Inst()
    end

    -- 关闭CMD
    local cmd = requireCommand( "gamestates/ShutdownGameCommand" )
    global.Facade:registerCommand( global.NoticeTable.ShutdownGame, cmd )

    -- 重启CMD
    local RestartCmd = requireCommand( "gamestates/RestartGameCommand" )
    global.Facade:registerCommand( global.NoticeTable.RestartGame, RestartCmd )

    -- 设计分辨率
    local ChangeResolutionCmd = requireCommand( "ChangeResolutionCommand" )
    global.Facade:registerCommand( global.NoticeTable.ChangeResolution, ChangeResolutionCmd )

    -- game env
    local gameEnvironment = requireProxy( "GameEnvironmentProxy" )
    local proxy = gameEnvironment.new( global.ProxyTable.GameEnvironmentProxy )
    global.Facade:registerProxy( proxy )
end

--统一文件夹//localUserData
function gameStateActive:InitUserData()
    local module        = global.L_ModuleManager:GetCurrentModule()
    local modulePath    = module:GetSubModPath()
    local moduleGameEnv = module:GetGameEnv()
    local storagePath   = string.format("%s%s", modulePath,global.MMO.LOCAL_USERDATA)  
    local WritablePath  = global.WritablePath
    -- 文件夹创建
    local modulePathDir = WritablePath..modulePath
    if not global.FileUtilCtl:isDirectoryExist(modulePathDir) then
        global.FileUtilCtl:createDirectory(modulePathDir)
    end
    if not global.FileUtilCtl:isDirectoryExist(WritablePath..storagePath) then
        global.FileUtilCtl:createDirectory(WritablePath..storagePath)
    end
    UserData:Cleanup()
    UserData:setVersionPath(storagePath)
end

return gameStateActive