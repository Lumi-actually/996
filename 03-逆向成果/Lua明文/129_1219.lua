local GameResumedCommand = class('GameResumedCommand', framework.SimpleCommand)

function GameResumedCommand:ctor()
end

function GameResumedCommand:execute(note)
    --debug
    print("OnGameResumed")

    global.Facade:sendNotification(global.NoticeTable.Audio_Resume_All)

    if SL:GetValue("GAME_DATA", "openResumeConnectCheck") == 1 then
        PerformWithDelayGlobal(function()
            local NetworkProxy = global.Facade:retrieveProxy(global.ProxyTable.NetworkProxy)
            if NetworkProxy:IsDisconnect() then
                return
            end

            if global.MMO.GAME_STATE_WORLD == GET_GAME_STATE() then
                LuaSendMsg(global.MsgType.MSG_CS_SERVER_TIME_REQUEST)
                local ServerTimeProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerTimeProxy)
                ServerTimeProxy:SetResumeConnect(false)
            end
        end, 0.2)
    else
        if global.MMO.GAME_STATE_WORLD == GET_GAME_STATE() then
            LuaSendMsg(global.MsgType.MSG_CS_SERVER_TIME_REQUEST)
        end
    end

    if GetModListServerTime then 
        GetModListServerTime()--刷新cdn鉴权时间
    end
end

return GameResumedCommand