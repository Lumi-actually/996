local RemoteProxy = requireProxy("RemoteProxy")
local NPCProxy = class("NPCProxy", RemoteProxy)
NPCProxy.NAME = global.ProxyTable.NPCProxy

function NPCProxy:ctor()
    NPCProxy.super.ctor(self)

    self._currClickNPCID        = nil  --当前点击的npc id,  跨服之后服务端发送的Useid是本地的, 导致找不到npc, 只好本地记录一下
    self._currentBackground     = nil
    self._currentNPCTalkData    = nil
    self._isClickCD             = false
    self._forbidOpenBagEquip    = false
    self._config                = {}
end

local shareData = {}
function NPCProxy:LoadConfig()
    local config = {}
    local filePath = "scripts/game_config/cfg_npclist.lua"
    if SL:IsFileExist(filePath) then
        SL:Print("[Require game_config] ", "cfg_npclist")
        config = SL:Require(filePath)
    end
    if config and next(config) then
        for i, data in pairs(config) do
            if data.effectid and string.len(data.effectid) > 0 then
                local icons = {}
                local paramList = G_GetSplitArray(data.effectid, "&")
                for i, params in ipairs(paramList) do
                    if string.len(params) > 0 then
                        local data = G_GetSplitArray(params, "#")
                        if tonumber(data[1]) then
                            local isEffect = (tonumber(data[6]) or 0) == 0
                            local pos = i - 1
                            icons[pos] = {}
                            icons[pos].Id = pos
                            icons[pos].effType = isEffect and 1 or 0                                -- 0：图片; 1：特效
                            icons[pos].effSrc = isEffect and (tonumber(data[1]) or 0) or data[1]    -- 图片名字或者特效ID
                            icons[pos].X = tonumber(data[2]) or 0
                            icons[pos].iY = tonumber(data[3]) or 0
                            icons[pos].height = tonumber(data[4]) or 0 -- 自动补全空白位置0,1(0=掉 1=不掉) 无效  大于1 当长度 自动排序忽视Y
                            icons[pos].after = tonumber(data[5]) or 0 -- 增加播放在npc前面和后面参数 2: npc前场景字后
                        end
                    end
                end
                if next(icons) then
                    data.effectList = icons
                end
            end

            if type(data.sChgColor) == "string" then
                local colorList = G_GetSplitArray(data.sChgColor, "#")
                if colorList[2] and tonumber(colorList[2]) then
                    local autoColor = {}
                    for _, value in ipairs(colorList) do
                        table.insert(autoColor, tonumber(value))
                    end
                    data.sChgColor = nil
                    data.sChgColorList = next(autoColor) and autoColor
                else
                    data.sChgColor = tonumber(colorList[1])
                end
            end

            if not data.sChgColor and not data.sChgColorList then
                data.sChgColor = 250
            end
        end
        self._config = config
    end
end

function NPCProxy:GetConfigById(npcID)
    if not next(self._config) or not npcID then
        return nil
    end
    return self._config[npcID]
end

function NPCProxy:GetHudIconsByNPCID(npcID)
    local data = self:GetConfigById(npcID)
    if not data then
        return nil
    end
    return data.effectList
end

function NPCProxy:GetNameColorByNPCID(npcID)
    local data = self:GetConfigById(npcID)
    if not data then
        return nil
    end
    if data.sChgColor then
        return data.sChgColor
    elseif data.sChgColorList then
        return data.sChgColorList, true
    end

    return nil
end

function NPCProxy:CheckNpcTalkLayerClose(npcTypeIndex)
    if self:GetCurrentNPCIndex() == npcTypeIndex then
        self:Cleanup()
    end
end

function NPCProxy:IsForbidOpenBagEquip()
    return self._forbidOpenBagEquip
end

function NPCProxy:SetForbidOpenBagEquip(bool)
    self._forbidOpenBagEquip = bool
end

function NPCProxy:GetCurrentNPCTalkData()
    return self._currentNPCTalkData
end

