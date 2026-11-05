local gameStateLogin = class('gameStateLogin')

function gameStateLogin:ctor()
end

function gameStateLogin:getStateType()
    return global.MMO.GAME_STATE_LOGIN
end

function gameStateLogin:onEnter()
    global.Facade:sendNotification(global.NoticeTable.Layer_Notice_Open)
    global.Facade:sendNotification(global.NoticeTable.Layer_Login_Version_Open)

    -- 开启定时器
    if self._scheduleId then
        UnSchedule(self._scheduleId)
        self._scheduleId = nil
    end
    local function updater( delta )
        global.networkCtl:Tick()
        global.FrameAnimManager:Tick( delta )
        global.ResDownloader:Tick( delta )
    end
    self._scheduleId = Schedule( updater, 0.05 )

    -- load
    -- ！！！注意先加载配置，使用gamedata部分数据
    self:InitPreload()
    self:InitConfig()
    self:InitProperty()
    self:InitUserInput()
    self:InitLogin()
    self:InitGUI()

    -- enter login
    global.Facade:sendNotification(global.NoticeTable.EnterLogin)
end

function gameStateLogin:InitPreload()
    -- reload config
    requireGameConfig("cfg_att_score")
    requireGameConfig("cfg_auction_type")
    requireGameConfig("cfg_damage_number")
    requireGameConfig("cfg_KeyFunc")
    requireGameConfig("cfg_magicinfo")
    requireGameConfig("cfg_mapdesc")
    requireGameConfig("cfg_buff")
    requireGameConfig("cfg_pick_set")
    requireGameConfig("cfg_setup")
    requireGameConfig("cfg_skill_present")

    require("scene/sceneManagerHelper")
    require("logic/mouseEventController")
    require("logic/gamePlayerController")
    require("logic/netPlayerController")
    require("logic/netMonsterController")
    require("logic/netNpcController")
    require("logic/dropItemController")
    require("logic/gameMapController")
    require("logic/gameCameraController")
    require("logic/actorRefreshController")
    require("logic/actorPickerController")
    require("logic/actorSkillController")
    require("logic/ObstacleController")
    require("logic/PathFindController")
    require("buff/ActorEffectManager")
    require("bt/BehaviorController")
    require("actor/actorManager")
    require("scene/monsterManager")
    require("scene/playerManager")
    require("scene/npcManager")
    require("scene/dropItemManager")
    require("scene/sceneEffectManager")
    require("scene/darkNodeManager")
    require("skill/skillManager")
    require("actor/actorHUDManager")
    require("actor/actorHUDHPManager")
    require("buff/BuffManager")
    require("render/RenderTextureManager")

    -- 预加载
    local registerTable = requireCommand("register/WorldControllerTable")
    for i, v in ipairs(registerTable) do
        requireCommand(v)
    end
    local registerTable = requireCommand("register/WorldMediatorTable")
    for i, v in ipairs(registerTable) do
        requireMediator(v)
    end
    local registerTable = requireCommand("register/WorldProxyTable")
    for i, v in ipairs(registerTable) do
        requireProxy(v)
    end
end

