local DebugProxy = requireProxy("DebugProxy")
local NativeBridgeProxy = class("NativeBridgeProxy", DebugProxy)
NativeBridgeProxy.NAME = global.ProxyTable.NativeBridgeProxy

local cjson = require("cjson")

function NativeBridgeProxy:ctor()
    NativeBridgeProxy.super.ctor(self)
    
    self:registerN2GMethods()

    self._996_kefu_un_read_ums = 0
end

-- 隐私撤销
function NativeBridgeProxy:GN_Private_BackOut( data )
    -- 是否撤回隐私协议
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = data and cjson.encode(data) or ""
        local methodName = "GN_Private_BackOut"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        release_print("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. jsonString)
    end
end

-- 语音
function NativeBridgeProxy:GN_Voice( data )
    -- 语音
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = data and cjson.encode(data) or ""
        local methodName = "GN_Voice"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. jsonString)
    end
end

--PC callof 直接打开 渠道的充值窗口  美杜莎360要用
function NativeBridgeProxy:GN_PC_CallOF( data )
    -- 充值
    if cc.PLATFORM_OS_WINDOWS == global.Platform then
        local jsonString = data and cjson.encode(data) or ""
        local methodName = "GN_onCallOF"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. jsonString)
    end
end

-- 任务
function NativeBridgeProxy:GN_Mission( data )
    -- 任务
    if global.L_GameEnvManager:GetEnvDataByKey("platform") == "mac" then
        local DataRePortProxy = global.Facade:retrieveProxy( global.ProxyTable.DataRePortProxy )
        DataRePortProxy:RoleTask(data)
    else
        if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
            local jsonString = data and cjson.encode(data) or ""
            local methodName = "GN_Mission"
            NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        elseif cc.PLATFORM_OS_WINDOWS == global.Platform then
            local DataRePortProxy = global.Facade:retrieveProxy( global.ProxyTable.DataRePortProxy )
            DataRePortProxy:RoleTask(data)
        end
    end
    
end

-- 移动端 游戏时长上报暂停/恢复
-- 掉线/小退通知暂停，  重连成功通知恢复
-- isGameDuration: false 暂停   true 恢复
function NativeBridgeProxy:GN_Game_Duration_State( data )
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = data and cjson.encode(data) or ""
        local methodName = "GN_Game_Duration_State"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. jsonString)
        return
    end

    local state = data and data.isGameDuration or false
    local DataRePortProxy = global.Facade:retrieveProxy( global.ProxyTable.DataRePortProxy )
    DataRePortProxy:SetGameDuration( state )
end

-- PC关闭按钮状态
--- param data table {state=1: 能关闭(默认)， 0: 不能关闭}
function NativeBridgeProxy:GN_IsCan_Windown_Close_State( data )
    if cc.PLATFORM_OS_WINDOWS == global.Platform then
        local jsonString = data and cjson.encode(data) or ""
        local methodName = "GN_IsCan_Windown_Close_State"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. jsonString)
    end
end
-----------------------------------------------------------------------
-- 三方交易行相关
--- param data table {event = "action",params = {}}
function NativeBridgeProxy:GN_TradingBank_Interface( data )
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local jsonString = data and cjson.encode(data) or ""
        local methodName = "GN_TradingBank_Interface"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. jsonString)
    end
end
-- 三方交易行相关
function NativeBridgeProxy:NG_TradingBank_Interface(sender,jsonStr)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        -- debug
        releasePrint("lua NG_TradingBank_Interface:" ..  (jsonStr and tostring(jsonStr) or ""))

        local paramJson = cjson.decode(jsonStr)
        if paramJson  then
            global.Facade:sendNotification( global.NoticeTable.Layer_TradingBank_Interface_other,paramJson)
        end
    end
end
-----------------------------------------------------------------------
---------------------------------c++ to lua  begin-------------------------------------------
-- PC关闭按钮通知
function NativeBridgeProxy:NG_windowClose()
    global.Facade:sendNotification( global.NoticeTable.Delay_Exit_Game_Window_Close_Notice )
end
---------------------------------c++ to lua    end-------------------------------------------

-- 自定义数据上报
-- and & ios
function NativeBridgeProxy:GN_ReportCustomEvent(data)
    if global.L_GameEnvManager:GetEnvDataByKey("platform") == "mac" then
        local DataRePortProxy = global.Facade:retrieveProxy( global.ProxyTable.DataRePortProxy )
        DataRePortProxy:ReportCustomEvent(cjson.decode(data))
        return
    end
    
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_ReportCustomEvent"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, data)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. data)
        return
    end

    -- pc 数据上报
    local DataRePortProxy = global.Facade:retrieveProxy( global.ProxyTable.DataRePortProxy )
    DataRePortProxy:ReportCustomEvent(cjson.decode(data))
end

