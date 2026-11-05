local registerTable =
{
    "network/NetworkMediator" ,                         -- network
    "gameworld/GameWorldConnectMediator",               -- 游戏世界连接

    -- 缓存
    "couping/FrameRateMediator" ,                       -- 帧率检测
    "couping/CalcSkillCDMediator" ,                     -- 技能CD计算
    "couping/CalcComboSkillCDMediator",                 -- 连击技能CD计算

    "scene/SceneOptionsMediator" ,                      -- 场景元素设置
    "scene/SceneParticleMediator",                      -- 场景粒子
    "scene/SceneEffectMediator",                        -- 场景特效
    
    "role/KeepMovingController",                        -- 持续移动
    "role/RoleEffectMediator",                          -- 角色特效
    "role/PlayerInputController" ,                      -- 玩家输入逻辑
    "role/AutoController" ,                             -- 自动策略路基
    "role/AssistMediator" ,                             -- 内挂辅助

    "damage_number/DamageNumMediator" ,                 -- 伤害飘字

    "suicomponent/SUIComponentMediator",                -- 自定义组件
    "suicomponent/MetaValueMediator",                   -- 自定义组件
    "suicomponent/ConditionMediator",                   -- 条件系统
    "suicomponent/CostItemCellMediator",                -- 通用消耗组件管理

    "top_touch_layer/TopTouchMediator",                 -- 最上层点击
    
    "npc_layer/NPCLayerMediator",                       -- NPC

    "trading_bank_layer/TradingBankFrameMediator", --交易行外框
    "trading_bank_layer/TradingBankBuyLayerMediator", --交易行购买
    "trading_bank_layer/TradingBankBuyAllLayerMediator",--全部
    "trading_bank_layer/TradingBankBuyRoleLayerMediator",--角色 
    "trading_bank_layer/TradingBankBuyEquipLayerMediator",--装备 
    "trading_bank_layer/TradingBankBuyMoneyLayerMediator", --货币
    "trading_bank_layer/TradingBankBuySeekBuyLayerMediator", --求购
    "trading_bank_layer/TradingBankBuyMeLayerMediator", --指定我
    "trading_bank_layer/TradingBankBuyTipsLayerMediator",--筛选
    "trading_bank_layer/TradingBankSellLayerMediator", --交易行寄售
    "trading_bank_layer/TradingBankSupplyEquipLayerMediator", --交易行供应装备
    "trading_bank_layer/TradingBankGoodsLayerMediator", --交易行货架
    "trading_bank_layer/TradingBankCaptureLayerMediator", -- 交易行截图界面
    "trading_bank_layer/TradingBankCaptureMaskLayerMediator",--截图遮罩
    "trading_bank_layer/TradingBankZFPanelMediator", -- 支付面版
    "trading_bank_layer/TradingBankCostZFPanelMediator", -- 支付面版
    "trading_bank_layer/TradingBankPlayerInfoMediator",--用户信息
    "trading_bank_layer/TradingBankZFLayerMediator", -- 支付面版
    "trading_bank_layer/TradingBankCostZFLayerMediator", -- 支付面版
    "trading_bank_layer/TradingBankZFPlayerLayerMediator", -- 支付面版
    "trading_bank_layer/TradingBankLookTextureMediator", -- 支付面版
    "trading_bank_layer/TradingBankMeLayerMediator", -- 我的
    "trading_bank_layer/TradingBankPowerfulLayerMediator",
    "trading_bank_layer/TradingBankReceiveLayerMediator",--收货
    "trading_bank_layer/TradingBankRefuseLayerMediator",--拒绝收货
    "trading_bank_layer/TradingBankUpModifyEquipPanelMediator", --上架 修改价格 装备
    "trading_bank_layer/TradingBankDownGetEquipPanelMediator", --下架 取回

    "trading_bank_layer/TradingBankSupplyMoneyPanelMediator", -- 供应货币
    "trading_bank_layer/TradingBankBuyPurchaseEquipLayerMediator", -- 求购装备
    "trading_bank_layer/TradingBankBuyPurchasePayLayerMediator",   --求购支付页面
    "trading_bank_layer/TradingBankRequestQgOrderLayerMediator",   --求购货币装备页面
    "trading_bank_layer/TradingBankPurchasePowerfulLayerMediator",   --求购支付页面
    

    
    "trading_bank_layer_other/TradingBankFrameMediator_other", --交易行外框
    "trading_bank_layer_other/TradingBankBuyLayerMediator_other", --交易行购买
    "trading_bank_layer_other/TradingBankBuyRoleLayerMediator_other",--角色 
    "trading_bank_layer_other/TradingBankBuyMoneyLayerMediator_other", --货币
    "trading_bank_layer_other/TradingBankBuyRequestLayerMediator_other",--求购
    "trading_bank_layer_other/TradingBankBuyMeLayerMediator_other", --指定我
    "trading_bank_layer_other/TradingBankBuyTipsLayerMediator_other",--筛选
    "trading_bank_layer_other/TradingBankBuyServerNameTipsLayerMediator_other", -- 服务器名字筛选
    "trading_bank_layer_other/TradingBankSellLayerMediator_other", --交易行寄售
    "trading_bank_layer_other/TradingBankGoodsLayerMediator_other", --交易行货架
    "trading_bank_layer_other/TradingBankCaptureLayerMediator_other", -- 交易行截图界面
    "trading_bank_layer_other/TradingBankCaptureMaskLayerMediator_other",--截图遮罩
    "trading_bank_layer_other/TradingBankZFPanelMediator_other", -- 支付面版
    "trading_bank_layer_other/TradingBankCostZFPanelMediator_other", -- 支付面版
    "trading_bank_layer_other/TradingBankPlayerInfoMediator_other",--用户信息
    "trading_bank_layer_other/TradingBankCostZFLayerMediator_other", -- 支付面版
    "trading_bank_layer_other/TradingBankZFPlayerLayerMediator_other", -- 支付面版
    "trading_bank_layer_other/TradingBankLookTextureMediator_other", -- 支付面版
    "trading_bank_layer_other/TradingBankMeLayerMediator_other", -- 我的
    "trading_bank_layer_other/TradingBankMeGetMoneyPanelLayerMediator_other", -- 我的-提现弹窗
    "trading_bank_layer_other/TradingBankMeRecodPanelLayerMediator_other", -- 我的-购买记录弹窗
    "trading_bank_layer_other/TradingBankPowerfulLayerMediator_other",
    "trading_bank_layer_other/TradingBankReceiveLayerMediator_other",--收货
    "trading_bank_layer_other/TradingBankRefuseLayerMediator_other",--拒绝收货
    "trading_bank_layer_other/TradingBankWaitPayPanelLayerMediator_other",--待支付
    "trading_bank_layer_other/TradingBankSuggestPanelLayerMediator_other",--意见反馈
    "trading_bank_layer_other/TradingBankIdentityLayerMediator_other",--实名
    "trading_bank_layer_other/TradingBankLookOtherServerPlayerLayerMediator_other",--查看其他服的角色信息

    "dark_layer/DarkMediator",                          --夜晚模式

        --新版设置
    "setting_layer/SettingInformationCollectMediator",  -- 设置-个人信息收集清单
    "setting_layer/SettingFrameMediator",
    "setting_layer/SettingBasicMediator",                --基础设置
    "setting_layer/SettingWindowRangeMediator",          --视距
    "setting_layer/SettingLaunchMediator",               --战斗
    "setting_layer/SettingProtectMediator",              --保护
    "setting_layer/SettingAutoMediator",                 --挂机
    "setting_layer/SettingHelpMediator",                 --帮助
    "community_layer/CommunityLayerMediator",       
    --zfs end-----

    "box996_layer/Box996MainLayerMediator",             -- 996盒子
    "box996_layer/Box996TitleLayerMediator",            -- 996盒子  称号
    "box996_layer/Box996EveryDayLayerMediator",         -- 996盒子  每日礼包
    "box996_layer/Box996SuperLayerMediator",            -- 996盒子  超级礼包
    "box996_layer/Box996VIPLayerMediator",              -- 996盒子  盒子会员VIP
    "box996_layer/Box996GuideLayerMediator",            -- 996盒子  引导界面
    "box996_layer/Box996SVIPLayerMediator",             -- 996盒子  SVIP
    "box996_layer/Box996CloudPhoneLayerMediator",       -- 996盒子  云手机

    "mainui/MainRootMediator" ,                         -- 主界面
    "mainui/MainExtraMediator",

    "manual_service_996_layer/ManualService996Mediator",    -- 客服  996客服 WebView
}

-- debug
if global.isDebugMode or global.isGMMode then
    local t = 
    {
        "test_layer/CacheTestMediator",                     -- 内存展示面板
    }
    for _, v in ipairs(t) do
        table.insert(registerTable, v)
    end
end

return registerTable