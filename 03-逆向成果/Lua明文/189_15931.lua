local GameWorldInfoInitCommand = class('GameWorldInfoInitCommand', framework.SimpleCommand)

function GameWorldInfoInitCommand:ctor()
end

function GameWorldInfoInitCommand:execute(note)
    print( "====================================" )
    print( "GameWorldInfoInit" )
    print( "====================================" )

    local data = note:getBody()
    local jsonData = data and data.jsonData 
    
    --是否试玩模式
    local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
    if  shiwan and tonumber(shiwan) == 1 or global.IsReceiveRole then 
        global.IsVisitor = true
        local TradingBankLookPlayerProxy = global.Facade:retrieveProxy(global.ProxyTable.TradingBankLookPlayerProxy)
        TradingBankLookPlayerProxy:RequestPlayerData(global.gamePlayerController:GetMainPlayerID())
        global.Facade:sendNotification(global.NoticeTable.ReconnectForbidden)
        global.Facade:sendNotification(global.NoticeTable.Layer_NPC_Talk_Close)
    end

    -- 重连
    local NetworkProxy = global.Facade:retrieveProxy( global.ProxyTable.NetworkProxy )
    if NetworkProxy:IsDisconnect() then
        global.Facade:sendNotification(global.NoticeTable.Reconnect)
    else
        self:handleGameInfo(jsonData)
    end
end

function GameWorldInfoInitCommand:handleGameInfo(jsonData)
    global.networkCtl:SetIgnoreDisconnect(false)
    -- data
    self:InitData(jsonData)

    -- config
    self:InitConfig()

    -- ui
    self:InitUI()

    -- 后台添加
    self:InitExAddUI(jsonData)
end