-- 好评有礼
function NativeBridgeProxy:GN_ReviewGift(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_ReviewGift"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, data)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. (data or ""))
    end
end

-- 服务器踢人通知
-- and & ios
function NativeBridgeProxy:GN_DetachSucceedByServer(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_DetachSucceedByServer"
        local jsonString = data and cjson.encode(data) or ""
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. jsonString)
        return
    end
    dump(data,"GN_DetachSucceedByServer")
end

-- 盒子交易行  返回盒子 到 某商品
function NativeBridgeProxy:GN_GoToCommondity(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_GoToCommondity"
        local jsonString = data and cjson.encode(data) or ""
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. (jsonString or ""))
    end
end
-- 盒子交易行 返回盒子 到 求购商品
function NativeBridgeProxy:GN_GoToPurchaseCommondity(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_GoToPurchaseCommondity"
        local jsonString = data and cjson.encode(data) or ""
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. (jsonString or ""))
    end
end

-- 盒子交易行 手机盒子交易行跳转支付宝app支付
function NativeBridgeProxy:GN_TradingPayAppInfo(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_TradingPayAppInfo"
        local jsonString = data and cjson.encode(data) or ""
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. (jsonString or ""))
    end
end

-- 主界面按钮/图片点击事件上报
function NativeBridgeProxy:GN_MainUIClickEvent(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        return
    end
    local DataRePortProxy = global.Facade:retrieveProxy(global.ProxyTable.DataRePortProxy)
    DataRePortProxy:MainUIClickEvent(data)
end

------------------------------------------游戏内客服  begin----------------------------------------
-- 显示客服会话窗口
function NativeBridgeProxy:GN_ShowCustomerService(data)
    -- 移动端
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_ShowCustomerService"
        local jsonString = data and cjson.encode(data) or ""
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. (jsonString or ""))
        return
    end

    -- 直接跳转
    local url = data and data.url
    if url then
        cc.Application:getInstance():openURL(url)
    end

end

-- 隐藏客服会话窗口
function NativeBridgeProxy:GN_DismissCustomerService(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_DismissCustomerService"
        local jsonString = data and cjson.encode(data) or ""
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. (jsonString or ""))
    end
end

-- 显示消息列表
function NativeBridgeProxy:GN_ShowMsgListPop(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_ShowMsgListPop"
        local jsonString = data and cjson.encode(data) or ""
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. (jsonString or ""))
    end
end

-- 隐藏消息列表
function NativeBridgeProxy:GN_DismissMsgListPop(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_DismissMsgListPop"
        local jsonString = data and cjson.encode(data) or ""
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. (jsonString or ""))
    end
end

-- 结束当前会员
function NativeBridgeProxy:GN_StopCurrentSession(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_StopCurrentSession"
        local jsonString = data and cjson.encode(data) or ""
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. (jsonString or ""))
    end
end

-- 鸿蒙账号解绑
function NativeBridgeProxy:GN_unbindAccount()
    if global.isOHOS then
        local methodName = "GN_unbindAccount"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, "")
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName)
    end
end

-- 接收客服消息
function NativeBridgeProxy:NG_Receive_996KeFu_Message(sender,jsonString)
    local paramJson = cjson.decode(jsonString)
    if not paramJson then
        return
    end

    releasePrint("=====================NG_Receive_996KeFu_Message jsonString： ", jsonString)
    if paramJson.nType == 1 then --收到消息，内容字段msg  类型字符串
        SLBridge:onLUAEvent(LUA_EVENT_MANUAL_SERVICE_MESSAGE_NEW, {message = paramJson.msg})
    elseif paramJson.nType == 2 then -- 未读消息个数   字段num   类型 int
        self._996_kefu_un_read_ums  = paramJson.num or 0
        local ManualService996Proxy = global.Facade:retrieveProxy(global.ProxyTable.ManualService996Proxy)
        if ManualService996Proxy then
            ManualService996Proxy:SetUnReadNums(paramJson.num or 0)
            SLBridge:onLUAEvent(LUA_EVENT_MANUAL_SERVICE_MESSAGE_UN_READ, {unReadNums = paramJson.num})
        end
    elseif paramJson.nType == 3 then -- 关闭客服
        local ManualService996Proxy = global.Facade:retrieveProxy(global.ProxyTable.ManualService996Proxy)
        if ManualService996Proxy then
            ManualService996Proxy:SetShowMaulServiceState(false)
            ManualService996Proxy:SetUnReadNums(0)
            SLBridge:onLUAEvent(LUA_EVENT_MANUAL_SERVICE_MESSAGE_CLOSE)
        end
    end
end

-- sdk打开的ui
function NativeBridgeProxy:NG_Receive_996KeFu_SDKUI(sender,jsonString)
    releasePrint("=====================NG_Receive_996KeFu_SDKUI")
    local ManualService996Proxy = global.Facade:retrieveProxy(global.ProxyTable.ManualService996Proxy)
    if ManualService996Proxy then
        releasePrint("=====================NG_Receive_996KeFu_SDKUI111111")
        ManualService996Proxy:SetSDKUI(true)
    end
