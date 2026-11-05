local GameStateMediator = class('GameStateMediator', framework.Mediator)
GameStateMediator.NAME = "GameStateMediator"

function GameStateMediator:ctor()
    GameStateMediator.super.ctor(self, self.NAME)
end

function GameStateMediator:onRegister()
    GameStateMediator.super.onRegister(self)
end

function GameStateMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return
    {
        noticeTable.RequestShutdownGame,
        noticeTable.RequestLeaveWorld,
        noticeTable.PlayerBeDamaged,
        noticeTable.MainPlayerActionBegan,
    }
end

function GameStateMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()

    if noticeID == noticeTable.RequestShutdownGame then
        self:OnRequestShutdownGame()

    elseif noticeID == noticeTable.RequestLeaveWorld then
        self:OnRequestLeaveWorld()

    elseif noticeID == noticeTable.PlayerBeDamaged then
        self:OnPlayerBeDamaged()

    elseif noticeID == noticeTable.MainPlayerActionBegan then
        self:OnMainPlayerActionBegan(data)
    end
end

function GameStateMediator:OnRequestShutdownGame()
    local function quit()
        if self._timerID then
            UnSchedule( self._timerID )
            self._timerID = nil
            SL:onLUAEvent(LUA_EVENT_MAIN_DEL_QUIT_TIME_TIPS)
        end
        local glview = global.Director:getOpenGLView()
        glview:endToLua()
    end

    if self._timerID then
        UnSchedule( self._timerID )
        self._timerID = nil
    end

    if self._leaveID then
        UnSchedule( self._leaveID )
        self._leaveID = nil
    end

    if CHECK_SERVER_OPTION("DelayBQuit") then
        local delayTime = CHECK_SERVER_OPTION("nBQuitTime")
        if delayTime and tonumber(delayTime) then
            SL:onLUAEvent(LUA_EVENT_MAIN_ADD_QUIT_TIME_TIPS, {time = tonumber(delayTime), type = 2})
            self._timerID = Schedule( quit,  tonumber(delayTime))
        else
            quit()
        end
    else
        quit()
    end
end

function GameStateMediator:OnRequestLeaveWorld()
    local function leave()
        if self._leaveID then
            UnSchedule( self._leaveID )
            self._leaveID = nil
            SL:onLUAEvent(LUA_EVENT_MAIN_DEL_QUIT_TIME_TIPS)
        end

        local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        LoginProxy:RequestSoftClose()
    end

    if self._leaveID then
        UnSchedule( self._leaveID )
        self._leaveID = nil
    end

    if self._timerID then
        UnSchedule( self._timerID )
        self._timerID = nil
    end

    if CHECK_SERVER_OPTION("boDelaySQuit") then
        local delayTime = CHECK_SERVER_OPTION("nSQuitTime")
        if delayTime and tonumber(delayTime) then
            SL:onLUAEvent(LUA_EVENT_MAIN_ADD_QUIT_TIME_TIPS, {time = tonumber(delayTime), type = 1})
            self._leaveID = Schedule( leave,  tonumber(delayTime))
        else
            leave()
        end
    else
        leave()
    end
end

function GameStateMediator:OnPlayerBeDamaged( ... )
    if self._timerID and CHECK_SERVER_OPTION("boBQuitStruckBreak") then
        UnSchedule( self._timerID )
        self._timerID = nil
        SL:onLUAEvent(LUA_EVENT_MAIN_DEL_QUIT_TIME_TIPS)
    end

    if self._leaveID and CHECK_SERVER_OPTION("boSQuitStruckBreak") then
        UnSchedule( self._leaveID )
        self._leaveID = nil
        SL:onLUAEvent(LUA_EVENT_MAIN_DEL_QUIT_TIME_TIPS)
    end
end

function GameStateMediator:OnMainPlayerActionBegan(act)
    if not GUIFunction:IsMoveAction(act) then
        return
    end

    if self._timerID and CHECK_SERVER_OPTION("boBQuitMoveBreak") then
        UnSchedule( self._timerID )
        self._timerID = nil
        SL:onLUAEvent(LUA_EVENT_MAIN_DEL_QUIT_TIME_TIPS)
    end

    if self._leaveID and CHECK_SERVER_OPTION("boSQuitMoveBreak") then
        UnSchedule( self._leaveID )
        self._leaveID = nil
        SL:onLUAEvent(LUA_EVENT_MAIN_DEL_QUIT_TIME_TIPS)
    end
end


return GameStateMediator
