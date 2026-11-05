local RemoteProxy = requireProxy("RemoteProxy")
local NoticeProxy = class("NoticeProxy", RemoteProxy)
NoticeProxy.NAME = global.ProxyTable.NoticeProxy

function NoticeProxy:ctor()
    NoticeProxy.super.ctor(self)

    self._isDelete = false
end

function NoticeProxy:handle_MSG_SC_SERVICE_TIPS(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return false
    end
    dump(jsonData)

    -- close
    if not next(jsonData) or (not jsonData.Msg) or (jsonData.Msg == "") then
        UIOperator:CloseCommonTipsUI()
        return false
    end

    local btn = {}
    if jsonData.Btn1 and string.len(jsonData.Btn1) > 1 then
        table.insert(btn, {name = GET_STRING(1001), act = jsonData.Btn1})
    end
    if jsonData.Btn2 and string.len(jsonData.Btn2) > 1 then
        table.insert(btn, {name = GET_STRING(1000), act = jsonData.Btn2})
    end

    local tips    = string.gsub(jsonData.Msg, "\\", "<br>") 
    local data    = {}
    data.str      = tips
    data.btnDesc  = #btn > 0 and {btn[1].name, btn[2] and btn[2].name or nil} or {GET_STRING(1001)}
    data.callback = function(eventIndex)
        if #btn > 0 then
            local cdata    = {}
            cdata.UserID   = jsonData.UserID
            cdata.newIndex = jsonData.newIndex
            cdata.Act      = btn[eventIndex].act
            local NPCProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
            NPCProxy:ExecuteWithJsonData(cdata)
        end
    end
    UIOperator:OpenCommonTipsUI(data)
end

function NoticeProxy:handle_MSG_SC_SYSTEM_INFO(msg)
    local jsonData = msg:GetJsonData()
    if not jsonData then
        return
    end

    -- print("------------------------------------")
    -- print(" into here to get system info ")
    -- dump(jsonData,"handle_MSG_SC_SYSTEM_INFO__")
    -- print("------------------------------------")

    local param = msg:GetP0()
    if param == 1 then  -- lua版维持老版字段
        self:OnSendLuaNoticeMsg(jsonData)
        return
    end

    -- MsgType:
    -- //1 发送聊天框固顶信息 8
    -- //2 发送屏幕滚动信息 5
    -- //3 发送屏幕中间大字体信息 6
    -- //4 屏幕任意坐标发送公告信息 10
    -- //5 主屏幕弹出公告 13
    -- //6 显示倒计时信息提示 14
    -- //7 SYSTEMTIPS 9

    -- Type: 聊天频道
    -- Msg:提示内容
    -- FColor:文字色值ID
    -- BColor:背景色值ID
    -- Y:坐标Y
    -- Count:播放次数
    -- Time:倒计时
    -- Label:响应Link
    -- Prefix: 聊天消息前缀

    if jsonData.MsgType == 1 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Time        = jsonData.Time,
            Label       = jsonData.Label,
            SendId      = jsonData.UserID,
            SendName    = jsonData.UserName,
        }
        ChatData.AddChatExItemsData(data)

    elseif jsonData.MsgType == 2 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Y           = jsonData.MsgY,
            Count       = jsonData.Count,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowSystemNotice, data)

    elseif jsonData.MsgType == 3 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Time        = jsonData.Time,
            Label       = jsonData.Label,
            X           = jsonData.MsgX,
            Y           = jsonData.MsgY
        }
        global.Facade:sendNotification(global.NoticeTable.ShowTimerNotice, data)
        
    elseif jsonData.MsgType == 4 then
        local data      = {
            X           = jsonData.MsgX,
            Y           = jsonData.MsgY,
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowSystemNoticeXY, data)
        
    elseif jsonData.MsgType == 5 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Y           = jsonData.MsgY,
            Count       = jsonData.Count,
            ShowTime    = jsonData.Time,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowSystemNoticeScale, data)

    elseif jsonData.MsgType == 6 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Time        = jsonData.Time,
            Label       = jsonData.Label,
            X           = jsonData.MsgX,
            isDelete    = jsonData.Del,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowTimerNoticeXY, data)

    elseif jsonData.MsgType == 7 then  
        ShowSystemTips(jsonData.Msg)

    else
        if not jsonData.Type then return end
        if jsonData.Type <= 9 then -- 按聊天消息处理
            if jsonData.Type <= 0 then jsonData.Type = 9 end
            local isNpcMsg = nil
            -- NPC名字特殊拆分
            if jsonData.Npc == 1 and jsonData.Msg then
                local _, _, npcName = string.find(jsonData.Msg, "^%[(.-)%]")
                if npcName then
                    local _, _, showName = string.find(npcName, ".-%#(.-)%#")
                    if showName then
                        isNpcMsg = string.gsub(jsonData.Msg, npcName, showName)
                    end
                end
            end
            local mdata     = {
                Msg         = isNpcMsg or jsonData.Msg,
                FColor      = jsonData.FColor,
                BColor      = jsonData.BColor,
                ChannelId   = jsonData.Type,
                SendName    = jsonData.UserName,
                SendId      = jsonData.UserID,
                Prefix      = jsonData.Prefix,
                textType    = GUIDefine.ChatTextType.SRTEXT,
            }
            SLBridge:onLUAEvent(LUA_EVENT_CHAT_MSG_ADD, mdata)
        end
    end