function GameWorldInfoInitCommand:InitData(jsonData)
    if not jsonData then
        return false
    end

    --kfday  开服天数
    --unixtime 当前时间戳
    --kfunixtime 开服时间戳
    local ServerTimeProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerTimeProxy)
    ServerTimeProxy:SaveTimeData(jsonData)

    -- save 云端存储
    local CloudStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.CloudStorageProxy)
    CloudStorageProxy:RespCloudStorage(jsonData.save)

    -- 拍卖行数据
    local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
    AuctionProxy:SetQualities(jsonData.auctionby or {})
    AuctionProxy:SetJobAble(jsonData.paimaijob or {})
    AuctionProxy:SetLimitShelf(jsonData.paimaicount or 0)

    AuctionProxy:SetLowBidPrice(jsonData.AuctionPrice)
    AuctionProxy:SetLowBuyPrice(jsonData.OneBitePrice)
    AuctionProxy:SetHighBidPrice(jsonData.MaxAuctionPrice)
    AuctionProxy:SetHighBuyPrice(jsonData.MaxOneBitePrice)

    -- 拍卖行物品列表请求最小间隔
    if jsonData.PaiMaiQueryTime then
        AuctionProxy:SetRequestMinTime(jsonData.PaiMaiQueryTime)
    end

    -- 服务器开关
    local ServerOptionsProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerOptionsProxy)
    ServerOptionsProxy:SetOptions(jsonData.gameoptions)
    --野蛮禁止移动状态释放
    ServerOptionsProxy:SetMoveActionForbidDash(jsonData.MooteboWithCD or 0)

    EquipData.SetBestRingsOpenState(jsonData.SndaItemBoxOpened)
    GUIFunction:SetCustomPlayerEquip(jsonData.gameoptions.CustUserItem)

    -- 多开数量
    if global.isWindows and jsonData.maxClientCount then
        local luaBridgeCtl  = LuaBridgeCtl:Inst()
        local maxCount      = jsonData.maxClientCount
        if luaBridgeCtl.CheckClientCount and false == luaBridgeCtl:CheckClientCount(maxCount) then
            local function callback(bType, custom)
                global.Director:endToLua()
            end
            local data = {}
            data.str = GET_STRING(1089)
            data.btnDesc = {GET_STRING(1001)}
            data.callback = callback
            UIOperator:OpenCommonTipsUI(data)

            --客户端上限不允许联网
            global.networkCtl:Disconnect()
            global.Facade:sendNotification( global.NoticeTable.ReconnectForbidden )
        end
    end

    -- 掉落光柱时间
    if jsonData.JPshuxingEquipEffect then
        SL:SetValue("GAME_DATA","JPshuxingEquipEffect",jsonData.JPshuxingEquipEffect)
    end

    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy) --本地储存devicecode
    LoginProxy:SaveDeviceCode(jsonData.devicecode)

    --是否是 新版交易行
    if jsonData.gameoptions.IsNewBoxSellVersion then
        global.IsNewBoxSellVersion = true
    end

    if global.IsVisitor then
        global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankReceiveLayer_Open)
    end

    -- 禁止聊天开关
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    LoginProxy:SetForbidChat(jsonData.LimitChat == 1)

    --英雄召唤cd时间
    if jsonData.recallherotime then
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        HeroPropertyProxy:setCD(jsonData.recallherotime)
    end

    local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    -- 连击格子加额外暴击几率
    for i = 1, 4 do
        if jsonData["BJCommonRate" .. i] then
            PlayerPropertyProxy:SetComboExtraBJRate(jsonData["BJCommonRate" .. i], i)
        end 
    end

    -- 是否启用新版属性加点
    local reinAttrProxy = global.Facade:retrieveProxy(global.ProxyTable.ReinAttrProxy)
    reinAttrProxy:SetIsNewBouns(jsonData.gameoptions.NewBonus)

    -- 人物最大等级 [暂供行会申请等级使用]
    if jsonData.gameoptions.MaxLevel then
        PlayerPropertyProxy:SetMaxLevel(jsonData.gameoptions.MaxLevel)
    end

    -- 求购货币默认
    if jsonData.gameoptions.sQiugouDefaultGoldType then
        local PurchaseProxy = global.Facade:retrieveProxy(global.ProxyTable.PurchaseProxy)
        PurchaseProxy:SetCurrencies(jsonData.gameoptions.sQiugouDefaultGoldType)
    end

    -- 交易所货币默认
    if jsonData.gameoptions.sJiaoYiSuoDefaultGoldType then
        ExchangeData.SetCurrencies(jsonData.gameoptions.sJiaoYiSuoDefaultGoldType)
    end
    ExchangeData.SetLimitShelf(jsonData.gameoptions.JiaoYiSuoCountLimit or 0)
    
    -- 掉落格式
    if jsonData.DropItemHint then
        local data = {
            Msg     = global.isWinPlayMode and jsonData.PCDropItemHint or jsonData.DropItemHint,
            BColor  = jsonData.DropItemBC,
            FColor  = jsonData.DropItemFC,
        }
        ChatData.SetFakeDropParam(data)
    end

    --进入游戏上报云手机信息
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:RequestIsCloudLogin() 
    
    -- 加载攻城区域
    local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    MapProxy:LoadShabakeZone() 

    -- 消息提示前缀是否显示
    PlayerPropertyProxy:SetPromptPrefixShow((jsonData.ShowPreFixMsg or 0) == 1)

    -- 技能 衔接连续
    local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    SkillProxy:SetContinueSkills(jsonData.CheckContinueSkills)
    SkillProxy:SetContinueInterval(jsonData.SkillContinueInterval)
end

