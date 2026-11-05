local DebugMediator      = requireMediator( "DebugMediator" )
local NetworkMediator = class('NetworkMediator', DebugMediator)
NetworkMediator.NAME  = "NetworkMediator"

-- 服务器被攻击，迁移DNS解析需要时间，这里一直重连，重连时玩家可以主动选择退出
-- 2024.02.26, suntong 让连10次失败后不再连接，弹窗提醒玩家退出。

local TOTAL_TRY_MAX      = 10	-- x次后弹出提醒框，并终止重连
local FIRST_WAIT_TIME    = 1	-- 初次重连等待时间
local WAIT_TIME          = 3
local CLICK_WAIT_TIME    = 3*60 -- 手动重连等待时间


function NetworkMediator:ctor()
    NetworkMediator.super.ctor( self, self.NAME )

    self._totalTry = 0
	self._otherClient = false
end

function NetworkMediator:listNotificationInterests()
	local noticeTable = global.NoticeTable
	return  
	{
		noticeTable.Disconnect,
		noticeTable.OtherClientLogin,
		noticeTable.ReconnectGameWorld,
		noticeTable.ReconnectForbidden,
	}
end


function NetworkMediator:handleNotification(notification)
	local noticeTable = global.NoticeTable
	local noticeID = notification:getName()
	local data = notification:getBody()

	if noticeTable.Disconnect == noticeID then
		self:OnDisconnect()

	elseif noticeTable.OtherClientLogin == noticeID then
		self:OnOtherClientLogin()

	elseif noticeTable.ReconnectGameWorld == noticeID then
		self:OnReconnectGameWorld()

	elseif noticeTable.ReconnectForbidden == noticeID then
		self:OnReconnectForbidden()

	end
end 

function NetworkMediator:StartReconnect()
	UIOperator:OpenLoadingBarUI()

	self._totalTry = 0
	PerformWithDelayGlobal( handler( self, self.Reconnect ), FIRST_WAIT_TIME)
end

function NetworkMediator:StopReconnect()
	UIOperator:CloseLoadingBarUI()
end

function NetworkMediator:TryReconnect()
	-- 只在游戏世界可触发重连
	if global.MMO.GAME_STATE_WORLD ~= GET_GAME_STATE() then
        return
    end

    -- 重连禁用
    if not global.networkCtl:CheckReconnectAble() then
        return
    end

	self:StartReconnect()
end

function NetworkMediator:Reconnect()
    local AuthProxy    = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local loginProxy   = global.Facade:retrieveProxy( global.ProxyTable.LoginProxy )

    local ip          = loginProxy:GetSelectedServerIp()
    local port        = loginProxy:GetGameServerPort()
    local proxyport   = loginProxy:GetSelectedServerProxyPort()
    local connectIP   = tostring(ip)
    local connectPort = tonumber(proxyport or port)
	local debugPort     = nil
	local debugIp       = nil
	if SL._DEBUG then 
		debugPort     = global.L_GameEnvManager:GetEnvDataByKey("DebugPort")
		debugIp       = global.L_GameEnvManager:GetEnvDataByKey("DebugIp")
		if debugIp and debugPort then
			connectIP     = tostring(debugIp)
			connectPort   = tonumber(debugPort)
		end
	end
    release_print("-------------------------------------- reconnect", connectIP, connectPort, self._totalTry)
	local reconnect = function (param1Ex)
		global.networkCtl:Connect(connectIP, connectPort)
		release_print("connect state", global.networkCtl:IsConnected())

		-- connect success
		if global.networkCtl:IsConnected() then
			local recog = GET_NET_MSG_STAMP_HEAD_PARAM0()
			local param1 = param1Ex or GET_NET_MSG_STAMP_HEAD_PARAM1()
			local param2 = tonumber(loginProxy:GetMainSelectedServerId() or loginProxy:GetSelectedServerId()) or 0
			local param3 = tonumber(loginProxy:GetGameServerPort()) or 0
			local sendStr = loginProxy:GetConnectGameServerStr()
			LuaSendMsg(global.MsgType.MSG_CS_RELOGIN_SERVER, recog, param1, param2, param3, sendStr)

			global.Facade:sendNotification(global.NoticeTable.GameWorldCheckTimeout)
			
			-- 
			self:StopReconnect()
			self:StopClickReconnect()
		else
			self._totalTry = self._totalTry + 1
			self:StartClickReconnect()
			if self._totalTry >= TOTAL_TRY_MAX then
				self:StopReconnect()
				if self._clickForbidden then
					self:ShowReconnectTips()
				else
					self:ShowClickReconnectTips()
				end
			else
				PerformWithDelayGlobal( handler( self, self.Reconnect ), WAIT_TIME )
			end
		end
	end
	if proxyport then 
		GET_NET_MSG_STAMP_HEAD_PARAM1_NEW(function (param1Ex)
			reconnect(param1Ex)
			local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
			LoginProxy.param1Ex = nil
		end)
	else
		reconnect()
	end
end