function NPCProxy:GetCurrentNPCID()
    if not self._currentNPCTalkData then
        return nil
    end
    return self._currentNPCTalkData.npcID
end

function NPCProxy:GetCurrentNPCIndex()
    if not self._currentNPCTalkData then
        return nil
    end
    return self._currentNPCTalkData.index
end

function NPCProxy:GetCurrentClickNPCID()
    return self._currClickNPCID
end

function NPCProxy:SetCurrentNPCTalkData(data)
    self._currentNPCTalkData = data
end

function NPCProxy:GetCurrentBackground()
    return self._currentBackground
end

function NPCProxy:SetCurrentBackground(data)
    self._currentBackground = data
end

function NPCProxy:ResetCurrentBackground()
    self._currentBackground = nil
end

function NPCProxy:Cleanup()
    self._forbidOpenBagEquip = false
    self._currClickNPCID = nil
    self:ResetCurrentBackground()
    global.Facade:sendNotification(global.NoticeTable.SUIITEMBOXPutoutAll)
    global.Facade:sendNotification(global.NoticeTable.Layer_NPC_Talk_Close)
    SL:onLUAEvent(LUA_EVENT_NPC_TALK_CLOSE)
end

function NPCProxy:ExecuteWithCommonInput(jsonData)
    local sendData = {
        UserID      = jsonData.UserID,
        Act         = jsonData.Act,
        commonInput = jsonData.commonInput,
        inputID     = jsonData.inputID,
    }
    self:ExecuteWithJsonData(sendData)
end

function NPCProxy:ExecuteWithJsonData(jsonData)
    local currNpcData = self:GetCurrentNPCTalkData()
    if currNpcData and currNpcData.index then
        jsonData.index = currNpcData.index
    end

    if jsonData.newIndex then
        jsonData.index = jsonData.newIndex
    end

    dump(jsonData)
    NPCEXECUTE_CLOCK = os.clock()
    SendTableToServer(global.MsgType.MSG_CS_NPC_TASK_CLICK, jsonData)
end

function NPCProxy:RequestNpcStoreItemList(data)
    local sendData = {
        UserID = self._currentNPCTalkData.npcID,
        Name = data.Name,
    }
    SendTableToServer(global.MsgType.MSG_CS_NPC_STORE_ITEM_LIST, sendData)
end

function NPCProxy:RequestNpcStoreBuy(data)
    local sendData = {
        UserID = self._currentNPCTalkData.npcID,
        Name = data.Name,
        MakeIndex = data.MakeIndex or 0
    }
    SendTableToServer(global.MsgType.MSG_CS_NPC_STORE_BUY, sendData)
end

function NPCProxy:RequestNpcMakeDrug(data)
    local sendData = {
        userid = self._currentNPCTalkData.npcID,
        name = data.name,
    }
    SendTableToServer(global.MsgType.MSG_CS_NPC_MAKE_DRUG, sendData)
end

local function handle_MSG_SC_NPC_TALK(msg)
    if NPCEXECUTE_CLOCK then
        print("NPC TALK RESP cost", os.clock() - NPCEXECUTE_CLOCK)
    end

    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return -1
    end

    if not jsonData or not jsonData.sMsg then
        return
    end

    -- dump(jsonData)

    local nData    = {}
    nData.content = jsonData.sMsg
    nData.npcName = jsonData.Name
    nData.npcID    = jsonData.UserID
    nData.index    = jsonData.index

    -- Timer:id:remaining:content:x:y:anchor:colorID
    -- Timer:1:7200:秘境倒计时：%s:10:10:0:255
    -- Timer:1:0:秘境倒计时:%s
    if nData.content == "CloseNpcLayer" then
        global.Facade:sendNotification(global.NoticeTable.Layer_NPC_Talk_Close)
        SL:onLUAEvent(LUA_EVENT_NPC_TALK_CLOSE)
        return
    end

    if string.find(nData.content, "<JumpTo:.->") then
        local find_info = { string.find(nData.content, "<JumpTo:(.-)>") }
        if find_info[1] and find_info[2] then
            local slices = G_GetSplitArray(find_info[3], ":")
            local jumpID = tonumber(slices[1])
            local close = (tonumber(slices[2]) == nil or tonumber(slices[2]) == 0)

            -- close npc talk
            if close then
                global.Facade:sendNotification(global.NoticeTable.Layer_NPC_Talk_Close)
                SL:onLUAEvent(LUA_EVENT_NPC_TALK_CLOSE)
            end

            JUMPTO(jumpID)
        end

    else
        SL:SetValue("NPC_TALK_DATA", nData)
        global.Facade:sendNotification(global.NoticeTable.Layer_NPC_Talk_Open)

        -- 同步至 SL框架
        SLBridge:onLUAEvent(LUA_EVENT_NPC_TALK, {id = jsonData.UserID, index = jsonData.index, name = jsonData.Name})
    end