function gameStateLogin:InitConfig()
    -- 环境配置
    local cjson = require("cjson")
    local function loadDataConfig(filename)
        local filePath = "data_config/" .. filename
        if global.FileUtilCtl:isFileExist(filePath) then
            local jsonStr = global.FileUtilCtl:getDataFromFileEx(filePath)
            if not jsonStr or jsonStr == "" or jsonStr == filePath then
                return false
            end
            local jsonData = {}
            xpcall(function()
                    jsonData = cjson.decode(jsonStr)
                end, 
                function()
                    if global.isDebugMode or global.isGMMode then
                        ShowSystemTips(string.format("json文件格式错误: %s", filename))
                    end
                end
            )
            if jsonData then
                for k, v in pairs(jsonData) do
                    global.ConstantConfig[k] = v
                end
            end
        end
    end
    loadDataConfig("gameopt_996.txt")
    loadDataConfig("gameopt.txt")
    
    -- gamedata配置
    local dconfig = requireGameConfig("cfg_game_data")
    for k, v in pairs(dconfig) do
        global.ConstantConfig[v.k] = v.value
    end

    -- anim mrmory warning
    if global.L_GameEnvManager:GetEnvDataByKey("isAliCloudPhone") then
        local cloudPhoneAnimMemorySize = global.L_GameEnvManager:GetEnvDataByKey("cloudPhoneAnimMemorySize") or 100
        global.FrameAnimManager:setMemWarningInMB(cloudPhoneAnimMemorySize)
        global.FrameAnimManager._expiredInterval = 5
        global.FrameAnimManager._loadingLimit = 1
    elseif global.L_GameEnvManager:GetEnvDataByKey("isCloudLogin") then
        local cloudPhoneAnimMemorySize = global.L_GameEnvManager:GetEnvDataByKey("cloudPhoneAnimMemorySize") or 400
        global.FrameAnimManager:setMemWarningInMB(cloudPhoneAnimMemorySize)
        global.FrameAnimManager._expiredInterval = 5
        global.FrameAnimManager._loadingLimit = 1
    else
        local memSize = global.isWindows and 800 or (tonumber(global.ConstantConfig.animMemorySize) or 600)
        global.FrameAnimManager:setMemWarningInMB(memSize)
    end

    -- 多职业配置
    local list = {}
    for i = 5, 15 do 
        if global.ConstantConfig["MultipleJobSet" .. i] then
            local param = G_GetSplitArray(global.ConstantConfig["MultipleJobSet" .. i], "|")
            local function checkValue(str)
                if string.len(str or "") > 0 then
                    return str
                end
                return nil
            end
            list[i] = {
                isOpen  = tonumber(param[1]) == 1,                                  -- 开关
                name    = checkValue(param[2]) or string.format("未命名%s", i),     -- 职业名称
                hudStr  = checkValue(param[3]) or "X",                              -- HUD
                createLightMaleID   = tonumber(param[4]),                           -- 创建常亮动画- 男
                createLightFemaleID = tonumber(param[5]),                           -- 创建常亮动画- 女
                animGToLMaleID      = tonumber(param[6]),                           -- 灰到亮动画 - 男
                animGToLFemaleID    = tonumber(param[7]),                           -- 灰到亮动画 - 女
                clothFeatureShowID  = tonumber(param[8]),                           -- 裸模外观ID
                UIModelPicMaleID    = checkValue(param[9]),                         -- 裸模内观图片ID - 男
                UIModelPicFeMaleID  = checkValue(param[10]),                        -- 裸模内观图片ID - 女
            }
        end
    end
    global.ConstantConfig.MultipleJobSetMap = list

    -- 武器外观层级配置
    if global.ConstantConfig.WeaponLooksOrderUp and string.len(global.ConstantConfig.WeaponLooksOrderUp) > 0 then
        local data = G_GetSplitArray(global.ConstantConfig.WeaponLooksOrderUp, "|")
        local list = {}
        for _, v in ipairs(data) do
            if string.len(v) > 0 then
                local param = G_GetSplitArray(v, "#")
                if tonumber(param[1]) and tonumber(param[2]) then
                    table.insert(list, {dir = tonumber(param[1]), act = tonumber(param[2])})
                end
            end
        end
        global.ConstantConfig.WeaponLooksOrderUp = list
    else
        global.ConstantConfig.WeaponLooksOrderUp = {}
    end

    -- 动画
    local ModelConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ModelConfigProxy)
    ModelConfigProxy:LoadConfig()
    ModelConfigProxy:LoadSplitConfigs()
    global.FrameAnimManager:Init()

    -- audio
    local AudioProxy = global.Facade:retrieveProxy(global.ProxyTable.AudioProxy)
    AudioProxy:LoadConfig()

    -- 后台静默下载功能
    global.ResDownloader:initGMResList()
    global.ResDownloader:initBackgroundRes()

    -- WidgetCacheManager
    global.WidgetCacheManager = requireUtil("WidgetCacheManager").new()
    global.WidgetCacheManager:WidgetPoolCapacity("item/item", 50)

    -- 定时释放无用资源
    Schedule(function()
        global.TextureCache:removeUnusedTextures()
        global.SWidgetCache:releaseLimit()
    end, 10*60)

    -- player render config
    G_ActorUtils.ResetPlayerRenderOrderByGameData()

    -- GUI
    require("GUILayout/GUIInitPre")
end

function gameStateLogin:InitProperty()
    -- 描边大小
    if global.Director.setDefaultOutlineSize then
        local outlineSize = tonumber(global.ConstantConfig.outlineSize) or 0
        global.Director:setDefaultOutlineSize(outlineSize)
    end
    
    -- 抗锯齿在PC端是否开启
    if global.isWinPlayMode then
        global.Director:setFontAtlasAntialiasEnabled(global.ConstantConfig.FontAtlasAntialiasEnabled == 1)
    else
        global.Director:setFontAtlasAntialiasEnabled(true)
    end

    -- 采样方式
    global.Director:setTexture2DAntialiasEnabled(global.ConstantConfig.Texture2DAntialiasEnabled == 1 and true or (global.isWinPlayMode == false))

    -- 聊天/tips 字体
    if global.isWinPlayMode and global.FileUtilCtl:isFileExist(global.MMO.PATH_FONT4) then 
        if global.LuaBridgeCtl:GetModulesSwitch(global.MMO.Modules_Index_Cpp_Version) >= global.MMO.CPP_VERSION_LABEL_TTF then
            global.ChatAndTips_Use_Font = global.MMO.PATH_FONT4
        end
    end
    
    if global.ConstantConfig.DEFAULT_FONT_SIZE == 0 then
        global.ConstantConfig.DEFAULT_FONT_SIZE = global.isWinPlayMode and 12 or 16
    end

    -- 加载拓展定义
    require("GUILayout/GUIDefineEx")

    --pc 字体设置    
    if GUIDefineEx.PCFontSize then
        global.ConstantConfig.DEFAULT_FONT_SIZE = GUIDefineEx.PCFontSize
        global.ConstantConfig.sceneFontSize_pc = GUIDefineEx.PCFontSize
    end

    if global.isWinPlayMode and SL:GetValue("GAME_DATA", "HudNotUseBmpFont") ~= 1 then
        -- bmp场景字固定12
        global.ConstantConfig.sceneFontSize_pc = 12
    end
