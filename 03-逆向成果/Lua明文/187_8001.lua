local LoadingBeginCommand = class('LoadingBeginCommand', framework.SimpleCommand)

function LoadingBeginCommand:ctor()
end

function LoadingBeginCommand:execute(note)
    print("LoadingBegin")

    -- for debug loading time
    local loadCost = os.clock()

    -- remove notification
    global.Facade:removeCommand(global.NoticeTable.LoadingBegin)

    -- release
    UIOperator:CloseLoginRoleUI()
    global.Facade:sendNotification(global.NoticeTable.LeaveRole)
    global.Facade:sendNotification(global.NoticeTable.Layer_Login_Version_Close)

    -- loading
    -- load        
    self:LoadController()
    self:RegisterWorldMVC()

    -- print load cost
    print("+++++++++++++load cost", os.clock() - loadCost)

    -- complete
    global.Facade:sendNotification(global.NoticeTable.LoadingCompleted)

    self:InitGetServerTimeSchedule()
end

function LoadingBeginCommand:LoadController()
    if global.isWinPlayMode then
        global.LuaBridgeCtl:SetModulesSwitch(global.MMO.Modules_Index_Scene_Tex_Type, 1)
        global.LuaBridgeCtl:SetModulesSwitch(global.MMO.Modules_Index_Scene_Artifact_Flag, 0)
        -- global.LuaBridgeCtl:SetModulesSwitch(global.MMO.Modules_Index_Scene_Blend_Flag, 0)
    end
    local module            = global.L_ModuleManager:GetCurrentModule()
    local modulePath        = module:GetSubModPath()
    local moduleGameEnv     = module:GetGameEnv()
    local storagePath       = global.WritablePath .. modulePath
    -- GM 自定义搜索路径
    local gmCachePath       = global.L_GameEnvManager:GetGMCachePath()
    if global.isWindows and gmCachePath and string.len(gmCachePath) > 0 then
        storagePath         = gmCachePath
    end
    local GMResUrl = moduleGameEnv:GetGMWebResUrl() or ""
    local GMResVer = moduleGameEnv:GetGMWebResVer() or ""
    global.sceneManager = tileSceneManager:Inst()
    global.sceneManager:setGMResUrl(GMResUrl, storagePath)
    self:SetGMResVer(GMResVer)

    -- 资源释放延迟时间
    local sceneReleaseTime = tonumber(global.ConstantConfig.sceneReleaseTime) or 20
    if global.L_GameEnvManager:GetEnvDataByKey("isCloudLogin") then
        sceneReleaseTime = 3
    end
    global.sceneManager:setAtlasExpiredInterval(sceneReleaseTime)

    -- 内存限制
    local cloudPhoneSceneMemorySize = 300
    local cloudPhoneSceneMemoryWarn = 250
    if global.L_GameEnvManager:GetEnvDataByKey("isAliCloudPhone") then
        cloudPhoneSceneMemorySize = global.L_GameEnvManager:GetEnvDataByKey("cloudPhoneSceneMemorySize") or 80
        cloudPhoneSceneMemoryWarn = cloudPhoneSceneMemorySize - 30
    elseif global.L_GameEnvManager:GetEnvDataByKey("isCloudLogin") then
        cloudPhoneSceneMemorySize = global.L_GameEnvManager:GetEnvDataByKey("cloudPhoneSceneMemorySize") or 150
        cloudPhoneSceneMemoryWarn = cloudPhoneSceneMemorySize - 30
    end
    global.sceneManager:setTextureMemLimitInMB(cloudPhoneSceneMemorySize)
    global.sceneManager:setTextureMemWarnMB(cloudPhoneSceneMemoryWarn)

    global.sceneGraphCtl = require("scene/sceneGraph").create()

    global.gameWorldController = require("logic/gameWorldController").create()

    global.sceneManagerHelper = require("scene/sceneManagerHelper").create()

    global.mouseEventController = require("logic/mouseEventController").create()

    global.gamePlayerController = require("logic/gamePlayerController").create()

    global.netPlayerController = require("logic/netPlayerController").create()

    global.netMonsterController = require("logic/netMonsterController").create()

    global.netNpcController = require("logic/netNpcController").create()

    global.dropItemController = require("logic/dropItemController").create()

    global.gameMapController = require("logic/gameMapController").create()

    global.gameCameraController = require("logic/gameCameraController").create()

    global.actorRefreshController = require("logic/actorRefreshController").create()

    global.actorPickerController = require("logic/actorPickerController").create()

    global.actorSkillController = require("logic/actorSkillController").create()

    global.actorManager = require("actor/actorManager").create()

    global.monsterManager = require("scene/monsterManager").create()

    global.playerManager = require("scene/playerManager").create()

    global.npcManager = require("scene/npcManager").create()

    global.dropItemManager = require("scene/dropItemManager").create()

    global.sceneEffectManager = require("scene/sceneEffectManager").create()

    global.darkNodeManager = require("scene/darkNodeManager").create()

    global.skillManager = require("skill/skillManager").create()

    global.HUDManager = require("actor/actorHUDManager").create()

    global.HUDHPManager = require("actor/actorHUDHPManager").create()

    global.BuffManager = require("buff/BuffManager").create()

    global.ObstacleController = require("logic/ObstacleController").create()

    global.PathFindController = require("logic/PathFindController").create()

    global.BehaviorController = require("bt/BehaviorController").create()

    global.ActorEffectManager = require("buff/ActorEffectManager").create()

    global.RenderTextureManager = require("render/RenderTextureManager").create()
