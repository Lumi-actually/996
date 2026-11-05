global = global or {}
local M = global

-- ************************** init cpp ctl **************************
-- init cocos2d ctl
M.Director               = cc.Director:getInstance()
M.FileUtilCtl            = cc.FileUtils:getInstance()
M.GUIReader              = ccs.GUIReader:getInstance()
M.Platform               = cc.Application:getInstance():getTargetPlatform()
M.Scheduler              = M.Director:getScheduler()
M.GLProgramCache         = cc.GLProgramCache:getInstance()
M.TextureCache           = M.Director:getTextureCache()
M.SpriteFrameCache       = cc.SpriteFrameCache:getInstance()
M.ScriptHandlerMgr       = ScriptHandlerMgr:getInstance()

-- init mmoclient ctl
M.L_NativeBridgeManager    = nil
M.L_ModuleManager          = nil
M.L_GameEnvManager         = nil
M.L_GameLayerManager       = nil
M.L_LoadingManager         = nil
M.L_SystemTipsManager      = nil
M.L_ModuleChooseManager    = nil
M.L_CommonTipsManager      = nil

-- macro
cc.PLATFORM_OS_WINDOWS = 0
cc.PLATFORM_OS_LINUX   = 1
cc.PLATFORM_OS_MAC     = 2
cc.PLATFORM_OS_ANDROID = 3
cc.PLATFORM_OS_IPHONE  = 4
cc.PLATFORM_OS_IPAD    = 5
cc.PLATFORM_OS_BLACKBERRY = 6
cc.PLATFORM_OS_NACL    = 7
cc.PLATFORM_OS_EMSCRIPTEN = 8
cc.PLATFORM_OS_TIZEN   = 9
cc.PLATFORM_OS_WINRT   = 10
cc.PLATFORM_OS_WP8     = 11
cc.PLATFORM_OS_HARMONY = 12
cc.PLATFORM_OS_HARMONY_PC = 13

M.isWindows = M.Platform == cc.PLATFORM_OS_WINDOWS or M.Platform == cc.PLATFORM_OS_HARMONY_PC
M.isAndroid = M.Platform == cc.PLATFORM_OS_ANDROID
M.isIOS = M.Platform == cc.PLATFORM_OS_IPAD or M.Platform == cc.PLATFORM_OS_IPHONE
M.isOHOS = M.Platform == cc.PLATFORM_OS_HARMONY
M.isMobile = M.isAndroid or M.isIOS or M.isOHOS

M.VersionName = {
    stab    = "stab",
    beta    = "beta",
    alpha   = "alpha",

    default = "stab",
}

M.IS_PORTRAIT = false

M.DesignSize_Win = {width = 1136, height = 640 }  -- window 设计分别率
M.DesignSize_Oth = {width = 1136, height = 640 }  -- other 设计分辨率


-- M.DeviceSize_Win = {width = 800, height = 600 }   -- window 窗口大小(800 * 600)
M.DeviceSize_Win = {width = 1136, height = 640 }  -- window 窗口大小(ip5/5s)
-- M.DeviceSize_Win = {width = 1280, height = 720 }  -- window 窗口大小(720P)
-- M.DeviceSize_Win = {width = 1920, height = 1080 } -- window 窗口大小(1080P)
-- M.DeviceSize_Win = {width = 2048, height = 1546 } -- window 窗口大小(ipad mini)
-- M.DeviceSize_Win = {width = 2040, height = 1080 } -- window 窗口大小(xiaomi MIX)
-- M.DeviceSize_Win = {width = 2436, height = 1125 } -- window 窗口大小(iphoneX)
-- M.DeviceSize_Win = {width = 2160, height = 1080 } -- window 窗口大小(VIVO X20)
M.DeviceWith_Win = 1920 -- window窗口最大分辨率宽度
M.DeviceHeight_Win = 1080 -- window窗口最大分辨率高度

M.DeviceZoom_Win = 1            -- window 窗口比例(用于缩小大于显示器尺寸的窗口大小)

M.isDebugMode      = cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS and LuaBridgeCtl:Inst():GetModulesSwitch(5) == 1    -- 开发模式 windows & xx
M.isGMMode         = cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS and LuaBridgeCtl:Inst():GetModulesSwitch(5) == 2    -- GM模式 windows & xx
M.OPERMODE_WINDOWS = 1
M.OPERMODE_MOBILE  = 2
M.CURRENT_OPERMODE = (M.isWindows and M.OPERMODE_WINDOWS or M.OPERMODE_MOBILE)

M.Modules_Index_Cpp_Version = 19 -- c++版本
----c++版本---------
M.CPP_VERSION_LABEL_TTF = 1       -- 修复ttf宋体崩溃  ttf显示优化
--------------------

M.WINIS4K = false