function GameWorldInfoInitCommand:InitConfig()
    global.skillManager:LoadConfig()

    local SceneOptionsProxy = global.Facade:retrieveProxy(global.ProxyTable.SceneOptionsProxy)
    SceneOptionsProxy:LoadConfig()

    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    GameSettingProxy:LoadConfig()

    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    BuffProxy:LoadConfig()

    local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    SkillProxy:LoadConfig()

    local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
    HeroSkillProxy:LoadConfig()

    local AttrConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.AttrConfigProxy)
    AttrConfigProxy:LoadConfig()

    local NPCStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
    NPCStorageProxy:LoadConfig()

    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    ItemConfigProxy:LoadConfig()
    
    local DamageNumProxy = global.Facade:retrieveProxy(global.ProxyTable.DamageNumProxy)
    DamageNumProxy:LoadConfig()

    local ItemTipsProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemTipsProxy)
    ItemTipsProxy:LoadConfig()
    ItemTipsProxy:LoadCustAbilConfig()

    local SUIComponentProxy = global.Facade:retrieveProxy(global.ProxyTable.SUIComponentProxy)
    SUIComponentProxy:LoadConfig()

    local PageStoreProxy = global.Facade:retrieveProxy(global.ProxyTable.PageStoreProxy)
    PageStoreProxy:InitPageStoreData()

    local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    HeroPropertyProxy:initConfig()

    local ColorStyleProxy = global.Facade:retrieveProxy(global.ProxyTable.ColorStyleProxy)
    ColorStyleProxy:LoadConfig()

    local SummonsProxy = global.Facade:retrieveProxy(global.ProxyTable.SummonsProxy)
    SummonsProxy:LoadConfig()

    local ReinAttrProxy = global.Facade:retrieveProxy(global.ProxyTable.ReinAttrProxy)
    ReinAttrProxy:LoadConfig()

    local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    MapProxy:LoadConfig()

    local npcProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
    npcProxy:LoadConfig()

    -- debug/gm模式 部分表重加载
    if SL._DEBUG then
        if AuctionData and AuctionData.InitConfigType then
            AuctionData.InitConfigType()
        end

        local PurchaseProxy = global.Facade:retrieveProxy(global.ProxyTable.PurchaseProxy)
        PurchaseProxy:LoadConfig()

        if MiniMapData and MiniMapData.LoadConfig then
            MiniMapData.LoadConfig()
        end

        local BubbleProxy = global.Facade:retrieveProxy(global.ProxyTable.BubbleProxy)
        BubbleProxy:LoadConfig()

        local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
        ConditionProxy:ReloadConfig()

        local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
        RelationProxy:ReloadConfig()

        if global.monsterManager then
            global.monsterManager:ReloadConfig()
        end

        if CompoundItemData and CompoundItemData.ReloadConfig then
            CompoundItemData.ReloadConfig()
        end

        local configProxy = global.Facade:retrieveProxy(global.ProxyTable.ModelConfigProxy)
        configProxy:Reload()

        self:ReloadGameDataConfig()

        local AudioProxy = global.Facade:retrieveProxy(global.ProxyTable.AudioProxy)
        AudioProxy:LoadConfig()
    end

end