end

function LoadingBeginCommand:SetGMResVer(GMResVerOri)
    local module        = global.L_ModuleManager:GetCurrentModule()
    local subMod        = module:GetCurrentSubMod()
    local subModInfo    = subMod:GetSubModInfo()
    local gameid        = subMod:GetOperID()
    local xk            = subMod:GetXK()
    local channelID     = global.L_GameEnvManager:GetChannelID() or 1
    local GMResVer      = GMResVerOri

    if GetCdnSign then
        local sign  = GetCdnSign(gameid, global.modListSrvTime, xk or "")
        local param = string.format("gameId=%s&time=%s&sign=%s&channelID=%s", gameid, global.modListSrvTime, sign, channelID)
        GMResVer  = string.format("%s&%s", GMResVer, param)
        --刷新时间戳 cdn鉴权
        global.modListSrvTimeCallFuncs = global.modListSrvTimeCallFuncs or {}
        local refResTime = function ()
            local sign  = GetCdnSign(gameid, global.modListSrvTime, xk or "")
            local param = string.format("gameId=%s&time=%s&sign=%s&channelID=%s", gameid, global.modListSrvTime, sign, channelID)
            local GMResVer  = string.format("%s&%s", GMResVerOri, param)
            if global.sceneManager then 
                global.sceneManager:setGMResVer(GMResVer)
            end
        end
        table.insert(global.modListSrvTimeCallFuncs, refResTime)
    end
    global.sceneManager:setGMResVer(GMResVer)
end

function LoadingBeginCommand:RegisterWorldMVC()
    -- register 
    local RegisterWorldController = requireCommand("register/RegisterWorldControllerCommand")
    local RegisterWorldMediator = requireCommand("register/RegisterWorldMediatorCommand")
    local RegisterWorldProxy = requireCommand("register/RegisterWorldProxyCommand")
    global.Facade:registerCommand(global.NoticeTable.RegisterWorldController, RegisterWorldController.new())
    global.Facade:registerCommand(global.NoticeTable.RegisterWorldMediator, RegisterWorldMediator.new())
    global.Facade:registerCommand(global.NoticeTable.RegisterWorldProxy, RegisterWorldProxy.new())

    -- 
    global.Facade:sendNotification(global.NoticeTable.RegisterWorldController)
    global.Facade:sendNotification(global.NoticeTable.RegisterWorldProxy)
    global.Facade:sendNotification(global.NoticeTable.RegisterWorldMediator)
end

function LoadingBeginCommand:InitGetServerTimeSchedule()
    if GetModListServerTime then
        GetModListServerTime()
        Schedule(function ()
            GetModListServerTime()
        end, 3*60*60)--三小时刷新一次资源请求时间戳 
    end
end
return LoadingBeginCommand
