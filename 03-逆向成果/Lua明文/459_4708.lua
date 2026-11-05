local registerTable =
{
    "JumpProxy",                          -- 超链跳转
    "CodeDOMUIProxy",                     -- GUI界面管理
    "AttrConfigProxy",                    -- 一些前端基础设定数据
    "SceneOptionsProxy",                  -- scene options
    "DamageNumProxy",                     -- 伤害飘字
    "VoiceManagerProxy",                  -- 语音
    "PlayerInputProxy" ,                  -- player input

    "PlayerPropertyProxy",               -- 角色属性数据 proxy
    "MoneyProxy",                        -- 货币
    "ItemConfigProxy",                    -- 道具相关
    "BagProxy" ,                         -- 背包数据 Proxy
    -- "EquipProxy" ,                       -- 装备数据 Proxy
    "SkillProxy" ,                       -- 技能(服务器下发, Proxy
    "DarkLayerProxy",                    -- 黑夜模式 --要在map前面
    "MapProxy" ,                         -- 地图相关
    "AutoProxy" ,                        -- 角色 一些状态数据
    "PayProxy" ,                         -- 付费 proxy
    "NPCProxy",                          -- npc 相关
    "NPCRepaireProxy",                   -- npc 修理
    "NPCSellProxy",                      -- npc 出售
    "NPCStorageProxy",                   -- npc 仓库
    "QuickUseProxy",                     -- 快捷栏
    "BuffProxy",                         -- buff proxy
    "AssistProxy",                       -- 内挂
    "NPCDoSomethingProxy",               -- 自定义放入框  类似于NPC修理/出售

    ---------------------

    -- 
    "ChatProxy",                         -- 聊天
    "TradeProxy",                        -- 交易
    "StallProxy",                        -- 摆摊
    "GameSettingProxy",                  -- 游戏设置
    "GameConfigMgrProxy",                -- 游戏配置
    "RechargeProxy",                     -- 充值
    "SummonsProxy",                      -- 召唤物
    "CloudStorageProxy",                 -- 云端存储
    "MissionProxy",                      -- 任务系统
    "AuctionProxy",                      -- 拍卖行
    "ServerOptionsProxy",                -- 游戏内开关
    "GuideProxy",                        -- 新手指引
    "MiniMapProxy",                      -- 小地图


    "ItemTipsProxy",                     -- ItemTipsProxy
    "FriendProxy",                       -- 好友
    "GuildProxy",                        -- 行会相关
    "MailProxy",
    "FuncDockProxy",                     -- 功能按钮
    "TeamProxy",                         -- 组队
    "TitleProxy",                  -- 称号

    "ItemUseProxy",                       -- 道具使用
    "ItemMoveProxy",                      -- 道具丢弃
    "AutoUseItemProxy",                  -- 自动使用
    "PageStoreProxy",                    -- 商城
    "RankProxy",                         -- 排行榜

    "LookPlayerProxy",                   -- 查看玩家

    "NetworkProxy",                   -- disconnect

    "ServerTimeProxy",                   -- 获取服务器时间

    "ItemManagerProxy",                   -- 道具一些管理
    "SceneEffectProxy",                  -- 场景特效

    "GoldBoxProxy",                      -- 宝箱抽奖
    "EquipRetrieveProxy",                -- 装备回收

    -- zfs begin --- 
    "TradingBankLookPlayerProxy",        -- 交易行查看玩家
    "RemindUpgradeProxy",                -- 提升提示
    "RedDotProxy",                       -- 红点提示
    "BubbleProxy",                       -- 前端条件 气泡

    "HeroEquipProxy",                    -- 英雄装备信息
    "HeroPropertyProxy",                 -- 英雄属性    
    "HeroSkillProxy",                    -- 英雄技能   
    "HeroBagProxy",                      -- 英雄背包
    "PickupSpriteProxy",

    "DarkLayerProxy",                    -- 黑夜模式
    
    -- zfs end ---

    "ReinAttrProxy",                     -- 转生属性点
    "NPCNewTypeOkProxy",                 -- OK框新类型

    "ItemCompoundProxy",                 -- 合成
    "Box996Proxy",                       -- 996传奇盒子

    "InformationProxy",                  -- 收集个人信息

    "HorseProxy",                        -- 骑马

    "MeridianProxy",                     -- 内功经络

    "PurchaseProxy",                     -- 求购

    "RelationProxy",                     -- 关系

    "ManualService996Proxy",             -- 客服回话

    "ExchangeProxy",                     -- 交易所
}

return registerTable