end

function NoticeProxy:OnSendLuaNoticeMsg(jsonData)
    if jsonData.Type == 1 or jsonData.Type == 0 or not jsonData.Type then
        local mdata     = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            ChannelId   = jsonData.Type == 0 and GUIDefine.ChatChannel.WORLD or GUIDefine.ChatChannel.SYSTEM,
            SendName    = jsonData.SendName,
            SendId      = jsonData.SendId,
            textType    = jsonData.mt or GUIDefine.ChatTextType.SRTEXT,
            Prefix      = jsonData.Prefix,
        }
        SLBridge:onLUAEvent(LUA_EVENT_CHAT_MSG_ADD, mdata)

    elseif jsonData.Type == 2 then
        local mdata     = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            ChannelId   = GUIDefine.ChatChannel.GUILD,
            textType    = GUIDefine.ChatTextType.SYSTEMTIPS,
            Prefix      = jsonData.Prefix
        }
        SLBridge:onLUAEvent(LUA_EVENT_CHAT_MSG_ADD, mdata)
    
    elseif jsonData.Type == 3 then
        local mdata     = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            ChannelId   = GUIDefine.ChatChannel.TEAM,
            textType    = GUIDefine.ChatTextType.SYSTEMTIPS,
            Prefix      = jsonData.Prefix
        }
        SLBridge:onLUAEvent(LUA_EVENT_CHAT_MSG_ADD, mdata)

    elseif jsonData.Type == 4 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowServerNotice, data)

    elseif jsonData.Type == 5 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Y           = jsonData.Y,
            Count       = jsonData.Count,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowSystemNotice, data)

    elseif jsonData.Type == 6 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Time        = jsonData.Time,
            Label       = jsonData.Label,
            X           = jsonData.X,
            Y           = jsonData.Y
        }
        global.Facade:sendNotification(global.NoticeTable.ShowTimerNotice, data)

    elseif jsonData.Type == 8 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Time        = jsonData.Time,
            Label       = jsonData.Label,
            SendId      = jsonData.SendId,
            SendName    = jsonData.SendName,
        }
        ChatData.AddChatExItemsData(data)

    elseif jsonData.Type == 9 then
        ShowSystemTips(jsonData.Msg)

    elseif jsonData.Type == 10 then
        local data      = {
            X           = jsonData.X,
            Y           = jsonData.Y,
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowSystemNoticeXY, data)

    elseif jsonData.Type == 11 then
        local data      = {
            Type        = jsonData.Type,
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
        }
        global.Facade:sendNotification(global.NoticeTable.ServerNoticeEvent, data)

    elseif jsonData.Type == 12 then
        local mdata     = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            ChannelId   = GUIDefine.ChatChannel.SYSTEM,
            textType    = GUIDefine.ChatTextType.SYSTEMTIPS,
            Prefix      = jsonData.Prefix,
        }
        SLBridge:onLUAEvent(LUA_EVENT_CHAT_MSG_ADD, mdata)

    elseif jsonData.Type == 13 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Y           = jsonData.Y,
            Count       = jsonData.Count,
            ShowTime    = jsonData.time,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowSystemNoticeScale, data)

    elseif jsonData.Type == 14 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Time        = jsonData.Time,
            Label       = jsonData.Label,
            X           = jsonData.X,
            isDelete    = jsonData.isDelete,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowTimerNoticeXY, data)

    elseif jsonData.Type == 15 then
        local data      = {
            Type        = jsonData.Type,
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowItemDropNotice, data)
    end
end

function NoticeProxy:handle_MSG_SC_REMOVE_TIMER_NOTICEXY(msg)
    local header = msg:GetHeader()
    -- dump(header.param1) 

    if tonumber(header.param1) and tonumber(header.param1) == 14 then
        global.Facade:sendNotification(global.NoticeTable.DeleteTimerNoticeXY)
    end
