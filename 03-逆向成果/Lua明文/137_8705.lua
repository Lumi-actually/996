local gameStateWorld = class('gameStateWorld')

function gameStateWorld:ctor()
end

function gameStateWorld:getStateType()
    return global.MMO.GAME_STATE_WORLD
end

--- enter
function gameStateWorld:onEnter()
    self:InitWorld()
    self:EnterWorld()

    return 1
end

function gameStateWorld:InitWorld()
    local facade = global.Facade

    -- command
    facade:removeCommand( global.NoticeTable.RegisterWorldController )
    facade:removeCommand( global.NoticeTable.RegisterWorldMediator )
    facade:removeCommand( global.NoticeTable.RegisterWorldProxy )

    -- laoding close
    UIOperator:CloseLoadingBarUI()

    -- init resolution size & policy
    local normalPolicy = global.DesignPolicy
    local designSize   = global.DesignSize_Oth
    local glview       = global.Director:getOpenGLView()
    if global.isWinPlayMode and glview then
        -- keep camera zoom(FrameSize == ViewPortSize)
        designSize = glview:getFrameSize()
    end
    local resolutionData     = {}
    resolutionData.rType     = normalPolicy
    resolutionData.size      = designSize
    facade:sendNotification(global.NoticeTable.ChangeResolution, resolutionData)

    -- init layer facade
    local LayerFacadeMediator = requireMediator( "LayerFacadeMediator" )
    local layerFacade = facade:retrieveMediator( LayerFacadeMediator.NAME )
    layerFacade:InitOnEnterWorld()

    global.BehaviorController:InitOnEnterWorld()
    global.userInputController:InitOnEnterWorld()
    global.actorManager:InitOnEnterWorld()
end

function gameStateWorld:EnterWorld()
    local facade = global.Facade

    -- register msg handler
    local noticeProxy = facade:retrieveProxy( global.ProxyTable.NoticeProxy )
    noticeProxy:RegisterMsgHandlerAfterEnterWorld()

    -- register msg handler
    global.SUIManager:RegisterMsgHandlerAfterEnterWorld()

    local ChatProxy = global.Facade:retrieveProxy(global.ProxyTable.ChatProxy)
    ChatProxy:RegisterMsgHandlerAfterEnterWorld()
end

function gameStateWorld:onEnd()--重启
    self:onExit()
end

--- exit world
function gameStateWorld:onExit()
    self:CleanWorld()
    global.Facade:sendNotification( global.NoticeTable.ReleaseMemory)--清理完再释放

    self:LeaveWorld()
    self:Destory()

    return 1
end

function gameStateWorld:LeaveWorld()
    local facade = global.Facade

    global.userInputController:ResetKeyboard()
    global.userInputController:ResetTouch()
    -- SL
    SLBridge:onLeaveWorld()
    
    facade:sendNotification(global.NoticeTable.Layer_Notice_Close, SLBridge:CheckLuaEventCleaned())
    UIOperator:CloseCommonTipsUI()

    -- unregister world
    facade:sendNotification( global.NoticeTable.UnRegisterOther )
    facade:sendNotification( global.NoticeTable.UnRegisterWorldProxy )
    facade:sendNotification( global.NoticeTable.UnRegisterWorldMediator )
    facade:sendNotification( global.NoticeTable.UnRegisterWorldController )
    
    --清理收货和试玩状态
    global.IsReceiveRole = false
    global.IsVisitor = false

    --清理寄售成功状态
    global.IsConsignmentRole = false
    -- clear cocos2d event
    -- clear cocos2d scheduler, but system scheduler( ActionManager )
    -- clear cocos2d action
    -- clear cocos2d audio
    local director = global.Director
    local currScene = global.Director:getRunningScene()
    local eventDispatcher = global.EventDispatcher
    eventDispatcher:removeEventListenersForType(1)
    eventDispatcher:removeEventListenersForType(2)
    eventDispatcher:removeEventListenersForType(3)
    eventDispatcher:removeEventListenersForType(4)
    eventDispatcher:removeEventListenersForType(5)
    eventDispatcher:removeEventListenersForTarget(currScene, true)
    global.Scheduler:unscheduleAllWithMinPriority( cc.PRIORITY_NON_SYSTEM_MIN )
    cc.AsyncTaskPool:getInstance():stopTasks(cc.AsyncTaskPool.TaskType.TASK_IO)
    global.ActionManager:removeAllActions()
    cc.SimpleAudioEngine:destroyInstance()
    ccexp.AudioEngine:uncacheAll()
    global.HttpDownloader:reset()

    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:resetDownloader()

    -- unregister script handle
    if currScene then
        local function disableEvents(node)
            if tolua.type(node) == "cc.TableView" then
            else
                node:disableNodeEvents()
            end
            local children = node:getChildren()
            for k, v in pairs(children) do
                disableEvents(v)
            end
        end
        disableEvents(currScene)
    end

    -- replace scene
    local scene     = cc.Scene:create()
    local currScene = global.Director:getRunningScene()
    if not currScene then
        global.Director:runWithScene( scene )
    else
        global.Director:replaceScene( scene )
    end
    local LayerFacadeMediator = requireMediator( "LayerFacadeMediator" )
    local lFMediator = facade:retrieveMediator(LayerFacadeMediator.NAME)
    lFMediator:InitOnEnterActive(scene)

    -- 网络清理
    global.networkCtl:CleanAllHandlers()
    dump("CleanAllHandlers__________")
