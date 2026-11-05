local gameStateInit = class('gameStateInit')

local SplashFadeInTime = 0.2
local SplashFadeOutTime = 0.1
local SplashFiles = {"splash.png"}   -- 闪屏配置

function gameStateInit:ctor()
    self._currScene = nil
end

function gameStateInit:getStateType()
    return global.MMO.GAME_STATE_INIT
end

function gameStateInit:onEnter()
    -- reset FPS
    global.Director:setAnimationInterval(1 / 60)

    self:InitConfig()
    self:InitProxy()
    self:InitCommand()
    self:InitMediator()
    self:InitDownloader()
    self:InitDebug()

    -- init randomseed
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))

    -- splash and goto login
    self:InitSplash()

    if global.isWinPlayMode then
        SetCustomCursor(global.MMO.CURSOR_TYPE_NORMAL)
    end
    return 1
end

function gameStateInit:onEnd()
    return 1
end

function gameStateInit:onExit()
    return 1
end

function gameStateInit:InitConfig()
    -- scene
    local scene = cc.Scene:create()
    local currScene = global.Director:getRunningScene()
    if not currScene then
        global.Director:runWithScene(scene)
    else
        global.Director:replaceScene(scene)
    end
    self._currScene = scene

    -- 是否联运交易行
    local currentModule = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv = currentModule:GetGameEnv()
    local exchangeIsTrade = moduleGameEnv:GetCustomDataByKey("exchangeIsTrade")
    if exchangeIsTrade and exchangeIsTrade == 1 then
        global.OtherTradingBank = true -- 联运 交易行
    end

    -- http download
    if not global.HttpDownloader then
        global.HttpDownloader = httpDownloader:Inst()
    end

    -- environment
    if not global.gameEnvironment then
        global.gameEnvironment = gameEnviroment:Inst()
    end

    -- network
    if not global.networkCtl then
        global.networkCtl = require("network/LuaNetworkController").new()
    end

    -- LuaBridgeCtl
    if not global.LuaBridgeCtl then
        global.LuaBridgeCtl = LuaBridgeCtl:Inst()
    end

    -- FrameAnimManager
    if not global.FrameAnimManager then
        local actorSequFrameAnimManager = require("animation/actorSequFrameAnimManager")
        global.FrameAnimManager = actorSequFrameAnimManager.new()
    end

    -- CustomCache
    if not global.CustomCache then
        local CustomCache = requireUtil("CustomCache")
        global.CustomCache = CustomCache.new()
    end

    -- SUIManager
    if not global.SUIManager then
        local SUIManager = require("sui/SUIManager")
        global.SUIManager = SUIManager:Inst()
    end

    -- SWidgetCache
    if not global.SWidgetCache then
        local SWidgetCache = require("sui/SWidgetCache")
        global.SWidgetCache = SWidgetCache.new()
    end

    -- mod bridge
    if not global.modBridgeController then
        global.modBridgeController = require("logic/ModBridgeController").new()
    end

    -- 
    local UserInputController = require("logic/UserInputController")
    global.userInputController = UserInputController:Inst()
end

function gameStateInit:InitProxy()
    local facade = global.Facade
    local proxy = nil

    -- string_table
    proxy = requireProxy("StringTableProxy")
    facade:registerProxy(proxy.new())

    -- color style
    proxy = requireProxy("ColorStyleProxy")
    facade:registerProxy(proxy.new())

    -- login proxy
    proxy = requireProxy("LoginProxy")
    facade:registerProxy(proxy.new())

    -- Auth Proxy
    proxy = requireProxy("AuthProxy")
    facade:registerProxy(proxy.new())

    -- 敏感词
    proxy = requireProxy("SensitiveWordProxy")
    facade:registerProxy(proxy.new())

    -- audio 
    proxy = requireProxy("AudioProxy")
    facade:registerProxy(proxy.new())

    -- model config proxy
    proxy = requireProxy("ModelConfigProxy")
    facade:registerProxy(proxy.new())

    -- NativeBridgeProxy
    proxy = requireProxy("NativeBridgeProxy")
    facade:registerProxy(proxy.new())

    -- TradingBankProxy
    proxy = requireProxy("TradingBankProxy")
    facade:registerProxy(proxy.new())

    proxy = requireProxy("OtherTradingBankProxy")
    facade:registerProxy(proxy.new())

    -- SUIComponentProxy
    proxy = requireProxy("SUIComponentProxy")
    facade:registerProxy(proxy.new())

    -- MetaValueProxy
    proxy = requireProxy("MetaValueProxy")
    facade:registerProxy(proxy.new())

    -- ConditionProxy
    proxy = requireProxy("ConditionProxy")
    facade:registerProxy(proxy.new())

    -- Data RePort
    proxy = requireProxy("DataRePortProxy")
    facade:registerProxy(proxy.new())

    -- DataTrackProxy
    proxy = requireProxy("DataTrackProxy")
    facade:registerProxy(proxy.new())

    -- NoticeProxy
    proxy = requireProxy("NoticeProxy")
    facade:registerProxy(proxy.new())
     
    --EquipProxy
    proxy = requireProxy("EquipProxy")
    facade:registerProxy(proxy.new())


