local LuaNetworkController = class("LuaNetworkController")
local RecvNetPackage = require("network/RecvNetPackage")
local SendNetPackage = require("network/SendNetPackage")
local cjson = require("cjson")

G_NetLogEnable = false

function LuaNetworkController:ctor()
	self._LuaHandlers = {}
	self._isConnected = false
	self._reconnectAble = true
	self._ignoreDisconnect = true
	self:Init()
end

function LuaNetworkController:CleanAllHandlers()
	self._LuaHandlers = {}
end

function LuaNetworkController:Cleanup()
	self:CleanAllHandlers()
	self._netClient:Cleanup()
	self._isConnected = false
	self._reconnectAble = true
	self._ignoreDisconnect = true
end

function LuaNetworkController:SetIgnoreDisconnect(ignore)
	self._ignoreDisconnect = ignore
end

function LuaNetworkController:IsIgnoreDisconnect()
	return self._ignoreDisconnect
end

function LuaNetworkController:Init()
	self._netClient = netClientLua:Inst()
    self:Cleanup()
	
	-- 网络消息
	self._netClient:SetRecvHandler(handler(self, self.HandleMessage))

	-- 网络错误消息
	self._netClient:SetErrorLuaHandler(handler(self, self.HandleNetError))

	-- 短线消息
	self._netClient:SetDisconnectLuaHandler(handler(self, self.HandleDisconnect))
end

function LuaNetworkController:GetNetClient()
	return self._netClient
end

function LuaNetworkController:Tick(dt)
	self._netClient:Tick()
end

function LuaNetworkController:Connect(ip, port)
	local ret = self._netClient:Connect(ip, port)
	self._isConnected = (ret == 1)
end

function LuaNetworkController:Disconnect()
	self._netClient:Disconnect()
end

function LuaNetworkController:IsConnected()
	return self._isConnected
end

function LuaNetworkController:RegisterHandler(msgID, netCB)
	if msgID == nil then
		print("net tips: RegisterHandler msgID is nil")
		return
	end
	if netCB == nil then
		print("net tips: RegisterHandler handler is nil")
		return
	end

    if self._LuaHandlers[msgID] == nil then
        self._LuaHandlers[msgID] = {}
    end
    self._LuaHandlers[msgID][#self._LuaHandlers[msgID]+1] = netCB
end

function LuaNetworkController:CheckReconnectAble()
	return self._reconnectAble
end

function LuaNetworkController:SetReconnectAble(v)
	self._reconnectAble = v
end

function LuaNetworkController:OnHeartBeatTimeout()
	-- 心跳断开
	if not SL._DEBUG then 
		dump("心跳超时  主动断开")
		self:Disconnect()
	end
end

function LuaNetworkController:HandleDisconnect()
	self._isConnected = false

	if self:IsIgnoreDisconnect() then
		return
	end
	print("HandleDisconnect")
	global.networkCtl:SetIgnoreDisconnect(true)
	global.Facade:sendNotification(global.NoticeTable.Disconnect)

	local ServerTimeProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerTimeProxy)
	if ServerTimeProxy then
    	ServerTimeProxy:CloseCheckDisconnectTimer()
	end
end

function LuaNetworkController:HandleNetError(errorCode)
	if errorCode ~= - 1 then 
		self:SetReconnectAble(false)
	end

	print("LuaNetworkController:HandleNetError(errorCode)", errorCode)
	if errorCode == 1 then
		-- // 非法消息头[消息头解密长度不对]
		local function callback(bType, custom)
			global.L_NativeBridgeManager:GN_accountLogout()
			global.Facade:sendNotification(global.NoticeTable.RestartGame)
		end
		local data = {}
		data.str    = string.format(GET_STRING(10000001), errorCode)
		data.btnDesc = { GET_STRING(1091)}
		data.callback = callback
		data.hideCloseBtn = true
		UIOperator:OpenCommonTipsUI(data)
	end
end