end

function gameStateWorld:CleanWorld()
    -- logic
    global.BuffManager:Cleanup()
    global.ActorEffectManager:Cleanup()
    global.gameMapController:Cleanup()
    global.netNpcController:Cleanup()
    global.netMonsterController:Cleanup()
    global.netPlayerController:Cleanup()
    global.gamePlayerController:Cleanup()   
    global.dropItemController:Cleanup()
    global.actorRefreshController:Cleanup()

    -- actor
    global.actorManager:Cleanup()
    global.HUDManager:Cleanup()

    -- scene
    global.dropItemManager:Cleanup()
    global.monsterManager:Cleanup()
    global.npcManager:Cleanup()
    global.playerManager:Cleanup()
    global.sceneGraphCtl:Cleanup()
    global.sceneManager:Cleanup()
    global.sceneEffectManager:Cleanup()

    -- skill
    global.skillManager:Cleanup()
    global.actorSkillController:Cleanup()

    -- anim cleanup
    global.FrameAnimManager:unloadAllUnusedAnimData()

    -- clean
    global.ResDownloader:CleanupDownloadCount()
end

function gameStateWorld:Destory()
    global.sceneManager:destory()
    global.sceneManager = nil

    global.sceneGraphCtl:destory()
    global.sceneGraphCtl = nil

    global.gameWorldController:destory()
    global.gameWorldController:autorelease()
    global.gameWorldController = nil

    global.sceneManagerHelper:destory()
    global.sceneManagerHelper = nil

    global.mouseEventController:destory()
    global.mouseEventController = nil

    global.gamePlayerController:destory()
    global.gamePlayerController = nil

    global.netPlayerController:destory()
    global.netPlayerController = nil

    global.netMonsterController:destory()
    global.netMonsterController = nil
    
    global.netNpcController:destory()
    global.netNpcController = nil
    
    global.dropItemController:destory()
    global.dropItemController = nil
    
    global.gameMapController:destory()
    global.gameMapController = nil
    
    global.gameCameraController:destory()
    global.gameCameraController = nil

    global.actorRefreshController:destory()
    global.actorRefreshController = nil
    
    global.actorPickerController:destory()
    global.actorPickerController = nil

    global.actorSkillController:destory()
    global.actorSkillController = nil

    global.actorManager:destory()
    global.actorManager = nil

    global.monsterManager:destory()
    global.monsterManager = nil

    global.playerManager:destory()
    global.playerManager = nil

    global.npcManager:destory()
    global.npcManager = nil

    global.dropItemManager:destory()
    global.dropItemManager = nil

    global.sceneEffectManager:destory()
    global.sceneEffectManager = nil

    global.skillManager:destory()
    global.skillManager = nil

    global.HUDManager:destory()
    global.HUDManager = nil

    global.HUDHPManager:destory()
    global.HUDHPManager = nil

    global.BuffManager:destory()
    global.BuffManager = nil

    global.ObstacleController:destory()
    global.ObstacleController = nil

    global.PathFindController:destory()
    global.PathFindController = nil

    global.BehaviorController:destory()
    global.BehaviorController = nil

    global.ActorEffectManager:destory()
    global.ActorEffectManager = nil

    global.RenderTextureManager:destory()
    global.RenderTextureManager = nil
end


return gameStateWorld
