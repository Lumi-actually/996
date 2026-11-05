local BaseUIMediator = requireMediator("BaseUIMediator")
local GameWorldConnectMediator = class("GameWorldConnectMediator", BaseUIMediator)
GameWorldConnectMediator.NAME = "GameWorldConnectMediator"

function GameWorldConnectMediator:ctor()
    GameWorldConnectMediator.super.ctor(self)
end

function GameWorldConnectMediator:listNotificationInterests()
    local notice = global.NoticeTable
    return {
        notice.GameWorldCheckTimeout,
        notice.GameWorldInfoInitBegin,
        notice.ResetGameWorldSendHeartBeat,
        notice.ResetGameWorldRecvHeartBeat,
    }
end

function GameWorldConnectMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()

    if noticeTable.GameWorldCheckTimeout == noticeID then
        self:OnGameWorldCheckTimeout(data)

    elseif noticeTable.GameWorldInfoInitBegin == noticeID then
        self:OnGameWorldInfoInitBegin(data)

    elseif noticeTable.ResetGameWorldSendHeartBeat == noticeID then
        self:OnResetGameWorldSendHeartBeat(data)

    elseif noticeTable.ResetGameWorldRecvHeartBeat == noticeID then
        self:OnResetGameWorldRecvHeartBeat(data)
    end
end

function GameWorldConnectMediator:OnGameWorldCheckTimeout()
    if self._gameWorldTimeout then
        UnSchedule(self._gameWorldTimeout)
        self._gameWorldTimeout = nil
    end

    self._gameWorldTimeout = SL:ScheduleOnce(function()
        self._gameWorldTimeout = nil
        -- 
        local function confirmCB()
            -- pc关闭游戏，方便使用新的登录信息和更新exe
            if global.isWindows and not (global.isDebugMode or global.isGMMode) then
                global.Facade:sendNotification(global.NoticeTable.ShutdownGame)
            else
                global.L_NativeBridgeManager:GN_accountLogout()
                global.Facade:sendNotification( global.NoticeTable.RestartGame ) 
            end
        end
    
        local data    = {}
        data.str      = GET_STRING( 30009096 )
        data.btnDesc  = { GET_STRING( 30009046 ) }
        data.callback = confirmCB
        UIOperator:CloseCommonTipsUI()
        UIOperator:OpenCommonTipsUI(data)

        -- 关闭自动重连
        global.Facade:sendNotification(global.NoticeTable.ReconnectForbidden)
        global.networkCtl:Disconnect()
    end, 30)
end

function GameWorldConnectMediator:OnGameWorldInfoInitBegin()
    if self._gameWorldTimeout then
        UnSchedule(self._gameWorldTimeout)
        self._gameWorldTimeout = nil
    end
end

function GameWorldConnectMediator:OnResetGameWorldSendHeartBeat()
    if global.gameWorldController then  
        global.gameWorldController:ResetSendHeartBeat()
    end
end

function GameWorldConnectMediator:OnResetGameWorldRecvHeartBeat()
    if global.gameWorldController then 
        global.gameWorldController:ResetRecvHeartBeat()
    end
end

return GameWorldConnectMediator