end

function gameStateInit:InitCommand()
    local facade = global.Facade

    local cmd = requireCommand("gamestates/LoadingCompletedCommand")
    facade:registerCommand(global.NoticeTable.LoadingCompleted, cmd)
    local cmd = requireCommand("gamestates/LoadingBeginCommand")
    facade:registerCommand(global.NoticeTable.LoadingBegin, cmd)

    local GameWorldConfirmCommand = requireCommand("gamestates/GameWorldConfirmCommand")
    facade:registerCommand(global.NoticeTable.GameWorldConfirm, GameWorldConfirmCommand)
    local GameWorldInfoInitCommand = requireCommand("gamestates/GameWorldInfoInitCommand")
    facade:registerCommand(global.NoticeTable.GameWorldInfoInit, GameWorldInfoInitCommand)

end

function gameStateInit:InitMediator()
    local facade = global.Facade
    local mediator = nil

    -- register audio mgr
    mediator = requireMediator("audio/AudioMediator")
    facade:registerMediator(mediator.new())

    -- rigister layer facade
    mediator = requireMediator("LayerFacadeMediator")
    local lFMediator = mediator.new()
    facade:registerMediator(lFMediator)
    lFMediator:InitOnEnterActive(self._currScene)

    -- notice
    mediator = requireMediator("message_layer/NoticeMediator")
    facade:registerMediator(mediator.new())

    -- login
    mediator = requireMediator("login_layer/LoginServerMediator")
    facade:registerMediator(mediator.new())
    mediator = requireMediator("login_layer/LoginRoleLockMediator")
    facade:registerMediator(mediator.new())
    mediator = requireMediator("login_layer/LoginVersionMediator")
    facade:registerMediator(mediator.new())

    mediator = requireMediator("trading_bank_layer/TradingBankPhoneLayerMediator")
    global.Facade:registerMediator(mediator.new())
    mediator = requireMediator("trading_bank_layer/TradingBankTipsLayerMediator")
    global.Facade:registerMediator(mediator.new())
    mediator = requireMediator("trading_bank_layer/TradingBankTips2LayerMediator")
    global.Facade:registerMediator(mediator.new())

    -------------------三方交易行
    mediator = requireMediator("trading_bank_layer_other/TradingBankPhoneLayerMediator_other")
    global.Facade:registerMediator(mediator.new())
    mediator = requireMediator("trading_bank_layer_other/TradingBankTipsLayerMediator_other")
    global.Facade:registerMediator(mediator.new())
    mediator = requireMediator("trading_bank_layer_other/TradingBankTips2LayerMediator_other")
    global.Facade:registerMediator(mediator.new())

    -- delay exit game
    mediator = requireMediator("delay_exit_game/DelayExitGameMediator")
    global.Facade:registerMediator(mediator.new())

    -- couping
    mediator = requireMediator("couping/GameStateMediator")
    global.Facade:registerMediator(mediator.new())
end