function GameWorldInfoInitCommand:ReloadGameDataConfig()
    -- 加载game_data配置
    local dconfig = SL:RequireFile("game_config/cfg_game_data")
    for k, v in pairs(dconfig) do
        global.ConstantConfig[v.k] = v.value
    end

    -- 多职业配置
    local list = {}
    for i = 5, 15 do 
        if global.ConstantConfig["MultipleJobSet" .. i] then
            local param = G_GetSplitArray(global.ConstantConfig["MultipleJobSet" .. i], "|")
            local function checkValue(str)
                if string.len(str or "") > 0 then
                    return str
                end
                return nil
            end
            list[i] = {
                isOpen  = tonumber(param[1]) == 1,                                  -- 开关
                name    = checkValue(param[2]) or string.format("未命名%s", i),     -- 职业名称
                hudStr  = checkValue(param[3]) or "X",                              -- HUD
                createLightMaleID   = tonumber(param[4]),                           -- 创建常亮动画- 男
                createLightFemaleID = tonumber(param[5]),                           -- 创建常亮动画- 女
                animGToLMaleID      = tonumber(param[6]),                           -- 灰到亮动画 - 男
                animGToLFemaleID    = tonumber(param[7]),                           -- 灰到亮动画 - 女
                clothFeatureShowID  = tonumber(param[8]),                           -- 裸模外观ID
                UIModelPicMaleID    = checkValue(param[9]),                         -- 裸模内观图片ID - 男
                UIModelPicFeMaleID  = checkValue(param[10]),                        -- 裸模内观图片ID - 女
            }
        end
    end
    global.ConstantConfig.MultipleJobSetMap = list

    -- 武器外观层级配置
    if global.ConstantConfig.WeaponLooksOrderUp and type(global.ConstantConfig.WeaponLooksOrderUp) == "string" and string.len(global.ConstantConfig.WeaponLooksOrderUp) > 0 then
        local data = G_GetSplitArray(global.ConstantConfig.WeaponLooksOrderUp, "|")
        local list = {}
        for _, v in ipairs(data) do
            if string.len(v) > 0 then
                local param = G_GetSplitArray(v, "#")
                if tonumber(param[1]) and tonumber(param[2]) then
                    table.insert(list, {dir = tonumber(param[1]), act = tonumber(param[2])})
                end
            end
        end
        global.ConstantConfig.WeaponLooksOrderUp = list
    else
        global.ConstantConfig.WeaponLooksOrderUp = {}
    end

    -- player render config
    G_ActorUtils.ResetPlayerRenderOrderByGameData()

    -----------------------------------------
    if global.ConstantConfig.DEFAULT_FONT_SIZE == 0 then
        global.ConstantConfig.DEFAULT_FONT_SIZE = global.isWinPlayMode and 12 or 16
    end

    SL:RequireFile("GUILayout/GUIDefineEx")
    -- pc 字体设置    
    if GUIDefineEx.PCFontSize then
        global.ConstantConfig.DEFAULT_FONT_SIZE = GUIDefineEx.PCFontSize
        global.ConstantConfig.sceneFontSize_pc = GUIDefineEx.PCFontSize
    end

    if global.isWinPlayMode and SL:GetValue("GAME_DATA", "HudNotUseBmpFont") ~= 1 then
        -- bmp场景字固定12
        global.ConstantConfig.sceneFontSize_pc = 12
    end
end

function GameWorldInfoInitCommand:InitUI()
    -- 
    SLBridge:onEnterWorld()

    UIOperator:OpenRtouchEventUI()
    UIOperator:OpenMoveEventUI()
    UIOperator:OpenSightBeadUI()

    global.Facade:sendNotification( global.NoticeTable.Layer_Notice_Open)

    -- init main nodes
    global.Facade:sendNotification( global.NoticeTable.Layer_Main_Open )
    
    -- init main ui
    global.Facade:sendNotification(global.NoticeTable.Layer_Main_Init)
    SLBridge:onLUAEvent(LUA_EVENT_MAIN_INIT)
    -- 
    global.Facade:sendNotification(global.NoticeTable.GameWorldInitComplete)

    -- SL
    SLBridge:onLUAEvent(LUA_EVENT_ENTER_WORLD)

    -- debug 键盘事件
    global.userInputController:InitKeyCodeDebug()
end

function GameWorldInfoInitCommand:InitExAddUI(jsonData)
    if not jsonData then
        return false
    end
    
    if jsonData.box_state and jsonData.box_state == 1 then
        global.Facade:sendNotification(global.NoticeTable.AddBoxDayBtnToScreen, {
            x = jsonData.box_x,
            y = jsonData.box_y,
            subid = jsonData.box_subid,
            scale = jsonData.box_scale
        })
    end

    if jsonData.jyh_state and jsonData.jyh_state == 1  then
        global.Facade:sendNotification(global.NoticeTable.AddTradingBankBtnToScreen, {
            x = jsonData.jyh_x,
            y = jsonData.jyh_y,
            subid = jsonData.jyh_subid,
            width = jsonData.jyh_width,
            height= jsonData.jyh_height
        })
    end
end

return GameWorldInfoInitCommand