end

local function handle_MSG_SC_NPC_TALK_BACKGROUND(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return -1
    end

    SL:SetValue("CURRENT_BACKGROUND", jsonData)
end

function NPCProxy:handle_MSG_SC_NPC_TALK_CLOSE(msg)
    releasePrint("local function handle_MSG_SC_NPC_TALK_CLOSE(msg) 644")
    self:Cleanup()
end

local function handle_MSG_SC_NPC_STORE_OPEN(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return -1
    end

    SL:onLUAEvent(LUA_EVENT_NPC_STORE_OPEN, jsonData)
end

local function handle_MSG_SC_NPC_STORE_ITEM_LIST(msg)
    local header = msg:GetHeader()
    local len    = msg:GetDataLength()
    if len <= 0 then
        return false
    end
    local pageCount = header.recog

    local data = msg:GetJsonData()
    local itemList = {}
    if data.ItemList and next(data.ItemList) then
        for i, v in ipairs(data.ItemList) do
            local item = clone(ChangeItemServersSendDatas(v.Item))
            item.Price = v.Price
            table.insert(itemList, item)
        end
    end
    SL:onLUAEvent(LUA_EVENT_NPC_STORE_OPEN, {Items = itemList})
end

local function handle_MSG_SC_NPC_STORE_BUY_RESULT_FAIL(msg)
    local head = msg:GetHeader()
    if not head then
        return
    end

    SL:onLUAEvent(LUA_EVENT_NPC_STORE_BUY_RESULT_FAIL, head.recog)
end

local function handle_MSG_SC_NPC_STORE_BUY_RESULT_SUCCESS(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return -1
    end

    -- 剩余商品数量
    local remainNum = msg:GetP0()
    local MakeIndex = jsonData.MakeIndex
    if MakeIndex and MakeIndex ~= 0 and remainNum == 0 then
        SL:onLUAEvent(LUA_EVENT_NPC_STORE_ITEM_REMOVE, MakeIndex)
    end
end

local function handle_MSG_SC_NPC_MAKE_DRUG_LIST(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return -1
    end

    SL:onLUAEvent(LUA_EVENT_NPC_MAKE_DRUG_OPEN, jsonData)
end

local function handle_MSG_SC_NPC_MAKE_DRUG_SUCCESS(msg)
    local head = msg:GetHeader()
    if not head then
        return
    end

    SL:onLUAEvent(LUA_EVENT_NPC_MAKE_DRUG_SUCCESS)
end

local function handle_MSG_SC_NPC_MAKE_DRUG_FAILED(msg)
    local head = msg:GetHeader()
    if not head then
        return
    end

    SL:onLUAEvent(LUA_EVENT_NPC_MAKE_DRUG_FAILED, head.recog)
end

function NPCProxy:handle_MSG_SC_PROGRESS_BAR(msg)
    local jsonData = ParseRawMsgToJson(msg)
    SL:onLUAEvent(LUA_EVENT_OPEN_PROGRESSBAR, jsonData)
end

function NPCProxy:RequestTalk(npcID)
    print("talk to NPC", npcID)
    NPCEXECUTE_CLOCK = os.clock()

    self:ResetCurrentBackground()

    local npc = global.npcManager:FindOneNpcInCurrViewFieldById(npcID)
    if npc then
        self._currClickNPCID = npcID

        local typeIndex = npc:GetTypeIndex()

        local sendData = {
            UserID = npcID,
            index = typeIndex,
        }
        SendTableToServer(global.MsgType.MSG_CS_NPC_CLICK, sendData)

        dump(sendData)

        SL:PlayNpcTalkAudio(typeIndex)

        -- SL
        local talkData = 
        {
            UserID = npcID,
            index = typeIndex,
            name = npc:GetName()
        }
        SLBridge:onLUAEvent(LUA_EVENT_TALKTONPC, talkData)
    end
end

function NPCProxy:CheckTalk(npcID, isAuto)
    -- 摆摊
    if SL:GetValue("STALL_MY_TRADING_STATUS") then
        SL:onLUAEvent(LUA_EVENT_TRADE_STALL_FORBID)
        return nil
    end

    -- NPC点击间隔，只有手动生效
    if not isAuto then
        if self._isClickCD then
            return nil
        end

        local clickInterval = SL:GetValue("NPC_CLICK_SPEED") * 0.001
        if clickInterval and clickInterval > 0 then
            self._isClickCD = true
            SL:ScheduleOnce(function()
                self._isClickCD = false
            end, clickInterval)
        end
    end

    -- 现在点击即可打开NPC
    local npc = global.npcManager:FindOneNpcInCurrViewFieldById(npcID)
    if npc then
        self:RequestTalk(npcID)
    end
end

function NPCProxy:RequestNotifyTalkOpen(talkLayerID)
    if not talkLayerID or "" == talkLayerID then
        return nil
    end

    releasePrint("---------------RequestNotifyTalkOpen", talkLayerID)

    SendTableToServer(global.MsgType.MSG_CS_NPC_TALK_OPEN_NOTIFY, {layerid = talkLayerID})
end

function NPCProxy:RequestNotifyTalkClose(talkLayerID)
    if not talkLayerID or "" == talkLayerID then
        return nil
    end

    releasePrint("---------------RequestNotifyTalkClose", talkLayerID)

    SendTableToServer(global.MsgType.MSG_CS_NPC_TALK_CLOSE_NOTIFY, {layerid = talkLayerID})
end

function NPCProxy:RegisterMsgHandler()
    NPCProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    -- NPC 对话数据(以及任务)
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_TALK, handle_MSG_SC_NPC_TALK)
    -- NPC 对话框背景数据
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_TALK_BACKGROUND, handle_MSG_SC_NPC_TALK_BACKGROUND)
    -- NPC 关闭NPC面板
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_TALK_CLOSE, handler(self, self.handle_MSG_SC_NPC_TALK_CLOSE))
    -- 打开NPC商店
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_STORE_OPEN, handle_MSG_SC_NPC_STORE_OPEN)
    -- NPC商店道具列表返回
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_STORE_ITEM_LIST, handle_MSG_SC_NPC_STORE_ITEM_LIST)
    -- NPC商店购买失败返回
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_STORE_BUY_RESULT_FAIL, handle_MSG_SC_NPC_STORE_BUY_RESULT_FAIL)
    -- NPC商店购买成功返回
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_STORE_BUY_RESULT_SUCCESS, handle_MSG_SC_NPC_STORE_BUY_RESULT_SUCCESS)
    -- 打开NPC 炼药
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_MAKE_DRUG_LIST, handle_MSG_SC_NPC_MAKE_DRUG_LIST)
    -- NPC 炼药成功
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_MAKE_DRUG_SUCCESS, handle_MSG_SC_NPC_MAKE_DRUG_SUCCESS)
    -- NPC 炼药失败
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_MAKE_DRUG_FAILED, handle_MSG_SC_NPC_MAKE_DRUG_FAILED)
    -- NPC 进度条
    LuaRegisterMsgHandler(msgType.MSG_SC_PROGRESS_BAR, handler(self, self.handle_MSG_SC_PROGRESS_BAR))
end

return NPCProxy