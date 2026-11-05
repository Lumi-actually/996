local RemoteProxy = requireProxy("RemoteProxy")
local MailProxy = class("MailProxy", RemoteProxy)
MailProxy.NAME = global.ProxyTable.MailProxy

function MailProxy:ctor()
	MailProxy.super.ctor(self)

	self._mails = {}        	--服务器发过来的邮件列表
	self._mailCount = 0         --邮件个数
	self._mailRewardCount = 0   --未领取奖励的邮件个数
end

function MailProxy:ResetAllMail()
	self._mails = {}
	self._mailCount = 0
	self._mailRewardCount = 0
end

--获取邮件的邮件列表
function MailProxy:GetMailList()
	return self._mails
end

--根据邮件的mailId得到邮件
function MailProxy:GetMailByID(mailID)
	return self._mails[mailID]
end

function MailProxy:GetMailCount()
	-- 获取邮件数量
	return self._mailCount
end

function MailProxy:GetMailRewardCount()
	-- 可领取邮件数量
	return self._mailRewardCount
end

function MailProxy:CheckHaveUnReadMail()
    local mails = SL:GetValue("MAIL_LIST")
    for k, v in pairs(mails) do
        if v.btReadFlag == 0 or (#v.sItem > 0 and v.btRecvFlag == 0) then
            return true
        end
    end
    return false
end

function MailProxy:CheckRefreshBubbleTips()
	local show = false
	if self:CheckHaveUnReadMail() then
		show = true
	end
	SL:onLUAEvent(LUA_EVENT_MAIL_BUBBLE_TIPS_CHANGE, show)
end

--读邮件
function MailProxy:RequestReadMail(mailID)
	if self:GetMailByID(mailID) == nil then
		return
	end
	self._mails[mailID].btReadFlag = 1
	LuaSendMsg(global.MsgType.MSG_CS_EMAIL_READ, 0, mailID)
	self:CheckRefreshBubbleTips()
end

--提取附件
function MailProxy:RequestGetMailRewardByID(mailID)
	if self:GetMailByID(mailID) == nil then
		return false
	end
	LuaSendMsg(global.MsgType.MSG_CS_EMAIL_GET, 0, 1, mailID)
end

--全部提取
function MailProxy:RequestGetAllMailIReward()
    for k, v in pairs(self._mails) do
        v.btReadFlag = 1
    end
	LuaSendMsg(global.MsgType.MSG_CS_EMAIL_GET, 0, 2)
end

--删除邮件
function MailProxy:RequestDeleteMail(mailID)
	if self:GetMailByID(mailID) == nil then
		return false
	end
	LuaSendMsg(global.MsgType.MSG_CS_EMAIL_DELETE, 0, mailID)

	self._mails[mailID] = nil
	self._mailCount = self._mailCount - 1

	SL:onLUAEvent(LUA_EVENT_MAIL_DELETE, mailID)
end

--删除已读
function MailProxy:RequestDeleteAllReadMail()
	LuaSendMsg(global.MsgType.MSG_CS_EMAIL_DELETE_ALL_READ)
end

--请求获取所有邮件列表 
function MailProxy:RequestMailList()
	LuaSendMsg(global.MsgType.MSG_CS_EMAIL_LIST)
end

function MailProxy:handle_MSG_SC_EMAIL_LIST(msg)
	local totalMailCount = msg:GetP0()
	local isReset = msg:GetP1() == 1
	-- 初始邮件数据[可能多条 30封发一次]
	if isReset then
		self:ResetAllMail()
	end

	local jsonData = msg:GetJsonData()
	for i, mail in ipairs(jsonData) do
		mail.index = self._mailCount + 1
		mail.sItem = mail.sItem or {}

		if #mail.sItem > 0 and mail.btRecvFlag ~= 1 then
			self._mailRewardCount = self._mailRewardCount + 1
		end
		
		self._mails[mail.Id] = mail
		self._mailCount = self._mailCount + 1
	end
	if totalMailCount == self._mailCount then
		SL:onLUAEvent(LUA_EVENT_MAIL_LIST_REFRESH, self._mails)
		self:CheckRefreshBubbleTips()
	end
end

function MailProxy:handle_MSG_SC_EMAIL_DELETE_ALL_READ(msg)
	SL:onLUAEvent(LUA_EVENT_MAIL_DELETE_ALL_READ)
end

function MailProxy:handle_MSG_SC_EMAIL_GET(netPkg)
	local recog = netPkg:GetP0()
	if recog == 1 then
		-- 单个刷新
		local mailID = netPkg:GetP1()
		if self._mails[mailID] then
			self._mails[mailID].btRecvFlag = 1
			self._mailRewardCount = self._mailRewardCount - 1
			SL:onLUAEvent(LUA_EVENT_MAIL_UPDATE, mailID)
		end

	elseif recog == 2 then
		-- 所有刷新
		for k, v in pairs(self._mails) do
			v.btRecvFlag = 1
		end
		self._mailRewardCount = 0
		SL:onLUAEvent(LUA_EVENT_MAIL_UPDATE_ALL)
	end
	self:CheckRefreshBubbleTips()
end

function MailProxy:handle_MSG_SC_EMAIL_NEW_NOTICE()
	SL:onLUAEvent(LUA_EVENT_MAIL_NEW_NOTICE)
end

function MailProxy:handle_MSG_SC_EMAIL_TAKE_STATE_RESPONSE(msg)
    local header = msg:GetHeader()
    local mailId = header.recog
    if self._mails[mailId] then
        local param = header.param1 -- 1 收货确认  2 拒绝收货
        if param == 1 then
            self._mails[mailId].btRecvFlag = 0 --btRecvFlag：附件领取标志：0：未领取，1：已领取
            self._mails[mailId].btType = 9999
			SLBridge:onLUAEvent(LUA_EVENT_MAIL_UPDATE, mailId)
			self:CheckRefreshBubbleTips()
        elseif param == 2 then
            if self._mails[mailId] == nil then
                return false
            end
			self._mails[mailId] = nil
            self._mailCount = self._mailCount - 1

			SLBridge:onLUAEvent(LUA_EVENT_MAIL_DELETE, mailId)
        end
    end
end

function MailProxy:RegisterMsgHandler()
	MailProxy.super.RegisterMsgHandler(self)
	local msgType = global.MsgType

	LuaRegisterMsgHandler(msgType.MSG_SC_EMAIL_LIST, handler(self, self.handle_MSG_SC_EMAIL_LIST)) -- 邮件列表
	LuaRegisterMsgHandler(msgType.MSG_SC_EMAIL_GET, handler(self, self.handle_MSG_SC_EMAIL_GET)) --提取附件成功
	LuaRegisterMsgHandler(msgType.MSG_SC_EMAIL_NEW_NOTICE, handler(self, self.handle_MSG_SC_EMAIL_NEW_NOTICE)) -- 新邮件到来
	LuaRegisterMsgHandler(msgType.MSG_SC_EMAIL_DELETE_ALL_READ, handler(self, self.handle_MSG_SC_EMAIL_DELETE_ALL_READ)) -- 删除已读的邮件
	LuaRegisterMsgHandler(msgType.MSG_SC_EMAIL_TAKE_STATE_RESPONSE, handler(self, self.handle_MSG_SC_EMAIL_TAKE_STATE_RESPONSE)) -- 邮件收货状态
end

return MailProxy