local GameSuspendCommand = class('GameSuspendCommand', framework.SimpleCommand)

function GameSuspendCommand:ctor()

end

function GameSuspendCommand:execute(note)
    --debug
    print("OnGameSuspend")

    global.Facade:sendNotification(global.NoticeTable.Audio_Pause_All)

    if global.MMO.GAME_STATE_WORLD == GET_GAME_STATE() then
        global.gameWorldController:OnGameSuspend()
    end
end

return GameSuspendCommand