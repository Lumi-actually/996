local gameStateRole = class('gameStateRole')

function gameStateRole:ctor()
end


function gameStateRole:getStateType()
    return global.MMO.GAME_STATE_ROLE
end

function gameStateRole:onEnter()
    local function updater( delta )
        global.networkCtl:Tick()
        global.FrameAnimManager:Tick( delta )
        global.ResDownloader:Tick( delta )
    end
    self._scheduleId = Schedule( updater, 0.05 )

    local  cmd = requireCommand("gamestates/LoadingBeginCommand")
    global.Facade:registerCommand(global.NoticeTable.LoadingBegin, cmd)

    global.Facade:sendNotification(global.NoticeTable.Layer_Notice_Open)
    global.Facade:sendNotification(global.NoticeTable.Layer_Login_Version_Open)
    UIOperator:OpenLoginRoleUI()

    global.userInputController:InitOnEnterRole()

    return 1
end

function gameStateRole:onEnd()--重启
    global.Facade:sendNotification( global.NoticeTable.ReleaseMemory)
end

function gameStateRole:onExit()
    if self._scheduleId ~= -1 then
        UnSchedule(self._scheduleId)
        self._scheduleId = -1
    end

    global.Facade:sendNotification(global.NoticeTable.Layer_Notice_Close)
    global.Facade:sendNotification(global.NoticeTable.Layer_Login_Version_Close)
    UIOperator:CloseLoginRoleUI()
    UIOperator:CloseCommonTipsUI()

    -- release texture cache
    global.TextureCache:removeUnusedTextures()

    global.FrameAnimManager:unloadUnusedAnimData()

    return 1
end

return gameStateRole
