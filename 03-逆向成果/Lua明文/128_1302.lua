local StartUpCommand = class('StartUpCommand', framework.SimpleCommand)

function StartUpCommand:ctor()

end

function StartUpCommand:execute(note)
    -- remove self command 
    local facade    = global.Facade
    local noticeTable = global.NoticeTable
    facade:removeCommand(noticeTable.StartUp)

    -- init some command
    local gameResumedCommand = requireCommand("gamestates/GameResumedCommand")
    local gameSuspendCommand = requireCommand("gamestates/GameSuspendCommand")
    local gameSizeChangedCommand = requireCommand("gamestates/GameSizeChangedCommand")
    facade:registerCommand(noticeTable.GameResumed, gameResumedCommand)
    facade:registerCommand(noticeTable.GameSuspend, gameSuspendCommand)
    facade:registerCommand(noticeTable.GameSizeChanged, gameSizeChangedCommand)

    self:GameInit()
end

function StartUpCommand:GameInit()
    -- init game fsm
    local GameStateController = requireMediator("gamestates/GameStateController")
    local gameFSMController = GameStateController.new()
    global.Facade:registerMediator(gameFSMController)
    global.GameStateController = gameFSMController

    -- goto active
    global.Facade:sendNotification(global.NoticeTable.ChangeGameState, global.MMO.GAME_STATE_ACTIVE)
end

return StartUpCommand