function gameStateInit:InitDownloader()
    -- HttpDownloader
    local module        = global.L_ModuleManager:GetCurrentModule()
    local modulePath    = module:GetSubModPath()
    local moduleGameEnv = module:GetGameEnv()
    local rootDomain    = moduleGameEnv:GetSceneDownloadUrl()
    local resVersionOri = moduleGameEnv:GetSceneDownloadVer()
    local storagePath   = global.WritablePath .. modulePath

    local subMod = module:GetCurrentSubMod()
    local subModInfo = subMod:GetSubModInfo()
    local gameid = subMod:GetOperID()
    local xk = subMod:GetXK()
    local resVersion = resVersionOri

    if GetCdnSign then
        local sign = GetCdnSign(gameid, global.modListSrvTime, xk or "")
        local param = string.format("gameId=%s&time=%s&sign=%s", gameid, global.modListSrvTime, sign)
        resVersion = string.format("%s&%s", resVersionOri, param)

        -- 刷新时间戳 cdn鉴权
        global.modListSrvTimeCallFuncs = {}
        local refResTime = function()
            local sign = GetCdnSign(gameid, global.modListSrvTime, xk or "")
            local param = string.format("gameId=%s&time=%s&sign=%s", gameid, global.modListSrvTime, sign)
            local resVersion = string.format("%s&%s", resVersionOri, param)
            global.HttpDownloader:SetResourceVer(resVersion)
        end
        table.insert(global.modListSrvTimeCallFuncs, refResTime)
    end

    global.HttpDownloader:SetTimeOut(30)
    global.HttpDownloader:SetSpeedLimit(0)
    global.HttpDownloader:SetResourceVer(resVersion)
    global.HttpDownloader:SetDownloadURL(rootDomain)
    global.HttpDownloader:SetDownloadDir(storagePath)
    global.HttpDownloader:SetDownloadProgress(nil)

    -- 文件夹创建
    if not global.FileUtilCtl:isDirectoryExist(storagePath) then
        global.FileUtilCtl:createDirectory(storagePath)
    end
    local stabPath = global.WritablePath .. module:GetStabPath()
    if not global.FileUtilCtl:isDirectoryExist(stabPath) then
        global.FileUtilCtl:createDirectory(stabPath)
    end
    local items = 
    {
        "anim/", 
        "anim/effect/", 
        "anim/hair/", 
        "anim/monster/", 
        "anim/npc/", 
        "anim/player/", 
        "anim/weapon/",
        "anim/shield/", 
        "anim/wings/", 
        
        "mp3/", 
        
        "scene/", 
        "scene/map/", 
        "scene/objects/", 
        "scene/smtiles/",
        "scene/tiles/", 
        "scene/uiminimap/"
    }
    for _, v in ipairs(items) do
        local path = storagePath .. v
        if not global.FileUtilCtl:isDirectoryExist(path) then
            global.FileUtilCtl:createDirectory(path)
        end
        local path = stabPath .. v
        if not global.FileUtilCtl:isDirectoryExist(path) then
            global.FileUtilCtl:createDirectory(path)
        end
    end

    -- dev
    if global.isWindows and (global.isDebugMode or global.isGMMode) then
        local items = 
        {
            "anim/", 
            "anim/effect/", 
            "anim/hair/", 
            "anim/monster/", 
            "anim/npc/", 
            "anim/player/", 
            "anim/weapon/",
            "anim/shield/", 
            "anim/wings/", 
            
            "mp3/", 
            
            "scene/", 
            "scene/map/", 
            "scene/objects/", 
            "scene/smtiles/",
            "scene/tiles/", 
            "scene/uiminimap/",

            ".996", 
            "fonts", 
            "mp3", 

            "res", 
            "res/buff_icon", 
            "res/custom", 
            "res/item", 
            "res/item/item_0",
            "res/item_ground",
            "res/item_ground/item_ground_0",
            "res/player_show",
            "res/player_show/player_show_0",
            "res/player_show/player_show_1",
            "res/player_show/player_show_10",
            "res/player_show/player_show_2",
            "res/player_show/player_show_3",
            "res/player_show/player_show_4",
            "res/player_show/player_show_5",
            "res/player_show/player_show_6",
            "res/player_show/player_show_7",
            "res/player_show/player_show_8",
            "res/player_show/player_show_9",
            "res/skill_icon", 
            "res/skill_icon_c", 
            "res/Topwear", 
            "res/private",
            "res/private/996hz",
            "res/private/announce",
            "res/private/auction",
            "res/private/auction-win32",
            "res/private/bag_ui",
            "res/private/bag_ui/bag_ui_mobile",
            "res/private/bag_ui/bag_ui_win32",
            "res/private/bag_ui_hero",
            "res/private/bag_ui_hero_win32",
            "res/private/bag_ui_mobile",
            "res/private/baitan_ui",
            "res/private/baitan_ui/baitan_ui_mobile",
            "res/private/baitan_ui/baitan_ui_win32",
            "res/private/be_strong",
            "res/private/box_996_ui",
            "res/private/chat",
            "res/private/chat/drop",
            "res/private/compound_items_ui",
            "res/private/compound_items_ui/win32",
            "res/private/create_hero",
            "res/private/damage_num",
            "res/private/forge_acupoint",
            "res/private/friend",
            "res//private/friend_win32",
            "res/private/guide",
            "res/private/guild_ui",
            "res/private/guild_ui_win32",
            "res/private/gui_edit",
            "res/private/gui_edit/scroll",
            "res/private/hud",
            "res/private/hurt_tips",
            "res/private/hzlb",
            "res/private/internal",
            "res/private/internal/meridian_ui",
            "res/private/internal_win32",
            "res/private/internal_win32/meridian_ui",
            "res/private/item_tips",
            "res/private/item_tips/sword_soul",
            "res/private/item_tips_win32",
            "res/private/item_tips_win32/sword_soul",
            "res/private/loading",
            "res/private/login",
            "res/private/login/account",
            "res/private/login/open_door",
            "res/private/mail",
            "res/private/mail_win32",
            "res/private/main",
            "res/private/main/assist",
            "res/private/main/assist/near_panel",
            "res/private/main/bottom",
            "res/private/main/bubble_tips",
            "res/private/main/Button",
            "res/private/main/Button_1",
            "res/private/main/Button_3",
            "res/private/main/collect",
            "res/private/main/miniMap",
            "res/private/main/Other",
            "res/private/main/Pattern",
            "res/private/main/Rocker",
            "res/private/main/Skill",
            "res/private/main/Skill/hero",
            "res/private/main/Skill/hero2",
            "res/private/main/summons",
            "res/private/main/Target",
            "res/private/main-win32",
            "res/private/main-win32/chat",
            "res/private/main_monster_ui",
            "res/private/main_monster_ui/hp",
            "res/private/main_monster_ui/monster",
            "res/private/mhp_ui",
            "res/private/mhp_ui_win32",
            "res/private/minimap",
            "res/private/monster_belong_netplayer",
            "res/private/new_setting",
            "res/private/new_setting/icon",
            "res/private/npc",
            "res/private/npc_res",
            "res/private/page_store_ui",
            "res/private/page_store_ui/page_store_ui_mobile",
            "res/private/page_store_ui/page_store_ui_win32",
            "res/private/particles",
            "res/private/player_best_rings_ui",
            "res/private/player_best_rings_ui/player_best_rings_ui_mobile",
            "res/private/player_best_rings_ui/player_best_rings_ui_win32",
            "res/private/player_hero",
            "res/private/player_main_layer_ui",
            "res/private/player_main_layer_ui/player_main_layer_ui_mobile",
            "res/private/player_main_layer_ui/player_main_layer_ui_win32",
            "res/private/player_model",
            "res/private/player_skill",
            "res/private/player_skill-win32",
            "res/private/play_dice",
            "res/private/powerful_secret",
            "res/private/quick_select",
            "res/private/rank_ui",
            "res/private/rank_ui/rank_ui_mobile",
            "res/private/rank_ui/rank_ui_win32",
            "res/private/rein_attr_ui",
            "res/private/rein_attr_ui/attr_ui_mobile",
            "res/private/rein_attr_ui/attr_ui_win32",
            "res/private/report",
            "res/private/revive",
            "res/private/script_show",
            "res/private/setting",
            "res/private/setting_basic",
            "res/private/skill",
            "res/private/splash",
            "res/private/sui",
            "res/private/team",
            "res/private/team_win32",
            "res/private/title_icon",
            "res/private/title_layer_ui",
            "res/private/title_layer_ui_win32",
            "res/private/trade",
            "res/private/trade/trade_ui_mobile",
            "res/private/trade/trade_ui_win32",
            "res/private/trading_bank",
            "res/private/trading_bank_other",
            "res/private/treasure_box",
            "res/private/zhqipz_ui",
            "res/public",
            "res/public_win32",

            "data_config",
            "data_config/ui_config",

            "scripts", 
            "scripts/game_config", 
            
            "GUILayout", 
            "GUIExport", 
            "GUIData"
        }
        local devPath = global.FileUtilCtl:getDefaultResourceRootPath() .. "dev"
        for _, v in ipairs(items) do
            local path = devPath .. "/" .. v
            if not global.FileUtilCtl:isDirectoryExist(path) then
                global.FileUtilCtl:createDirectory(path)
            end
        end

        -- fix configs
        local fixPath = devPath .. "/data_config/msg_decoder_config.txt"
        if global.FileUtilCtl:isFileExist(fixPath) then
            local fullPath = global.FileUtilCtl:fullPathForFilename(fixPath)
            global.FileUtilCtl:removeFile(fixPath)
            global.FileUtilCtl:purgeCachedEntries()
        end
    end

    -- GM网络资源 边玩边下
    global.ResDownloader = require("downloader/ResDownloader").new()
    global.ResDownloader:init()