function LuaNetworkController:HandleMessage(netPkg)

	--msgID, len, headBytes, bodyBytes
	-- dump({msgID, len, headBytes, bodyBytes},"HandleMessage___")
	-- 重置心跳
	global.Facade:sendNotification(global.NoticeTable.ResetGameWorldRecvHeartBeat)
	local msgID = netPkg:GetMsgID()
	local pList = self._LuaHandlers[msgID]
    if pList == nil then
        print("________________handler! unsolved net msgID:" .. msgID)
        return -2
    end

	local netPkg = RecvNetPackage.new(netPkg)
	if global.isWindows and G_NetLogEnable then
		if msgID ~= global.MsgType.MSG_CS_HEART_BEAT_KEEP then
			print("recv: ", msgID, netPkg:GetBodyLen())
			
            ---解析收到的消息 空格分割
            G_NetTestParse = G_NetTestParse or {}
            if G_NetTestParse[msgID] then 
                local buffer = netPkg:GetBodyLuaBuffer()
                buffer:SetLuaIndex(0)
                local recvList = string.split(G_NetTestParse[msgID]," ")
                local body = {}
                for i, v in ipairs(recvList) do
                    if G_BUFFER_READ_PARSE[v] then 
                        body[#body+1] = G_BUFFER_READ_PARSE[v](buffer)
                    else
                        if string.find(v,"s%d*") then 
                            local len =  string.match(v,"s(%d*)")
                            body[#body+1] = SL:GBKToUTF8(buffer:ReadShortString(tonumber(len)))
                        else
                            dump("unkonw parse"..v)
                        end
                    end
                end
                dump(body,"解析:".. msgID)
                buffer:SetLuaIndex(0)
            end
		end
	end
	for _, v in ipairs(pList) do
		v(netPkg, msgID)
	end
end

function LuaNetworkController:SendBytes(msgID, netPkg, bodyLen)
    if self._netClient == nil then
		print("_netClient is NULL!!")
        return
    end
    if not self:IsConnected() then
		print("netClient is not connected!!")
        return
    end
    if global.isWindows and G_NetLogEnable then
		if msgID ~= global.MsgType.MSG_CS_HEART_BEAT_KEEP then
			print("send: ", msgID)
		end
	end
	-- dump({msgID, headBytes, bodyBytes, bodyLen}, "SendMsg_____")
	-- dump(debug.traceback())
    self._netClient:SendNetMessage(netPkg)
	-- 重置心跳
	global.Facade:sendNotification(global.NoticeTable.ResetGameWorldSendHeartBeat)
end

function LuaNetworkController:SendMsg(msgID, p0, p1, p2, p3, bodyStr)
	local sendPkg = SendNetPackage.new(msgID)
	sendPkg:SetArrInt64OrStr({p0, p1, p2, p3})
	sendPkg:SetBody(bodyStr)
	sendPkg:SetHeadAndBody()
	local netPkg = sendPkg:GetNetPackage()
    LuaSendBytes(sendPkg:GetMsgID(), netPkg, sendPkg:GetBodyLen())
end


function LuaNetworkController:SendHeader2(msgID, int64_1, int64_2, int64_3, int64_4, bodyStr)
	local sendPkg = SendNetPackage.new(msgID)
	sendPkg:SetArrInt64({int64_1, int64_2, int64_3, int64_4})
	sendPkg:SetBody(bodyStr)
	sendPkg:SetHeadAndBody()
	local netPkg = sendPkg:GetNetPackage()
    LuaSendBytes(sendPkg:GetMsgID(), netPkg , sendPkg:GetBodyLen())
end

function LuaNetworkController:SendHeader3(msgID, head, bodyStr)
	local sendPkg = SendNetPackage.new(msgID)
	sendPkg:SetHead3(head)
	sendPkg:SetBody(bodyStr)
	sendPkg:SetHeadAndBody()
	local netPkg = sendPkg:GetNetPackage()
    LuaSendBytes(sendPkg:GetMsgID(), netPkg, sendPkg:GetBodyLen())
end

function LuaNetworkController:SendHeader4(msgID, int32_1, int32_2, int32_3, int32_4, int32_5, int32_6, int32_7, int32_8, bodyStr)
	local sendPkg = SendNetPackage.new(msgID)
	sendPkg:SetArrInt({int32_1, int32_2, int32_3, int32_4, int32_5, int32_6, int32_7, int32_8})
	sendPkg:SetBody(bodyStr)
	sendPkg:SetHeadAndBody()
	local netPkg = sendPkg:GetNetPackage()
    LuaSendBytes(sendPkg:GetMsgID(), netPkg, sendPkg:GetBodyLen())
end

function LuaNetworkController:SendHeader5(msgID, unint32_1, unint32_2, unint32_3, unint32_4, unint32_5, unint32_6, unint32_7, unint32_8, bodyStr)
	local sendPkg = SendNetPackage.new(msgID)
	sendPkg:SetArrUInt({unint32_1, unint32_2, unint32_3, unint32_4, unint32_5, unint32_6, unint32_7, unint32_8})
	sendPkg:SetBody(bodyStr)
	sendPkg:SetHeadAndBody()
	local netPkg = sendPkg:GetNetPackage()
    LuaSendBytes(sendPkg:GetMsgID(), netPkg, sendPkg:GetBodyLen())
end

function LuaNetworkController:SendHeader6(msgID, Guid1, Guid2, bodyStr)
	local sendPkg = SendNetPackage.new(msgID)
	sendPkg:SetArrGuid({Guid1,Guid2})
	sendPkg:SetBody(bodyStr)
	sendPkg:SetHeadAndBody()
	local netPkg = sendPkg:GetNetPackage()
    LuaSendBytes(sendPkg:GetMsgID(), netPkg, sendPkg:GetBodyLen())
end

-- {Guid,int64,int64}
function LuaNetworkController:SendHeader12(msgID, Guid, int64_1, int64_2, bodyStr)
	local sendPkg = SendNetPackage.new(msgID)
	sendPkg:SetGuidInt64({Guid, int64_1, int64_2})
	sendPkg:SetBody(bodyStr)
	sendPkg:SetHeadAndBody()
	local netPkg = sendPkg:GetNetPackage()
    LuaSendBytes(sendPkg:GetMsgID(), netPkg, sendPkg:GetBodyLen())
end

-- {Guid,int32,int32,int32,int32}
function LuaNetworkController:SendHeader13(msgID, Guid, int32_1, int32_2, int32_3, int32_4, bodyStr)
	local sendPkg = SendNetPackage.new(msgID)
	sendPkg:SetGuidInt32({Guid, int32_1, int32_2, int32_3, int32_4})
	sendPkg:SetBody(bodyStr)
	sendPkg:SetHeadAndBody()
	local netPkg = sendPkg:GetNetPackage()
    LuaSendBytes(sendPkg:GetMsgID(), netPkg, sendPkg:GetBodyLen())
end

-- {int64,int32,int32,int32,int32,int64}
function LuaNetworkController:SendHeader7(msgID, int64_1, int32_2, int32_3, int32_4, int32_5, int64_6, bodyStr)
	local sendPkg = SendNetPackage.new(msgID)
	sendPkg:SetArrP1P2Int64({int64_1, int32_2, int32_3, int32_4, int32_5, int64_6})
	sendPkg:SetBody(bodyStr)
	sendPkg:SetHeadAndBody()
	local netPkg = sendPkg:GetNetPackage()
	LuaSendBytes(sendPkg:GetMsgID(), netPkg, sendPkg:GetBodyLen())
end

function LuaNetworkController:SendHeadStr(msgID, headStr, bodyStr)
	local sendPkg = SendNetPackage.new(msgID)
	sendPkg:SetHeadStr(headStr)
	sendPkg:SetBody(bodyStr)
	sendPkg:SetHeadAndBody()
	local netPkg = sendPkg:GetNetPackage()
    LuaSendBytes(sendPkg:GetMsgID(), netPkg, sendPkg:GetBodyLen())
end

function LuaNetworkController:SendJsonData(msgID, jsonData)
	local sendPkg = SendNetPackage.new(msgID)
	sendPkg:SetArrInt64({0, 0, 0, 0})
	sendPkg:SetBody(cjson.encode(jsonData))
	sendPkg:SetHeadAndBody()
	local netPkg = sendPkg:GetNetPackage()
    LuaSendBytes(sendPkg:GetMsgID(), netPkg, sendPkg:GetBodyLen())
end

function LuaNetworkController:SendHeaderBody(msgID, headProtos, bodyProtos)
	local sendPkg = SendNetPackage.new(msgID)
	sendPkg:SetHeadBody(headProtos, bodyProtos)
	sendPkg:SetHeadAndBody()
	local netPkg = sendPkg:GetNetPackage()
    LuaSendBytes(sendPkg:GetMsgID(), netPkg, sendPkg:GetBodyLen())
end

-------------------------------------------------------------------------
-- 网络消息工具方法
function LuaSendMsg(...)
    global.networkCtl:SendMsg(...)
end

function LuaSendHeadStr(...)
    global.networkCtl:SendHeadStr(...)
end

--int64 int64 int64 int64
function LuaSendHeader2(...)
    global.networkCtl:SendHeader2(...)
end

--{Id=xx,X=xx,Y=xx,Dir=xx,Type=xx,Flag=xx}
function LuaSendHeader3(...)
    global.networkCtl:SendHeader3(...)
end

--int32 int32 int32 int32 int32 int32 int32 int32
function LuaSendHeader4(...)
    global.networkCtl:SendHeader4(...)
end

--unint32 unint32 unint32 unint32 unint32 unint32 unint32 unint32
function LuaSendHeader5(...)
    global.networkCtl:SendHeader5(...)
end

--Guid Guid
function LuaSendHeader6(...)
    global.networkCtl:SendHeader6(...)
end

-- int64 int32 int32 int32 int32 int64
function LuaSendHeader7(...)
	global.networkCtl:SendHeader7(...)
end

--Guid, int64, int64
function LuaSendHeader12(...)
    global.networkCtl:SendHeader12(...)
end

-- Guid, int32, int32, int32, int32
function LuaSendHeader13(...)
    global.networkCtl:SendHeader13(...)
end

function LuaSendJsonData(...)
    global.networkCtl:SendJsonData(...)
end

function LuaSendHeadBody(...)
	global.networkCtl:SendHeaderBody(...)
end

return LuaNetworkController