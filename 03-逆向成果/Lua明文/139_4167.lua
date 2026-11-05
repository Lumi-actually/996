local RestartGameCommand = class('RestartGameCommand', framework.SimpleCommand)

function RestartGameCommand:ctor()
end

function RestartGameCommand:execute(note)
    --debug
    release_print( "RestartGameCommand" )
    
    --clean lua callfunc
    if global.sceneManager then
        global.sceneManager:Cleanup()
    end

    --语音通知退出
    local VoiceManagerProxy = global.Facade:retrieveProxy( global.ProxyTable.VoiceManagerProxy )
    if VoiceManagerProxy then
        VoiceManagerProxy:VoiceExit()
    end

    -- 数据上报 游戏时长
    local DataRePortProxy = global.Facade:retrieveProxy( global.ProxyTable.DataRePortProxy )
    DataRePortProxy:PlayGame()

    -- 网络清理
    global.networkCtl:SetIgnoreDisconnect(true)
    global.networkCtl:Disconnect()
    global.networkCtl:Cleanup()

    -- clean
    global.ResDownloader:Cleanup()

    -- release sui caches
    global.SWidgetCache:releaseAll()

    -- 释放节点缓存池
    global.WidgetCacheManager:Clear()

    -- 释放自定义缓存
    global.CustomCache:Clear()

    -- auth cache
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:SaveLocalCache()
    AuthProxy:releaseDownloader()
    
    local OtherTradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.OtherTradingBankProxy)
    OtherTradingBankProxy:setGameToken("")--清理token
    OtherTradingBankProxy:LoginOut()--登出交易行
    if global.OtherTradingBankH5 then --隐藏取回
        local loginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        local roleData = loginProxy:GetAllRoleInfo()
        local lock = false
        for i, v in ipairs(roleData) do
            if v.LockChar and (v.LockChar == 1 or v.LockChar == 3)  then 
                lock = true 
                break
            end
        end
        if lock then 
            OtherTradingBankProxy:dismissBackToView()
        end
    end
    global.Facade:sendNotification( global.NoticeTable.EndGameState )

    global.userInputController:ResetKeyboard()

    -- cleanup anim mgr
    global.FrameAnimManager:Cleanup()

    -- cleanup user data
    UserData:Cleanup()
    UserData:setVersionPath("")


    global.SpriteFrameCache:removeSpriteFrames()
    global.TextureCache:removeAllTextures()
    global.TextureCache:unbindAllImageAsync()

    -- clear cocos2d cache, issue: release res maybe crash.
    global.Director:purgeCachedData()
    -- clear cocos2d event
    global.EventDispatcher:removeAllEventListeners()
    -- clear cocos2d scheduler, but system scheduler( ActionManager )
    global.Scheduler:unscheduleAllWithMinPriority( cc.PRIORITY_NON_SYSTEM_MIN )
    -- clear cocos2d action
    global.ActionManager:removeAllActions()
    -- stop spriteframe async load task
    cc.AsyncTaskPool:getInstance():stopTasks(cc.AsyncTaskPool.TaskType.TASK_IO)
    cc.AsyncTaskPool:getInstance():stopTasks(cc.AsyncTaskPool.TaskType.TASK_NETWORK)
    -- clear cocos2d audio
    cc.SimpleAudioEngine:destroyInstance()
    ccexp.AudioEngine:uncacheAll()
    -- ccexp.AudioEngine:endToLua()
    -- destroy glProgram
    cc.GLProgramCache:destroyInstance()

    -- reset downloader
    global.HttpDownloader:reset()

    -- record log
    if global.Platform == cc.PLATFORM_OS_ANDROID then
        if nil ~= note:getBody() then
        local jData = {}
        jData.restartMode = note:getBody()
        global.L_NativeBridgeManager:GN_restartGame(jData)
        else 
        buglyLog( 0, "restart game", "Restart Lua VM!" )         
        end
    end

    -- debug: PC更改手机分辨率 需要清理Label缩放
    if SL._DEBUG and LuaBridgeCtl:Inst():GetModulesSwitch(global.MMO.Modules_Index_Cpp_Version) >= global.MMO.CPP_VERSION_LABEL_TTF then 
        cc.Label:setTTFAliasTexParameters(false)
        cc.Label:setTTFScaleFactor(1)
    end

    releasePrint( "RestartGameCommand completed" )
    releasePrint( "Restart Lua VM!" )    
    -- restart luaVM
    LuaBridgeCtl:Inst():CreateNewState()
end

return RestartGameCommand