function NetworkMediator:DialogCallback( type ,custom )
	if 1 == type then
		-- pc关闭游戏，方便使用新的登录信息和更新exe
		if global.isWindows and not (global.isDebugMode or global.isGMMode) then
			global.Facade:sendNotification(global.NoticeTable.ShutdownGame)
		else
			global.L_NativeBridgeManager:GN_accountLogout()
			global.Facade:sendNotification( global.NoticeTable.RestartGame ) 
		end
	end
end

function NetworkMediator:OnDisconnect()
	-- 只在游戏世界可触发重连
    if global.MMO.GAME_STATE_WORLD ~= GET_GAME_STATE() then
        return
    end

    -- 已经在短线中，不重复触发
    local NetworkProxy = global.Facade:retrieveProxy(global.ProxyTable.NetworkProxy)
    if NetworkProxy:IsDisconnect() then
        return
    end

	local VoiceManagerProxy = global.Facade:retrieveProxy( global.ProxyTable.VoiceManagerProxy )
	if VoiceManagerProxy then
		VoiceManagerProxy:VoiceExit()
	end

	local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    if NativeBridgeProxy then
        NativeBridgeProxy:GN_Game_Duration_State( {isGameDuration=false} )
    end

	NetworkProxy:SetDisconnect(true)

	-- 跨服状态断线，不重连，直接提示返回登录界面
	local ServerTimeProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerTimeProxy)
	if ServerTimeProxy and ServerTimeProxy:IsKFState() then
		release_print("In KF state, not reconnect!")
		self:ShowReconnectTips()
		return
	end

	self:TryReconnect()
end

function NetworkMediator:OnReconnectGameWorld()
	releasePrint("重连1")
    -- 重连时才响应658消息
    local NetworkProxy = global.Facade:retrieveProxy( global.ProxyTable.NetworkProxy )
    if false == NetworkProxy:IsDisconnect() then
        return false
    end
	releasePrint("重连2")
    -- enter world
    local loginProxy = global.Facade:retrieveProxy( global.ProxyTable.LoginProxy )
    loginProxy:RequestEnterWorld(true)
end

function NetworkMediator:OnReconnectForbidden()
    global.networkCtl:SetReconnectAble(false)
	local NativeBridgeProxy = global.Facade:retrieveProxy( global.ProxyTable.NativeBridgeProxy )
    NativeBridgeProxy:GN_DetachSucceedByServer()
    NativeBridgeProxy:GN_Game_Duration_State( {isGameDuration=false} )
end

function NetworkMediator:OnOtherClientLogin()
	-- 试玩模式
    if global.IsVisitor then
        return nil
    end
	if self._otherClient then
		return nil
	end
	self._otherClient = true
	if not GUI:GetWindow(nil, UIConst.LAYERID.CommonTipsGUI) then
		local data    = {}
		data.str      = GET_STRING(800801)
		data.btnDesc  = {GET_STRING(800802)}
		data.callback = handler(self, self.DialogCallback)
		UIOperator:OpenCommonTipsUI(data)
	end

	-- 通知native层native层
	if global.L_NativeBridgeManager.GN_otherClientLogin then
		global.L_NativeBridgeManager:GN_otherClientLogin()
	end

	-- 断开连接，且不重连
    global.networkCtl:SetReconnectAble(false)
    global.networkCtl:Disconnect()

	-- 云真机顶号 上报服务器
	if global.L_GameEnvManager:GetEnvDataByKey("isCloudLogin") then
		local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
		AuthProxy:CloudOtherLogin()
	end
end

function NetworkMediator:ShowReconnectTips()
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
	data.str      = GET_STRING(800804)
	data.btnDesc  = {GET_STRING( 800802 )}
	data.callback = confirmCB
	UIOperator:CloseCommonTipsUI()
	UIOperator:OpenCommonTipsUI(data)
end

function NetworkMediator:StartClickReconnect()
	if self._clickReconnectScheldID then
		return
	end
	if self._clickForbidden then
		return
	end
	self._clickReconnectScheldID = PerformWithDelayGlobal(function()
		self._clickReconnectScheldID = nil
		self._clickForbidden = true
	end, CLICK_WAIT_TIME)
end

function NetworkMediator:StopClickReconnect()
	self._clickForbidden = false
	if not self._clickReconnectScheldID then
		return
	end
	UnSchedule(self._clickReconnectScheldID)
	self._clickReconnectScheldID = nil
end

function NetworkMediator:ShowClickReconnectTips()
	local function reconnectCB( bType )
		if 1 == bType then
			-- pc关闭游戏，方便使用新的登录信息和更新exe
			if global.isWindows and not (global.isDebugMode or global.isGMMode) then
				global.Facade:sendNotification(global.NoticeTable.ShutdownGame)
			else
				global.L_NativeBridgeManager:GN_accountLogout()
				global.Facade:sendNotification( global.NoticeTable.RestartGame ) 
			end
		elseif 2 == bType then
			self:TryReconnect()
			return
		end
	end
	
	local data    = {}
	data.str      = GET_STRING(800807)
	data.btnDesc  = {GET_STRING( 800802 ), GET_STRING( 800808 )}
	data.callback = reconnectCB
	UIOperator:CloseCommonTipsUI()
	UIOperator:OpenCommonTipsUI(data)
end

return NetworkMediator