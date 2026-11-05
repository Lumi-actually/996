local GameWorldConfirmCommand = class('GameWorldConfirmCommand', framework.SimpleCommand)

function GameWorldConfirmCommand:ctor()

end

function GameWorldConfirmCommand:execute(note)
    print( "GameWorldConfirm" )

    local facade = global.Facade
    
    -- goto world
    global.Facade:sendNotification(global.NoticeTable.ChangeGameState, global.MMO.GAME_STATE_WORLD)

    -- request server, to game world
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    LoginProxy:RequestEnterWorld()
end

return GameWorldConfirmCommand