end

function gameStateInit:InitDebug()
    -- for debug anim
    if global.isDebugMode or global.isGMMode then
        local mediator = requireMediator("test_layer/PreviewAnimMediator")
        global.Facade:registerMediator(mediator.new())
    end

    if global.isDebugMode or global.isGMMode then
        local mediator = requireMediator("test_layer/AnimSetMediator")
        global.Facade:registerMediator(mediator.new())
    end

    -- sui
    if global.isDebugMode or global.isGMMode then
        local mediator = requireMediator("test_layer/SUIEditorMediator")
        global.Facade:registerMediator(mediator.new())
    end

    if global.isDebugMode or global.isGMMode then
        local mediator = requireMediator("test_layer/PreviewSkillMediator")
        global.Facade:registerMediator(mediator.new())
    end

    if global.isDebugMode or global.isGMMode then
        local mediator = requireMediator("test_layer/ConfigSettingMediator")
        global.Facade:registerMediator(mediator.new())
    end

    if global.isDebugMode or global.isGMMode then
        local mediator = requireMediator("test_layer/PreviewAnimActionMediator")
        global.Facade:registerMediator(mediator.new())
    end

    if global.isDebugMode or global.isGMMode then
        local mediator = requireMediator("test_layer/MagicInfoConfigMediator")
        global.Facade:registerMediator(mediator.new())
    end

    if global.isDebugMode or global.isGMMode then
        local mediator = requireMediator("test_layer/PreviewNodeMediator")
        global.Facade:registerMediator(mediator.new())
    end

    if global.isDebugMode or global.isGMMode then
        local mediator = requireMediator("test_layer/RichTextTestMediator")
        global.Facade:registerMediator(mediator.new())
    end

    -- gui
    if global.isDebugMode or global.isGMMode then
        local mediator = requireMediator("gui_layer/GUIEditorMediator")
        global.Facade:registerMediator(mediator.new())
    end

    -- gui res selector
    if global.isDebugMode or global.isGMMode then
        local mediator = requireMediator("gui_layer/GUIResSelectorMediator")
        global.Facade:registerMediator(mediator.new())
    end

    if global.isDebugMode or global.isGMMode then
        local mediator = requireMediator("gui_layer/ExtraColorEditorMediator")
        global.Facade:registerMediator(mediator.new())
    end

    -- gui color selector
    if global.isDebugMode or global.isGMMode then
        local mediator = requireMediator("gui_layer/GUIColorSelectorMediator")
        global.Facade:registerMediator(mediator.new())
    end