end

-- 播放音效
local audio_data = {}
function NoticeProxy:handle_MSG_SC_PLAY_AUDIO(msg)
    local jsonData = ParseRawMsgToJson(msg)
    dump(jsonData)
    if not jsonData then
        return nil
    end
    if not jsonData.id or not jsonData.playcount then
        return nil
    end

    audio_data.id    = jsonData.id
    audio_data.times = jsonData.playcount or 1
    audio_data.loop  = false
    audio_data.type  = global.MMO.SUD_TYPE_NORMAL
    global.Facade:sendNotification(global.NoticeTable.Audio_Play_EffectId, audio_data)
end

function NoticeProxy:handle_MSG_SC_REMOVE_TIMER_NOTICE(msg)
    local tag = msg:GetBodyStr() or ""
    tag = string.len(tag) > 0 and tag or nil
    global.Facade:sendNotification(global.NoticeTable.DeleteTimerNotice, tag)
end

function NoticeProxy:handle_MSG_SC_OPENUI(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return
    end
    dump(jsonData)

    local id        = jsonData.id
    local param     = jsonData.param
    local param2    = tonumber(jsonData.param2) or 0
    
    local JumpProxy = global.Facade:retrieveProxy(global.ProxyTable.JumpProxy)
    JumpProxy:JumpTo(id, param, param2)
end

function NoticeProxy:handle_MSG_SC_PLAY_DICE(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return
    end
    dump(jsonData)

    UIOperator:OpenPlayDiceUI(jsonData)
end

function NoticeProxy:handle_MSG_SC_CLIPBOARD_TEXT(msg)
    local msgLen = msg:GetDataLength()
    if msgLen > 0 then
        local dataString = msg:GetBodyStr()
        if global.isWindows then
            if Win32BridgeCtl then
                Win32BridgeCtl:Inst():copyToClipboard(dataString)
            end
        else
            global.L_NativeBridgeManager:GN_setClipboardText(dataString)
        end
    end
end

-- 拉起微信/QQ
function NoticeProxy:handle_MSG_SC_START_APP(msg)
    local header = msg:GetHeader()

    if header.recog == 1 then
        -- 拉起qq
        if global.L_NativeBridgeManager.GN_startQQ then
            global.L_NativeBridgeManager:GN_startQQ()
        end
        
    elseif header.recog == 2 then
        -- 加qq好友
        local jsonData = ParseRawMsgToJson(msg)
        if jsonData and jsonData.qqKey then
            if global.L_NativeBridgeManager.GN_joinQQ then
                global.L_NativeBridgeManager:GN_joinQQ({qqKey = jsonData.qqKey})
            end
        end
    
    elseif header.recog == 3 then
        -- 加qq群
        local jsonData = ParseRawMsgToJson(msg)
        if jsonData and jsonData.qqGroupUin and jsonData.qqGroupKey then
            if global.L_NativeBridgeManager.GN_joinQQGroup then
                global.L_NativeBridgeManager:GN_joinQQGroup({qqGroupUin = jsonData.qqGroupUin, qqGroupKey = jsonData.qqGroupKey})
            end
        end

    elseif header.recog == 4 then
        -- 拉微信
        if global.L_NativeBridgeManager.GN_startWX then
            global.L_NativeBridgeManager:GN_startWX()
        end

    elseif header.recog == 5 then
        -- todo
        -- 拉微信公众号
    end
end

-- 服务器断开提醒
function NoticeProxy:handle_MSG_SC_SERVER_GAME_ERROR(msg)
    local function callback(bType, custom)
        -- pc关闭游戏，方便使用新的登录信息和更新exe
        if global.isWindows and not (global.isDebugMode or global.isGMMode) then
            global.Facade:sendNotification(global.NoticeTable.ShutdownGame)
        else
            global.L_NativeBridgeManager:GN_accountLogout()
            global.Facade:sendNotification( global.NoticeTable.RestartGame ) 
        end
    end

    -- 提醒内容
    local msgLen = msg:GetDataLength()
    local dataString = msgLen > 0 and  msg:GetBodyStr() or ""

    --退出倒计时
    local findS, findE = string.find(dataString, "%[restart:%d+%]")
    local restartDownTimes = nil
    if findS and findE and findE > findS then
        local restartStr = string.sub(dataString, findS+1, findE-1)
        local resartArray = string.split(restartStr, ":")
        restartDownTimes = resartArray[2] and tonumber(resartArray[2])
        dataString = string.gsub(dataString, "%["..restartStr.."%]", "")

        -- 退出
        if restartDownTimes then
            SL:ScheduleOnce(function()
                global.gameWorldController:OnGameRestart()
            end, restartDownTimes)
        end
    end

    -- 是否直接退出
    local checkWord  = restartDownTimes and {} or {"crash"}
    local titleStr   = string.lower(dataString)
    local isExitGame = false
    for i,v in ipairs(checkWord) do
        local findS,findE = string.find(titleStr, v)
        if findS and findE then
            isExitGame = true
            break
        end
    end

    if isExitGame then
        global.Director:endToLua()
        return
    end

    if not GUI:GetWindow(nil, UIConst.LAYERID.CommonTipsGUI) then
        local data = {}
        data.str = dataString
        data.btnDesc = { GET_STRING(1001)}
        data.callback = callback
        data.hideCloseBtn = true
        UIOperator:OpenCommonTipsUI(data)
    end

    -- 重连禁用
    global.Facade:sendNotification(global.NoticeTable.ReconnectForbidden)
end

-- 限制聊天
function NoticeProxy:handle_MSG_SC_LIMIT_CHAT(msg)
    local header = msg:GetHeader()
    local forbidSay = header.recog

    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    LoginProxy:SetForbidChat(forbidSay == 1)
end

-- 自定义事件数据上报
function NoticeProxy:handle_MSG_SC_CUSTOM_EVENT_REPORT(msg)
    local msgLen = msg:GetDataLength()
    if msgLen <= 0 then
        return
    end
    local dataString = msg:GetBodyStr()

    local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    NativeBridgeProxy:GN_ReportCustomEvent(dataString)
end

local function urlencodechar(char)
    return "%" .. string.format("%02X", string.byte(char))
end
local function urlencodeT(input)
    -- convert line endings
    input = string.gsub(tostring(input), "\n", "\r\n")

    -- escape all characters but alphanumeric, '.' and '-'
    input = string.gsub(input, "([^%w%.%-%_%~ :/=?&#])", urlencodechar)
    -- convert spaces to "+" symbols
    return string.gsub(input, " ", "+")
end
function NoticeProxy:handle_MSG_SC_OPEN_URL(msg)
    local header = msg:GetHeader()
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return -1
    end

    dump(jsonData)
    local url = jsonData.url
    if not url or string.len(url) < 1 then
        return
    end
    if global.isIOS then
        url = urlencodeT(url)
    end
    cc.Application:getInstance():openURL(url)
end

-- CDK兑换
function NoticeProxy:handle_MSG_SC_USE_CDK(msg)
    local msgLen = msg:GetDataLength()
    if msgLen <= 0 then
        release_print("Convert string len is 0")
        return
    end

    local convertID = msg:GetBodyStr()
    self:RequestCDK(convertID)
end

function NoticeProxy:RequestCDK(convertID)
    local loginProxy    = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local envProxy      = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)

    local userid        = loginProxy:GetSelectedRoleID()
    local rolename      = loginProxy:GetSelectedRoleName()
    local code          = convertID
    local serverid      = loginProxy:GetSelectedServerId()
    local operid        = global.L_ModuleManager:GetCurrentModule():GetOperID()
    local platformid    = envProxy:GetChannelID()

    local serverip      = loginProxy:GetSelectedServerIp()
    local serverdomain  = loginProxy:GetSelectedServerDomain()
    local cdkURL        = envProxy:GetCustomDataByKey("checkCodeUrl")

    if not cdkURL or string.len(cdkURL) <= 0 then
        return
    end

    local cjson = require("cjson")
    -- http数据请求回调
    local function callback(success, response)
        if success then
            local jsonData = cjson.decode(response)
            if not jsonData then
                release_print("request Convert error: step 2, convert code http callback！ json decode error")
                return false
            end
            --[[                Scodearr=array（
                    0=>’激活码可用”，
                    2=>’激活码不可用”，
                    2=>’激活码不存在’，
                    3=>’激活到已失效’，
                    4=>’使用过同类礼包’，
                    5=>’激活码已使用’，
                    6=>’激活码繁忙，请稍后重试”，
            ]]
            dump(jsonData, "jsonData::::")

            local titleStr = jsonData.msg or GET_STRING(700001000)
            global.Facade:sendNotification(global.NoticeTable.SystemTips, titleStr)
        else
            release_print("request Convert error: step 1, convert code http callback！ failed")
            global.Facade:sendNotification(global.NoticeTable.SystemTips, GET_STRING(700001001))
        end
    end
    local suffix = string.format("userid=%s&name=%s&code=%s&serverid=%s&operid=%s&platformId=%s&serverDomain=%s", userid, rolename, code, serverid, operid, platformid, serverdomain)
    HTTPRequestPost(cdkURL, callback, suffix)
end

-- 弹实名认证
function NoticeProxy:handle_MSG_SM_BINDHUMMSG(msg)
    global.L_NativeBridgeManager:GN_requestRealName()
end

-- 播放特效
function NoticeProxy:handle_MSG_SC_FIRE_WORK_TX_REPONSE(netPkg)
    local data = {
        userid = netPkg:GetP0Str(),
        effectID = netPkg:GetP1(),
    }
    SL:onLUAEvent(LUA_EVENT_FIRE_WORK_HALL_SHOW,data)
end

--气泡
function NoticeProxy:handle_MSG_SC_BUBBLE_TIPS_CUSTOM(msg)
    local msgLen = msg:GetDataLength()
    local msgHdr = msg:GetHeader()
    local str = ""
    if msgLen ~= 0 then
        str = msg:GetBodyStr()
    end

    local t = {}
    if msgHdr.recog == 0 then
        local strs = G_GetSplitArray(str, ",")
        local path = strs[1]
        local link = strs[2]
        local id = msgHdr.param1 or 0
        local func = function()
            local SUIComponentProxy = global.Facade:retrieveProxy(global.ProxyTable.SUIComponentProxy)
            SUIComponentProxy:SubmitAct({Act = link})
        end
        SL:AddBubbleTips("custom_" .. id, path, func)
    else
        local id = msgHdr.param1 or 0
        SL:DelBubbleTips("custom_" .. id)
    end
end

function NoticeProxy:RegisterMsgHandlerAfterEnterWorld()
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_SERVICE_TIPS, handler(self, self.handle_MSG_SC_SERVICE_TIPS))
    LuaRegisterMsgHandler(msgType.MSG_SC_SYSTEM_INFO, handler(self, self.handle_MSG_SC_SYSTEM_INFO))    -- 接收到的系统消息
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAY_AUDIO, handler(self, self.handle_MSG_SC_PLAY_AUDIO))      -- 播放音乐
    LuaRegisterMsgHandler(msgType.MSG_SC_REMOVE_TIMER_NOTICE, handler(self, self.handle_MSG_SC_REMOVE_TIMER_NOTICE))    -- 删除定时系统消息
    LuaRegisterMsgHandler(msgType.MSG_SC_OPENUI, handler(self, self.handle_MSG_SC_OPENUI))      -- 打开界面
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAY_DICE, handler(self, self.handle_MSG_SC_PLAY_DICE))      -- 播放骰子
    LuaRegisterMsgHandler(msgType.MSG_SC_CLIPBOARD_TEXT, handler(self, self.handle_MSG_SC_CLIPBOARD_TEXT))      -- 播放骰子
    LuaRegisterMsgHandler(msgType.MSG_SC_REMOVE_TIMER_NOTICEXY, handler(self, self.handle_MSG_SC_REMOVE_TIMER_NOTICEXY))
    LuaRegisterMsgHandler(msgType.MSG_SC_START_APP, handler(self, self.handle_MSG_SC_START_APP))
    LuaRegisterMsgHandler(msgType.MSG_SC_SERVER_GAME_ERROR, handler(self, self.handle_MSG_SC_SERVER_GAME_ERROR))
    LuaRegisterMsgHandler(msgType.MSG_SC_LIMIT_CHAT, handler(self, self.handle_MSG_SC_LIMIT_CHAT))
    LuaRegisterMsgHandler(msgType.MSG_SC_CUSTOM_EVENT_REPORT, handler(self, self.handle_MSG_SC_CUSTOM_EVENT_REPORT))
    LuaRegisterMsgHandler(msgType.MSG_SC_OPEN_URL, handler(self, self.handle_MSG_SC_OPEN_URL))
    LuaRegisterMsgHandler(msgType.MSG_SC_USE_CDK, handler(self, self.handle_MSG_SC_USE_CDK))
    LuaRegisterMsgHandler(msgType.MSG_SM_BINDHUMMSG, handler(self, self.handle_MSG_SM_BINDHUMMSG))--弹实名
    LuaRegisterMsgHandler(msgType.MSG_SC_FIRE_WORK_TX_REPONSE,  handler(self, self.handle_MSG_SC_FIRE_WORK_TX_REPONSE))
    LuaRegisterMsgHandler(msgType.MSG_SC_BUBBLE_TIPS_CUSTOM, handler(self, self.handle_MSG_SC_BUBBLE_TIPS_CUSTOM)) --气泡
end

return NoticeProxy
