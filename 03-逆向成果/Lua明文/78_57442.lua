local NoticeTable =
{
    -- start notice
    StartUp                               = "StartUp",                                      -- 框架启动

    GameResumed                           = "GameResumed",                                  -- 游戏从后台恢复
    GameSuspend                           = "GameSuspend",                                  -- 游戏挂起到后台
    GameSizeChanged                       = "GameSizeChanged",                              -- 游戏大小改变

    -- state trigger
    ChangeGameState                       = "ChangeGameState",                              -- 切换游戏状态
    EndGameState                          = "EndGameState",                                 -- 退出当前状态
    
    RestartGame                           = "RestartGame",                                  -- 重启游戏
    ShutdownGame                          = "ShutdownGame",                                 -- 关闭进程
    ReleaseMemory                         = "ReleaseMemory",                                -- 释放内存
    EnterLogin                            = "EnterLogin",                                   -- 进入登录
    LeaveRole                             = "LeaveRole",                                    -- 离开角色
    LeaveWorld                            = "LeaveWorld",                                   -- 离开游戏世界，返回角色界面
    RequestLeaveWorld                     = "RequestLeaveWorld",                            -- 请求 离开游戏世界，返回角色界面
    RequestShutdownGame                   = "RequestShutdownGame",                          -- 请求 关闭游戏

    -- loading
    LoadingBegin                          = "LoadingBegin",                                 -- loading开始
    LoadingCompleted                      = "LoadingCompleted",                             -- loading完成
    GameWorldConfirm                      = "GameWorldConfirm",                             -- 游戏确认进入
    GameWorldCheckTimeout                 = "GameWorldCheckTimeout",                        -- 游戏确认进入超时
    GameWorldInfoInitBegin                = "GameWorldInfoInitBegin",                       -- 游戏必要的数据初始化，比Init先到
    GameWorldInfoInit                     = "GameWorldInfoInit",                            -- 游戏必要的数据初始化
    GameWorldInitComplete                 = "GameWorldInitComplete",                        -- 游戏必要的数据初始化 完成
    ResetGameWorldSendHeartBeat           = "ResetGameWorldSendHeartBeat",                  -- 重置游戏世界发送心跳
    ResetGameWorldRecvHeartBeat           = "ResetGameWorldRecvHeartBeat",                  -- 重置游戏世界接收心跳

    -- register
    RegisterWorldController               = "RegisterWorldController",                      -- 注册world Controller
    RegisterWorldMediator                 = "RegisterWorldMediator",                        -- 注册world Mediator
    RegisterWorldProxy                    = "RegisterWorldProxy",                           -- 注册world Proxy
    UnRegisterWorldController             = "UnRegisterWorldController",                    -- 注销world Controller
    UnRegisterWorldMediator               = "UnRegisterWorldMediator",                      -- 注销world Mediator
    UnRegisterWorldProxy                  = "UnRegisterWorldProxy",                         -- 注销world Proxy

    -- func notice
    ChangeResolution                      = "ChangeResolution",                             -- 改变设计分辨率
    WindowResized                         = "WindowResized",                                -- 改变Window大小
    DRotationChanged                      = "DRotationChanged",                             -- 设备刘海屏方向改变
    DeviceRotationChanged                 = "DeviceRotationChanged",                        -- 设备方向改变

    -- shader
    GrayNodeShader                        = "GrayNodeShader",                               -- 把某个node渲染成灰色
    NormalNodeShader                      = "NormalNodeShader",                             -- 把某个node按正常渲染
    HighLightNodeShader                   = "HighLightNodeShader",                          -- 把某个node按高亮渲染
    GradientNodeShader                    = "GradientNodeShader",                           -- 渲染渐变色

    -- auto state
    AFKBegin                              = "AFKBegin",                                     -- 开始 挂机
    AFKEnd                                = "AFKEnd",                                       -- 结束 挂机
    AutoFightBegin                        = "AutoFightBegin",                               -- 开始 自动战斗
    AutoFightEnd                          = "AutoFightEnd",                                 -- 结束 自动战斗
    AutoMoveBegin                         = "AutoMoveBegin",                                -- 开始 自动寻路
    AutoMoveEnd                           = "AutoMoveEnd",                                  -- 结束 自动寻路
    AutoFindNPC                           = "AutoFindNPC",                                  -- 自动 锁定NPC
    AutoFindCollection                    = "AutoFindCollection",                           -- 自动 锁定采集物
    AutoFindDropItem                      = "AutoFindDropItem",                             -- 自动 锁定掉落物
    LaunchAttackSkill                     = "LaunchAttackSkill",                            -- 自动 释放强攻技能

    ClearAllInputState                    = "ClearAllInputState",                           -- 清理 输入状态
    ClearAllAutoState                     = "ClearAllAutoState",                            -- 清理 自动状态
    AutoPickBegin                         = "AutoPickBegin",                                -- 开始 自动捡物
    AutoPickEnd                           = "AutoPickEnd",                                  -- 结束 自动捡物
    AutoFightBack                         = "AutoFightBack",                                -- 自动反击


    -- scene
    ShakeScene                            = "ShakeScene",                                   -- 抖动场景
    RefreshActorSceneOptions              = "RefreshActorSceneOptions",                     -- 刷新一个角色的场景选项
    RefreshOneActorCloth                  = "RefreshOneActorCloth",                         -- 刷新一个角色的外观
    ShowThrowDamage                       = "ShowThrowDamage",                              -- 显示飘血(添加到队列)
    MapPickCursorPosChange                = "MapPickCursorPosChange",                       -- 场景点击特效
    SLThrowDamageNum                      = "SLThrowDamageNum",                             -- SL方法飘血(不添加到队列)


    -- actor action
    ActorEnterIdleAction                  = "ActorEnterIdleAction",                         -- 进入idle状态
    ActorEnterWalkAction                  = "ActorEnterWalkAction",                         -- 进入walk状态
    ActorEnterRunAction                   = "ActorEnterRunAction",                          -- 进入run状态
    ActorEnterAttackAction                = "ActorEnterAttackAction",                       -- 进入attack状态
    ActorEnterSkillAction                 = "ActorEnterSkillAction",                        -- 进入skill状态


    -- input
    InputIdle                             = "InputIdle",
    InputLaunch                           = "InputLaunch",
    InputMove                             = "InputMove",
    InputCorpse                           = "InputCorpse",
    InputMining                           = "InputMining",
    UserInputMove                         = "UserInputMove",                                -- 手动 发起移动
    UserInputLaunch                       = "UserInputLaunch",                              -- 手动 释放技能
    UserInputCorpse                       = "UserInputCorpse",                              -- 手动 挖尸体
    UserInputMining                       = "UserInputMining",                              -- 手动 挖矿
    UserPressedShift                      = "UserPressedShift",                             -- shift按下
    UserReleaseShift                      = "UserReleaseShift",                             -- shift抬起
    TargetChange                          = "TargetChange",                                 -- 目标改变

    --keep touch moving
    keepMovingBegin                       = "keepMovingBegin",                              -- 左右键触摸按住移动
    keepMovingUpdate                      = "keepMovingUpdate",
    keepMovingEnded                       = "keepMovingEnded",

    -- mouse move with actor events
    MouseMoveOutActorSide                 = "MouseMoveOutActorSide",                        -- 鼠标移出某个对象
    MouseMoveInActorSide                  = "MouseMoveInActorSide",                         -- 鼠标移入某个对象

    -- actor
    BindMainPlayer                        = "BindMainPlayer",                               -- 绑定主玩家
    ActorDie                              = "ActorDie",                                     -- actor 死亡
    ActorRevive                           = "ActorRevive",                                  -- actor 复活
    ActorPlayerDie                        = "ActorPlayerDie",                               -- player 死亡
    ActorMonsterDie                       = "ActorMonsterDie",                              -- monster 死亡
    ActorMonsterDeath                     = "ActorMonsterDeath",                            -- monster 死亡
    ActorMonsterBorn                      = "ActorMonsterBorn",                             -- monster 出生
    ActorMonsterBirth                     = "ActorMonsterBirth",                            -- monster 出生完成
    ActorMonsterCave                      = "ActorMonsterCave",                             -- monster 钻回地下
    ActorMonsterCaved                     = "ActorMonsterCaved",                            -- monster 钻回地下，完成
    ActorOutOfView                        = "ActorOutOfView",                               -- actor 从视野消失
    ActorInOfView                         = "ActorInOfView",                                -- actor 进入视野
    NpcInOfView                           = "NpcInOfView",                                  -- NPC进入视野
    NpcOutOfView                          = "NpcOutOfView",                                 -- NPC出视野
    DropItemOutOfView                     = "DropItemOutOfView",                            -- 掉落物 从视野消失
    DropItemInOfView                      = "DropItemInOfView",                             -- 掉落物 进入视野
    RefreshDropItem                       = "RefreshDropItem",                              -- 刷新掉落物信息
    ActorFeatureChange                    = "ActorFeatureChange",                           -- actor 外观改变
    MainPlayerDie                         = "MainPlayerDie",                                -- 主玩家死亡
    MainPlayerRevive                      = "MainPlayerRevive",                             -- 主玩家复活
    ActorSay                              = "ActorSay",                                     -- actor 说话
    RefreshActorBooth                     = "RefreshActorBooth",                            -- 摆摊名字改变
    PlayerStallStatusChange               = "PlayerStallStatusChange",                      -- 摆摊状态改变
    RefreshActorSafeZone                  = "RefreshActorSafeZone",                         -- 安全区状态
    ActorSafeZoneChange                   = "ActorSafeZoneChange",                          -- 安全区状态发生改变
    ActorMoveForce                        = "ActorMoveForce",                               -- actor 强制刷新位置
    ActorEffectOutOfView                  = "ActorEffectOutOfView",                         -- 特效出视野
    ActorEffectInOfView                   = "ActorEffectInOfView",                          -- 特效进入视野
    ActorMapXYChange                      = "ActorMapXYChange",                             -- actor map位置更改
    RefreshActorShaBaKeZone               = "RefreshActorShaBaKeZone",                      -- 沙巴克区域
    RefreshActorNameColor                 = "RefreshActorNameColor",                        -- 刷新actor名字颜色
    RefreshGuildActorColor                = "RefreshGuildActorColor",                       -- 刷新行会actor名字颜色
    
    -- actor feature
    SetPlayerFeature                      = "SetPlayerFeature",                             -- 设置player实际外观参数
    SetPlayerFeatureEX                    = "SetPlayerFeatureEX",                           -- 设置player要显示的外观参数(0:means cleanup)

    -- actor effect
    ActorCollect                          = "ActorCollect",                                 -- actor 采集标志
    ActorFlyIn                            = "ActorFlyIn",                                   -- actor 飞入
    ActorFlyOut                           = "ActorFlyOut",                                  -- actor 飞出

    -- actor buff
    AddBuffEntity                         = "AddBuffEntity",
    ActorBuffPresentUpdate                = "ActorBuffPresentUpdate",
    RefreshBuffVisible                    = "RefreshBuffVisible",

    -- HUD
    RefreshHUDLabel                       = "RefreshHUDLabel",                              -- HUD label 刷新
    RefreshHUDTitle                       = "RefreshHUDTitle",                              -- HUD title 刷新
    RefreshActorHP                        = "RefreshActorHP",                               -- 刷新 actor HP
    RefreshHUDHP                          = "RefreshHUDHP",
    RefreshActorIForce                    = "RefreshActorIForce",                           -- 刷新 actor 内力值

    -- delay refresh
    DelayRefreshHUDLabel                  = "DelayRefreshHUDLabel",
    DelayRefreshHUDLabelColor             = "DelayRefreshHUDLabelColor",  
    DelayRefreshHUDTitle                  = "DelayRefreshHUDTitle", 
    DelayActorFeatureChange               = "DelayActorFeatureChange",
    DelayCreateHUDBar                     = "DelayCreateHUDBar",
    DelayDirtyFeature                     = "DelayDirtyFeature",

    RefreshMoveInView                     = "RefreshMoveInView",                            -- 视野内怪物移动刷新 actor 显示


    -- summons alive status
    SummonsAliveStatusChange              = "SummonsAliveStatusChange",                     -- 召唤物存活状态更新


    -- audio
    Audio_Play                            = "Audio_Play",                                   -- 播放音频( 背景音乐、音效 )
    Audio_Play_BGM                        = "Audio_Play_BGM",                               -- 播放背景音乐
    Audio_Stop_BGM                        = "Audio_Stop_BGM",                               -- 关闭背景音乐
    Audio_Pause_BGM                       = "Audio_Pause_BGM",                              -- 暂停背景音乐
    Audio_Resume_BGM                      = "Audio_Resume_BGM",                             -- 恢复背景音乐
    Audio_Play_EffectId                   = "Audio_Play_EffectId",                          -- 播放音效
    Audio_Pause_All                       = "Audio_Pause_All",                              -- 暂停所有音效
    Audio_Resume_All                      = "Audio_Resume_All",                             -- 恢复所有音效
    Audio_Stop_All                        = "Audio_Stop_All",                               -- 停止所有音效
    Audio_Stop_EffectId                   = "Audio_Stop_EffectId",                          -- 停止对应音效

    -- ++++++++++++++++++++++++ model notice ++++++++++++++++++++++++
    -- 角色属性
    PlayerPropertyChange                  = "PlayerPropertyChange",                         -- 角色属性发生改变
    PlayerPropertyInited                  = "PlayerPropertyInited",                         -- 主角属性初始化完毕
    PlayerLevelChange                     = "PlayerLevelChange",                            -- 角色 等级 发生改变
    PlayerBeDamaged                       = "PlayerBeDamaged",                              -- 角色被攻击(掉血了)
    PlayerMoneyChange                     = "PlayerMoneyChange",                            -- 角色 money 发生改变
    PlayerLevelInit                       = "PlayerLevelInit",                              -- 角色等级初始化  红点用

    PlayerInternalLevelChange             = "PlayerInternalLevelChange",                    -- 人物内功等级改变
    HeroInternalLevelChange               = "HeroInternalLevelChange",                      -- 英雄内功等级改变

    -- 充值
    PayProductRequest                     = "PayProductRequest",                            -- 充值

    TakeOnRequest                         = "TakeOnRequest",                                -- 穿装备    请求
    TakeOffRequest                        = "TakeOffRequest",                               -- 脱装备    

    -- 技能相关
    RequestLaunchSkill                    = "RequestLaunchSkill",                           -- 请求释放技能
    RequestSkillPresent                   = "RequestSkillPresent",                          -- 请求技能表现

    SkillEnterCD                          = "SkillEnterCD",                                 -- 技能进入CD
    SkillCDTimeChange                     = "SkillCDTimeChange",                            -- 技能cd改变广播
    ClearSelectSkill                      = "ClearSelectSkill",
    
    ComboSkillEnterCD                     = "ComboSkillEnterCD",                            -- 连击技能进入CD

    -- 地图相关
    MapStateChange                        = "MapStateChange",                               -- 是否是安全区域
    MapInfoChange                         = "MapInfoChange",                                -- 地图信息改变
    ChangeScene                           = "ChangeScene",                                  -- 地图信息改变,类似于MapInfoChange
    InitedWorldTree                       = "InitedWorldTree",                              -- 初始化游戏树
    SiegeAreaChange                       = "SiegeAreaChange",                              -- 攻城区域改变
    SceneFollowMainPlayer                 = "SceneFollowMainPlayer",                        -- 地图跟随主玩家刷新

    -- for debug
    DebugMapOpen                          = "DebugMapOpen",                                 -- 调试地图 打开
    DebugMapClose                         = "DebugMapClose",                                -- 调试地图 关闭
    DebugMapSwitch                        = "DebugMapSwitch",                               -- 调试地图信息 开关
    PreviewAnimOpen                       = "PreviewAnimOpen",                              -- 预览动画 界面打开
    PreviewAnimClose                      = "PreviewAnimClose",                             -- 预览动画 界面关闭
    AnimSetOpen                           = "AnimSetOpen",                                  -- 预览动画设置 打开
    AnimSetClose                          = "AnimSetClose",                                 -- 预览动画设置 关闭
    Layer_RichTextTest_Open               = "Layer_RichTextTest_Open",
    Layer_RichTextTest_Close              = "Layer_RichTextTest_Close",

    -- picker相关
    PickerChange                          = "PickerChange",                                 -- picker改变

    MainPlayerActionBegan                 = "MainPlayerActionBegan",                        -- 动作 开始
    MainPlayerActionEnded                 = "MainPlayerActionEnded",                        -- 动作 结束
    MainPlayerActionProcess               = "MainPlayerActionProcess",                      -- 动作进行中

    -- ++++++++++++++++++++++++ model notice end ++++++++++++++++++++++++

    -- layer facade  所有的界面的开关都应发这2个通知
    Layer_Open                            = "Layer_Open",                                   -- 某个界面打开
    Layer_Close                           = "Layer_Close",                                  -- 某个关闭
    Layer_Close_Current                   = "Layer_Close_Current",                          -- 关闭当前界面
    Layer_Enter_Current                   = "Layer_Enter_Current",                          -- 确认当前界面
    Layer_SetMoveEnable                   = "Layer_SetMoveEnable",                          -- 设置界面可拖动
    Layer_HideMainEvent                   = "Layer_HideMainEvent",                          -- 隐藏主界面通知
    Layer_SetZOrderPanel                  = "Layer_SetZOrderPanel",                         -- 设置界面点击浮起块

    -- ++++++++++++++++++++++++ layer notice ++++++++++++++++++++++++

    -- 提示信息
    ShowServerNotice                      = "ShowServerNotice",                             -- 全服公告
    ShowSystemNotice                      = "ShowSystemNotice",                             -- 系统公告
    ShowTimerNotice                       = "ShowTimerNotice",                              -- 倒计时
    DeleteTimerNotice                     = "DeleteTimerNotice",                            -- 删除倒计时公告
    ShowSystemNoticeXY                    = "ShowSystemNoticeXY",
    ShowSystemNoticeScale                 = "ShowSystemNoticeScale",
    ShowTimerNoticeXY                     = "ShowTimerNoticeXY",
    DeleteTimerNoticeXY                   = "DeleteTimerNoticeXY",
    ServerNoticeEvent                     = "ServerNoticeEvent",
    SystemTips                            = "SystemTips",                                   -- 系统 提示信息(中间位置)
    ShowCostItem                          = "ShowCostItem",                                 -- 消耗物品提示
    ShowGetBagItem                        = "ShowGetBagItem",                               -- 获得物品提示
    ShowPlayerEXPNotice                   = "ShowPlayerEXPNotice",                          -- 获取经验提示XY
    Layer_Notice_Open                     = "Layer_Notice_Open",                            -- 通知 打开
    Layer_Notice_Close                    = "Layer_Notice_Close",                           -- 通知 关闭
    Layer_Notice_AddChild                 = "Layer_Notice_AddChild",
    Layer_Notice_RemoveChild              = "Layer_Notice_RemoveChild",

    -- main layer
    Layer_Main_Open                       = "Layer_Main_Open",                              -- 打开主界面
    Layer_Main_Init                       = "Layer_Main_Init",                              -- 初始化主界面
    Layer_Main_AddChild                   = "Layer_Main_AddChild",                          -- 添加view元素
    Layer_Main_Show                       = "Layer_Main_Show",                              -- 显示主界面
    Layer_Main_Hide                       = "Layer_Main_Hide",                              -- 隐藏主界面
    

    Layer_Login_Version_Open              = "Layer_Login_Version_Open",                     -- 版本号 打开
    Layer_Login_Version_Close             = "Layer_Login_Version_Close",                    -- 版本号 关闭

    -- buff 
    ForbiddenMoveBuffBegan                = "ForbiddenMoveBuffBegan",
    ForbiddenMoveBuffEnd                  = "ForbiddenMoveBuffEnd",

    --map minimap 小地图
    MapData_Load_Success                  = "MapData_Load_Success",                         -- 地图数据加载完成
    Map_Refresh_Throug_HHum               = "Map_Refresh_Throug_HHum",                      -- 刷新地图的穿人穿怪


    -- 充值
    Layer_Recharge_QRCode_Open            = "Layer_Recharge_QRCode_Open",
    Layer_Recharge_QRCode_Close           = "Layer_Recharge_QRCode_Close",

    -- 脚本组件
    SUIComponentAttach                    = "SUIComponentAttach",
    SUIComponentDetach                    = "SUIComponentDetach",
    SUIComponentUpdate                    = "SUIComponentUpdate",

    -- lua组件
    GUIComponentAttachOrDetch             = "GUIComponentAttachOrDetch",
    GUIComponentUpdate                    = "GUIComponentUpdate",
    GUI_ITEMBOX_Widget_Add                = "GUI_ITEMBOX_Widget_Add",
    GUI_ITEMBOX_Widget_Remove             = "GUI_ITEMBOX_Widget_Remove",
    GUI_ITEMBOX_Widget_Update             = "GUI_ITEMBOX_Widget_Update",

    -- sui
    SUIEditorOpen                         = "SUIEditorOpen",
    SUIEditorClose                        = "SUIEditorClose",
    SUIITEMBOXWidgetAdd                   = "SUIITEMBOXWidgetAdd",
    SUIITEMBOXPutoutAll                   = "SUIITEMBOXPutoutAll",
    SUIMetaWidgetAdd                      = "SUIMetaWidgetAdd",
    SUIConditionWidgetAdd                 = "SUIConditionWidgetAdd",                        -- 条件控件

    UserInputEventNotice                  = "UserInputEventNotice",

    CloudStorageInit                      = "CloudStorageInit",                             -- 云端存储

    Bag_Oper_Data_Delay                   = "Bag_Oper_Data_Delay",                          -- 背包数据操作
    HeroBag_Oper_Data_Delay               = "HeroBag_Oper_Data_Delay",                      -- 英雄背包数据操作

    IntoDropItem                          = "IntoDropItem",                                 -- 发起道具丢弃

    ItemUpdate                            = "ItemUpdate",                                   -- 更新道具属性

    -- 设置 setting
    GameSettingInited                     = "GameSettingInited",
    GameSettingChange                     = "GameSettingChange",
    GamePickSettingChange                 = "GamePickSettingChange",

    -- 设置个人信息收集清单
    Layer_SettingInformationCollect_Open  = "Layer_SettingInformationCollect_Open",
    Layer_SettingInformationCollect_Close = "Layer_SettingInformationCollect_Close",
    Layer_SettingInformationCollect_OnRefresh = "Layer_SettingInformationCollect_OnRefresh",

    -- NPC
    Layer_NPC_Talk_Open                   = "Layer_NPC_Talk_Open",                          -- NPC对话
    Layer_NPC_Talk_Close                  = "Layer_NPC_Talk_Close",                         -- 关闭NPC对话

    -- 断线重连相关
    Disconnect                            = "Disconnect",                                   -- 断线
    OtherClientLogin                      = "OtherClientLogin",                             -- 另外一个客户端登录
    Reconnect                             = "Reconnect",                                    -- 重连
    ReconnectForbidden                    = "ReconnectForbidden",                           -- 禁止断线重连
    ReconnectGameWorld                    = "ReconnectGameWorld",

    -- 屏蔽场景特效变更
    SetChange_AllPlayer                   = "SetChange_AllPlayer",                          -- 所有玩家 屏蔽设置的修改
    SetChange_OwnSidePlayer               = "SetChange_OwnSidePlayer",                      -- 己方玩家
    SetChange_AllEffect                   = "SetChange_AllEffect",                          -- 所有特效 (除技能特效2022.10.18 技能特效单独设置)
    SetChange_SkillEffect                 = "SetChange_SkillEffect",                        -- 屏蔽技能特效
    SetChange_NormalMonster               = "SetChange_NormalMonster",                      -- 普通怪物
    SetChange_MonsterPet                  = "SetChange_MonsterPet",                         -- 屏蔽召唤物
    SetChange_SimpleDressPlayer           = "SetChange_SimpleDressPlayer",                  -- 人物简装
    SetChange_SimpleDressMonster          = "SetChange_SimpleDressMonster",                 -- 怪物简装
    SetChange_SimpleDressMonsterBoss      = "SetChange_SimpleDressMonsterBoss",             -- Boss不简装
    SetChange_AllHero                     = "SetChange_AllHero",                            -- 英雄屏蔽设置

    MainActorChange_OwnSidePlayer         = "MainActorChange_OwnSidePlayer",                -- 主玩家改变 己方玩家改变

    Layer_FrameRateClose                  = "Layer_FrameRateClose",

    ReloadMap                             = "ReloadMap",                                    -- 重新加载地图

    Layer_Login_RoleLock_Open             = "Layer_Login_RoleLock_Open",                    -- （取回） 角色锁定 打开
    Layer_Login_RoleLock_Close            = "Layer_Login_RoleLock_Close",                   -- （取回） 角色锁定 关闭

    Layer_TradingBankFrame_Open                             = "Layer_TradingBankFrame_Open",                            -- 交易行外框
    Layer_TradingBankFrame_Close                            = "Layer_TradingBankFrame_Close",
    Layer_TradingBankBuyLayer_Open                          = "Layer_TradingBankBuyLayer_Open",                         -- 交易行购买
    Layer_TradingBankBuyLayer_Close                         = "Layer_TradingBankBuyLayer_Close",
    Layer_TradingBankPlayerInfo_Open                        = "Layer_TradingBankPlayerInfo_Open",                       -- 用户信息
    Layer_TradingBankPlayerInfo_Close                       = "Layer_TradingBankPlayerInfo_Close",
    Layer_TradingBankBuyTipsLayer_Open                      = "Layer_TradingBankBuyTipsLayer_Open",                     -- 筛选
    Layer_TradingBankBuyTipsLayer_Close                     = "Layer_TradingBankBuyTipsLayer_Close",
    Layer_TradingBankTipsLayer_Open                         = "Layer_TradingBankTipsLayer_Open",                        -- 提示
    Layer_TradingBankTipsLayer_Close                        = "Layer_TradingBankTipsLayer_Close",
    Layer_TradingBankTips2Layer_Open                        = "Layer_TradingBankTips2Layer_Open",                       -- 提示2
    Layer_TradingBankTips2Layer_Close                       = "Layer_TradingBankTips2Layer_Close",
    Layer_TradingBankBuyRoleLayer_Open                      = "Layer_TradingBankBuyRoleLayer_Open",                     -- 角色
    Layer_TradingBankBuyRoleLayer_Close                     = "Layer_TradingBankBuyRoleLayer_Close",
    Layer_TradingBankBuyRoleLayer_Search                    = "Layer_TradingBankBuyRoleLayer_Search",
    Layer_TradingBankBuyMoneyLayer_Open                     = "Layer_TradingBankBuyMoneyLayer_Open",                    -- 货币
    Layer_TradingBankBuyMoneyLayer_Close                    = "Layer_TradingBankBuyMoneyLayer_Close",
    Layer_TradingBankBuyEquipLayer_Open                     = "Layer_TradingBankBuyEquipLayer_Open",                    -- 装备
    Layer_TradingBankBuyEquipLayer_TypeChange               = "Layer_TradingBankBuyEquipLayer_TypeChange",
    Layer_TradingBankBuyEquipLayer_Search                   = "Layer_TradingBankBuyEquipLayer_Search",
    Layer_TradingBankBuyEquip_Tips                          = "Layer_TradingBankBuyEquip_Tips",
    Layer_TradingBankBuyEquipLayer_Close                    = "Layer_TradingBankBuyEquipLayer_Close",
    Layer_TradingBankUpModifyEquipPanel_Open                = "Layer_TradingBankUpModifyEquipPanel_Open",               -- 装备上架 修改价格
    Layer_TradingBankUpModifyEquipPanel_Close               = "Layer_TradingBankUpModifyEquipPanel_Close",
    Layer_TradingBankUpModifyEquipPanel_CheckSuccess        = "Layer_TradingBankUpModifyEquipPanel_CheckSuccess",
    Layer_TradingBankDownGetEquipPanel_Open                 = "Layer_TradingBankDownGetEquipPanel_Open",                -- 装备 下架 和取回
    Layer_TradingBankDownGetEquipPanel_Close                = "Layer_TradingBankDownGetEquipPanel_Close",
    Layer_TradingBankBuyMeLayer_Open                        = "Layer_TradingBankBuyMeLayer_Open",                       -- 指定我
    Layer_TradingBankBuyMeLayer_Close                       = "Layer_TradingBankBuyMeLayer_Close",
    Layer_TradingBankPhoneLayer_Open                        = "Layer_TradingBankPhoneLayer_Open",                       -- 验证手机
    Layer_TradingBankPhoneLayer_Close                       = "Layer_TradingBankPhoneLayer_Close",
    Layer_TradingBankZFLayer_Open                           = "Layer_TradingBankZFLayer_Open",                          -- 支付面板
    Layer_TradingBankZFLayer_Close                          = "Layer_TradingBankZFLayer_Close",
    Layer_TradingBankZFPanel_Open                           = "Layer_TradingBankZFPanel_Open",                          -- 支付面板
    Layer_TradingBankZFPanel_Close                          = "Layer_TradingBankZFPanel_Close",
    Layer_TradingBankCostZFLayer_Open                       = "Layer_TradingBankCostZFLayer_Open",
    Layer_TradingBankCostZFLayer_Close                      = "Layer_TradingBankCostZFLayer_Close",
    Layer_TradingBankCostZFPanel_Open                       = "Layer_TradingBankCostZFPanel_Open",
    Layer_TradingBankCostZFPanel_Close                      = "Layer_TradingBankCostZFPanel_Close",
    Layer_TradingBankSellLayer_Open                         = "Layer_TradingBankSellLayer_Open",                        -- 交易行寄售
    Layer_TradingBankSellLayer_RefGoodList                  = "Layer_TradingBankSellLayer_RefGoodList",
    Layer_TradingBankSellLayer_Close                        = "Layer_TradingBankSellLayer_Close",
    Layer_TradingBankZFPlayerLayer_Open                     = "Layer_TradingBankZFPlayerLayer_Open",
    Layer_TradingBankZFPlayerLayer_Close                    = "Layer_TradingBankZFPlayerLayer_Close",
    Layer_TradingBankGoodsLayer_Open                        = "Layer_TradingBankGoodsLayer_Open",                       -- 交易行货架
    Layer_TradingBankGoodsLayer_Close                       = "Layer_TradingBankGoodsLayer_Close",
    Layer_TradingBankMeLayer_Open                           = "Layer_TradingBankMeLayer_Open",                          -- 交易行我的
    Layer_TradingBankMeLayer_Close                          = "Layer_TradingBankMeLayer_Close",
    Layer_TradingBankSeekBuyLayer_Open                      = "Layer_TradingBankSeekBuyLayer_Open",                     -- 交易行求购
    Layer_TradingBankSeekBuyLayer_Close                     = "Layer_TradingBankSeekBuyLayer_Close",
    Layer_TradingBankSeekBuyLayer_Update                    = "Layer_TradingBankSeekBuyLayer_Update",
    Layer_TradingBankPurchasePowerfulLayer_Open             = "Layer_TradingBankPurchasePowerfulLayer_Open",            -- 求购支付
    Layer_TradingBankPurchasePowerfulLayer_Close            = "Layer_TradingBankPurchasePowerfulLayer_Close",
    Layer_TradingBankPowerfulLayer_Open                     = "Layer_TradingBankPowerfulLayer_Open",                    -- 支付
    Layer_TradingBankPowerfulLayer_Close                    = "Layer_TradingBankPowerfulLayer_Close",


    Layer_TradingBankSupplyMoneyPanel_Open                = "Layer_TradingBankSupplyMoneyPanel_Open",                   -- 供应货币
    Layer_TradingBankSupplyMoneyPanel_Close               = "Layer_TradingBankSupplyMoneyPanel_Close",
    Layer_TradingBankSupplyEquipPanel_Open                = "Layer_TradingBankSupplyEquipPanel_Open",                   -- 供应装备
    Layer_TradingBankSupplyEquipPanel_Close               = "Layer_TradingBankSupplyEquipPanel_Close",
    Layer_TradingBankPurchaseEquipPanel_Open              = "Layer_TradingBankPurchaseEquipPanel_Open",                  -- 求购装备 搜索
    Layer_TradingBankPurchaseEquipPanel_Close             = "Layer_TradingBankPurchaseEquipPanel_Close",

    Layer_TradingBankPurchasePayPanel_Open                = "Layer_TradingBankPurchasePayPanel_Open",                    -- 求购支付
    Layer_TradingBankPurchasePayPanel_Close               = "Layer_TradingBankPurchasePayPanel_Close",

    Layer_TradingBankOrderLayertwo_open                   = "Layer_TradingBankOrderLayertwo_open",                       -- 求购货币装备
    Layer_TradingBankOrderLayertwo_close                  = "Layer_TradingBankOrderLayertwo_close",
    Layer_TradingBankOrderLayer_Update                    = "Layer_TradingBankOrderLayer_Update",

    Layer_TradingBankCaptureLayer_Open                      = "Layer_TradingBankCaptureLayer_Open",                     -- 交易行截图
    Layer_TradingBankCaptureLayer_Close                     = "Layer_TradingBankCaptureLayer_Close",
    Layer_TradingBankCaptureMaskLayer_Open                  = "Layer_TradingBankCaptureMaskLayer_Open",
    Layer_TradingBankCaptureMaskLayer_Close                 = "Layer_TradingBankCaptureMaskLayer_Close",
    Layer_TradingBankLookTexture_Open                       = "Layer_TradingBankLookTexture_Open",                      -- 交易查看图片
    Layer_TradingBankLookTexture_Close                      = "Layer_TradingBankLookTexture_Close",
    Layer_TradingBankReceiveLayer_Open                      = "Layer_TradingBankReceiveLayer_Open",                     -- 收货
    Layer_TradingBankReceiveLayer_Close                     = "Layer_TradingBankReceiveLayer_Close",
    Layer_TradingBankRefuseLayer_Open                       = "Layer_TradingBankRefuseLayer_Open",                      -- 拒绝收货
    Layer_TradingBankRefuseLayer_Close                      = "Layer_TradingBankRefuseLayer_Close",

    ----------- 三方 交易行 ------------------
    Layer_TradingBankFrame_Open_other                       = "Layer_TradingBankFrame_Open_other",                      -- 交易行外框
    Layer_TradingBankFrame_Close_other                      = "Layer_TradingBankFrame_Close_other",
    Layer_TradingBankBuyLayer_Open_other                    = "Layer_TradingBankBuyLayer_Open_other",                   -- 交易行购买
    Layer_TradingBankBuyLayer_Close_other                   = "Layer_TradingBankBuyLayer_Close_other",
    Layer_TradingBankPlayerInfo_Open_other                  = "Layer_TradingBankPlayerInfo_Open_other",                 -- 用户信息
    Layer_TradingBankPlayerInfo_Close_other                 = "Layer_TradingBankPlayerInfo_Close_other",
    Layer_TradingBankBuyTipsLayer_Open_other                = "Layer_TradingBankBuyTipsLayer_Open_other",               -- 筛选
    Layer_TradingBankBuyTipsLayer_Close_other               = "Layer_TradingBankBuyTipsLayer_Close_other",
    Layer_TradingBankTipsLayer_Open_other                   = "Layer_TradingBankTipsLayer_Open_other",                  -- 提示
    Layer_TradingBankTipsLayer_Close_other                  = "Layer_TradingBankTipsLayer_Close_other",
    Layer_TradingBankTips2Layer_Open_other                  = "Layer_TradingBankTips2Layer_Open_other",                 -- 提示2
    Layer_TradingBankTips2Layer_Close_other                 = "Layer_TradingBankTips2Layer_Close_other",
    Layer_TradingBankBuyAllLayer_Open                       = "Layer_TradingBankBuyAllLayer_Open",                      --全部
    Layer_TradingBankBuyAllLayer_Close                      = "Layer_TradingBankBuyAllLayer_Close",
    Layer_TradingBankBuyRoleLayer_Open_other                = "Layer_TradingBankBuyRoleLayer_Open_other",               -- 角色
    Layer_TradingBankBuyRoleLayer_Close_other               = "Layer_TradingBankBuyRoleLayer_Close_other",
    Layer_TradingBankBuyRoleLayer_Search_other              = "Layer_TradingBankBuyRoleLayer_Search_other",
    Layer_TradingBankBuyMoneyLayer_Open_other               = "Layer_TradingBankBuyMoneyLayer_Open_other",              -- 货币
    Layer_TradingBankBuyMoneyLayer_Close_other              = "Layer_TradingBankBuyMoneyLayer_Close_other",
    Layer_TradingBankBuyRequestLayer_Open_other             = "Layer_TradingBankBuyRequestLayer_Open_other",            -- 求购
    Layer_TradingBankBuyRequestLayer_Close_other            = "Layer_TradingBankBuyRequestLayer_Close_other",
    Layer_TradingBankBuyRequestLayer_RefList_other          = "Layer_TradingBankBuyRequestLayer_RefList_other",
    Layer_TradingBankBuyMeLayer_Open_other                  = "Layer_TradingBankBuyMeLayer_Open_other",                 -- 指定我
    Layer_TradingBankBuyMeLayer_Close_other                 = "Layer_TradingBankBuyMeLayer_Close_other",
    Layer_TradingBankPhoneLayer_Open_other                  = "Layer_TradingBankPhoneLayer_Open_other",                 -- 验证手机
    Layer_TradingBankPhoneLayer_Close_other                 = "Layer_TradingBankPhoneLayer_Close_other", -- 
    Layer_TradingBankZFPanel_Open_other                     = "Layer_TradingBankZFPanel_Open_other",                    -- 支付面板
    Layer_TradingBankZFPanel_Close_other                    = "Layer_TradingBankZFPanel_Close_other",
    Layer_TradingBankCostZFLayer_Open_other                 = "Layer_TradingBankCostZFLayer_Open_other",
    Layer_TradingBankCostZFLayer_Close_other                = "Layer_TradingBankCostZFLayer_Close_other",
    Layer_TradingBankCostZFPanel_Open_other                 = "Layer_TradingBankCostZFPanel_Open_other",
    Layer_TradingBankCostZFPanel_Close_other                = "Layer_TradingBankCostZFPanel_Close_other",
    Layer_TradingBankSellLayer_Open_other                   = "Layer_TradingBankSellLayer_Open_other",                  -- 交易行寄售
    Layer_TradingBankSellLayer_Close_other                  = "Layer_TradingBankSellLayer_Close_other",
    Layer_TradingBankZFPlayerLayer_Open_other               = "Layer_TradingBankZFPlayerLayer_Open_other",
    Layer_TradingBankZFPlayerLayer_Close_other              = "Layer_TradingBankZFPlayerLayer_Close_other",
    Layer_TradingBankGoodsLayer_Open_other                  = "Layer_TradingBankGoodsLayer_Open_other",                 -- 交易行货架
    Layer_TradingBankGoodsLayer_Close_other                 = "Layer_TradingBankGoodsLayer_Close_other",
    Layer_TradingBankMeLayer_Open_other                     = "Layer_TradingBankMeLayer_Open_other",                    -- 交易行我的
    Layer_TradingBankMeLayer_Close_other                    = "Layer_TradingBankMeLayer_Close_other",
    Layer_TradingBankMeLayer_ShowGetMoneyRecord_other       = "Layer_TradingBankMeLayer_ShowGetMoneyRecord_other",
    Layer_TradingBankMeGetMoneyPanelLayer_Open_other        = "Layer_TradingBankMeGetMoneyPanelLayer_Open_other",
    Layer_TradingBankMeGetMoneyPanelLayer_Close_other       = "Layer_TradingBankMeGetMoneyPanelLayer_Close_other",
    Layer_TradingBankMeRecordPanelLayer_Open_other          = "Layer_TradingBankMeRecordPanelLayer_Open_other",
    Layer_TradingBankMeRecordPanelLayer_Close_other         = "Layer_TradingBankMeRecordPanelLayer_Close_other",
    Layer_TradingBankPowerfulLayer_Open_other               = "Layer_TradingBankPowerfulLayer_Open_other",              -- 支付
    Layer_TradingBankPowerfulLayer_Close_other              = "Layer_TradingBankPowerfulLayer_Close_other",
    Layer_TradingBankCaptureLayer_Open_other                = "Layer_TradingBankCaptureLayer_Open_other",               -- 交易行截图
    Layer_TradingBankCaptureLayer_Close_other               = "Layer_TradingBankCaptureLayer_Close_other",
    Layer_TradingBankCaptureMaskLayer_Open_other            = "Layer_TradingBankCaptureMaskLayer_Open_other",
    Layer_TradingBankCaptureMaskLayer_Close_other           = "Layer_TradingBankCaptureMaskLayer_Close_other",
    Layer_TradingBankLookTexture_Open_other                 = "Layer_TradingBankLookTexture_Open_other",                -- 交易查看图片
    Layer_TradingBankLookTexture_Close_other                = "Layer_TradingBankLookTexture_Close_other",
    Layer_TradingBankReceiveLayer_Open_other                = "Layer_TradingBankReceiveLayer_Open_other",               -- 收货
    Layer_TradingBankReceiveLayer_Close_other               = "Layer_TradingBankReceiveLayer_Close_other",
    Layer_TradingBankRefuseLayer_Open_other                 = "Layer_TradingBankRefuseLayer_Open_other",                -- 拒绝收货
    Layer_TradingBankRefuseLayer_Close_other                = "Layer_TradingBankRefuseLayer_Close_other",
    Layer_TradingBankWaitPayPanelLayer_Open_other           = "Layer_TradingBankWaitPayPanelLayer_Open_other",          -- 待支付
    Layer_TradingBankWaitPayPanelLayer_Close_other          = "Layer_TradingBankWaitPayPanelLayer_Close_other",
    Layer_TradingBankSuggestPanelLayer_Open_other           = "Layer_TradingBankSuggestPanelLayer_Open_other",          -- 意见反馈
    Layer_TradingBankSuggestPanelLayer_Close_other          = "Layer_TradingBankSuggestPanelLayer_Close_other",
    Layer_TradingBank_Interface_other                       = "Layer_TradingBank_Interface_other",                      -- 交易行接口
    Layer_TradingBankBindIdentityLayer_Open_other           = "Layer_TradingBankBindIdentityLayer_Open_other",          -- 身份证绑定
    Layer_TradingBankBindIdentityLayer_Close_other          = "Layer_TradingBankBindIdentityLayer_Close_other",
    Layer_TradingBankBuyServerNameTipsLayer_Open_other      = "Layer_TradingBankBuyServerNameTipsLayer_Open_other",
    Layer_TradingBankBuyServerNameTipsLayer_Close_other     = "Layer_TradingBankBuyServerNameTipsLayer_Close_other",
    Layer_TradingBankLookOtherServerPlayerLayer_Open_other  = "Layer_TradingBankLookOtherServerPlayerLayer_Open_other",
    Layer_TradingBankLookOtherServerPlayerLayer_Close_other = "Layer_TradingBankLookOtherServerPlayerLayer_Close_other",
    -----------------------------------------

    HeroBeDamaged                         = "HeroBeDamaged",                                -- 被攻击    

    TakeOnRequestFromHeroBag              = "TakeOnRequestFromHeroBag",                     -- 穿装备来源英雄背包    请求

    HeroTakeOnRequest                     = "HeroTakeOnRequest",                            -- 穿装备    请求
    HeroTakeOffRequest                    = "HeroTakeOffRequest",                           -- 脱装备    请求

    HeroTakeOffRequestToHumBag            = "HeroTakeOffRequestToHumBag",                   -- 脱装备到人物背包
    TakeOffToHeroBagRequest               = "TakeOffToHeroBagRequest",
    HeroTakeOnRequestFromHumBag           = "HeroTakeOnRequestFromHumBag",                  -- 穿装备    请求

    AutoPickupBySprite                    = "AutoPickupBySprite",                           -- 小精灵拾取

    ShowCostItem_Hero                     = "ShowCostItem_Hero",                            -- 消耗物品提示
    ShowGetBagItem_Hero                   = "ShowGetBagItem_Hero",                          -- 获得物品提示

    IntoDropItem_Hero                     = "IntoDropItem_Hero",                            -- 发起道具丢弃

    RealNameInfo                          = "RealNameInfo",                                 -- 实名认证


    ResolutionSizeChange                  = "ResolutionSizeChange",                         -- pc分辨率改变
    NPCTalkLayer_Open_Success             = "NPCTalkLayer_Open_Success",                    -- NPC打开完成
    PlayerAttribute_Change                = "PlayerAttribute_Change",                       -- 玩家属性改变
    PlayerReinLevelChange                 = "PlayerReinLevelChange",                        -- 转生改变
    PlayerAttribute_Change_Hero           = "PlayerAttribute_Change_Hero",                  -- 玩家属性改变
    PlayerReinLevelChange_Hero            = "PlayerReinLevelChange_Hero",                   -- 转生改变

    Layer_SettingFrame_Open               = "Layer_SettingFrame_Open",                      -- 设置
    Layer_SettingFrame_Close              = "Layer_SettingFrame_Close",
    Layer_SettingBasic_Open               = "Layer_SettingBasic_Open",                      -- 设置
    Layer_SettingBasic_Close              = "Layer_SettingBasic_Close",
    Layer_SettingWindowRange_Open         = "Layer_SettingWindowRange_Open",                -- 视距
    Layer_SettingWindowRange_Close        = "Layer_SettingWindowRange_Close", 
    Layer_SettingLaunch_Open              = "Layer_SettingLaunch_Open",                     -- 战斗
    Layer_SettingLaunch_Close             = "Layer_SettingLaunch_Close",
    
    Layer_SettingProtect_Open             = "Layer_SettingProtect_Open",                    -- 保护设置
    Layer_SettingProtect_Close            = "Layer_SettingProtect_Close",
    Layer_SettingAuto_Open                = "Layer_SettingAuto_Open",                       -- 挂机
    Layer_SettingAuto_Close               = "Layer_SettingAuto_Close", 
    Layer_SettingHelp_Open                = "Layer_SettingHelp_Open",
    Layer_SettingHelp_Close               = "Layer_SettingHelp_Close",
    Layer_SkillPanel_Open                 = "Layer_SkillPanel_Open",
    Layer_SkillPanel_Close                = "Layer_SkillPanel_Close",
    Layer_SkillRankPanel_Open             = "Layer_SkillRankPanel_Open",
    Layer_SkillRankPanel_Close            = "Layer_SkillRankPanel_Close",
    
    Refresh_RestoreRole_UI                = "Refresh_RestoreRole_UI",                       -- 恢复角色ui刷新
    TradingBank_other_Capture             = "TradingBank_other_Capture",                    -- 截图   
    Layer_CommunityLayer_Open             = "Layer_CommunityLayer_Open",                    -- 社区帖子
    Layer_CommunityLayer_Close            = "Layer_CommunityLayer_Close", 

    Layer_CacheTest_Open                  = "Layer_CacheTest_Open",
    Layer_CacheTest_Close                 = "Layer_CacheTest_Close", 
    
    Layer_GUIEditor_Open                  = "Layer_GUIEditor_Open",
    Layer_GUIEditor_Close                 = "Layer_GUIEditor_Close",

    Layer_GUIResSelector_Open             = "Layer_GUIResSelector_Open",
    Layer_GUIResSelector_Close            = "Layer_GUIResSelector_Close",

    Layer_GUIColorSelector_Open           = "Layer_GUIColorSelector_Open",
    Layer_GUIColorSelector_Close          = "Layer_GUIColorSelector_Close",

    Layer_ExtraColorEditor_Open           = "Layer_ExtraColorEditor_Open",
    Layer_ExtraColorEditor_Close          = "Layer_ExtraColorEditor_Close",

    -- 预览技能
    PreviewSkillOpen                      = "PreviewSkillOpen",                             -- 预览技能 界面打开
    PreviewSkillClose                     = "PreviewSkillClose",                            -- 预览技能 界面关闭
    -- 预览动作
    Preview_Skill_Action_Attach           = "Preview_Skill_Action_Attach",                  -- 预览技能动作
    Preview_Skill_Action_UnAttach         = "Preview_Skill_Action_UnAttach",
    Preview_Skill_Action_Refresh          = "Preview_Skill_Action_Refresh",

    -- 技能表
    MagicInfoOpen                         = "MagicInfoOpen",                                -- 技能表 界面打开
    MagicInfoClose                        = "MagicInfoClose",                               -- 技能表 界面关闭

    Layer_PreviewNode_Open                = "Layer_PreviewNode_Open",
    Layer_PreviewNode_Close               = "Layer_PreviewNode_Close",
    
    Layer_ConfigSetting_Open              = "Layer_ConfigSetting_Open",                     -- 配置表设置面板
    Layer_ConfigSetting_Close             = "Layer_ConfigSetting_Close",

    Layer_Box996Main_Open                 = "Layer_Box996Main_Open",                        --996传奇盒子
    Layer_Box996Main_Close                = "Layer_Box996Main_Close",                       --996传奇盒子
    Layer_Box996Main_Refresh              = "Layer_Box996Main_Refresh",                     --996传奇盒子
    Layer_Box996Title_Attach              = "Layer_Box996Title_Attach",                     --996传奇盒子  称号
    Layer_Box996Title_UnAttach            = "Layer_Box996Title_UnAttach",                   --996传奇盒子  称号
    Layer_Box996Title_Refresh             = "Layer_Box996Title_Refresh",                    --996传奇盒子  称号 刷新
    Layer_Box996EveryDay_Attach           = "Layer_Box996EveryDay_Attach",                  --996传奇盒子  每日礼包
    Layer_Box996EveryDay_UnAttach         = "Layer_Box996EveryDay_UnAttach",                --996传奇盒子  每日礼包
    Layer_Box996EveryDay_Refresh          = "Layer_Box996EveryDay_Refresh",                 --996传奇盒子  每日礼包 刷新
    Layer_Box996Super_Attach              = "Layer_Box996Super_Attach",                     --996传奇盒子  超级礼包
    Layer_Box996Super_UnAttach            = "Layer_Box996Super_UnAttach",                   --996传奇盒子  超级礼包
    Layer_Box996Super_Refresh             = "Layer_Box996Super_Refresh",                    --996传奇盒子  超级礼包 刷新
    Layer_Box996VIP_Attach                = "Layer_Box996VIP_Attach",                       --996传奇盒子  盒子vip会员
    Layer_Box996VIP_UnAttach              = "Layer_Box996VIP_UnAttach",                     --996传奇盒子  盒子vip会员
    Layer_Box996VIP_Refresh               = "Layer_Box996VIP_Refresh",                      --996传奇盒子  盒子vip会员 刷新
    Layer_Box996Guide_Open                = "Layer_Box996Guide_Open",                       --996传奇盒子  引导界面
    Layer_Box996Guide_Close               = "Layer_Box996Guide_Close",                      --996传奇盒子  引导界面
    Layer_Box996Guide_Refresh             = "Layer_Box996Guide_Refresh",                    --996传奇盒子  引导界面 刷新
    Layer_Box996SVIP_Attach               = "Layer_Box996SVIP_Attach",                      --996传奇盒子  svip
    Layer_Box996SVIP_UnAttach             = "Layer_Box996SVIP_UnAttach",                    --996传奇盒子  svip
    Layer_Box996SVIP_Refresh              = "Layer_Box996SVIP_Refresh",                     --996传奇盒子  svip 刷新
    Layer_Box996CloudPhone_Attach         = "Layer_Box996CloudPhone_Attach",                --996传奇盒子  云手机
    Layer_Box996CloudPhone_UnAttach       = "Layer_Box996CloudPhone_UnAttach",              --996传奇盒子  云手机
    Layer_Box996CloudPhone_Refresh        = "Layer_Box996CloudPhone_Refresh",               --996传奇盒子  云手机 刷新

    Scene_Weather_Effect_Add              = "Scene_Weather_Effect_Add",                     -- 新增地图天气特效
    Scene_Weather_Effect_Remove           = "Scene_Weather_Effect_Remove",                  -- 删除地图天气特效

    ShowItemDropNotice                    = "ShowItemDropNotice",                           -- 掉落物品提示
    Layer_Monster_Belong_TargetChange     = "Layer_Monster_Belong_TargetChange",            -- 快捷归属操作


    Server_Var_Change                     = "Server_Var_Change",                            -- 红点变量改变
    CustomAttrWidgetAdd                   = "CustomAttrWidgetAdd",                          -- 自定义角色属性添加
    AutoEquipShowWidgetAdd                = "AutoEquipShowWidgetAdd",                       -- 自定义EquipShow添加自动刷新

    AddBoxDayBtnToScreen                  = "AddBoxDayBtnToScreen",                         -- 添加天天省钱按钮
    AddTradingBankBtnToScreen             = "AddTradingBankBtnToScreen",                    -- 添加交易行按钮

    SUISlider_Value_Change                = "SUISlider_Value_Change",                       -- 脚本组件拉杆值变动


    Delay_Exit_Game_Window_Close_Notice   = "Delay_Exit_Game_Window_Close_Notice",          -- 延迟退出游戏通知
    Delay_Exit_Game_Window_Leave_World    = "Delay_Exit_Game_Window_Leave_World",           -- 游戏小退

    -- 通用消耗
    AddCostItemCell                       = "AddCostItemCell",
    RmvCostItemCell                       = "RmvCostItemCell",

    Layer_Manual_Service_996_Open               = "Layer_Manual_Service_996_Open",    -- 打开996客服WebView
    Layer_Manual_Service_996_Close              = "Layer_Manual_Service_996_Close",   -- 关闭996客服WebView

    CheckAutoTarget                       = "CheckAutoTarget",                              -- 检查近距离目标

}

return NoticeTable