end

function gameStateInit:InitSplash()
    local function finishCB()
        global.Facade:sendNotification(global.NoticeTable.ChangeGameState, global.MMO.GAME_STATE_LOGIN)
    end

    -- -- 本次游戏只闪一次
    -- -- record splash switch
    -- if global.LuaBridgeCtl:GetModulesSwitch(global.MMO.Modules_Index_Enable_Splash) == 1 then
    --     finishCB()
    --     return
    -- end
    -- global.LuaBridgeCtl:SetModulesSwitch(global.MMO.Modules_Index_Enable_Splash, 1)

    -- 未配置
    if not SplashFiles or not next(SplashFiles) then
        finishCB()
        return
    end

    -- show
    local items = clone(SplashFiles)
    local function showSplashAuto()
        if #items <= 0 then
            finishCB()
            return
        end

        local filename = table.remove(items, 1)

        -- config error
        if not filename or "" == filename then
            showSplashAuto()
            return
        end

        -- check file exist
        local splashPath = global.MMO.PATH_RES_PRIVATE .. "splash/" .. filename
        if not global.FileUtilCtl:isFileExist(splashPath) then
            showSplashAuto()
            return
        end

        local viewSize = global.Director:getVisibleSize()
        
        -- 黑色背景
        local blackLayout = ccui.Layout:create()
        self._currScene:addChild(blackLayout)
        blackLayout:setBackGroundColor(cc.c3b(0, 0, 0))
        blackLayout:setBackGroundColorType(1)
        blackLayout:setTouchEnabled(true)
        blackLayout:setContentSize(viewSize.width, viewSize.height)

        -- image
        local image = ccui.ImageView:create()
        image:loadTexture(splashPath)
        image:setPosition(viewSize.width * 0.5, viewSize.height * 0.5)
        image:setAnchorPoint(0.5, 0.5)
        self._currScene:addChild(image)

        local function actionCB()
            showSplashAuto()
        end
        image:setOpacity(0)
        image:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.01),
            cc.FadeIn:create(SplashFadeInTime), 
            cc.CallFunc:create(actionCB), 
            cc.DelayTime:create(0.5),
            cc.FadeTo:create(SplashFadeOutTime, 0), 
            cc.CallFunc:create(function()
                blackLayout:removeFromParent()
            end),
            cc.RemoveSelf:create())
        )

        -- remove texture cache
        global.TextureCache:removeTextureForKey(splashPath)
    end

    showSplashAuto()
end

return gameStateInit