end

function gameStateLogin:InitUserInput()
    -- user input
    global.userInputController:InitOnEnterLogin()
end

function gameStateLogin:InitLogin()
    -- 登录
    local needInputAccount  = true
    local currentModule     = global.L_ModuleManager:GetCurrentModule()
    local moduleGameEnv     = currentModule:GetGameEnv()

    -- 手机端
    local loginData         = moduleGameEnv:GetLoginData()

    -- PC联运
    local PCPlatform        = global.L_GameEnvManager:GetEnvDataByKey("PCPlatform")
    local user_id           = global.L_GameEnvManager:GetEnvDataByKey("user_id")
    local token             = global.L_GameEnvManager:GetEnvDataByKey("token")

    if user_id and string.len(string.trim(user_id)) == 0 then
        user_id = nil
    end

    if token and string.len(string.trim(token)) == 0 then
        token = nil
    end

    -- 盒子
    local envProxy          = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
    local bokuid            = envProxy:getBoxuid()
    local boxtoken          = envProxy:getBoxtoken()

    -- PCSDK 
    local isPcSdk           = global.L_GameEnvManager:GetEnvDataByKey("isPcSdk")


    -- UGC快捷登录
    local isUGC             = global.L_GameEnvManager:GetEnvDataByKey("isUgc") == 1
    local isUgcQuickLogin   = global.L_GameEnvManager:GetEnvDataByKey("isUgcQuickLogin") == 1
    if loginData and loginData.username and loginData.password then
        -- 针对手机端 账号密码
        local username      = loginData.username
        local password      = loginData.password
        
        local AuthProxy     = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        local authData      = {}
        authData.type       = 1
        authData.username   = username
        authData.password   = password
        AuthProxy:RequestLoginAdmin(authData)
        needInputAccount    = false
    elseif isUGC and isUgcQuickLogin and bokuid and boxtoken then
        -- 针对UGC快捷登录  账号密码
        local password      = boxtoken
        local uid           = bokuid
        
        local AuthProxy     = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        local authData      = {}
        authData.type       = 1
        authData.username   = uid
        authData.password   = password
        AuthProxy:RequestLoginAdmin(authData)
        needInputAccount    = false

    elseif tonumber(PCPlatform) == 1 and user_id and token then
        -- 针对PC联运 账号密码
        local password      = token
        local uid           = user_id
        
        local AuthProxy     = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        local authData      = {}
        authData.type       = 1
        authData.username   = uid
        authData.password   = password
        AuthProxy:RequestLoginAdmin(authData)
        needInputAccount    = false
    
    elseif tonumber(PCPlatform) == 2 and user_id and token then
        -- 996PC独立包
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        AuthProxy:RequestCheckToken(user_id, token)
        needInputAccount    = false

    elseif bokuid and boxtoken then
        -- 盒子快捷登录
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        AuthProxy:RequestCheckToken(bokuid, boxtoken)
        needInputAccount    = false

    elseif isPcSdk then
        -- 美杜莎pcsdk接入
        local data = {}
        local cjson= require("cjson")
        local jsonString = (data and cjson.encode(data))
        local methodName = "GN_accountLogin"
        global.NativeBridgeCtl:sendMessage2Native(methodName, jsonString)
        needInputAccount = false
    end
    
    -- env写入的实名
    if global.isMobile then
        if global.L_NativeBridgeManager.SetCertification and global.L_NativeBridgeManager.SetAdult then
            local is_adult = global.L_GameEnvManager:GetEnvDataByKey("is_adult")
            local is_realname = global.L_GameEnvManager:GetEnvDataByKey("is_realname")
            if is_adult and is_realname then
                global.L_NativeBridgeManager:SetAdult(tonumber(is_adult) == 1)
                global.L_NativeBridgeManager:SetCertification(tonumber(is_realname) == 1)
            end
        end
    end

    -- 账号界面
    if needInputAccount then
        -- 进入账号界面
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        AuthProxy:ReadLocalData()
        UIOperator:OpenLoginAccountUI()
    else
        UIOperator:OpenLoginServerUI()
    end
end

function gameStateLogin:InitGUI()
    require("GUI/GUIDeprecated")
end

function gameStateLogin:onEnd()--重启
    global.Facade:sendNotification( global.NoticeTable.ReleaseMemory)
end

function gameStateLogin:onExit()
    if self._scheduleId ~= -1 then
        UnSchedule(self._scheduleId)
        self._scheduleId = -1
    end

    global.Facade:sendNotification(global.NoticeTable.Layer_Notice_Close)
    global.Facade:sendNotification(global.NoticeTable.Layer_Login_Version_Close)
    UIOperator:CloseLoginServerUI()

    return 1
end

return gameStateLogin
