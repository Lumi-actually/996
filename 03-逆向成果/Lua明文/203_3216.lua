local DebugMediator = requireMediator("DebugMediator")
local DelayExitGameMediator = class('DelayExitGameMediator', DebugMediator)
DelayExitGameMediator.NAME = "DelayExitGameMediator"

function DelayExitGameMediator:ctor()
    DelayExitGameMediator.super.ctor(self, self.NAME)

    self._game_init_finish = false
    self:onIsCanWindownCloseState()
end

function DelayExitGameMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
            noticeTable.GameWorldInitComplete, 
            noticeTable.Delay_Exit_Game_Window_Close_Notice,
            noticeTable.Delay_Exit_Game_Window_Leave_World,
    }
end

function DelayExitGameMediator:handleNotification(notification)
    local noticeID = notification:getName()
    local notices = global.NoticeTable
    local data = notification:getBody()

    if notices.GameWorldInitComplete == noticeID then
        self._game_init_finish = true
        self:onIsCanWindownCloseState()
    elseif notices.Delay_Exit_Game_Window_Close_Notice == noticeID then
        self:onGameWindowCloseNotice()
    elseif notices.Delay_Exit_Game_Window_Leave_World == noticeID then
        self:onLeaveWorld()
    end
end

--- PC端 关闭按钮状态
function DelayExitGameMediator:onIsCanWindownCloseState()
    local CloseGameID = global.L_GameEnvManager:GetEnvDataByKey("CloseGameID")
    if (self._game_init_finish and CHECK_SERVER_OPTION("DelayBQuit")) or CloseGameID then -- 延迟刷新
        local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
        NativeBridgeProxy:GN_IsCan_Windown_Close_State({
            state = 0
        })
    end
end

--- PC端 点击关闭按钮时通知
function DelayExitGameMediator:onGameWindowCloseNotice()
    local CloseGameID = global.L_GameEnvManager:GetEnvDataByKey("CloseGameID")
    if not ((self._game_init_finish and CHECK_SERVER_OPTION("DelayBQuit")) or CloseGameID) then
        return
    end
    if CloseGameID then
        -- 5. 关闭 触发SDK调用[特殊SDK]
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        AuthProxy:uploadData(5, {gameInitFinish=self._game_init_finish})
        return
    end

    local function checkExitGame(atype)
        if atype == 1 then
            if self._game_init_finish then
                global.Facade:sendNotification(global.NoticeTable.RequestShutdownGame)
            else
                global.Facade:sendNotification(global.NoticeTable.ShutdownGame)
            end
        end
    end

    local data = {}
    data.str = GET_STRING(30003036)
    data.btnType = 2
    data.callback = checkExitGame
    UIOperator:OpenCommonTipsUI(data)
end

function DelayExitGameMediator:onLeaveWorld()
    local CloseGameID = global.L_GameEnvManager:GetEnvDataByKey("CloseGameID")
    if CHECK_SERVER_OPTION("DelayBQuit") or CloseGameID then -- 延迟刷新
        local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
        NativeBridgeProxy:GN_IsCan_Windown_Close_State({
            state = 1
        })
    end
end

return DelayExitGameMediator
