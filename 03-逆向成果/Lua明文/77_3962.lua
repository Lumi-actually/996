global = global or {}
local M = global

M.frameworkCore = "mmoclient"

-- ************************** init cpp ctl **************************
-- init cocos2d ctl
M.Director               = cc.Director:getInstance()
M.TextureCache           = M.Director:getTextureCache()
M.Scheduler              = M.Director:getScheduler()
M.OpenGLView             = M.Director:getOpenGLView()
M.EventDispatcher        = M.Director:getEventDispatcher()
M.ActionManager          = M.Director:getActionManager()
M.FileUtilCtl            = cc.FileUtils:getInstance()
M.WritablePath           = M.FileUtilCtl:getWritablePath()
M.Platform               = cc.Application:getInstance():getTargetPlatform()
M.GLProgramCache         = cc.GLProgramCache:getInstance()
M.SpriteFrameCache       = cc.SpriteFrameCache:getInstance()
M.ScriptHandlerMgr       = ScriptHandlerMgr:getInstance()

-- init mmoclient ctl
M.networkCtl             = nil
M.sceneGraphCtl          = nil
M.gamePlayerController   = nil
M.netPlayerController    = nil
M.sceneManager           = nil
M.actorManager           = nil
M.monsterManager         = nil
M.playerManager          = nil
M.npcManager             = nil
M.dropItemManager        = nil
M.sceneEffectManager     = nil
M.FrameAnimManager       = nil
M.LuaBridgeCtl           = nil
M.BuffManager            = nil
M.gameWorldController    = nil
M.userInputController    = nil
M.BehaviorController     = nil
M.ActorEffectManager     = nil
M.modBridgeController    = nil
M.HttpDownloader         = nil          -- 下载(URL)
M.gameEnvironment        = nil
M.gameStateCtl           = nil
M.NativeBridgeCtl        = nil
M.skillManager           = nil
M.HUDManager             = nil
M.ResDownloader          = nil
M.darkNodeManager        = nil


-- init lua global member
M.Facade                 = nil          -- pureMVC facade
M.GameStateController    = nil
M.DesignPolicy           = cc.ResolutionPolicy.FIXED_WIDTH

M.ActorAttr              = {}

-- ************************** init cpp ctl end **************************

-- ************************** world ui zOrder **************************
M.UIZ = 
{
    UI_BOTTOM                   = -3,               -- 战争迷雾最底层
    UI_RTOUCH                   = -2,               -- 按键触摸层
    UI_MAIN                     = -1,               -- 主界面
    UI_NORMAL                   = 1,                -- 正常界面(全屏)
    UI_FUNC                     = 2,                -- 功能按钮
    UI_LOADING                  = 3,                -- loading层
    UI_TOBOX                    = 4,                -- 弹出框
    UI_LOADINGBAR               = 5,                -- 菊花转
    UI_NOTICE                   = 6,                -- 滚动层提示
    UI_MOUSE                    = 7,                -- 鼠标操作层
    UI_MASK                     = 8,                -- 遮盖一切
}
-- ************************** world ui zOrder end **************************


-- macro
M.isWindows = M.Platform == cc.PLATFORM_OS_WINDOWS or M.Platform == cc.PLATFORM_OS_HARMONY_PC
M.isAndroid = M.Platform == cc.PLATFORM_OS_ANDROID
M.isIOS = M.Platform == cc.PLATFORM_OS_IPAD or M.Platform == cc.PLATFORM_OS_IPHONE
M.isOHOS = M.Platform == cc.PLATFORM_OS_HARMONY
M.isMobile = M.isAndroid or M.isIOS or M.isOHOS

-- play mode
M.isWinPlayMode = global.CURRENT_OPERMODE == global.OPERMODE_WINDOWS

-- init notice table 
M.NoticeTable = require("config/NotificationTable")

-- init Proxy table
M.ProxyTable = require("config/ProxyTable")

-- init Game Constants
M.MMO = require("config/mmoConstants")

-- init MsgType
M.MsgType = require("network/netMessageDef")

-- init MsgType
M.SLT = require("config/ShareLuaTable")

M.SUIComponentTable = require("config/SUIComponentTable")
M.BehaviorConfig = require("config/BehaviorConfig") 
M.ConstantConfig = require("config/ConstantConfig")