end
---------------------------------------游戏内客服   end----------------------------------------------
-- 调用sdk接口打开第三方应用   需sdk实现
function NativeBridgeProxy:GN_Third_APP( data )
    -- 移动端
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_Third_APP"
        local jsonString = data and cjson.encode(data) or ""
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. (jsonString or ""))
        return
    end
end

-- 获取系统剪贴板文本
function NativeBridgeProxy:GN_getClipboardText()
    -- 移动端
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_getClipboardText"
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, "")
        return
    end

    -- PC端
    if global.isWindows and Win32BridgeCtl then
        local text = Win32BridgeCtl:Inst():getTextFromClipboard()
        self:NG_recvClipboardText(nil, text, true)
    end
end

-- 接收系统剪贴板文本回调
function NativeBridgeProxy:NG_recvClipboardText(sender, jsonString, isWindows)

    local text = jsonString or ""
    if not isWindows then -- "{content: text}"
        if text ~= "" then
            local tab = SL:JsonDecode(text)
            text = tab and tab.content or ""
        end
    end
    
    releasePrint("NG_recvClipboardText: " .. tostring(jsonString))
    self._clipboardText = text or ""
    SLBridge:onLUAEvent(LUA_EVENT_CLIPBOARD_TEXT_CHANGE, self._clipboardText)
end

-- 获取剪贴板缓存
function NativeBridgeProxy:GetClipboardText()
    return self._clipboardText or ""
end

-- 传递的扩展参数数据
function NativeBridgeProxy:GN_SetExpandInfo(data)
    if cc.PLATFORM_OS_WINDOWS ~= global.Platform then
        local methodName = "GN_SetExpandInfo"
        local jsonString = data and cjson.encode(data) or ""
        NativeBridgeCtl:Inst():sendMessage2Native(methodName, jsonString)
        releasePrint("+++++++++++++++++++++++++++++++++++++ " .. methodName .. "  " .. (jsonString or ""))
        return
    end
end

function NativeBridgeProxy:registerN2GMethods()
    local nativeBridgeCtl = NativeBridgeCtl:Inst()
    -- remove last selector
    nativeBridgeCtl:removeSelectorsInGroup("windowMonitor")

    -- register windowMonitor callback
    nativeBridgeCtl:addNativeSelector("windowMonitor","NG_windowClose",handler(self, self.NG_windowClose), nil)

    --tradingBank_other
    nativeBridgeCtl:removeSelectorsInGroup("tradingBank_other")

    nativeBridgeCtl:addNativeSelector("tradingBank_other","NG_TradingBank_Interface",handler(self, self.NG_TradingBank_Interface), nil)

    -- clipboard callback
    nativeBridgeCtl:removeSelectorsInGroup("clipboard")
    nativeBridgeCtl:addNativeSelector("clipboard", "NG_recvClipboardText", handler(self, self.NG_recvClipboardText), nil)


    local function onNativeStatusChangedCB(sender, jsonString)
        -- debug
        releasePrint("NativeStatusChanged 22222222:" .. tostring(jsonString))

        local paramJson = cjson.decode(jsonString)

        local networkDesc = {[-1] = "unknown", [0] = "wifi", [1] = "2g", [2] = "3g", [3] = "4g"}
        releasePrint("NativeStatusChanged, network:" .. networkDesc[paramJson.network] .. ",battery:" .. paramJson.battery)

        local env = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
        env:SetNetType(paramJson.network)
        env:SetBatteryLevel(paramJson.battery)
    end

    -- register native status changing callback
    global.NativeBridgeCtl:removeSelectorsInGroup("NativeStatus")
    global.NativeBridgeCtl:addNativeSelector("NativeStatus", "NG_NativeStatusChanged", onNativeStatusChangedCB, nil)

    -- logout 
    local function onLogoutCB(sender, jsonString)
        -- debug
        releasePrint("LogoutCallback mod_fgcq :" .. tostring(jsonString))

        global.Facade:sendNotification(global.NoticeTable.RestartGame)
    end
    -- register logout status changing callback
    global.NativeBridgeCtl:removeSelectorsInGroup("AccountOperator")
    global.NativeBridgeCtl:addNativeSelector("AccountOperator", "NG_Logout", onLogoutCB, nil)


    --game_kefu
    nativeBridgeCtl:removeSelectorsInGroup("game_kefu")
    --receive
    nativeBridgeCtl:addNativeSelector("game_kefu","NG_Receive_996KeFu_Message",handler(self, self.NG_Receive_996KeFu_Message), nil)
    nativeBridgeCtl:addNativeSelector("game_kefu","NG_Receive_996KeFu_SDKUI", handler(self, self.NG_Receive_996KeFu_SDKUI), nil)
end

return NativeBridgeProxy